from pydantic import BaseModel
from typing import Optional, List

class HospitalDetail(BaseModel):
    name: str
    address: Optional[str] = None
    phone: Optional[str] = None
    distance_km: float

class NearbyHospitalsResponse(BaseModel):
    count: int
    hospitals: List[HospitalDetail]
