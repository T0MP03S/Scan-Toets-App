# Toets Scan App

Een cross-platform applicatie waarmee leerkrachten handgeschreven toetsen automatisch kunnen nakijken en analyseren met behulp van Gemini Vision AI.

## Status

**Fase 4 — Scan-straat (Core AI)** ✅

## Tech Stack

| Component | Technologie |
|---|---|
| Frontend | Flutter Web (later iOS/Android) |
| Backend | Python FastAPI |
| Database | PostgreSQL 16 (lokaal via Docker) |
| AI Engine | Google Gemini 3 Flash (Vision) |
| Icons | Lucide |

## Projectstructuur

```
toets-scan-app/
├── frontend/                 # Flutter Web app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/           # Thema, routes, constanten
│   │   ├── models/           # Data modellen
│   │   ├── services/         # API calls, auth service
│   │   ├── providers/        # State management
│   │   └── screens/          # Pagina's
│   └── pubspec.yaml
├── backend/                  # Python FastAPI
│   ├── app/
│   │   ├── main.py           # FastAPI applicatie
│   │   ├── config.py         # Settings uit .env
│   │   ├── database.py       # Database connectie
│   │   ├── models/           # SQLAlchemy modellen
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── routers/          # API routes
│   │   ├── services/         # Business logica + AI
│   │   └── utils/            # Privacy filter, helpers
│   ├── requirements.txt
│   └── Dockerfile
├── docs/                     # Documentatie
│   ├── CHANGELOG.md
│   ├── API.md
│   └── DATABASE.md
├── docker-compose.yml        # PostgreSQL database
├── .env.example              # Voorbeeld configuratie
└── .gitignore
```

## Snel starten

### Vereisten
- **Flutter SDK** 3.41+
- **Python** 3.12+
- **Docker** (voor PostgreSQL)

### 1. Database starten
```bash
docker compose up -d
```

### 2. Backend starten
```bash
cd backend
cp ../.env.example .env       # Pas de waarden aan
python -m venv venv
venv\Scripts\activate         # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```
De API draait nu op `http://localhost:8000`. Documentatie: `http://localhost:8000/docs`

### 3. Frontend starten
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Documentatie
- [API Endpoints](docs/API.md)
- [Database Schema](docs/DATABASE.md)
- [Changelog](docs/CHANGELOG.md)

## Conventies
- **UI tekst**: Nederlands
- **Code**: Engels (variabelen, functies, comments)
- **Naamgeving**: snake_case overal
- **Configuratie**: Altijd via `.env`, nooit hardcoded
- Zie het volledige overzicht in het [projectplan](.windsurf/plans/)
