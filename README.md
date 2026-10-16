# machine-jan.github.io

Website von Jan Buchenau – generative Musik und Klimasonifikation mit Sonic Pi.
Live: https://machine-jan.github.io

## Struktur

```
index.html              Startseite
site.css                gemeinsames Layout
code.html               Code-Viewer (?f=pfad/zur/datei.rb)

heat/                   HEAT! – Circular Sounds (Klimasonifikation)
  index.html            Projektseite mit Versionsverlauf
  scripts/              Sonic-Pi-Fassungen in chronologischer Reihenfolge
  live/                 HTML-Plakat der Performance (v0.22)
    index.html          Performance-Modus: liest latest.json jede Sekunde
    demo.html           Demo-Modus: simuliert latest.json im Zeitraffer (?s=Sekunden pro Jahrzehnt)
    logos/              Fab City Hamburg, Behörde für Kultur und Medien
  material/             Abreißkalender, Beamer-Folie, frühes Thermometer

regenwald/              Generativer Regenwald (v21, v37)

rainforest.html         Weiterleitung → regenwald/
climate-sonification/   Weiterleitung → heat/
```

## Performance-Setup (HEAT! v0.22)

Sonic Pi schreibt bei jedem Jahrzehnt `latest.json`. Für die Aufführung `heat/live/` lokal
in den Ordner legen, in den das Skript schreibt (`LATEST_PATH`), und `index.html`
über einen lokalen Webserver öffnen (z. B. `python -m http.server`), damit `fetch` funktioniert.

## Daten & Quellen

Die Datenreihen in HEAT! sind künstlerisch geglättete Steuerreihen. Referenzdatensätze zum Vergleich
(Berkeley Earth, NOAA, IPCC AR6, Global Carbon Budget 2024, WWF/ZSL Living Planet Index, FAO FRA 2020)
stehen auf der Projektseite: https://machine-jan.github.io/heat/#quellen

## Lizenz

© 2025–2026 Jan Buchenau

- **Code** (Sonic-Pi-Skripte, JavaScript, HTML, CSS): [MIT-Lizenz](LICENSE) – frei nutzbar,
  veränderbar und weitergebbar, solange Copyright-Hinweis und Lizenztext erhalten bleiben.
- **Texte, Gestaltung, Musik und Material** (z. B. PDFs): alle Rechte vorbehalten.
- **Logos** in `heat/live/logos/` gehören den jeweiligen Inhabern (Fab City Hamburg,
  Freie und Hansestadt Hamburg) und sind nicht zur Weiterverwendung lizenziert.
