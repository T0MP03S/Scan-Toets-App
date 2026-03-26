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
