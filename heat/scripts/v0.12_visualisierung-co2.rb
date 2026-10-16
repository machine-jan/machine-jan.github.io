# Copyright (c) 2025-2026 Jan Buchenau
# SPDX-License-Identifier: MIT
# https://machine-jan.github.io

# ============================================================
# CIRCULAR SOUNDS – VERSION 0.12 TEST
# ============================================================
#
# AUDIOVISUELLE DATENKOMPOSITION FÜR SONIC PI + HTML
#
# ZEITRAUM
# 1800 bis 2100 in 10-Jahres-Schritten
#
# TESTDAUER
# 6 Minuten
# Für die spätere Langfassung:
# total_seconds = 2 * 60 * 60
#
# DATENREIHEN / KLANGZUORDNUNG
#
# 1) MÄNNERCHOR = GLOBALER CO2-AUSSTOSS
#    - mehr CO2-Ausstoß = mehr Stimmen
#    - tiefer Registerraum
#    - Hybrid aus Prophet + Hollow
#
# 2) FRAUENCHOR = GLOBALE TEMPERATUR
#    - mehr Temperatur = mehr Stimmen
#    - höherer Registerraum
#    - Hollow-Chor
#
# 3) REGENWALD = BIODIVERSITÄT
#    - hohe Biodiversität = dichter, lebendiger Wald
#    - sinkende Biodiversität = weniger Waldereignisse
#    - enthält hier:
#      Regen, Waldbett, Vogelrufe, rhythmischen Affenschrei
#
# VISUALISIERUNG
#
# LINKES THERMOMETER
# - Globale Temperatur
# - rechts daneben absolute Temperatur / Erwärmungsanomalie
#
# MITTLERES THERMOMETER
# - Globaler CO2-Ausstoß in GtCO2/Jahr
#
# RECHTES THERMOMETER
# - Biodiversität
# - grüner Grundkörper = intakter Zustand
# - weißer Pegel = Verlust / Verdrängung
#
# HINWEIS
# Diese Version ersetzt die Bevölkerungsreihe vollständig durch
# eine CO2-Ausstoß-Reihe und rechnet alle verwendeten Datenreihen
# auf 1800–2100 neu um.
#
# ============================================================

use_bpm 60
use_debug false

# ----------------------
# DATEN 1800–2100
# ----------------------
years = (1800..2100).step(10).to_a

# Erwärmungsanomalie relativ zu einem vorindustriellen Referenzwert
temperature_anomaly = [-0.30, -0.28, -0.27, -0.25, -0.24, -0.22, -0.20, -0.18,
                       -0.15, -0.12, -0.08, -0.03,  0.02,  0.08,  0.15,  0.22,
                       0.30,  0.40,  0.52,  0.65,  0.80,  0.95,  1.12,  1.30,
                       1.52,  1.75,  2.00,  2.25,  2.50,  2.75,  3.00]

# Absolute globale Mitteltemperatur (vereinfachte künstlerische Steuerreihe)
baseline_temp = 13.7
temperature = temperature_anomaly.map { |a| (baseline_temp + a).round(2) }

# Globaler CO2-Ausstoß in GtCO2/Jahr (künstlerisch plausibilisierte Steuerreihe)
co2_emissions = [0.02, 0.03, 0.05, 0.08, 0.12, 0.18, 0.28, 0.45,
                 0.70, 1.00, 1.50, 2.30, 3.50, 5.20, 7.80, 11.0,
                 15.0, 20.0, 25.0, 31.0, 36.0, 40.0, 43.0, 46.0,
                 48.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0]

# Relativer Biodiversitätszustand
biodiversity = [1.00, 0.995, 0.990, 0.985, 0.975, 0.965, 0.950, 0.930,
                0.905, 0.875, 0.840, 0.800, 0.755, 0.705, 0.650, 0.590,
                0.530, 0.470, 0.410, 0.350, 0.295, 0.245, 0.200, 0.160,
                0.125, 0.095, 0.072, 0.055, 0.043, 0.035, 0.030]

