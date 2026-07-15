from pydantic import BaseModel, Field


class MotifBiometrique(BaseModel):
    motif: str = Field(min_length=3, max_length=500)
