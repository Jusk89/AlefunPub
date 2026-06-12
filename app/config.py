from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables and `.env`."""

    app_name: str = "Restaurant Loyalty API"
    app_env: str = "development"
    debug: bool = False

    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/restaurant_loyalty"

    jwt_secret_key: str = "change-this-secret-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @model_validator(mode="after")
    def validate_production_secrets(self) -> "Settings":
        """Reject unsafe defaults when the app is explicitly running in production."""
        if self.app_env == "production" and self.jwt_secret_key == "change-this-secret-in-production":
            raise ValueError("JWT_SECRET_KEY must be changed in production")
        return self


@lru_cache
def get_settings() -> Settings:
    """Return cached settings for dependency-free imports."""
    return Settings()


settings = get_settings()
