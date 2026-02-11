from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.services import family_access_service
from app.schemas import family_access as schemas
from app.schemas.family_access import AccessRequestOut, FamilyAccessOut

from app.api.deps import get_current_user
from app.models.user import AuthUser

router = APIRouter(prefix="/family-access", tags=["Family Access"])

# --- Access Request Endpoints ---

@router.post("/request", response_model=AccessRequestOut)
def request_access(
    request_data: schemas.AccessRequestCreate,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.send_access_request(
        db, 
        current_user.id, 
        request_data.owner_user_id
    )


@router.post("/respond/{request_id}", response_model=AccessRequestOut)
def respond_to_request(
    request_id: UUID,
    response: schemas.AccessRequestResponse,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.respond_to_access_request(
        db,
        request_id,
        current_user.id,
        response.accept
    )


@router.get("/pending-requests", response_model=List[AccessRequestOut])
def get_pending_requests(
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.get_pending_requests_for_owner(db, current_user.id)


# --- Active Access Management ---

@router.get("/active-access", response_model=List[FamilyAccessOut])
def get_active_access(
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.get_active_access_for_owner(db, current_user.id)

@router.get("/shared-with-me", response_model=List[FamilyAccessOut])
def get_shared_access(
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.get_active_access_for_viewer(db, current_user.id)


@router.delete("/revoke/{viewer_id}")
def revoke_access(
    viewer_id: UUID,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.revoke_access(db, current_user.id, viewer_id)


# --- Permission Check Endpoint (for frontend validation) ---

@router.get("/can-view/{owner_id}")
def check_access_permission(
    owner_id: UUID,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    has_access = family_access_service.check_medical_record_access(
        db, 
        current_user.id, 
        owner_id
    )
    
    return {
        "has_access": has_access,
        "owner_id": owner_id,
        "viewer_id": current_user.id
    }


# --- QR Invite Endpoints ---

@router.post("/generate-invite", response_model=schemas.InviteTokenOut)
def generate_qr_invite(
    invite_config: schemas.InviteTokenCreate = schemas.InviteTokenCreate(),
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    token = family_access_service.generate_invite_token(
        db, 
        current_user.id, 
        invite_config.expires_in_hours
    )
    
    return schemas.InviteTokenOut(
        invite_token=token.invite_token,
        expires_at=token.expires_at,
        created_at=token.created_at
    )


@router.post("/redeem-invite", response_model=AccessRequestOut)
def redeem_invite_token(
    invite_data: schemas.InviteTokenRedeem,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return family_access_service.validate_and_redeem_invite_token(
        db,
        invite_data.invite_token,
        current_user.id
    )

