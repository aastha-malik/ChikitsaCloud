from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.services import family_access_service
from app.schemas import family_access as schemas
from app.schemas.family_access import AccessRequestOut, FamilyAccessOut

router = APIRouter(prefix="/family-access", tags=["Family Access"])

# --- Access Request Endpoints ---

@router.post("/request", response_model=AccessRequestOut)
def request_access(
    requester_id: UUID,  # TODO: Replace with current_user from JWT
    request_data: schemas.AccessRequestCreate,
    db: Session = Depends(get_db)
):
    """
    Send an access request to another user.
    Does NOT grant access automatically.
    """
    return family_access_service.send_access_request(
        db, 
        requester_id, 
        request_data.owner_user_id
    )


@router.post("/respond/{request_id}", response_model=AccessRequestOut)
def respond_to_request(
    request_id: UUID,
    owner_id: UUID,  # TODO: Replace with current_user from JWT
    response: schemas.AccessRequestResponse,
    db: Session = Depends(get_db)
):
    """
    Accept or reject an access request.
    Only the owner can respond.
    On accept, creates active access grant.
    """
    return family_access_service.respond_to_access_request(
        db,
        request_id,
        owner_id,
        response.accept
    )


@router.get("/pending-requests", response_model=List[AccessRequestOut])
def get_pending_requests(
    owner_id: UUID,  # TODO: Replace with current_user from JWT
    db: Session = Depends(get_db)
):
    """
    Get all pending access requests for the current user.
    """
    return family_access_service.get_pending_requests_for_owner(db, owner_id)


# --- Active Access Management ---

@router.get("/active-access", response_model=List[FamilyAccessOut])
def get_active_access(
    owner_id: UUID,  # TODO: Replace with current_user from JWT
    db: Session = Depends(get_db)
):
    """
    Get all users who currently have access to your medical records.
    """
    return family_access_service.get_active_access_for_owner(db, owner_id)


@router.delete("/revoke/{viewer_id}")
def revoke_access(
    viewer_id: UUID,
    owner_id: UUID,  # TODO: Replace with current_user from JWT
    db: Session = Depends(get_db)
):
    """
    Revoke a user's access to your medical records.
    Takes effect immediately.
    """
    return family_access_service.revoke_access(db, owner_id, viewer_id)


# --- Permission Check Endpoint (for frontend validation) ---

@router.get("/can-view/{owner_id}")
def check_access_permission(
    owner_id: UUID,
    viewer_id: UUID,  # TODO: Replace with current_user from JWT
    db: Session = Depends(get_db)
):
    """
    Check if viewer has permission to view owner's medical records.
    Backend is the source of truth.
    """
    has_access = family_access_service.check_medical_record_access(
        db, 
        viewer_id, 
        owner_id
    )
    
    return {
        "has_access": has_access,
        "owner_id": owner_id,
        "viewer_id": viewer_id
    }


# --- QR Invite Endpoints ---

@router.post("/generate-invite", response_model=schemas.InviteTokenOut)
def generate_qr_invite(
    owner_id: UUID,  # TODO: Replace with current_user from JWT
    invite_config: schemas.InviteTokenCreate = schemas.InviteTokenCreate(),
    db: Session = Depends(get_db)
):
    """
    Generate a temporary invite token for QR code sharing.
    
    Owner (User A) calls this to create a shareable QR code.
    
    Returns:
        - invite_token: Random string (use this for QR code)
        - expires_at: When token expires
        - created_at: When token was created
    
    The token does NOT contain user_id and does NOT grant automatic access.
    """
    token = family_access_service.generate_invite_token(
        db, 
        owner_id, 
        invite_config.expires_in_hours
    )
    
    return schemas.InviteTokenOut(
        invite_token=token.invite_token,
        expires_at=token.expires_at,
        created_at=token.created_at
    )


@router.post("/redeem-invite", response_model=AccessRequestOut)
def redeem_invite_token(
    requester_id: UUID,  # TODO: Replace with current_user from JWT
    invite_data: schemas.InviteTokenRedeem,
    db: Session = Depends(get_db)
):
    """
    Redeem a scanned invite token.
    
    Requester (User B) calls this after scanning QR code.
    
    Steps:
        1. Validates token (exists, not expired, not used)
        2. Creates access request (status = pending)
        3. Marks token as used
        
    Returns the access request (owner must still approve).
    Does NOT grant automatic access.
    """
    return family_access_service.validate_and_redeem_invite_token(
        db,
        invite_data.invite_token,
        requester_id
    )

