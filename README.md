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
