from pydantic import BaseModel, Field, validator
from typing import Optional

class FeedbackCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Star rating between 1 and 5")
    message: Optional[str] = Field(None, max_length=1000, description="Optional feedback message")

    @validator("message")
    def sanitize_message(cls, v):
        if v:
            # Basic sanitization: strip and remove any potential HTML tags (very simple)
            import html
            return html.escape(v.strip())
        return v
