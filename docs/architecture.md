# Restaurant Loyalty Backend Architecture

## Overview

This project is a FastAPI backend for a restaurant loyalty application. It uses PostgreSQL, SQLAlchemy 2.0 ORM models, Alembic migrations, JWT bearer authentication, and bcrypt password hashing.

The application is organized by responsibility:

- `app/models`: SQLAlchemy database models and relationships.
- `app/schemas`: Pydantic request and response schemas.
- `app/routers`: FastAPI HTTP route handlers.
- `app/services`: business logic, security helpers, audit logging, and reusable CRUD utilities.
- `alembic/versions`: ordered database migrations.

Routers should stay thin. Business rules belong in services, especially loyalty, QR, notification, audit, and activity flows.

## Main Domains

### Auth And Users

Users authenticate with JWT access tokens. Passwords are hashed with bcrypt. Client users receive a permanent UUID `qr_code`, which the mobile app can render as a QR code.

Roles:

- `client`
- `admin`
- `cashier`
- `courier`

Shared role dependencies live in `app/dependencies.py`.

### Restaurant Catalog

Restaurants own branches, menu categories, and menu items. Branches connect orders and QR cashier operations back to the correct restaurant.

### Orders

Orders store payment state, bonus amounts, final amount, branch, restaurant, and user. SQLAlchemy session hooks record order audit/activity side effects when orders are created or completed.

### Loyalty Bonuses

Bonus state is split into:

- `BonusAccount`: aggregate balance per user and restaurant.
- `BonusTransaction`: ledger rows for `earn`, `spend`, `expire`, and `manual` events.

FIFO spending consumes the oldest usable credits by expiration date first, then creation order. Earn/manual credit rows carry `remaining_amount`; spend and expire rows point back to their source transaction where applicable.

### Permanent QR Loyalty Flow

Cashiers scan a client's permanent QR code and submit:

- `qr_code`
- `branch_id`
- `total_amount`
- `payment_method`
- `use_bonuses`

The backend calculates all bonus values server-side. Clients never send `bonus_earned` or `bonus_spent`.

When `use_bonuses=false`, the system creates a completed in-restaurant order and awards bonuses based on the restaurant percent. When `use_bonuses=true`, the system spends available bonuses up to the order total and does not award new bonuses for that order.

QR orders deliberately set session flags to skip generic order-completed hooks, because QR order creation handles bonus and activity side effects explicitly in one transaction.

### Notifications And Activity

`NotificationService` is a placeholder and does not integrate Firebase yet. It logs/prints masked token payloads only.

`UserActivity` tracks:

- `last_visit_at`
- `total_spent`
- `total_orders`
- `last_notification_sent_at`

Inactive invitations target clients with `last_visit_at` older than 30 days or missing.

### Campaigns

Campaigns support target groups:

- `all_clients`
- `inactive_clients`
- `birthday_clients`
- `vip_clients`

Campaign creation writes an audit log.

### Delivery Foundation

`DeliveryOrder` exists only as a database foundation for future delivery work. There are no delivery endpoints, assignment logic, tracking logic, or delivery payment flows.

### Audit Logs

`AuditLog` records important business events:

- user registered
- order created
- order completed
- bonus earned
- bonus spent
- campaign created
- QR order created
- QR bonus earned
- QR bonus spent

## Index And Relationship Notes

Important indexes and constraints:

- `users.email`, `users.phone`, and `users.qr_code` are unique.
- `bonus_accounts` has a unique `(user_id, restaurant_id)` constraint.
- `bonus_transactions` has composite indexes for FIFO lookup and order/type lookup.
- `addresses` has `(user_id, is_default)` for user default-address management.
- `audit_logs` has `(entity_type, entity_id)` for entity audit history.
- `delivery_orders.order_id` is unique to match the one-to-one `Order.delivery_order` relationship.

Relationship ownership:

- Restaurant cascades delete branches, menu categories, menu items, and bonus accounts.
- User cascades delete addresses, push tokens, activity, and bonus accounts.
- Orders retain references to user/restaurant/branch with restrictive foreign keys.
- Delivery foundation uses one delivery order per order.

## Security Notes

- Passwords are never stored in plaintext.
- JWT tokens use `sub` as the user id.
- Swagger OAuth2 authorization uses `/auth/token`.
- JSON login uses `/auth/login`.
- Staff-only operations use shared role dependencies.
- Default JWT secret is allowed for development only; production startup rejects it.
- Push notification logs mask device tokens.

## Migration Notes

PostgreSQL enums are created explicitly in migrations and referenced with `create_type=False` to avoid duplicate enum creation during `op.create_table`.

Run migrations with:

```powershell
alembic upgrade head
```

## Development Checks

Compile Python files:

```powershell
python -m compileall app alembic
```

Start the API:

```powershell
uvicorn app.main:app --reload
```
