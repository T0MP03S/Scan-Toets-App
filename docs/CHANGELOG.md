# Changelog

Alle wijzigingen aan het Toets Scan App project worden hier bijgehouden.

## [0.7.1] - 2026-03-27

### Bugfixes & Optimalisaties

**Kritieke fixes:**
- **JWT_SECRET_KEY** werd bij elke herstart opnieuw gegenereerd → tokens bleven nu geldig (vereist .env configuratie)
- **Auth guard** toegevoegd: je kunt niet meer naar /dashboard zonder in te loggen
- **Page refresh** geeft geen lege pagina meer (auth state wordt correct hersteld met isInitialized flag)
- **Gemini AI calls** draaien nu async (blokkeerden de event loop) via asyncio.to_thread

**Nieuwe features:**
- **Landingspagina** toegevoegd op / met uitleg over de app, "Hoe het werkt" sectie, en privacy-informatie

**Performance verbeteringen:**
- **Zoekbalken** hebben nu debounce (400ms) → geen API-spam meer bij typen in klassen/toetsen/leerlingen screens

**Code cleanup:**
- Onnodige imports verwijderd (flutter/foundation.dart in meerdere screens)
- Unused code opgeruimd (_selectedKlas in scan_screen, _overrule in toets_analyse_screen)
- Router vereenvoudigd met duidelijkere redirect logica
- .env.example bijgewerkt met UPLOAD_DIR

**Frontend:**
- WidgetsFlutterBinding.ensureInitialized() toegevoegd voor correcte SharedPreferences init
- Router gebruikt nu buildRouter factory met AuthProvider parameter
- Landing screen met responsive design en Material 3 styling

## [0.7.0] - 2026-03-26

### Fase 6 — Human-in-the-loop & Polish
- Resultaat overrule API: leerkracht kan elk cijfer handmatig aanpassen
- Resultaat detail API: volledig resultaat ophalen met feedback
- Toets-analyse scherm met grafieken (fl_chart):
  - Cijferverdeling staafdiagram
  - Analyse per vraag met correct-percentage en voortgangsbalk
  - Meest gemaakte fout per vraag
  - Resultaten per leerling met kleurgecodeerde cijfers
- Analyse knop op toets-detailscherm
- API documentatie bijgewerkt

## [0.6.0] - 2026-03-26

### Fase 5 — Dashboard & Analyse
- Dashboard API: statistieken (klassen, leerlingen, toetsen, nagekeken)
- Dashboard API: recente resultaten met cijfer en confidence
- Dashboard API: toets-analyse met gemiddelden, score-verdeling, foutdiagnose per vraag
- Flutter dashboard met live data uit API (geen hardcoded waarden meer)
- Recente resultaten lijst met kleurgecodeerde cijfers
- Waarschuwingsicoon bij lage AI-zekerheid
- Pull-to-refresh op dashboard
- "Aan de slag" gids wanneer er nog geen resultaten zijn
- API documentatie bijgewerkt

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
