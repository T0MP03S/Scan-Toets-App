# API Documentatie

Base URL: `http://localhost:8000`  
Swagger UI: `http://localhost:8000/docs`

---

## Health Check

### `GET /health`
Controleert of de API draait.

**Response:** `200`
```json
{ "status": "ok", "version": "0.1.0" }
```

---

## Authenticatie

### `POST /auth/register`
Nieuw leerkracht-account aanmaken.

**Body:**
```json
{
  "email": "juf@school.nl",
  "password": "minstens8tekens",
  "full_name": "Juf Petra"
}
```

**Response:** `201`
```json
{ "id": 1, "email": "juf@school.nl", "full_name": "Juf Petra", "is_active": true }
```

**Fouten:**
- `409` — E-mailadres al in gebruik
- `400` — Wachtwoord te kort (< 8 tekens)

---

### `POST /auth/login`
Inloggen en JWT token ontvangen.

**Body:**
```json
{ "email": "juf@school.nl", "password": "minstens8tekens" }
```

**Response:** `200`
```json
{ "access_token": "eyJ...", "token_type": "bearer" }
```

**Fouten:**
- `401` — Ongeldig e-mailadres of wachtwoord
- `403` — Account gedeactiveerd

---

### `GET /auth/me`
Huidige ingelogde gebruiker ophalen. Vereist Bearer token.

**Headers:** `Authorization: Bearer <token>`

**Response:** `200`
```json
{ "id": 1, "email": "juf@school.nl", "full_name": "Juf Petra", "is_active": true }
```

**Fouten:**
- `401` — Ongeldige of verlopen token

---

## Klassen

Alle klassen-endpoints vereisen `Authorization: Bearer <token>`.

### `GET /klassen`
Alle klassen van de ingelogde docent ophalen.

**Query parameters:** `search` (optioneel) — zoek op klasnaam

**Response:** `200`
```json
[{ "id": 1, "naam": "Groep 6A", "docent_id": 1, "created_at": "...", "leerling_count": 25 }]
```

### `POST /klassen`
Nieuwe klas aanmaken.

**Body:** `{ "naam": "Groep 6A" }`  
**Response:** `201`

### `GET /klassen/{id}`
Enkele klas ophalen. **Response:** `200`

### `PUT /klassen/{id}`
Klasnaam wijzigen.

**Body:** `{ "naam": "Groep 6B" }`  
**Response:** `200`

### `DELETE /klassen/{id}`
Klas en alle bijbehorende leerlingen verwijderen. **Response:** `204`

---

## Leerlingen

### `GET /klassen/{klas_id}/leerlingen`
Alle leerlingen van een klas ophalen.

**Query parameters:** `search` (optioneel) — zoek op voor-/achternaam

**Response:** `200`
```json
[{ "id": 1, "voornaam": "Jan", "achternaam": "de Vries", "klas_id": 1, "created_at": "..." }]
```

### `POST /klassen/{klas_id}/leerlingen`
Leerling toevoegen aan een klas.

**Body:** `{ "voornaam": "Jan", "achternaam": "de Vries" }`  
**Response:** `201`

### `PUT /klassen/{klas_id}/leerlingen/{id}`
Leerling bewerken. **Body:** `{ "voornaam": "Jan", "achternaam": "de Vries" }`  
**Response:** `200`

### `DELETE /klassen/{klas_id}/leerlingen/{id}`
Leerling verwijderen. **Response:** `204`

---

## Toetsen

Alle toetsen-endpoints vereisen `Authorization: Bearer <token>`.

### `GET /toetsen`
Alle toetsen van de ingelogde docent ophalen.

**Query parameters:**
- `klas_id` (optioneel) — filter op klas
- `search` (optioneel) — zoek op titel of vak

**Response:** `200`
```json
[{
  "id": 1, "titel": "Rekenen Week 12", "vak": "Rekenen",
  "beschrijving": "Optellen en aftrekken", "klas_id": 1, "klas_naam": "Groep 6A",
  "totaal_punten": 7, "aantal_vragen": 3, "created_at": "..."
}]
```

### `POST /toetsen`
Nieuwe toets aanmaken.

**Body:**
```json
{ "titel": "Rekenen Week 12", "vak": "Rekenen", "beschrijving": "...", "klas_id": 1 }
```
**Response:** `201`

