from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from uuid import UUID
from datetime import datetime, timezone

from app.models.family_access import FamilyAccessRequest, FamilyMedicalAccess
from app.schemas.family_access import AccessRequestCreate, AccessRequestResponse

# --- Access Request Management ---

from app.models.user import AuthUser, UserProfile

def send_access_request(db: Session, requester_id: UUID, owner_id: UUID):
    if requester_id == owner_id:
        raise HTTPException(status_code=400, detail="You cannot request access to your own records.")
    
    # Check if access is already granted
    existing_access = db.query(FamilyMedicalAccess).filter(
        and_(FamilyMedicalAccess.owner_user_id == owner_id, FamilyMedicalAccess.viewer_user_id == requester_id)
    ).first()
    if existing_access:
        raise HTTPException(status_code=400, detail="Access has already been granted to this user.")

    # Check for existing pending request
    existing_request = db.query(FamilyAccessRequest).filter(
        and_(
            FamilyAccessRequest.requester_user_id == requester_id,
            FamilyAccessRequest.owner_user_id == owner_id,
            FamilyAccessRequest.status == "pending"
        )
    ).first()
    if existing_request:
        raise HTTPException(status_code=400, detail="An access request is already pending for this user.")
    
    new_request = FamilyAccessRequest(requester_user_id=requester_id, owner_user_id=owner_id)
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

def _map_request(db, r):
    req_profile = db.query(UserProfile).filter(UserProfile.user_id == r.requester_user_id).first()
    req_auth = db.query(AuthUser).filter(AuthUser.id == r.requester_user_id).first()
    own_profile = db.query(UserProfile).filter(UserProfile.id == r.owner_user_id).first()
    own_auth = db.query(AuthUser).filter(AuthUser.id == r.owner_user_id).first()
    
    r.requester_name = req_profile.name if req_profile else "Unknown"
    r.requester_email = req_auth.email if req_auth else "N/A"
    r.owner_name = own_profile.name if own_profile else "Unknown"
    r.owner_email = own_auth.email if own_auth else "N/A"
    return r

def get_pending_requests_for_owner(db: Session, owner_id: UUID):
    requests = db.query(FamilyAccessRequest).filter(
        and_(FamilyAccessRequest.owner_user_id == owner_id, FamilyAccessRequest.status == "pending")
    ).all()
    return [_map_request(db, r) for r in requests]

def respond_to_access_request(db: Session, request_id: UUID, owner_id: UUID, accept: bool):
    request = db.query(FamilyAccessRequest).filter(FamilyAccessRequest.id == request_id).first()
    if not request or request.owner_user_id != owner_id:
        raise HTTPException(status_code=404, detail="Request not found")
    
    request.status = "accepted" if accept else "rejected"
    request.responded_at = datetime.now(timezone.utc)
    
    if accept:
        access = db.query(FamilyMedicalAccess).filter(
            and_(FamilyMedicalAccess.owner_user_id == owner_id, FamilyMedicalAccess.viewer_user_id == request.requester_user_id)
        ).first()
        if not access:
            access = FamilyMedicalAccess(owner_user_id=owner_id, viewer_user_id=request.requester_user_id)
            db.add(access)
    
    db.commit()
    db.refresh(request)
    return _map_request(db, request)

def get_active_access_for_owner(db: Session, owner_id: UUID):
    access_list = db.query(FamilyMedicalAccess).filter(FamilyMedicalAccess.owner_user_id == owner_id).all()
    for a in access_list:
        p = db.query(UserProfile).filter(UserProfile.user_id == a.viewer_user_id).first()
        u = db.query(AuthUser).filter(AuthUser.id == a.viewer_user_id).first()
        a.viewer_name = p.name if p else "Unknown"
        a.viewer_email = u.email if u else "N/A"
    return access_list

def get_active_access_for_viewer(db: Session, viewer_id: UUID):
    access_list = db.query(FamilyMedicalAccess).filter(FamilyMedicalAccess.viewer_user_id == viewer_id).all()
    for a in access_list:
        p = db.query(UserProfile).filter(UserProfile.user_id == a.owner_user_id).first()
        u = db.query(AuthUser).filter(AuthUser.id == a.owner_user_id).first()
        a.owner_name = p.name if p else "Unknown"
        a.owner_email = u.email if u else "N/A"
    return access_list

