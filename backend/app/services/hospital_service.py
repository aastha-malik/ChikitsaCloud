import httpx
from typing import List, Optional, Tuple
from fastapi import HTTPException, status
from app.core.geo_utils import calculate_haversine_distance

# External API Constants
NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USER_AGENT = "ChikitsaCloud_HealthApp/1.0 (contact: admin@chikitsacloud.com)"

async def geocode_location(location_text: str) -> Tuple[float, float]:
    """
    Service: Convert manual text input to coordinates.
    Uses Nominatim API.
    """
    params = {
        "q": location_text,
        "format": "json",
        "limit": 1
    }
    headers = {"User-Agent": USER_AGENT}
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(NOMINATIM_URL, params=params, headers=headers, timeout=10.0)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY, 
                    detail="Geocoding service unavailable"
                )
            
            data = response.json()
            if not data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND, 
                    detail=f"Location '{location_text}' could not be resolved."
                )
            
            return float(data[0]["lat"]), float(data[0]["lon"])
            
    except (httpx.RequestError, httpx.TimeoutException):
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT, 
            detail="Timeout reaching geocoding service"
        )
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Internal error during geocoding: {str(e)}"
        )

async def search_nearby_hospitals(lat: float, lon: float, radius_km: int = 5) -> List[dict]:
    """
    Service: Search for hospitals within a fixed radius.
    Uses Overpass API.
    """
    radius_meters = radius_km * 1000
    
    # Overpass QL Query: Search for nodes/ways tagged as hospital
    query = f"""
    [out:json];
    (
      node["amenity"="hospital"](around:{radius_meters},{lat},{lon});
      way["amenity"="hospital"](around:{radius_meters},{lat},{lon});
    );
    out center;
    """
    
    headers = {"User-Agent": USER_AGENT}
    print(f"[DEBUG] Searching hospitals near {lat}, {lon} with radius {radius_km}km")
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(OVERPASS_URL, data={"data": query}, headers=headers, timeout=15.0)
            
            if response.status_code != 200:
                print(f"[ERROR] Overpass API failed with status {response.status_code}: {response.text}")
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY, 
                    detail=f"Hospital discovery service temporarily unavailable (Code: {response.status_code})"
                )
            
            data = response.json()
            elements = data.get("elements", [])
            print(f"[DEBUG] Found {len(elements)} raw elements from Overpass")
            
            hospitals = []
            for element in elements:
                tags = element.get("tags", {})
                
                # Extraction
                name = tags.get("name", "Unnamed Hospital")
                phone = tags.get("phone") or tags.get("contact:phone") or tags.get("phone:reception")
                
                # Address Formatting
                addr_parts = [
                    tags.get("addr:housenumber"),
                    tags.get("addr:street"),
                    tags.get("addr:suburb") or tags.get("addr:neighbourhood"),
                    tags.get("addr:city")
                ]
                address = ", ".join([p for p in addr_parts if p]) or None
                
                # Coordinate fallback for ways
                h_lat = element.get("lat") or element.get("center", {}).get("lat")
                h_lon = element.get("lon") or element.get("center", {}).get("lon")
                
                if h_lat is not None and h_lon is not None:
                    dist = calculate_haversine_distance(lat, lon, float(h_lat), float(h_lon))
                    hospitals.append({
                        "name": name,
                        "address": address,
                        "phone": phone,
                        "distance_km": dist
                    })
            
            # Sort by nearest first
            hospitals.sort(key=lambda x: x["distance_km"])
            
            # Return max 10
            return hospitals[:10]
            
    except (httpx.RequestError, httpx.TimeoutException):
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT, 
            detail="Timeout reaching hospital data service"
        )
    except Exception as e:
        if isinstance(e, HTTPException): raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error searching hospitals: {str(e)}"
        )