# ----------------------
# TIMING
# ----------------------
total_seconds = 6 * 60
years_count = years.length
seconds_per_year = total_seconds.to_f / years_count
year_index = 0

HTML_PATH = "C:/Users/FarmBot/Desktop/Stadtteilkultur/Circuar Sounds 2025/climate sonification/heat.html"

# ----------------------
# MIN/MAX
# ----------------------
CO2_MIN  = co2_emissions.min
CO2_MAX  = co2_emissions.max
TEMP_MIN = temperature.min
TEMP_MAX = temperature.max
BIO_MIN  = biodiversity.min
BIO_MAX  = biodiversity.max

# ----------------------
# HELPERS
# ----------------------
define :clamp01 do |x|
  return 0 if x < 0
  return 1 if x > 1
  x
end

define :clamp_range do |x, lo, hi|
  return lo if x < lo
  return hi if x > hi
  x
end

define :map_lin do |val, in_min, in_max, out_min, out_max|
  return out_min if in_max == in_min
  t = (val - in_min) / (in_max - in_min).to_f
  t = clamp01(t)
  out_min + (out_max - out_min) * t
end

define :epoch_palette do |y|
  if y <= 1860
    [:d3, :minor]
  elsif y <= 1920
    [:f3, :dorian]
  elsif y <= 1980
    [:c3, :major]
  else
    [:e3, :phrygian]
  end
end

define :forest_gain do |b|
  0.35 + b
end

define :choir_gain do |b|
  0.35 + (1.0 - b) * 0.8
end

define :voices_from_co2 do |v|
  x = map_lin(v, CO2_MIN, CO2_MAX, 1, 4).round
  clamp_range(x, 1, 4)
end

define :voices_from_temp do |t|
  x = map_lin(t, TEMP_MIN, TEMP_MAX, 1, 3).round
  clamp_range(x, 1, 3)
end

define :fmt_anom do |x|
  if x >= 0
    "+#{x.round(2)} °C"
  else
    "#{x.round(2)} °C"
  end
end

