# Database Schema

Database: PostgreSQL 16 (lokaal via Docker)

## Tabellen

### `users`
| Kolom | Type | Beschrijving |
|---|---|---|
| id | int (PK) | Auto-increment |
| email | varchar(255) | Uniek, geïndexeerd |
| hashed_password | varchar(255) | Bcrypt hash |
| full_name | varchar(255) | Volledige naam |
| is_active | boolean | Default: true |
| created_at | timestamptz | Automatisch |
| updated_at | timestamptz | Automatisch |

### `klassen`
| Kolom | Type | Beschrijving |
|---|---|---|
| id | int (PK) | Auto-increment |
| naam | varchar(100) | Klasnaam (bijv. "Groep 6A") |
| docent_id | int (FK → users) | Eigenaar van de klas |
| created_at | timestamptz | Automatisch |

### `leerlingen`
| Kolom | Type | Beschrijving |
|---|---|---|
| id | int (PK) | Auto-increment |
| voornaam | varchar(100) | Voornaam |
| achternaam | varchar(100) | Achternaam |
| klas_id | int (FK → klassen) | Klas van de leerling |
| created_at | timestamptz | Automatisch |

### `toetsen`
| Kolom | Type | Beschrijving |
|---|---|---|
| id | int (PK) | Auto-increment |
| titel | varchar(255) | Toetsnaam |
| vak | varchar(100) | Bijv. "Rekenen", "Spelling" |
| master_data_json | JSON | Gestructureerd antwoordmodel |
| docent_id | int (FK → users) | Eigenaar |
| created_at | timestamptz | Automatisch |

### `resultaten`
| Kolom | Type | Beschrijving |
|---|---|---|
| id | int (PK) | Auto-increment |
| student_id | int (FK → leerlingen) | Leerling |
| toets_id | int (FK → toetsen) | Toets |
| cijfer | float | Berekend cijfer (1-10) |
| feedback_json | JSON | AI feedback per vraag |
| is_overruled | boolean | Handmatig aangepast door leerkracht |
| uploaded_at | timestamptz | Datum/tijd van upload |

## Relaties
- `users` → `klassen` (1:N)
- `klassen` → `leerlingen` (1:N, cascade delete)
- `users` → `toetsen` (1:N)
- `leerlingen` → `resultaten` (1:N)
- `toetsen` → `resultaten` (1:N)
