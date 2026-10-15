# ============================================================
# CIRCULAR SOUNDS – VERSION 0.7d TEST (PROPHET MEN)
# ============================================================
#
# Testversion zur besseren Identifizierbarkeit des Männerchors.
#
# Änderungen gegenüber v0.7c:
# - Männerchor jetzt mit :prophet
# - Männerchor etwas tiefer
# - Männerchor etwas stärker angehoben
#
# Ziel:
# - klar prüfen, ob der Männerchor als eigener Klangkörper hörbar ist
#
# ============================================================

use_bpm 60
use_debug false

# ----------------------
# DATEN
# ----------------------
years = (1880..2080).step(10).to_a

temperature = [13.8, 13.9, 13.9, 14.0, 14.1, 14.15, 14.2, 14.3,
               14.4, 14.5, 14.6, 14.75, 14.9, 15.0, 15.2, 15.4,
               15.6, 15.8, 16.0, 16.3, 16.5]

temperature_anomaly = [-0.2, -0.1, -0.1, 0.0, 0.1, 0.15, 0.2, 0.3,
                       0.4, 0.5, 0.6, 0.75, 0.9, 1.0, 1.2, 1.4,
                       1.6, 1.8, 2.0, 2.3, 2.5]

population = [1.5, 1.7, 1.9, 2.1, 2.5, 3.0, 3.7, 4.5,
              5.3, 6.1, 6.8, 7.5, 8.0, 8.5, 9.0, 9.5,
              10.0, 10.3, 10.5, 10.7, 11.0]

biodiversity = [1.00, 0.98, 0.96, 0.93, 0.90, 0.86, 0.82, 0.78,
                0.73, 0.68, 0.62, 0.56, 0.50, 0.44, 0.38, 0.32,
                0.26, 0.20, 0.15, 0.10, 0.06]

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
POP_MIN  = population.min
POP_MAX  = population.max
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
  if y <= 1910
    [:d3, :minor]
  elsif y <= 1950
    [:f3, :dorian]
  elsif y <= 1990
    [:c3, :major]
  else
    [:e3, :phrygian]
  end
end

define :epoch_palette_male do |y|
  if y <= 1910
    [:d2, :minor]
  elsif y <= 1950
    [:f2, :dorian]
  elsif y <= 1990
    [:c2, :major]
  else
    [:e2, :phrygian]
  end
end

define :epoch_palette_female do |y|
  if y <= 1910
    [:a3, :minor]
  elsif y <= 1950
    [:c4, :dorian]
  elsif y <= 1990
    [:g3, :major]
  else
    [:b3, :phrygian]
  end
end

define :forest_gain do |b|
  0.35 + (b * 1.0)
end

define :choir_gain do |b|
  0.35 + ((1.0 - b) * 0.8)
end

define :voices_from_pop do |p|
  v = map_lin(p, POP_MIN, POP_MAX, 1, 4).round
  clamp_range(v, 1, 4)
end

define :voices_from_temp do |t|
  v = map_lin(t, TEMP_MIN, TEMP_MAX, 1, 3).round
  clamp_range(v, 1, 3)
end

define :forest_layer_allowed? do |threshold|
  biodiversity[year_index] >= threshold
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
define :update_html do |year, temp_val, temp_anom, pop_val, bio_val|
  t_level = clamp01((temp_val - TEMP_MIN) / (TEMP_MAX - TEMP_MIN).to_f)
  p_level = clamp01((pop_val - POP_MIN) / (POP_MAX - POP_MIN).to_f)
  b_level = clamp01((bio_val - BIO_MIN) / (BIO_MAX - BIO_MIN).to_f)
  
  t_fill = 5 + t_level * 95
  p_fill = 5 + p_level * 95
  b_fill = (1.0 - b_level) * 100.0
  
  temp_color = "rgb(#{(160 + 95 * t_level).to_i},#{(40 * (1 - t_level)).to_i},0)"
  pop_color  = "rgb(#{(210 + 35 * p_level).to_i},#{(175 + 60 * p_level).to_i},0)"
  
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
  
  pop_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    pop_ticks_html += "
      <div class='value-tick' style='bottom: #{bottom_percent}%;'>
        <div class='tick-line'></div>
        <div class='tick-label'>#{population[idx].round(1)} Mrd.</div>
      </div>"
  end
  
  bio_ticks_html = ""
  years.each_with_index do |y, idx|
    pos = idx.to_f / (years.length - 1)
    bottom_percent = (pos * 100).round(1)
    bio_ticks_html += "
      <div class='value-tick' style='bottom: #{bottom_percent}%;'>
        <div class='tick-line'></div>
        <div class='tick-label'>#{sprintf('%.2f', biodiversity[idx])}</div>
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
                <div class='thermo-fill' style='height: #{p_fill}%; background: #{pop_color};'></div>
              </div>
              <div class='values'>
                #{pop_ticks_html}
              </div>
            </div>
            <div class='thermo-title'>Weltbevölkerung</div>
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
          Weltbevölkerung: #{pop_val.round(1)} Milliarden<br>
          Biodiversität: #{sprintf('%.2f', bio_val)}
        </div>
      </div>
    </body>
  </html>
  "
  
  File.open(HTML_PATH, "w") { |f| f.write(html) }
