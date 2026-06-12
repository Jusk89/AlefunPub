from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.campaign import CampaignTargetGroup


class CampaignBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    message: str = Field(..., min_length=2)
    target_group: CampaignTargetGroup
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    is_active: bool = True


class CampaignCreate(CampaignBase):
    pass


class CampaignUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=255)
    message: str | None = Field(default=None, min_length=2)
    target_group: CampaignTargetGroup | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    is_active: bool | None = None


class CampaignRead(CampaignBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
