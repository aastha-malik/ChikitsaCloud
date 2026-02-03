from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def read_root():
    return {"message": "Welcome to Chikitsa Cloud API", "status": "running"}

@router.get("/health")
def health_check():
    return {"status": "ok", "service": "chikitsa-api"}