end

update_html(years[year_index], temperature[year_index], temperature_anomaly[year_index], population[year_index], biodiversity[year_index])

# ----------------------
# REGENWALD
# ----------------------
live_loop :rain do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  with_fx :hpf, cutoff: 60 do
    synth :noise,
      attack: 1.0,
      sustain: 2.2,
      release: 2.2,
      amp: 0.045 * g,
      pan: rrand(-0.4, 0.4)
  end
  
  sleep 4
end

live_loop :forest_bed do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  with_fx :lpf, cutoff: 75 do
    synth :noise,
      attack: 1.8,
      sustain: 3.5,
      release: 3.8,
      amp: 0.03 * g,
      pan: rrand(-0.35, 0.35)
  end
  
  sleep rrand(4.5, 7.5)
end

live_loop :forest_insects do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  if forest_layer_allowed?(0.15)
    with_fx :slicer, phase: 0.14, mix: 0.18 do
      synth :noise,
        attack: 0.01,
        sustain: 0.05,
        release: 0.08,
        amp: 0.02 * g,
        pan: rrand(-1, 1)
    end
  end
  
  sleep rrand(2.0, 4.0)
end

live_loop :forest_birds do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  if forest_layer_allowed?(0.20)
    root, mode = epoch_palette(years[year_index])
    sc = scale(root, mode, num_octaves: 2)
    
    with_fx :reverb, mix: 0.25, room: 0.7 do
      synth :sine,
        note: sc.choose + 12,
        attack: 0.02,
        sustain: 0.08,
        release: 0.22,
        amp: 0.07 * g,
        pan: rrand(-1, 1)
    end
  end
  
  sleep rrand(2.5, 5.0)
end

live_loop :forest_calls do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  if forest_layer_allowed?(0.45)
    root, mode = epoch_palette(years[year_index])
    sc = scale(root, mode, num_octaves: 2)
    
    synth :fm,
      note: sc.choose,
      attack: 0.04,
      sustain: 0.10,
      release: 0.20,
      amp: 0.085 * g,
      pan: rrand(-0.8, 0.8)
  end
  
  sleep rrand(7.0, 14.0)
end

# ----------------------
# CHOR-SYNTHS
# ----------------------
define :male_prophet_voice do |note, amp, pan|
  synth :prophet,
    note: note - 5,
    attack: 0.35,
    sustain: 1.2,
    release: 1.1,
    amp: amp,
    pan: pan
end

define :female_rich_voice do |note, amp, pan|
  synth :hollow,
    note: note + 12,
    attack: 0.55,
    sustain: 0.95,
    release: 0.9,
    amp: amp,
    pan: pan
end

# ----------------------
# MÄNNERCHOR (PROPHET TEST)
# ----------------------
live_loop :men_choir do
  b = biodiversity[year_index]
  gain = choir_gain(b)
  
  root, mode = epoch_palette_male(years[year_index])
  sc = scale(root, mode, num_octaves: 3)
  
  v = voices_from_pop(population[year_index])
  
  3.times do
    total_amp = map_lin(v, 1, 4, 0.38, 0.72) * gain
    per_voice_amp = total_amp / v.to_f
    
    with_fx :reverb, mix: 0.12, room: 0.62 do
      v.times do |vx|
        note = sc.choose + [0, 2, 4, 7][vx]
        male_prophet_voice(
          note + rrand(-0.03, 0.03),
          per_voice_amp * (1.0 + rrand(0.0, 0.10)),
          rrand(-0.82, -0.05)
        )
        sleep 0.04
      end
    end
    
    sleep 0.9
  end
end

# ----------------------
# FRAUENCHOR
# ----------------------
live_loop :women_choir do
  b = biodiversity[year_index]
  gain = choir_gain(b)
  
  root, mode = epoch_palette_female(years[year_index])
  sc = scale(root, mode, num_octaves: 3)
  
  v = voices_from_temp(temperature[year_index])
  
  3.times do
    total_amp = map_lin(v, 1, 3, 0.08, 0.17) * gain
    per_voice_amp = total_amp / v.to_f
    
    with_fx :reverb, mix: 0.12, room: 0.65 do
      v.times do |vx|
        note = sc.choose + [0, 2, 4][vx]
        female_rich_voice(
          note + rrand(-0.03, 0.03),
          per_voice_amp * (0.95 + rrand(0.0, 0.08)),
          rrand(-0.1, 0.7)
        )
        sleep 0.04
      end
    end
    
    sleep 0.9
  end
end

# ----------------------
# ZEIT / HTML
# ----------------------
live_loop :advance_year do
  sleep seconds_per_year
  year_index = (year_index + 1) % years_count
  
  update_html(
    years[year_index],
    temperature[year_index],
    temperature_anomaly[year_index],
    population[year_index],
    biodiversity[year_index]
  )
  
  puts "ANNO #{years[year_index]}"
end