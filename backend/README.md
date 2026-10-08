# Mastitis Detection System (MDS) — Backend Infrastructure

This directory contains the production REST backend for the **Mastitis Detection System (MDS)**, connecting the Flutter mobile application, an ESP32 IoT sensing module, and a Machine Learning model.

---

## 1. Directory Structure

```text
backend/
├── .env.example                       # Environment configuration template
├── init_db.sql                        # Finalized MySQL schema initialization & indexes
├── requirements.txt                   # Python package dependencies
├── models/
│   └── mastitis_rf_model.joblib       # Pre-trained Random Forest model artifact
├── scripts/
│   └── train_baseline_model.py        # Veterinary-grounded baseline model generator
└── src/
    ├── __init__.py
    ├── main.py                        # FastAPI entrypoint, lifespan loader & CORS
    ├── config/
    │   ├── __init__.py
    │   ├── config.py                  # Pydantic Settings & environment variables
    │   └── database.py                # MySQL connection pool & session factory
    ├── models/
    │   ├── __init__.py
    │   ├── db_models.py               # SQLAlchemy ORM models matching MySQL schema
    │   └── schemas.py                 # Pydantic request, response & DTO schemas
    ├── services/
    │   ├── __init__.py
    │   └── ml_service.py              # In-memory Random Forest inference service
    ├── middleware/
    │   ├── __init__.py
    │   ├── auth_middleware.py         # JWT security, bcrypt hashing & current farmer dep
    │   └── error_handler.py           # Global exception handling & error responses
    ├── controllers/
    │   ├── __init__.py
    │   ├── auth_controller.py         # Registration, login & profile with dynamic total_cows
    │   ├── cow_controller.py          # Cow registration, list & joined historical tests
    │   ├── test_controller.py         # Diagnostic test initiation & short-polling resolution
    │   ├── iot_controller.py          # ESP32 sensor ingestion, ML inference & alert dispatch
    │   └── alert_controller.py        # Farmer alert listing & bulk mark-as-read
    └── routes/
        ├── __init__.py
        ├── api_router.py              # Aggregated API router mounted at /api
        ├── auth_routes.py             # /api/auth routes
        ├── cow_routes.py              # /api/cows routes
        ├── test_routes.py             # /api/cows/{id}/initiate-test & latest-result
        ├── iot_routes.py              # /api/iot/sensor-reading
        └── alert_routes.py            # /api/alerts routes
```

---

## 2. Database Schema

The database interfaces strictly with the finalized MySQL schema:

- **`Farmer`**: `farmer_id` (PK, auto-increment), `fname`, `lname`, `email` (unique, indexed), `password` (bcrypt hash).
- **`Cow`**: `cow_id` (PK, auto-increment), `farmer_id` (FK -> `Farmer`), `cow_tag`, `breed`, `age`, `health_status` (`ENUM('Healthy', 'At Risk', 'Pending')`, default `'Healthy'`).
- **`Sensor_Reading`**: `reading_id` (PK, auto-increment), `cow_id` (FK -> `Cow`), `temperature` (`DECIMAL(5,2)`), `pH` (`DECIMAL(4,2)`), `electrical_conductivity` (`DECIMAL(6,2)`), `reading_time` (`DATETIME`).
- **`Detection_Result`**: `result_id` (PK, auto-increment), `cow_id` (FK -> `Cow`), `reading_id` (FK -> `Sensor_Reading`, unique), `prediction` (`ENUM('Mastitis Present', 'Mastitis Absent')`), `detection_time` (`DATETIME`).
- **`Alert`**: `alert_id` (PK, auto-increment), `result_id` (FK -> `Detection_Result`, unique), `farmer_id` (FK -> `Farmer`), `message`, `status` (`ENUM('Read', 'Unread')`, default `'Unread'`), `send_time` (`DATETIME`).

---

## 3. The 6-Step Asynchronous Testing Workflow

```
[Flutter Mobile]                   [FastAPI Backend]                 [ESP32 IoT Node]
       │                                   │                                 │
       │ 1. POST /cows/{id}/initiate-test  │                                 │
       ├──────────────────────────────────>│                                 │
       │                                   │ (Sets cow health_status='Pending')
       │                                   │                                 │
       │ 2. GET /cows/{id}/latest-result   │                                 │
       ├──────────────────────────────────>│                                 │
       │<── ── ── ── ── ── ── ── ── ── ── ─┤                                 │
       │   HTTP 202 Accepted (Pending)     │                                 │
       │   (Mobile polls every 2 seconds)  │                                 │
       │                                   │   3. POST /iot/sensor-reading   │
       │                                   │<────────────────────────────────┤
       │                                   │   (temp, pH, conductivity)      │
       │                                   │                                 │
       │                                   ├───┐ 4. Atomic Transaction:      │
       │                                   │   │ • Save Sensor_Reading       │
       │                                   │   │ • In-memory ML inference    │
       │                                   │   │ • Save Detection_Result     │
       │                                   │   │ • Set Cow health_status     │
       │                                   │   │ • Generate Alert if Present │
       │                                   │<──┘                             │
       │                                   │                                 │
       │ 6. GET /cows/{id}/latest-result   │                                 │
       ├──────────────────────────────────>│                                 │
       │<──────────────────────────────────┤                                 │
       │   HTTP 200 OK (Full Result)       │                                 │
       │   (Mobile polling terminates)     │                                 │
```

---

## 4. API Endpoints

| Method | Endpoint | Auth | Description |
| :---: | :--- | :---: | :--- |
| `POST` | `/api/auth/register` | No | Registers farmer account with bcrypt password hashing |
| `POST` | `/api/auth/login` | No | Authenticates credentials and returns signed JWT access token |
| `GET` | `/api/auth/profile` | Bearer JWT | Returns farmer details and dynamic `total_cows` count |
| `POST` | `/api/cows` | Bearer JWT | Registers cow in herd, default `health_status = 'Healthy'` |
| `GET` | `/api/cows` | Bearer JWT | Lists all cows owned by the authenticated farmer |
| `GET` | `/api/cows/{id}` | Bearer JWT | Returns cow details with joined historical tests (`Sensor_Reading` + `Detection_Result`) |
| `POST` | `/api/cows/{id}/initiate-test` | Bearer JWT | Step 1: Transitions cow `health_status` to `'Pending'` |
| `GET` | `/api/cows/{id}/latest-result` | Bearer JWT | Step 2 & 6: Short polling endpoint returning 202 while Pending, 200 once resolved |
| `POST` | `/api/iot/sensor-reading` | Open / Node | Step 3 & 4: Ingests raw telemetry, performs ML prediction, updates status, dispatches alert |
| `GET` | `/api/alerts` | Bearer JWT | Lists all alerts for authenticated farmer |
| `PUT` | `/api/alerts/{id}/read` | Bearer JWT | Marks a single alert as `'Read'` |
| `PUT` | `/api/alerts/mark-all-read` | Bearer JWT | Bulk updates all unread farmer alerts to `'Read'` |
| `GET` | `/health` | No | Verifies server, database connection, and ML model status |
