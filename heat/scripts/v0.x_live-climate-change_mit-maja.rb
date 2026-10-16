# Copyright (c) 2025-2026 Jan Buchenau
# SPDX-License-Identifier: MIT
# https://machine-jan.github.io

use_bpm 60

# ----------------------
# Datenreihen (alle 10 Jahre)
# ----------------------
years = (1880..2080).step(10).to_a

# Temperatur-Anomalien (relative Erwärmung)
temperature = [-0.2, -0.1, -0.1, 0.0, 0.1, 0.15, 0.2, 0.3,
               0.4, 0.5, 0.6, 0.75, 0.9, 1.0, 1.2, 1.4,
               1.6, 1.8, 2.0, 2.3, 2.5]

co2 = [290, 295, 300, 310, 320, 330, 340, 360,
       380, 400, 420, 440, 460, 480, 500, 520,
       540, 560, 580, 600, 620]

population = [1.5, 1.7, 1.9, 2.1, 2.5, 3.0, 3.7, 4.5,
              5.3, 6.1, 6.8, 7.5, 8.0, 8.5, 9.0, 9.5,
              10.0, 10.3, 10.5, 10.7, 11.0]

biodiversity = [1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65,
                0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25,
                0.2, 0.15, 0.1, 0.08, 0.05]

dystopian_life = [30, 31, 32, 32, 33, 34, 35, 36,
                  37, 38, 39, 40, 41, 42, 43, 44,
                  45, 46, 47, 48, 49] # Dystopische Lebenserwartung

utopian_life  = [30, 32, 34, 36, 38, 40, 42, 44,
                 46, 48, 50, 52, 54, 56, 58, 60,
                 62, 64, 66, 68, 70] # Utopische Lebenserwartung

# ----------------------
# Timing
# ----------------------
total_seconds = 2 * 60 * 60 # 2 Stunden
years_count = years.length
seconds_per_year = total_seconds.to_f / years_count
year_index = 0
global_amp = 0.5

# ----------------------
# Temperaturbereich für die Erwärmung (Anomalien)
# ----------------------
temp_anom_min = temperature.min   # z.B. -0.2
temp_anom_max = temperature.max   # z.B.  2.5

# Basiswert für globale Mitteltemperatur (vereinfachte Annahme)
baseline_temp = 14.0  # °C

