from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.campaign import CampaignTargetGroup


class CampaignBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    description: str = Field(..., min_length=2)
    image_url: str | None = Field(default=None, max_length=2048)
    target_group: CampaignTargetGroup
    start_date: datetime | None = None
    end_date: datetime | None = None
    is_active: bool = True


class CampaignCreate(CampaignBase):
    pass


class CampaignUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=255)
    description: str | None = Field(default=None, min_length=2)
    image_url: str | None = Field(default=None, max_length=2048)
    target_group: CampaignTargetGroup | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    is_active: bool | None = None


class CampaignRead(CampaignBase):
    id: int
    created_by_user_id: int | None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
