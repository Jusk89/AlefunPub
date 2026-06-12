from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.restaurant import Restaurant
from app.schemas.restaurant import RestaurantCreate, RestaurantRead, RestaurantUpdate
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/restaurants", tags=["restaurants"])


def get_restaurant_or_404(db: Session, restaurant_id: int) -> Restaurant:
    return get_record_or_404(db, Restaurant, restaurant_id, "Restaurant not found")


@router.get("", response_model=list[RestaurantRead])
def list_restaurants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
) -> list[Restaurant]:
    return list_records(db, Restaurant, skip=skip, limit=limit)


@router.post("", response_model=RestaurantRead, status_code=status.HTTP_201_CREATED)
def create_restaurant(payload: RestaurantCreate, db: Session = Depends(get_db)) -> Restaurant:
    return create_record(db, Restaurant, payload)


@router.get("/{restaurant_id}", response_model=RestaurantRead)
def get_restaurant(restaurant_id: int, db: Session = Depends(get_db)) -> Restaurant:
    return get_restaurant_or_404(db, restaurant_id)


@router.patch("/{restaurant_id}", response_model=RestaurantRead)
def update_restaurant(
    restaurant_id: int,
    payload: RestaurantUpdate,
    db: Session = Depends(get_db),
) -> Restaurant:
    restaurant = get_restaurant_or_404(db, restaurant_id)
    return update_record(db, restaurant, payload)


@router.delete("/{restaurant_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_restaurant(restaurant_id: int, db: Session = Depends(get_db)) -> Response:
    restaurant = get_restaurant_or_404(db, restaurant_id)
    delete_record(db, restaurant)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
