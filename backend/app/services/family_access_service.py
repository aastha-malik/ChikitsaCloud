from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from uuid import UUID
from datetime import datetime, timezone

from app.models.family_access import FamilyAccessRequest, FamilyMedicalAccess
from app.schemas.family_access import AccessRequestCreate, AccessRequestResponse

# --- Access Request Management ---

def send_access_request(db: Session, requester_id: UUID, owner_id: UUID):
    """
    Create a new access request.
    Does NOT grant access automatically.
    """
    # 1. Prevent self-requests
    if requester_id == owner_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot request access to your own records"
        )
    
    # 2. Check for existing pending request
    existing = db.query(FamilyAccessRequest).filter(
        and_(
            FamilyAccessRequest.requester_user_id == requester_id,
            FamilyAccessRequest.owner_user_id == owner_id,
            FamilyAccessRequest.status == "pending"
        )
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Access request already pending"
        )
    
    # 3. Check if access already granted
    existing_access = db.query(FamilyMedicalAccess).filter(
        and_(
            FamilyMedicalAccess.owner_user_id == owner_id,
            FamilyMedicalAccess.viewer_user_id == requester_id
        )
    ).first()
    
    if existing_access:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Access already granted"
        )
    
    # 4. Create request
    new_request = FamilyAccessRequest(
        requester_user_id=requester_id,
        owner_user_id=owner_id,
        status="pending"
    )
    
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    
    return new_request


def respond_to_access_request(db: Session, request_id: UUID, owner_id: UUID, accept: bool):
    """
    Owner accepts or rejects an access request.
    Only owner can respond.
    """
    # 1. Get request
    request = db.query(FamilyAccessRequest).filter(
        FamilyAccessRequest.id == request_id
    ).first()
    
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Access request not found"
        )
    
    # 2. Verify ownership
    if request.owner_user_id != owner_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the owner can respond to this request"
        )
    
    # 3. Check if already responded
    if request.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Request already {request.status}"
        )
    
    # 4. Update request
    request.status = "accepted" if accept else "rejected"
    request.responded_at = datetime.now(timezone.utc)
    
    # 5. If accepted, create access record
    if accept:
        new_access = FamilyMedicalAccess(
            owner_user_id=request.owner_user_id,
            viewer_user_id=request.requester_user_id,
            can_view_medical_records=True
        )
        db.add(new_access)
    
    db.commit()
    db.refresh(request)
    
    return request


def revoke_access(db: Session, owner_id: UUID, viewer_id: UUID):
    """
    Owner revokes viewer's access.
    Immediate effect.
    """
    access = db.query(FamilyMedicalAccess).filter(
        and_(
            FamilyMedicalAccess.owner_user_id == owner_id,
            FamilyMedicalAccess.viewer_user_id == viewer_id
        )
    ).first()
    
    if not access:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active access found"
        )
    
    db.delete(access)
    db.commit()
    
    return {"message": "Access revoked successfully"}


def get_pending_requests_for_owner(db: Session, owner_id: UUID):
    """
    Get all pending access requests for a user (as owner).
    """
    return db.query(FamilyAccessRequest).filter(
        and_(
            FamilyAccessRequest.owner_user_id == owner_id,
            FamilyAccessRequest.status == "pending"
        )
    ).all()


def get_active_access_for_owner(db: Session, owner_id: UUID):
    """
    Get all users who have access to owner's records.
    """
    return db.query(FamilyMedicalAccess).filter(
        FamilyMedicalAccess.owner_user_id == owner_id
    ).all()


# --- Permission Validation ---

def check_medical_record_access(db: Session, viewer_id: UUID, owner_id: UUID) -> bool:
    """
    Backend enforcement: Check if viewer has permission to view owner's records.
    Returns True only if explicit access exists.
    """
    # Owner can always view their own records
    if viewer_id == owner_id:
        return True
    
    # Check for active access grant
    access = db.query(FamilyMedicalAccess).filter(
        and_(
            FamilyMedicalAccess.owner_user_id == owner_id,
            FamilyMedicalAccess.viewer_user_id == viewer_id,
            FamilyMedicalAccess.can_view_medical_records == True
        )
    ).first()
    
    return access is not None



def enforce_medical_record_access(db: Session, viewer_id: UUID, owner_id: UUID):
    """
    Utility to check access and automatically raise 403 Forbidden if denied.
    Enforces that viewer has read-access to owner's records.
    """
    if not check_medical_record_access(db, viewer_id, owner_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. You do not have permission to access these medical records."
        )



# --- Invite Token Management ---

def generate_invite_token(db: Session, owner_id: UUID, expires_in_hours: int = 24):
    """
    Generate a temporary invite token for QR sharing.
    Called by owner (User A) to share access via QR code.
    
    Returns:
        - invite_token: Random string
        - expires_at: Expiration timestamp
    
    Does NOT grant access automatically.
    """
    import secrets
    from datetime import timedelta
    from app.models.family_access import FamilyInviteToken
    
    # Generate secure random token
    invite_token = secrets.token_urlsafe(32)
    
    # Calculate expiry
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expires_in_hours)
    
    # Create token record
    new_token = FamilyInviteToken(
        owner_user_id=owner_id,
        invite_token=invite_token,
        expires_at=expires_at,
        is_used=False
    )
    
    db.add(new_token)
    db.commit()
    db.refresh(new_token)
    
    return new_token


def validate_and_redeem_invite_token(db: Session, invite_token: str, requester_id: UUID):
    """
    Validate scanned invite token and create access request.
    Called when requester (User B) scans QR code.
    
    Steps:
        1. Check token exists and not expired
        2. Check token not already used
        3. Get owner_user_id from token
        4. Create FamilyAccessRequest (status=pending)
        5. Mark token as used
        
    Returns access request (still requires owner approval).
    Does NOT grant automatic access.
    """
    from app.models.family_access import FamilyInviteToken
    
    # 1. Find token
    token_record = db.query(FamilyInviteToken).filter(
        FamilyInviteToken.invite_token == invite_token
    ).first()
    
    if not token_record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid invite token"
        )
    
    # 2. Check expiry
    if token_record.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invite token has expired"
        )
    
    # 3. Check if already used
    if token_record.is_used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invite token has already been used"
        )
    
    # 4. Prevent self-redemption
    if token_record.owner_user_id == requester_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot use your own invite token"
        )
    
    # 5. Check if access already exists or pending
    existing_request = db.query(FamilyAccessRequest).filter(
        and_(
            FamilyAccessRequest.requester_user_id == requester_id,
            FamilyAccessRequest.owner_user_id == token_record.owner_user_id,
            FamilyAccessRequest.status == "pending"
        )
    ).first()
    
    if existing_request:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Access request already pending"
        )
    
    existing_access = db.query(FamilyMedicalAccess).filter(
        and_(
            FamilyMedicalAccess.owner_user_id == token_record.owner_user_id,
            FamilyMedicalAccess.viewer_user_id == requester_id
        )
    ).first()
    
    if existing_access:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Access already granted"
        )
    
    # 6. Create access request (pending approval)
    new_request = FamilyAccessRequest(
        requester_user_id=requester_id,
        owner_user_id=token_record.owner_user_id,
        status="pending"
    )
    
    db.add(new_request)
    
    # 7. Mark token as used
    token_record.is_used = True
    token_record.used_by_user_id = requester_id
    token_record.used_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(new_request)
    
    return new_request

