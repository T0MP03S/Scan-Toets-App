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