# ----------------------
# HTML-Output: aktuelles Performance-Jahr + Thermometer + Skalen
# ----------------------
define :update_html_year do |year, temp_anom|
  # Pfad bei Bedarf anpassen:
  path = "C:/Users/FarmBot/Desktop/Stadtteilkultur/circular_sounds_year.html"
  
  # Globale, tatsächliche Temperatur (Anomalie + Basiswert)
  global_temp = baseline_temp + temp_anom
  
  # Füllung: auf Anomalie-Bereich normalisieren (0..1)
  level = (temp_anom - temp_anom_min) / (temp_anom_max - temp_anom_min).to_f
  level = 0 if level < 0
  level = 1 if level > 1
  
  # Füllhöhe in Prozent (mit kleinem Mindestwert, damit 1880 sichtbar ist)
  fill_percent = 5 + (level * 95)
  fill_percent = 5 if fill_percent < 5
  fill_percent = 100 if fill_percent > 100
  
  # Rot-Farbintensität (je wärmer, desto roter)
  r = (160 + 95 * level).to_i   # 160..255
  g = (40 * (1 - level)).to_i   # 40..0
  b = 0
  fill_color = "rgb(#{r},#{g},#{b})"
  
  # -------------------------
  # Jahres-Skala links (gleichmäßig über Höhe)
  # -------------------------
  year_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    year_ticks_html += "
      <div class='year-tick' style='bottom: #{bottom_percent}%;'>
        #{y}
      </div>"
  end
  
  # -------------------------
  # Globale Temperatur rechts: alle 10 Jahre
  # gleiche vertikale Verteilung wie Jahreszahlen
  # -------------------------
  temp_ticks_html = ""
  years.each_with_index do |y, idx|
    anom = temperature[idx]
    t_val = baseline_temp + anom
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    temp_ticks_html += "
      <div class='temp-year-tick' style='bottom: #{bottom_percent}%;'>
        <div class='tick-line'></div>
        <div class='tick-label'>#{t_val.round(2)} °C</div>
      </div>"
  end
  
  # -------------------------
  # HTML CODE
  # -------------------------
  html = "
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset='utf-8'>
      <title>Circular Sounds – Jahr</title>
      <meta http-equiv='refresh' content='1'>
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          background: #000;
          color: #0f0;
          font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          display: flex;
          align-items: flex-start;    /* oben ausrichten */
          justify-content: center;
        }

        .wrapper {
          text-align: center;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: flex-start;
          margin-top: 8vh;           /* mehr schwarze Fläche über dem Thermometer */
        }

        .layout {
          display: flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 4vh;
        }

        /* Jahres-Skala links (etwas weiter links) */
        .years {
          position: relative;
          height: 70vh;
          margin-right: 3vw;  /* Abstand zum Thermometer */
          padding-right: 1vw;
          color: #0f0;
          text-align: right;
        }

        .year-tick {
          position: absolute;
          transform: translateY(50%);
          font-size: 0.9vw;
          white-space: nowrap;
          opacity: 0.9;
        }

        /* Thermometer (größer, nach unten gestreckt) */
        .thermo-container {
          height: 70vh;
          width: 7vw;
          max-width: 140px;
          border-radius: 999px;
          border: 4px solid #fff;   /* weißer Rahmen */
          box-sizing: border-box;
          position: relative;
          background: #ffffff;      /* Innenraum weiß */
          overflow: hidden;
          display: flex;
          align-items: flex-end;
          justify-content: center;
        }

        .thermo-fill {
          width: 100%;
          height: #{fill_percent}%;
          background: #{fill_color};
          transition: height 0.8s ease-out, background 0.8s ease-out;
        }

        /* Temperatur-Skala rechts: globale Temperatur alle 10 Jahre */
        .temps {
          position: relative;
          height: 70vh;
          max-height: 100%;
          width: auto;
          margin-left: 2vw;
        }

        .temp-year-tick {
          position: absolute;
          display: flex;
          align-items: center;
          transform: translateY(50%);
        }

        .tick-line {
          width: 1.4vw;
          max-width: 35px;
          border-top: 2px solid #fff;
          margin-right: 0.5vw;
          opacity: 0.9;
        }

        .tick-label {
          font-size: 1.0vw;
          color: #fff;
          opacity: 0.85;
          white-space: nowrap;
        }

        .label {
          font-size: 2vw;
          opacity: 0.7;
          text-align: center;
          margin-bottom: 1vw;
        }

        .year {
          font-size: 10vw;
          letter-spacing: 0.1em;
          text-transform: uppercase;
        }

        .temp-summary {
          font-size: 1.4vw;
          opacity: 0.8;
          margin-top: 1vh;
        }
      </style>
    </head>
    <body>
      <div class='wrapper'>
        <div class='layout'>
          <div class='years'>
            #{year_ticks_html}
          </div>
          <div class='thermo-container'>
            <div class='thermo-fill'></div>
          </div>
          <div class='temps'>
            #{temp_ticks_html}
          </div>
        </div>
        <div class='label'>Performance-Jahr</div>
        <div class='year'>#{year}</div>
        <div class='temp-summary'>
          Globale Temperatur: #{global_temp.round(2)} °C<br>
          (Erwärmung relativ zum Ausgangsniveau: #{temp_anom.round(2)} °C)
        </div>
      </div>
    </body>
  </html>
  "
  
  File.open(path, "w") do |f|
    f.write(html)
  end
end

# Initial das Startjahr ins HTML schreiben
update_html_year(years[year_index], temperature[year_index])

# ----------------------
# Synth-Definitionen (etwas lauter, männlich am stärksten)
# ----------------------
define :male_choir do |note, amp=0.8|
  synth :hollow, note: note-12, sustain: seconds_per_year, release: 2, amp: amp, attack: 0.5
end

define :female_choir do |note, amp=0.6|
  synth :hollow, note: note+12, sustain: seconds_per_year, release: 2, amp: amp, attack: 0.5
end

define :child_choir do |note, amp=0.5|
  synth :hollow, note: note+24, sustain: seconds_per_year, release: 2, amp: amp, attack: 0.5
end

# ----------------------
# Hilfsfunktion für lineare Interpolation
# ----------------------
define :scale_to_note do |val, min, max, base_note|
  rng = max - min
  norm = (val - min) / rng.to_f
  return base_note + (norm * 24).to_i
end

# ----------------------
# Delay- & Chorus-Funktion mit Biodiversitätspuls
# ----------------------
define :play_with_delay do |synth_fn, start_val, end_val, min_val, max_val, base_note, life_val|
  note_start = scale_to_note(start_val, min_val, max_val, base_note)
  note_end = scale_to_note(end_val, min_val, max_val, base_note)
  
  s = synth_fn.call(note_start)
  control s, note: note_end, note_slide: seconds_per_year
  
  # Delay moduliert durch Biodiversität + Lebenserwartung
  b = biodiversity[year_index]
  delay_phase = 0.1 + (1 - b) * 0.8 + (70 - life_val) / 140.0
  base_mix   = 0.1 + (b * 0.3)
  
  with_fx :echo, phase: delay_phase, decay: 2.0, mix: base_mix do |e|
    # Rhythmische Pulsvariation durch Biodiversität
    complexity = (b * 6).to_i + 1
    in_thread do
      complexity.times do
        control e, mix: base_mix + rand(0.2) # kleine Zufallswellen
        sleep seconds_per_year.to_f / complexity
      end
    end
    sleep 0.01
  end
end

# ----------------------
# Live Loops
# ----------------------
live_loop :male_chorus do
  t1 = temperature[year_index]
  t2 = temperature[(year_index + 1) % years_count]
  play_with_delay(method(:male_choir), t1, t2, -0.3, 2.5, :c2, dystopian_life[year_index])
  sleep seconds_per_year
end

live_loop :female_chorus do
  c1 = co2[year_index]
  c2 = co2[(year_index + 1) % years_count]
  play_with_delay(method(:female_choir), c1, c2, 290, 620, :c3, utopian_life[year_index])
  sleep seconds_per_year
end

live_loop :child_chorus do
  p1 = population[year_index]
  p2 = population[(year_index + 1) % years_count]
  play_with_delay(method(:child_choir), p1, p2, 1.5, 11.0, :c4, 50)
  sleep seconds_per_year
end

# ----------------------
# Tremolo der Gesamtlautstärke durch Biodiversität
# ----------------------
live_loop :biodiversity_tremolo do
  b = biodiversity[year_index]
  complexity = (b * 8).to_i
  complexity = 1 if complexity < 1
  complexity = 8 if complexity > 8
  complexity.times do
    global_amp = 0.3 + (b * 0.7)
    sleep seconds_per_year.to_f / complexity
  end
end

# ----------------------
# Fortschreiten der Jahre + HTML-Update
# ----------------------
live_loop :advance_year do
  sleep seconds_per_year
  year_index = (year_index + 1) % years_count
  current_year = years[year_index]
  current_temp_anom = temperature[year_index]
  puts "Jahr: #{current_year}, Anomalie: #{current_temp_anom}"
  
  # HTML jedes Jahr mit aktueller Jahreszahl + Temperatur/Thermometer aktualisieren
  update_html_year(current_year, current_temp_anom)
end
