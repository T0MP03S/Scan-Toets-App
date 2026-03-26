# Scanflow Ontwerp — Privacy-first

Dit document beschrijft hoe de leerkracht toetsen inscant, nakijkt en koppelt aan leerlingen.

> **AVG/GDPR**: Namen en andere persoonsgegevens van leerlingen worden NOOIT naar
> externe AI-diensten (Gemini) gestuurd. Alle PII wordt lokaal verwerkt en
> geredacteerd vóórdat foto's de server verlaten richting AI.

---

## Overzicht

De leerkracht doorloopt een "scan-straat": een stapsgewijze flow waarin per leerling
foto's worden gemaakt en de AI de toets nakijkt. De leerling wordt **handmatig
geselecteerd** door de leerkracht (geen AI naam-herkenning).

## Userflow

```
1. Klas kiezen
2. Toets kiezen (met antwoordmodel)
3. Scan-straat opent → klassenlijst met status per leerling
   │
   ├─ Leerkracht kiest leerling uit lijst
   │
   ├─ [Foto pagina 1 maken/uploaden]
   │   ├─ "Nog een pagina?" → [Foto pagina 2] → [Foto pagina 3] → [Foto pagina 4]
   │   └─ Preview per pagina, verwijderen/opnieuw mogelijk
   │
   ├─ "Klaar, nakijken"
   │   └─ Privacy-filter: PII (naam, leerlingnummer) wordt geredacteerd
   │   └─ Geredacteerde foto's + antwoordmodel → Gemini Vision API
   │   └─ Resultaat: score + feedback per vraag
   │
   ├─ Leerkracht bevestigt of past resultaat aan
   │
   └─ Volgende leerling (of klaar)
```

## Stappen in detail

### Stap 1 — Klas en toets selecteren
- Leerkracht kiest een klas uit het dropdown/lijst
- Kiest de toets die nagekeken moet worden
- Het antwoordmodel wordt als context geladen (Gemini Context Caching)
- Klassenlijst toont status per leerling (wachtend / gescand / nagekeken)

### Stap 2 — Leerling selecteren
- Leerkracht kiest de leerling handmatig uit de klassenlijst
- Leerlingen die al gescand zijn, worden grijs/afgevinkt
- **Geen AI naam-herkenning** (AVG-compliant)

### Stap 3 — Foto's maken
- Camera opent of bestand uploaden
- Leerkracht maakt 1-4 foto's van de toets
- Elke pagina wordt direct als preview getoond
- Pagina's kunnen verwijderd of opnieuw gemaakt worden

### Stap 4 — Nakijken
- Leerkracht klikt "Klaar, nakijken"
- **Privacy-filter** (server-side):
  - Naam, leerlingnummer en andere PII worden gedetecteerd en geredacteerd (zwart)
  - Originele foto's blijven ALLEEN lokaal op de server
  - ALLEEN geredacteerde versies gaan naar Gemini
- Alle geredacteerde foto's + het antwoordmodel (JSON) worden naar Gemini gestuurd
- Gemini retourneert:
  - Score per vraag
  - Totaalscore / cijfer
  - Feedback per vraag (wat ging goed/fout)
  - Confidence score (hoe zeker is de AI)

### Stap 5 — Resultaat bevestigen
- Resultaat wordt getoond met score en feedback
- Als confidence < 80%: gele waarschuwing, leerkracht moet handmatig bevestigen
- Leerkracht kan elk individueel antwoord overrulen
- Resultaat wordt opgeslagen in de database

### Stap 6 — Volgende leerling
- Automatisch door naar de volgende leerling
- Voortgangsbalk toont: "12 van 28 leerlingen gescand"
- Leerkracht kan op elk moment stoppen en later verder gaan

---

## Antwoordmodel

Het antwoordmodel kan op twee manieren worden aangemaakt:

### Optie 1 — Handmatig invoeren
- Per vraag: vraagnummer, correct antwoord, maximale punten
- Geschikt voor eenvoudige toetsen (meerkeuze, korte antwoorden)

### Optie 2 — Foto/upload + AI-herkenning
- Leerkracht maakt foto('s) van het antwoordmodel of upload een bestand
- Gemini Vision extraheert de vragen, antwoorden en puntenverdeling
- Leerkracht controleert en past het resultaat aan
- **Let op**: geen PII in antwoordmodellen (het is het blanco model, geen ingevulde toets)

---

## Privacy & AVG

### Regels
- **Geen leerlingnamen** naar Gemini — niet in foto's, niet in prompts
- **Geen PII** in API requests naar externe diensten
- Foto's met PII worden server-side geredacteerd vóór AI-verwerking
- Originele foto's blijven op de eigen server, worden na X dagen verwijderd
- Leerkracht is verwerkingsverantwoordelijke, app is verwerker
- Verwerkersovereenkomst met Google (Gemini) vereist voor productie

### Technische maatregelen
- Server-side PII-detectie en redactie (bovenste gedeelte van de foto waar naam staat)
- Geredacteerde foto's krijgen apart pad in opslag
- Logging bevat NOOIT leerlingnamen
- Database-encryptie voor persoonsgegevens (productie)

---

## Technische details

### Gemini Context Caching
- Het antwoordmodel (JSON) wordt 1x per toets gecached
- Alle leerlingen van dezelfde toets hergebruiken dit cache
- Bespaart kosten en versnelt verwerking

### Data model
- `scan_sessie`: koppelt klas + toets + datum
- `scan_item`: per leerling — status (wachtend/gescand/nagekeken)
- `scan_pagina`: per foto — volgorde, bestandspad, geredacteerd pad
- `resultaat`: score per vraag, totaal, feedback, confidence

---

## UI schermen (Fase 4)

1. **Scan-straat startscherm** — klas + toets kiezen, overzicht wie al gescand is
2. **Leerling selectie** — klassenlijst met status, kies volgende leerling
3. **Camera/upload scherm** — foto maken/kiezen, preview, pagina-management
4. **Resultaat scherm** — score, feedback, overrule opties
5. **Voortgangsoverzicht** — wie is gescand, wie niet, totaalstatistieken
