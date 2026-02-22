from fastapi import APIRouter, HTTPException, BackgroundTasks, Request
from app.schemas.feedback import FeedbackCreate
from app.services.email_service import send_feedback_email
from datetime import datetime
import time

router = APIRouter(prefix="/feedback", tags=["feedback"])

# Simple in-memory rate limiting: IP -> last_submission_time
# In production, use Redis or a similar persistent store
RATE_LIMIT_STORE = {}
RATE_LIMIT_SECONDS = 300  # 5 minutes between submissions per IP

@router.post("")
async def submit_feedback(
    request: Request,
    feedback: FeedbackCreate,
    background_tasks: BackgroundTasks
):
    """
    Submits anonymous feedback.
    - Validates rating (1-5)
    - Sanitizes message
    - Sends email in background
    - Implements basic rate limiting by IP
    """
    client_ip = request.client.host
    current_time = time.time()

    # Rate limiting check
    if client_ip in RATE_LIMIT_STORE:
        last_time = RATE_LIMIT_STORE[client_ip]
        if current_time - last_time < RATE_LIMIT_SECONDS:
            remaining = int(RATE_LIMIT_SECONDS - (current_time - last_time))
            raise HTTPException(
                status_code=429,
                detail=f"Too many submissions. Please wait {remaining} seconds."
            )

    # Update rate limit store
    RATE_LIMIT_STORE[client_ip] = current_time

    # Cleanup old entries occasionally (simple cleanup)
    if len(RATE_LIMIT_STORE) > 1000:
        expired = [ip for ip, t in RATE_LIMIT_STORE.items() if current_time - t > RATE_LIMIT_SECONDS]
        for ip in expired:
            del RATE_LIMIT_STORE[ip]

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Send email in background to keep response time fast
    background_tasks.add_task(
        send_feedback_email,
        rating=feedback.rating,
        message=feedback.message,
        timestamp=timestamp
    )

    return {"message": "Feedback submitted successfully. Thank you!"}
