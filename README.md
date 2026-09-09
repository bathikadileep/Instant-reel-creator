# Instant Reel - On-Demand Reel Creator Platform

> **Instant Reel** connects customers with professional reel creators across **Maripeda**, **Mahabubabad**, **Khammam**, and **Warangal**.
>
> **Workflow**: Customer books a reel creator $\rightarrow$ Creator accepts booking $\rightarrow$ Creator visits location $\rightarrow$ Shoots video $\rightarrow$ Edits reel within 10 minutes $\rightarrow$ Shares reel directly to customer through WhatsApp $\rightarrow$ Marks booking as delivered.

---

## 🏗️ Project Architecture (Phase 1 Foundation)

```
instant-reel/
├── backend/                  # FastAPI + SQLAlchemy + Alembic + Pydantic v2
│   ├── alembic/              # Database migration environments
│   ├── app/
│   │   ├── api/v1/           # API routes (/health, /health/db)
│   │   ├── core/             # Config, Async DB Engine, Security & JWT, Exceptions
│   │   ├── models/           # SQLAlchemy 2.0 Base Models (UUID + Timestamps)
│   │   ├── schemas/          # Pydantic validation & response schemas
│   │   └── main.py           # FastAPI Application Factory & Lifespan
│   ├── .env.example          # Neon PostgreSQL & Security environment templates
│   ├── Dockerfile            # Multi-stage production container
│   ├── requirements.txt      # Pinned dependencies
│   └── run.py                # Local development server runner
│
├── frontend/                 # Flutter + Riverpod + GoRouter (Clean Architecture)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/    # Service regions & API endpoints
│   │   │   ├── network/      # Dio client, Auth interceptor & logging
│   │   │   ├── router/       # GoRouter routes & paths
│   │   │   ├── theme/        # Dark/Light theme & Typography (Google Fonts)
│   │   │   └── utils/        # ResponsiveLayout & AppLogger
│   │   ├── features/
│   │   │   └── splash/       # Clean Architecture Foundation Feature
│   │   │       ├── domain/   # Repository interfaces
│   │   │       ├── data/     # Remote datasources & implementations
│   │   │       └── presentation/ # Riverpod StateNotifier & Responsive View
│   │   ├── app.dart          # MaterialApp.router
│   │   └── main.dart         # ProviderScope Entry Point
│   ├── pubspec.yaml          # Flutter dependencies
│   └── analysis_options.yaml # Strict lint configuration
│
├── docker-compose.yml        # Multi-service local development orchestration
├── render.yaml               # Render Cloud Blueprint for zero-friction deployment
└── README.md
```

---

## ⚡ Quick Start: Backend Setup (FastAPI + Neon PostgreSQL)

### 1. Prerequisites
- Python 3.11+
- A [Neon PostgreSQL](https://neon.tech) account & database instance.

### 2. Setup Virtual Environment
```bash
cd backend
python -m venv venv

# Windows (PowerShell)
.\venv\Scripts\Activate.ps1

# Linux / macOS
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Update your `DATABASE_URL` with your Neon PostgreSQL connection string:
```ini
DATABASE_URL="postgresql+asyncpg://neondb_owner:<PASSWORD>@<NEON_HOST>/neondb?ssl=require"
SYNC_DATABASE_URL="postgresql://neondb_owner:<PASSWORD>@<NEON_HOST>/neondb?sslmode=require"
JWT_SECRET_KEY="generate_secure_random_key"
```

### 4. Run Alembic Migrations
```bash
alembic upgrade head
```

### 5. Start the Backend Server
```bash
python run.py
# or
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- API Documentation: [http://localhost:8000/docs](http://localhost:8000/docs)
- Health Status: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)
- Neon DB Health: [http://localhost:8000/api/v1/health/db](http://localhost:8000/api/v1/health/db)

---

## 📱 Quick Start: Frontend Setup (Flutter)

### 1. Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+

### 2. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 3. Run Flutter Application
```bash
# Web
flutter run -d chrome

# Android Emulator
flutter run -d emulator-5554

# Windows Desktop
flutter run -d windows
```

---

## 🐳 Docker Deployment (Local)

To run the entire backend containerized:
```bash
docker compose up --build
```
This boots the FastAPI service with hot-reloading at `http://localhost:8000`.

---

## ☁️ Deploying to Render

1. Push your repository to GitHub or GitLab.
2. Log into [Render.com](https://dashboard.render.com).
3. Click **New** $\rightarrow$ **Blueprint**.
4. Connect this repository; Render will automatically detect `render.yaml`.
5. Enter your Neon PostgreSQL connection string in the `DATABASE_URL` environment variable field.
6. Click **Apply** to deploy the production web service with automatic health checks.

---

## 📍 Operating Regions
The platform currently serves:
- **Maripeda**
- **Mahabubabad**
- **Khammam**
- **Warangal**