### `GET /toetsen/{id}`
Enkele toets ophalen (inclusief antwoordmodel). **Response:** `200`

### `PUT /toetsen/{id}`
Toets bewerken. **Body:** `{ "titel": "...", "vak": "...", "beschrijving": "...", "klas_id": 1 }`  
**Response:** `200`

### `DELETE /toetsen/{id}`
Toets en alle bijbehorende resultaten verwijderen. **Response:** `204`

---

## Antwoordmodel

### `PUT /toetsen/{id}/antwoordmodel`
Antwoordmodel instellen of bijwerken (handmatige invoer).

**Body:**
```json
{
  "vragen": [
    { "nummer": 1, "vraag": "12 + 15 = ?", "correct_antwoord": "27", "punten": 2 },
    { "nummer": 2, "vraag": "45 - 18 = ?", "correct_antwoord": "27", "punten": 2 }
  ]
}
```
**Response:** `200` — retourneert de volledige toets met `totaal_punten` automatisch berekend

### `DELETE /toetsen/{id}/antwoordmodel`
Antwoordmodel verwijderen. **Response:** `204`

---

## Scan-straat

### `POST /scan/upload`
Upload een pagina-foto. Vereist `multipart/form-data`.

**Body:** `file` (JPG/PNG)  
**Response:** `200`
```json
{ "filename": "abc123.jpg", "path": "/uploads/scans/1/abc123.jpg" }
```

### `POST /scan/grade`
Laat een toets nakijken door AI. PII wordt automatisch geredacteerd.

**Body:**
```json
{
  "toets_id": 1,
  "leerling_id": 1,
  "filenames": ["abc123.jpg", "def456.jpg"]
}
```
**Response:** `200` — resultaat met cijfer, score, feedback per vraag, confidence

### `GET /scan/status/{toets_id}`
Scan-voortgang ophalen: welke leerlingen zijn al nagekeken.

**Response:** `200`
```json
{
  "toets_id": 1,
  "totaal_leerlingen": 28,
  "gescand": 12,
  "items": [{ "leerling_id": 1, "voornaam": "Jan", "achternaam": "de Vries", "status": "nagekeken", "cijfer": 7.5, "confidence": 0.92 }]
}
```

### `POST /scan/extract-antwoordmodel`
Herken antwoordmodel uit foto('s) met AI. Vereist `multipart/form-data`.

**Body:** `files` (meerdere JPG/PNG bestanden)  
**Response:** `200` — geëxtraheerde vragen in JSON formaat

---

## Dashboard & Analyse

### `GET /dashboard/stats`
Overzichtsstatistieken voor de ingelogde docent.

**Response:** `200`
```json
{ "klassen": 3, "leerlingen": 78, "toetsen": 12, "nagekeken": 45 }
```

### `GET /dashboard/recent-results`
Laatste 10 nakijkresultaten.

**Query parameters:** `limit` (optioneel, default 10)

**Response:** `200`
```json
[{ "id": 1, "leerling": "Jan de Vries", "toets": "Rekenen Week 12", "cijfer": 7.5, "score": 6, "max_score": 7, "confidence": 0.92, "created_at": "..." }]
```

### `PUT /scan/resultaat/{resultaat_id}/overrule`
Cijfer handmatig aanpassen (overrulen).

**Query parameters:** `cijfer` (float, 1-10)  
**Response:** `200`
```json
{ "id": 1, "cijfer": 8.0, "is_overruled": true }
```

### `GET /scan/resultaat/{resultaat_id}`
Enkel resultaat ophalen met volledige feedback.

**Response:** `200`

### `GET /dashboard/toets-analyse/{toets_id}`
Gedetailleerde analyse van een toets: gemiddelden, score-verdeling, foutdiagnose per vraag.

**Response:** `200`
```json
{
  "toets_titel": "Rekenen Week 12", "toets_vak": "Rekenen",
  "aantal_resultaten": 25, "gemiddeld_cijfer": 7.2,
  "hoogste_cijfer": 9.5, "laagste_cijfer": 3.0,
  "score_verdeling": { "7-8": 8, "6-7": 6, "5-6": 4 },
  "vraag_analyse": [{ "vraag_nummer": 1, "correct_percentage": 85, "meest_gemaakte_fout": "26" }],
  "resultaten": [{ "leerling": "Jan de Vries", "cijfer": 7.5, "score": 6, "max_score": 7 }]
}
```
