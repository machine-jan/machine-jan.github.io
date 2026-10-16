# Copyright (c) 2025-2026 Jan Buchenau
# SPDX-License-Identifier: MIT
# https://machine-jan.github.io

# ============================================================
# CIRCULAR SOUNDS – VERSION 0.13g TEST
# ============================================================
#
# BASIERT DIREKT AUF 0.13f
# - HTML vorerst deaktiviert
# - Prophet sämiger / weniger saw-artig
# - Frauenchor deutlich lauter
# - sonst möglichst nah am funktionierenden Stand
#
# ============================================================

use_bpm 60
use_debug false

# ----------------------
# DATEN 1800–2100
# ----------------------
years = (1800..2100).step(10).to_a

temperature_anomaly = [-0.30, -0.28, -0.27, -0.25, -0.24, -0.22, -0.20, -0.18,
                       -0.15, -0.12, -0.08, -0.03,  0.02,  0.08,  0.15,  0.22,
                       0.30,  0.40,  0.52,  0.65,  0.80,  0.95,  1.12,  1.30,
                       1.52,  1.75,  2.00,  2.25,  2.50,  2.75,  3.00]

baseline_temp = 13.7
temperature = temperature_anomaly.map { |a| (baseline_temp + a).round(2) }

co2_emissions = [0.02, 0.03, 0.05, 0.08, 0.12, 0.18, 0.28, 0.45,
                 0.70, 1.00, 1.50, 2.30, 3.50, 5.20, 7.80, 11.0,
                 15.0, 20.0, 25.0, 31.0, 36.0, 40.0, 43.0, 46.0,
                 48.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0]

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

define :decade_degree do |idx, temp_anom, co2_val, bio_val|
  base_cycle = (ring 0, 3, 4, 2, 5, 1, 4, 3)
  base = base_cycle[idx % base_cycle.length]
  
  heat_push = temp_anom >= 1.0 ? 1 : 0
  pressure_push = co2_val >= 40 ? 1 : 0
  collapse_push = bio_val <= 0.20 ? 1 : 0
  
  (base + heat_push + pressure_push + collapse_push) % 7
end

define :tertian_chord_from_scale do |sc, degree|
  [
    sc[degree],
    sc[degree + 2],
    sc[degree + 4],
    sc[degree + 6]
  ].uniq.sort
end

define :chord_for_decade do |idx|
  y = years[idx]
  root, mode = epoch_palette(y)
  sc = scale(root, mode, num_octaves: 3)
  
  deg = decade_degree(
    idx,
    temperature_anomaly[idx],
    co2_emissions[idx],
    biodiversity[idx]
  )
  
  tertian_chord_from_scale(sc, deg)
end

# weichere Männerstimme auf Basis prophet
define :soft_prophet_voice do |note, amp_val|
  with_fx :lpf, cutoff: 82 do
    synth :prophet,
      note: note,
      amp: amp_val,
      attack: 0.35,
      sustain: 1.0,
      release: 1.15,
      cutoff: 85,
      res: 0.7
    
    synth :prophet,
      note: note + 0.08,
      amp: amp_val * 0.55,
      attack: 0.38,
      sustain: 0.95,
      release: 1.2,
      cutoff: 78,
      res: 0.6
  end
end

# ----------------------
# HTML VORERST AUS
# ----------------------
define :update_html do |year, temp_val, temp_anom, co2_val, bio_val|
  # absichtlich leer
end

update_html(
  years[year_index],
  temperature[year_index],
  temperature_anomaly[year_index],
  co2_emissions[year_index],
  biodiversity[year_index]
)

# aktueller Akkord pro Jahrzehnt
set :men_chord, chord_for_decade(year_index)
set :women_chord, chord_for_decade(year_index).map { |n| n + 12 }
set :decade_change_pulse, 1

# ----------------------
# REGENWALD BASIS
# ----------------------
live_loop :rain do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  with_fx :hpf, cutoff: 95 do
    synth :noise,
      amp: 0.018 * g,
      attack: 0.03,
      sustain: 0.28,
      release: 0.18,
      pan: rrand(-0.45, 0.45)
  end
  
  sleep 0.42
end

live_loop :forest_bed do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  with_fx :lpf, cutoff: 72 do
    synth :bnoise,
      attack: 1.5,
      sustain: 5,
      release: 5,
      amp: 0.028 * g
  end
  
  sleep 4.0
end

