from fastapi import APIRouter, Query, HTTPException, status
from typing import Optional
from app.services import hospital_service
from app.schemas.hospital import NearbyHospitalsResponse

router = APIRouter(prefix="/hospitals", tags=["Hospitals"])

@router.get("/nearby", response_model=NearbyHospitalsResponse)
async def get_nearby_hospitals(
    latitude: Optional[float] = Query(None, alias="latitude"),
    longitude: Optional[float] = Query(None, alias="longitude"),
    location_text: Optional[str] = Query(None)
):
    """
    Hospital Discovery API (MVP - Backend Controlled)
    
    1. Validates input (GPS Priority > Text)
    2. Coordinates resolution (Geocoding)
    3. Spatial search (Overpass API)
    4. Distance sorting (Nearest first)
    """
    
    target_lat, target_lon = None, None
    
    # --- Step 1: Input Validation & Resolution ---
    
    # Priority A: Live GPS
    if latitude is not None and longitude is not None:
        # Strict GPS Range Validation
        if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid coordinate ranges. Latitude [-90, 90], Longitude [-180, 180]."
            )
        target_lat, target_lon = latitude, longitude
        
    # Priority B: Manual Text
    elif location_text:
        # Resolve text to coordinates via service
        target_lat, target_lon = await hospital_service.geocode_location(location_text)
        
    else:
        # No valid input provided
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing location data. Provide 'latitude' & 'longitude' OR 'location_text'."
        )
    
    # --- Step 2: Hospital Search ---
    
    # Radius is hardcoded to 5km as per backend authority rules
    hospitals = await hospital_service.search_nearby_hospitals(target_lat, target_lon, radius_km=5)
    
    # --- Step 3: Strict Formatting ---
    # Return count 0 and empty list if no results found (per requirement)
    if not hospitals:
        return {
            "count": 0,
            "hospitals": []
        }
    
    return {
        "count": len(hospitals),
        "hospitals": hospitals
    }