# ----------------------
# HTML
# ----------------------
define :update_html do |year, temp_val, temp_anom, co2_val, bio_val|
  t_level = clamp01((temp_val - TEMP_MIN) / (TEMP_MAX - TEMP_MIN).to_f)
  c_level = clamp01((co2_val - CO2_MIN) / (CO2_MAX - CO2_MIN).to_f)
  b_level = clamp01((bio_val - BIO_MIN) / (BIO_MAX - BIO_MIN).to_f)
  
  t_fill = 5 + t_level * 95
  c_fill = 5 + c_level * 95
  b_fill = (1.0 - b_level) * 100.0
  
  temp_color = "rgb(#{(160 + 95 * t_level).to_i},#{(40 * (1 - t_level)).to_i},0)"
  co2_color  = "rgb(#{(210 + 35 * c_level).to_i},#{(175 + 60 * c_level).to_i},0)"
  
  year_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    year_ticks_html += "
      <div class='year-tick' style='bottom: #{bottom_percent}%;'>
        #{y}
      </div>"
  end
  
  temp_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    temp_label = "#{temperature[idx].round(2)} °C / #{fmt_anom(temperature_anomaly[idx])}"
    temp_ticks_html += "
      <div class='value-tick' style='bottom: #{bottom_percent}%;'>
        <div class='tick-line'></div>
        <div class='tick-label'>#{temp_label}</div>
      </div>"
  end
  
  co2_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    co2_ticks_html += "
      <div class='value-tick' style='bottom: #{bottom_percent}%;'>
        <div class='tick-line'></div>
        <div class='tick-label'>#{co2_emissions[idx].round(2)} GtCO2/Jahr</div>
      </div>"
  end
  
  bio_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    bio_ticks_html += "
      <div class='value-tick' style='bottom: #{bottom_percent}%;'>
        <div class='tick-line'></div>
        <div class='tick-label'>#{sprintf('%.3f', biodiversity[idx])}</div>
      </div>"
  end
  
  html = "
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset='utf-8'>
      <meta http-equiv='refresh' content='1'>
      <title>Circular Sounds</title>
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          background: #000;
          color: #fff;
          font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          display: flex;
          align-items: flex-start;
          justify-content: center;
        }

        .wrapper {
          text-align: center;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: flex-start;
          margin-top: 6vh;
          width: 100%;
        }

        .layout {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 7vw;
          margin-bottom: 4vh;
        }

        .years {
          position: relative;
          height: 68vh;
          margin-right: 3vw;
          padding-right: 1vw;
          color: #0f0;
          text-align: right;
          min-width: 6vw;
        }

        .year-tick {
          position: absolute;
          transform: translateY(50%);
          font-size: 0.9vw;
          white-space: nowrap;
          opacity: 0.9;
        }

        .block {
          display: flex;
          flex-direction: column;
          align-items: center;
        }

        .thermo-group {
          display: flex;
          align-items: center;
          gap: 1.8vw;
        }

        .thermo-container {
          height: 68vh;
          width: 6.3vw;
          max-width: 128px;
          border-radius: 999px;
          border: 4px solid #fff;
          box-sizing: border-box;
          position: relative;
          overflow: hidden;
          display: flex;
          align-items: flex-end;
          justify-content: center;
        }

        .thermo-white { background: #fff; }
        .thermo-green { background: #15842d; }

        .thermo-fill {
          width: 100%;
          transition: height 0.8s ease-out, background 0.8s ease-out;
        }

        .values {
          position: relative;
          height: 68vh;
          width: 14vw;
          min-width: 240px;
        }

        .value-tick {
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
          font-size: 0.95vw;
          white-space: nowrap;
          opacity: 0.9;
          text-align: left;
        }

        .thermo-title {
          margin-top: 1.2vh;
          font-size: 1.45vw;
          font-weight: 600;
          opacity: 0.94;
        }

        .label {
          font-size: 2vw;
          opacity: 0.7;
          text-align: center;
          margin-bottom: 1vw;
        }

        .year {
          font-size: 9vw;
          letter-spacing: 0.1em;
          text-transform: uppercase;
        }

        .summary {
          font-size: 1.25vw;
          line-height: 1.55;
          opacity: 0.9;
        }
      </style>
    </head>
    <body>
      <div class='wrapper'>
        <div class='layout'>
          <div class='years'>
            #{year_ticks_html}
          </div>

          <div class='block'>
            <div class='thermo-group'>
              <div class='thermo-container thermo-white'>
                <div class='thermo-fill' style='height: #{t_fill}%; background: #{temp_color};'></div>
              </div>
              <div class='values'>
                #{temp_ticks_html}
              </div>
            </div>
            <div class='thermo-title'>Globale Temperatur / Erwärmung</div>
          </div>

          <div class='block'>
            <div class='thermo-group'>
              <div class='thermo-container thermo-white'>
                <div class='thermo-fill' style='height: #{c_fill}%; background: #{co2_color};'></div>
              </div>
              <div class='values'>
                #{co2_ticks_html}
              </div>
            </div>
            <div class='thermo-title'>Globaler CO2-Ausstoß</div>
          </div>

          <div class='block'>
            <div class='thermo-group'>
              <div class='thermo-container thermo-green'>
                <div class='thermo-fill' style='height: #{b_fill}%; background: #ffffff;'></div>
              </div>
              <div class='values'>
                #{bio_ticks_html}
              </div>
            </div>
            <div class='thermo-title'>Biodiversität</div>
          </div>
        </div>

        <div class='label'>Performance-Jahr</div>
        <div class='year'>#{year}</div>
        <div class='summary'>
          Globale Temperatur: #{temp_val.round(2)} °C / #{fmt_anom(temp_anom)}<br>
          Globaler CO2-Ausstoß: #{co2_val.round(2)} GtCO2/Jahr<br>
          Biodiversität: #{sprintf('%.3f', bio_val)}
        </div>
      </div>
    </body>
  </html>
  "
  
  File.open(HTML_PATH, "w") { |f| f.write(html) }
end

update_html(
  years[year_index],
  temperature[year_index],
  temperature_anomaly[year_index],
  co2_emissions[year_index],
  biodiversity[year_index]
)

# ----------------------
# REGENWALD BASIS
# ----------------------
live_loop :rain do
  b = biodiversity[year_index]
  synth :noise,
    amp: 0.04 * forest_gain(b),
    sustain: 2,
    release: 2
  sleep 4
end

live_loop :forest_bed do
  b = biodiversity[year_index]
  with_fx :lpf, cutoff: 70 do
    synth :bnoise,
      attack: 2,
      sustain: 4,
      release: 4,
      amp: 0.03 * forest_gain(b)
  end
  sleep 4.5
end

live_loop :forest_birds do
  b = biodiversity[year_index]
  if b > 0.2
    root, mode = epoch_palette(years[year_index])
    sc = scale(root, mode, num_octaves: 2)
    synth :sine,
      note: sc.choose + 12,
      amp: 0.06 * forest_gain(b)
  end
  sleep rrand(2, 5)
end

# ----------------------
# AFFENSCHREI
# ----------------------
live_loop :monkey_call do
  b = biodiversity[year_index]
  
  if b > 0.35
    root, mode = epoch_palette(years[year_index])
    sc = scale(root, mode, num_octaves: 2)
    
    g = forest_gain(b)
    
    with_fx :reverb, mix: 0.3, room: 0.7 do
      synth :fm,
        note: sc.choose,
        attack: 0.02,
        sustain: 0.1,
        release: 0.2,
        amp: 0.25 * g,
        pan: rrand(-0.8, 0.8)
      
      sleep 0.12
      
      synth :fm,
        note: sc.choose + [3, 5].choose,
        attack: 0.02,
        sustain: 0.08,
        release: 0.2,
        amp: 0.22 * g,
        pan: rrand(-0.8, 0.8)
    end
    
    sleep 6 + (1.0 - b) * 10
  else
    sleep 8
  end
end

# ----------------------
# MÄNNERCHOR = CO2
# ----------------------
live_loop :men do
  y = years[year_index]
  root, mode = epoch_palette(y)
  sc = scale(root - 12, mode, num_octaves: 3)
  
  v = voices_from_co2(co2_emissions[year_index])
  gain = choir_gain(biodiversity[year_index])
  
  v.times do
    note = sc.choose
    
    synth :prophet,
      note: note,
      amp: 0.12 * gain,
      attack: 0.6,
      sustain: 0.8,
      release: 1.2
    
    synth :hollow,
      note: note - 12,
      amp: 0.08 * gain,
      sustain: 1.2
    
    sleep 0.05
  end
  
  sleep 1.2
end

# ----------------------
# FRAUENCHOR = TEMPERATUR
# ----------------------
live_loop :women do
  y = years[year_index]
  root, mode = epoch_palette(y)
  sc = scale(root + 12, mode, num_octaves: 3)
  
  v = voices_from_temp(temperature[year_index])
  gain = choir_gain(biodiversity[year_index])
  
  v.times do
    synth :hollow,
      note: sc.choose,
      amp: 0.1 * gain,
      sustain: 0.9
    
    sleep 0.05
  end
  
  sleep 1.2
end

# ----------------------
# ZEIT / HTML
# ----------------------
live_loop :time do
  sleep seconds_per_year
  year_index = (year_index + 1) % years_count
  
  update_html(
    years[year_index],
    temperature[year_index],
    temperature_anomaly[year_index],
    co2_emissions[year_index],
    biodiversity[year_index]
  )
end