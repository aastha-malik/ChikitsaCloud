from fastapi import APIRouter, Query, HTTPException, status
from typing import Optional, List
from app.services import hospital_service
from app.schemas import hospital as schemas

router = APIRouter(prefix="/hospitals", tags=["Hospitals"])

@router.get("/nearby", response_model=List[schemas.HospitalDetail])
async def get_nearby_hospitals(
    lat: Optional[float] = Query(None),
    lng: Optional[float] = Query(None),
    location: Optional[str] = Query(None)
):
    """
    Hospital Discovery API
    - GPS Priority (lat/lng)
    - Fallback to manual location text
    - Returns flat list of hospitals
    """
    target_lat, target_lng = None, None

    if lat is not None and lng is not None:
        if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
            raise HTTPException(status_code=400, detail="Invalid coordinates")
        target_lat, target_lng = lat, lng
    elif location:
        target_lat, target_lng = await hospital_service.geocode_location(location)
    else:
        raise HTTPException(status_code=400, detail="Missing location data")

    hospitals = await hospital_service.search_nearby_hospitals(target_lat, target_lng, radius_km=10)
    return hospitals
