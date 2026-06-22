import argparse
import sys

from sqlalchemy import select

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.services.security import hash_password
from app.services.users import get_user_by_email, get_user_by_phone


def main() -> int:
    parser = argparse.ArgumentParser(description="Create the first owner account.")
    parser.add_argument("email")
    parser.add_argument("password")
    parser.add_argument("full_name")
    parser.add_argument("phone")
    args = parser.parse_args()

    with SessionLocal() as db:
        existing_owner = db.scalar(select(User).where(User.role == UserRole.owner))
        if existing_owner is not None:
            print("Owner already exists. Refusing to create another owner.", file=sys.stderr)
            return 1
        if get_user_by_email(db, args.email):
            print("Email is already registered.", file=sys.stderr)
            return 1
        if get_user_by_phone(db, args.phone):
            print("Phone is already registered.", file=sys.stderr)
            return 1

        owner = User(
            full_name=args.full_name,
            phone=args.phone,
            email=args.email.lower(),
            password_hash=hash_password(args.password),
            role=UserRole.owner,
            is_active=True,
        )
        db.add(owner)
        db.commit()
        db.refresh(owner)
        print(f"Owner created: id={owner.id}, email={owner.email}")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