def revoke_access(db: Session, owner_id: UUID, viewer_id: UUID):
    access = db.query(FamilyMedicalAccess).filter(
        and_(FamilyMedicalAccess.owner_user_id == owner_id, FamilyMedicalAccess.viewer_user_id == viewer_id)
    ).first()
    if not access:
        raise HTTPException(status_code=404, detail="Access not found")
    db.delete(access)
    db.commit()
    return {"message": "Access revoked"}

def check_medical_record_access(db: Session, viewer_id: UUID, owner_id: UUID) -> bool:
    if viewer_id == owner_id: return True
    access = db.query(FamilyMedicalAccess).filter(
        and_(FamilyMedicalAccess.owner_user_id == owner_id, FamilyMedicalAccess.viewer_user_id == viewer_id)
    ).first()
    return access is not None

def enforce_medical_record_access(db: Session, viewer_id: UUID, owner_id: UUID):
    if not check_medical_record_access(db, viewer_id, owner_id):
        raise HTTPException(status_code=403, detail="Access denied")

def generate_invite_token(db: Session, owner_id: UUID, expires_in_hours: int = 24):
    import secrets
    from datetime import timedelta
    from app.models.family_access import FamilyInviteToken
    
    # Reuse existing unexpired unused token
    existing_token = db.query(FamilyInviteToken).filter(
        and_(
            FamilyInviteToken.owner_user_id == owner_id,
            FamilyInviteToken.is_used == False,
            FamilyInviteToken.expires_at > datetime.now(timezone.utc)
        )
    ).order_by(FamilyInviteToken.created_at.desc()).first()
    
    if existing_token:
        return existing_token

    invite_token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expires_in_hours)
    new_token = FamilyInviteToken(owner_user_id=owner_id, invite_token=invite_token, expires_at=expires_at)
    db.add(new_token)
    db.commit()
    db.refresh(new_token)
    return new_token

def validate_and_redeem_invite_token(db: Session, invite_token: str, requester_id: UUID):
    from app.models.family_access import FamilyInviteToken
    token_record = db.query(FamilyInviteToken).filter(FamilyInviteToken.invite_token == invite_token).first()
    
    if not token_record:
        print(f"[WARNING] Redeem failed: Token '{invite_token[:8]}...' not found in DB")
        raise HTTPException(status_code=400, detail="Invalid QR code or invite token.")
    
    print(f"[DEBUG] Found token for owner: {token_record.owner_user_id}, used status: {token_record.is_used}")
        
    if token_record.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="This invite has expired.")

    if token_record.owner_user_id == requester_id:
        raise HTTPException(status_code=400, detail="You cannot redeem your own invite.")
    
    # If already used, check who used it
    if token_record.is_used:
        if token_record.used_by_user_id == requester_id:
            # Already redeemed by THIS user, treat as success/exists
            return {
                "id": requester_id, 
                "requester_user_id": requester_id,
                "owner_user_id": token_record.owner_user_id,
                "status": "already_exists",
                "created_at": token_record.used_at or datetime.now(timezone.utc),
                "message": "You have already redeemed this invite."
            }
        else:
            raise HTTPException(status_code=400, detail="This invite has already been used by another user.")

    # Mark as used
    token_record.is_used = True
    token_record.used_by_user_id = requester_id
    token_record.used_at = datetime.now(timezone.utc)
    db.commit() # Commit the 'used' status first to prevent race conditions
    
    try:
        req = send_access_request(db, requester_id, token_record.owner_user_id)
        print(f"[SUCCESS] Redeemed invite: Request {req.id} created")
        return _map_request(db, req)
    except HTTPException as e:
        if "already" in str(e.detail).lower() or "pending" in str(e.detail).lower():
            # If it's just that they already have it, treat as 200 OK
            print(f"[INFO] Invite redemption skip: {e.detail}")
            return {
                "id": requester_id, 
                "requester_user_id": requester_id,
                "owner_user_id": token_record.owner_user_id,
                "status": "already_exists",
                "created_at": datetime.now(timezone.utc),
                "message": e.detail
            }
        raise e

