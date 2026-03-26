# Changelog

Alle wijzigingen aan het Toets Scan App project worden hier bijgehouden.

## [0.5.0] - 2026-03-26

### Fase 4 — Scan-straat (Core AI Feature)
- Gemini 3 Flash (Vision) integratie voor toets-nakijking
- google-genai SDK geïnstalleerd en geconfigureerd
- PII-redactie service: naam bovenaan foto wordt automatisch zwartgemaakt
- Scan API: upload pagina’s, AI nakijken, voortgangsstatus
- Antwoordmodel extractie uit foto’s via AI
- Flutter scan-straat: 4-stappen flow (klas/toets kiezen → leerling selecteren → foto’s uploaden → resultaat)
- Voortgangsbalk en leerlingenlijst met scan-status
- Resultaatscherm met cijfer, score per vraag, confidence indicator
- Waarschuwing bij lage AI-zekerheid (< 80%)
- Privacy-first: geen leerlingnamen naar externe AI
- API documentatie bijgewerkt

## [0.4.0] - 2026-03-26

### Fase 3 — Master Toets Beheer
- Toets model uitgebreid: klas_id, beschrijving, totaal_punten
- CRUD API endpoints voor toetsen (aanmaken, bewerken, verwijderen, ophalen)
- Antwoordmodel API: handmatig invoeren per vraag (nummer, vraag, antwoord, punten)
- Totaal punten worden automatisch berekend uit antwoordmodel
- Flutter toetsen-overzicht met zoekbalk, klas-dropdown, CRUD
- Flutter toets-detailscherm met antwoordmodel weergave
- Flutter antwoordmodel-editor: vragen toevoegen/verwijderen/bewerken
- Scanflow ontwerp gedocumenteerd (privacy-first, AVG-compliant)
- Geen leerlingnamen naar externe AI — handmatige leerling-selectie
- API documentatie bijgewerkt

## [0.3.0] - 2026-03-26

### Fase 2 — Klassenbeheer
- CRUD API endpoints voor klassen (aanmaken, bewerken, verwijderen, ophalen)
- CRUD API endpoints voor leerlingen per klas
- Zoekfunctie op klassen en leerlingen (query parameter)
- Cascade delete: klas verwijderen verwijdert ook leerlingen
- Flutter klassen-scherm met lijst, zoekbalk, aanmaken/bewerken/verwijderen dialogen
- Flutter leerlingen-scherm per klas met volledige CRUD
- ApiService geüpdatet voor list-responses en 204 no-content
- API documentatie bijgewerkt

## [0.2.0] - 2026-03-26

### Fase 1 — Authenticatie & Basis UI
- JWT authenticatie (register, login, me) in FastAPI
- Bcrypt wachtwoord hashing
- Configureerbare CORS origins via `.env`
- Random JWT secret key als fallback
- Flutter login- en registratiescherm met echte API-koppeling
- AuthProvider met token persistence (SharedPreferences)
- In-app snackbar notificaties (geen browser popups)
- Sidebar navigatie met logout functionaliteit
- Dashboard toont gebruikersnaam
- Global exception handler in backend
- API documentatie bijgewerkt

## [0.1.0] - 2026-03-26

### Fase 0 — Project Setup & Fundament
- Flutter Web project geïnitialiseerd
- FastAPI backend opgezet met basis structuur
- PostgreSQL database schema ontworpen (users, klassen, leerlingen, toetsen, resultaten)
- Docker Compose configuratie voor lokale PostgreSQL
- Project conventies en regels vastgesteld