live_loop :forest_birds do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  if b > 0.18
    chord_notes = get(:women_chord)
    synth :sine,
      note: chord_notes.choose + [0, 7, 12].choose,
      attack: 0.01,
      sustain: 0.08,
      release: 0.2,
      amp: 0.055 * g,
      pan: rrand(-0.8, 0.8)
  end
  
  sleep map_lin(b, BIO_MIN, BIO_MAX, 4.2, 1.8)
end

live_loop :forest_insects do
  b = biodiversity[year_index]
  g = forest_gain(b)
  
  if b > 0.28
    with_fx :hpf, cutoff: 110 do
      synth :pulse,
        note: [:e5, :g5, :a5, :b5].choose,
        amp: 0.018 * g,
        attack: 0.01,
        sustain: 0.03,
        release: 0.05,
        pulse_width: 0.2,
        pan: rrand(-0.9, 0.9)
    end
  end
  
  sleep 0.75 + rrand(0.0, 0.35)
end

# ----------------------
# AFFENSCHREI
# ----------------------
live_loop :monkey_call do
  b = biodiversity[year_index]
  
  if b > 0.35
    chord_notes = get(:women_chord)
    g = forest_gain(b)
    
    with_fx :reverb, mix: 0.3, room: 0.7 do
      synth :fm,
        note: chord_notes[0],
        attack: 0.02,
        sustain: 0.10,
        release: 0.20,
        amp: 0.22 * g,
        pan: rrand(-0.8, 0.8)
      
      sleep 0.12
      
      synth :fm,
        note: chord_notes[1] || (chord_notes[0] + 3),
        attack: 0.02,
        sustain: 0.08,
        release: 0.20,
        amp: 0.19 * g,
        pan: rrand(-0.8, 0.8)
    end
    
    sleep 5.5 + (1.0 - b) * 8
  else
    sleep 7
  end
end

# ----------------------
# JAHRZEHNTSPRUNG-MARKER
# ----------------------
live_loop :decade_marker do
  if get(:decade_change_pulse) == 1
    b = biodiversity[year_index]
    gain = choir_gain(b)
    
    men_ch = get(:men_chord)
    women_ch = get(:women_chord)
    
    with_fx :reverb, room: 0.9, mix: 0.35 do
      men_ch.take(3).each do |n|
        soft_prophet_voice(n, 0.14 * gain)
        sleep 0.03
      end
      
      women_ch.take(3).each do |n|
        synth :hollow,
          note: n,
          amp: 0.24 * gain,
          attack: 0.05,
          sustain: 0.25,
          release: 0.8
        sleep 0.03
      end
    end
    
    set :decade_change_pulse, 0
  end
  
  sleep 0.25
end

# ----------------------
# MÄNNERCHOR = CO2
# Prophet sämiger
# ----------------------
live_loop :men do
  idx = year_index
  chord_notes = get(:men_chord)
  v = voices_from_co2(co2_emissions[idx])
  gain = choir_gain(biodiversity[idx])
  
  active_notes = chord_notes.take(v)
  
  with_fx :reverb, room: 0.78, mix: 0.30 do
    active_notes.each do |note|
      soft_prophet_voice(note, 0.10 * gain)
      
      synth :hollow,
        note: note - 12,
        amp: 0.03 * gain,
        attack: 0.30,
        sustain: 0.95,
        release: 1.0
      
      sleep 0.05
    end
  end
  
  sleep 1.2
end

# ----------------------
# FRAUENCHOR = TEMPERATUR
# lauter
# ----------------------
live_loop :women do
  idx = year_index
  chord_notes = get(:women_chord)
  v = voices_from_temp(temperature[idx])
  gain = choir_gain(biodiversity[idx])
  
  active_notes = chord_notes.reverse.take(v).reverse
  
  with_fx :reverb, room: 0.95, mix: 0.46 do
    active_notes.each do |note|
      synth :hollow,
        note: note,
        amp: 0.24 * gain,
        attack: 0.20,
        sustain: 1.20,
        release: 1.10
      
      sleep 0.05
    end
  end
  
  sleep 1.2
end

# ----------------------
# ZEIT
# ----------------------
live_loop :time do
  sleep seconds_per_year
  year_index = (year_index + 1) % years_count
  
  new_chord = chord_for_decade(year_index)
  
  set :men_chord, new_chord
  set :women_chord, new_chord.map { |n| n + 12 }
  set :decade_change_pulse, 1
  
  update_html(
    years[year_index],
    temperature[year_index],
    temperature_anomaly[year_index],
    co2_emissions[year_index],
    biodiversity[year_index]
  )
end