from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def read_root():
    return {"message": "Welcome to Chikitsa Cloud API", "status": "running"}

@router.api_route("/health", methods=["GET", "HEAD"])
def health_check():
    return {"status": "ok", "service": "chikitsa-api"}
