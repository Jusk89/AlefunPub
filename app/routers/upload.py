import shutil
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from app.dependencies import require_admin_or_owner
from app.models.user import User

router = APIRouter(prefix="/upload", tags=["upload"])

UPLOAD_ROOT = Path("uploads")
ALLOWED_FOLDERS = {"menu", "campaigns", "gifts", "logos"}
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


@router.post("/image")
def upload_image(
    file: UploadFile = File(...),
    folder: str = Form("menu"),
    current_user: User = Depends(require_admin_or_owner),
) -> dict[str, str]:
    """Store an admin-uploaded image in one of the supported local folders."""
    normalized_folder = folder.strip().lower()
    if normalized_folder not in ALLOWED_FOLDERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Folder must be one of: menu, campaigns, gifts, logos",
        )

    extension = Path(file.filename or "").suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only jpg, jpeg, png and webp images are supported",
        )

    target_dir = UPLOAD_ROOT / normalized_folder
    target_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4()}{extension}"
    target_path = target_dir / filename

    with target_path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return {"image_url": f"/uploads/{normalized_folder}/{filename}"}
