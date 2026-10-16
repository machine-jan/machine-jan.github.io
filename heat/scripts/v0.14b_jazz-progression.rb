# Copyright (c) 2025-2026 Jan Buchenau
# SPDX-License-Identifier: MIT
# https://machine-jan.github.io

# ============================================================
# CIRCULAR SOUNDS – VERSION 0.14b TEST
# ============================================================
#
# BASIERT AUF 0.14
# - HTML vorerst deaktiviert
# - Regenwald stärker an Skalen gebunden
# - leichte jazzige / progressive Harmonik
# - große CO2-Sprünge -> dissonantere Intervalle
# - bedrohliche Temperatur / Kipppunkte -> zusätzliche Schärfung
# - Regenwald-Impulse jetzt auch in alterierenden Rhythmuspatterns
# - Chor weiterhin dekadenbezogen
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

define :safe_prev do |arr, idx|
  return arr[idx] if idx <= 0
  arr[idx - 1]
end

define :relative_jump do |current_val, prev_val|
  return 0.0 if prev_val <= 0
  ((current_val - prev_val) / prev_val.to_f)
end

define :co2_jump_factor do |idx|
  prev = safe_prev(co2_emissions, idx)
  jump = relative_jump(co2_emissions[idx], prev)
  clamp01(jump / 0.35)
end

define :heat_threat_factor do |idx|
  a = temperature_anomaly[idx]
  if a < 1.0
    0.0
  elsif a < 1.5
    0.25
  elsif a < 2.0
    0.5
  elsif a < 2.5
    0.75
  else
    1.0
  end
end

define :tipping_factor do |idx|
  a = temperature_anomaly[idx]
  c = co2_emissions[idx]
  b = biodiversity[idx]
  
  score = 0.0
  score += 0.35 if a >= 1.5
  score += 0.30 if a >= 2.0
  score += 0.25 if c >= 40
  score += 0.30 if b <= 0.20
  
  clamp01(score)
end

define :dissonance_factor do |idx|
  d = co2_jump_factor(idx) * 0.5 + heat_threat_factor(idx) * 0.3 + tipping_factor(idx) * 0.2
  clamp01(d)
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

define :forest_scale do |idx|
  y = years[idx]
  root, mode = epoch_palette(y)
  scale(root, mode, num_octaves: 3)
end

define :forest_progression_degrees do |idx|
  base_ring = (ring 0, 3, 4, 2)
  shift = decade_degree(
    idx,
    temperature_anomaly[idx],
    co2_emissions[idx],
    biodiversity[idx]
  )
  
  [
    (base_ring[0] + shift) % 7,
    (base_ring[1] + shift) % 7,
    (base_ring[2] + shift) % 7,
    (base_ring[3] + shift) % 7
  ]
end

define :forest_chord_for_step do |idx, step_idx|
  sc = forest_scale(idx)
  degs = forest_progression_degrees(idx)
  deg = degs[step_idx % degs.length]
  base = tertian_chord_from_scale(sc, deg)
  
  diss = dissonance_factor(idx)
  
  if diss > 0.75
    base + [base[-1] + 1]
  elsif diss > 0.45
    base + [base[1] + 1]
  elsif diss > 0.20
    base + [base[0] + 2]
  else
    base
  end.sort
end

define :soft_prophet_voice do |note, amp_val, idx|
  diss = dissonance_factor(idx)
  cutoff_val = 82 - (diss * 10)
  res_val = 0.65 + (diss * 0.2)
  
  with_fx :lpf, cutoff: cutoff_val do
    synth :prophet,
      note: note,
      amp: amp_val,
      attack: 0.35,
      sustain: 1.0,
      release: 1.15,
      cutoff: cutoff_val + 3,
      res: res_val
    
    synth :prophet,
      note: note + 0.08,
      amp: amp_val * 0.55,
      attack: 0.38,
      sustain: 0.95,
      release: 1.2,
      cutoff: cutoff_val - 2,
      res: res_val * 0.9
  end
end

# ----------------------
# RHYTHMUS-PATTERNS FÜR DEN WALD
# ----------------------
define :forest_pattern_pool do |idx|
  diss = dissonance_factor(idx)
  heat = heat_threat_factor(idx)
  tip = tipping_factor(idx)
  
  if tip > 0.75
    [
      [0.18, 0.18, 0.36, 0.14, 0.14, 0.30],
      [0.22, 0.11, 0.11, 0.28, 0.17, 0.31],
      [0.16, 0.16, 0.16, 0.32, 0.20]
    ]
  elsif diss > 0.55 || heat > 0.5
    [
      [0.25, 0.25, 0.50],
      [0.20, 0.15, 0.25, 0.40],
      [0.30, 0.10, 0.20, 0.40],
      [0.18, 0.18, 0.24, 0.40]
    ]
  else
    [
      [0.50, 0.50],
      [0.33, 0.33, 0.34],
      [0.25, 0.25, 0.50],
      [0.20, 0.30, 0.50]
    ]
  end
end

define :choose_forest_pattern do |idx, voice_offset = 0|
  pool = forest_pattern_pool(idx)
  pool[(idx + voice_offset) % pool.length].ring
end

define :forest_note_pool do |idx, step_idx|
  chord_notes = forest_chord_for_step(idx, step_idx)
  sc = forest_scale(idx)
  diss = dissonance_factor(idx)
  
  if diss > 0.6
    (chord_notes + [chord_notes[1] + 1, chord_notes[2] + 1, chord_notes[0] + 13]).uniq.sort
  elsif diss > 0.25
    (chord_notes + [chord_notes[0] + 2, chord_notes[1] + 12]).uniq.sort
  else
    (chord_notes + sc.take(7)).uniq.sort
  end
end

# ----------------------
# HTML VORERST AUS
# ----------------------
define :update_html do |year, temp_val, temp_anom, co2_val, bio_val|
end

update_html(
  years[year_index],
  temperature[year_index],
  temperature_anomaly[year_index],
  co2_emissions[year_index],
  biodiversity[year_index]
)

set :men_chord, chord_for_decade(year_index)
set :women_chord, chord_for_decade(year_index).map { |n| n + 12 }
set :decade_change_pulse, 1
set :forest_step, 0

# ----------------------
# REGENWALD BASIS
# stärker skalen-/progressionsbezogen
# mit alternierenden Rhythmuspatterns
# ----------------------
live_loop :rain do
  idx = year_index
  b = biodiversity[idx]
  g = forest_gain(b)
  diss = dissonance_factor(idx)
  pat = choose_forest_pattern(idx, 0)
  d = pat.tick(:rain_pat)
  
  with_fx :hpf, cutoff: 95 + diss * 12 do
    synth :noise,
      amp: (0.013 + diss * 0.004) * g,
      attack: 0.01,
      sustain: d * 0.45,
      release: d * 0.25,
      pan: rrand(-0.45, 0.45)
  end
  
  sleep d
end

live_loop :rain_soft_layer do
  idx = year_index
  b = biodiversity[idx]
  g = forest_gain(b)
  pat = choose_forest_pattern(idx, 1)
  d = pat.tick(:rain_soft_pat)
  
  with_fx :lpf, cutoff: 92 do
    synth :bnoise,
      amp: 0.010 * g,
      attack: d * 0.25,
      sustain: d * 0.65,
      release: d * 0.35
  end
  
  sleep d
end

live_loop :forest_bed do
  idx = year_index
  b = biodiversity[idx]
  g = forest_gain(b)
  step_idx = get(:forest_step)
  chord_notes = forest_chord_for_step(idx, step_idx)
  root_note = chord_notes[0]
  diss = dissonance_factor(idx)
  
  with_fx :lpf, cutoff: 70 - diss * 6 do
    synth :bnoise,
      attack: 1.5,
      sustain: 5,
      release: 5,
      amp: 0.024 * g
  end
  
  with_fx :reverb, room: 0.75, mix: 0.25 do
    synth :dark_ambience,
      note: root_note - 12,
      amp: 0.08 * g,
      attack: 1.2,
      sustain: 3.8,
      release: 2.5
  end
  
  if diss > 0.35
    with_fx :reverb, room: 0.7, mix: 0.2 do
      synth :hollow,
        note: chord_notes[-1] - 12,
        amp: 0.03 * g,
        attack: 0.8,
        sustain: 1.8,
        release: 1.6
    end
  end
  
  sleep 4.0
end

live_loop :forest_birds do
  idx = year_index
  b = biodiversity[idx]
  g = forest_gain(b)
  
  if b > 0.18
    step_idx = get(:forest_step)
    pool = forest_note_pool(idx, step_idx)
    pat = choose_forest_pattern(idx, 2)
    d = pat.tick(:birds_pat)
    note = pool.choose + [12, 19].choose
    
    synth :sine,
      note: note,
      attack: 0.01,
      sustain: [0.04, d * 0.28].max,
      release: [0.08, d * 0.18].max,
      amp: 0.045 * g,
      pan: rrand(-0.8, 0.8)
    
    sleep d
  else
    sleep 1.2
  end
end

live_loop :forest_insects do
  idx = year_index
  b = biodiversity[idx]
  g = forest_gain(b)
  
  if b > 0.28
    step_idx = get(:forest_step)
    pool = forest_note_pool(idx, step_idx)
    pat = choose_forest_pattern(idx, 3)
    d = pat.tick(:insects_pat)
    
    with_fx :hpf, cutoff: 110 do
      synth :pulse,
        note: pool.choose + [12, 19].choose,
        amp: 0.015 * g,
        attack: 0.005,
        sustain: [0.02, d * 0.18].max,
        release: [0.03, d * 0.10].max,
        pulse_width: 0.2,
        pan: rrand(-0.9, 0.9)
    end
    
    sleep d
  else
    sleep 1.0
  end
end

live_loop :forest_harmony do
  idx = year_index
  b = biodiversity[idx]
  
  if b > 0.14
    step_idx = get(:forest_step)
    chord_notes = forest_chord_for_step(idx, step_idx)
    g = forest_gain(b)
    diss = dissonance_factor(idx)
    pat = choose_forest_pattern(idx, 4)
    d = pat.tick(:harmony_pat)
    
    with_fx :reverb, room: 0.82, mix: 0.24 do
      synth :hollow,
        note: chord_notes[1],
        amp: (0.024 + diss * 0.01) * g,
        attack: d * 0.35,
        sustain: d * 0.55,
        release: d * 0.45
    end
    
    sleep d
  else
    sleep 1.5
  end
end

# ----------------------
# AFFENSCHREI
# stärker an Progression gebunden
# rhythmisch alternierend
# ----------------------
live_loop :monkey_call do
  idx = year_index
  b = biodiversity[idx]
  
  if b > 0.35
    step_idx = get(:forest_step)
    chord_notes = forest_chord_for_step(idx, step_idx)
    g = forest_gain(b)
    diss = dissonance_factor(idx)
    
    # kleine alternierende Ruf-Figuren
    call_patterns =
    if diss > 0.6
      [[0.10, 0.08, 0.18], [0.12, 0.12, 0.10, 0.16]]
    else
      [[0.12, 0.18], [0.10, 0.10, 0.20]]
    end
    
    pat = call_patterns[(idx + step_idx) % call_patterns.length]
    
    with_fx :reverb, mix: 0.3, room: 0.7 do
      pat.each_with_index do |dur, i|
        n =
        case i % 3
        when 0
          chord_notes[0] + (diss > 0.6 ? 1 : 0)
        when 1
          chord_notes[1] || (chord_notes[0] + 3)
        else
          chord_notes[2] || (chord_notes[1] + 2)
        end
        
        synth :fm,
          note: n,
          attack: 0.02,
          sustain: dur * 0.45,
          release: dur * 0.65,
          amp: (0.15 + 0.05 * g),
          pan: rrand(-0.8, 0.8)
        
        sleep dur
      end
    end
    
    sleep 4.5 + (1.0 - b) * 7.0
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
        soft_prophet_voice(n, 0.14 * gain, year_index)
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
# größere CO2-Sprünge -> dissonantere Färbung
# ----------------------
live_loop :men do
  idx = year_index
  chord_notes = get(:men_chord)
  v = voices_from_co2(co2_emissions[idx])
  gain = choir_gain(biodiversity[idx])
  diss = dissonance_factor(idx)
  
  active_notes = chord_notes.take(v)
  
  if diss > 0.6 && active_notes.length > 1
    active_notes = active_notes.dup
    active_notes[-1] = active_notes[-1] + 1
  elsif diss > 0.3 && active_notes.length > 2
    active_notes = active_notes.dup
    active_notes[1] = active_notes[1] + 1
  end
  
  with_fx :reverb, room: 0.78, mix: 0.30 do
    active_notes.each do |note|
      soft_prophet_voice(note, 0.10 * gain, idx)
      
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
# Kipppunkte -> schärfere obere Reibung
# ----------------------
live_loop :women do
  idx = year_index
  chord_notes = get(:women_chord)
  v = voices_from_temp(temperature[idx])
  gain = choir_gain(biodiversity[idx])
  threat = heat_threat_factor(idx)
  tip = tipping_factor(idx)
  
  active_notes = chord_notes.reverse.take(v).reverse
  
  if tip > 0.7 && active_notes.length > 0
    active_notes = active_notes.dup
    active_notes[-1] = active_notes[-1] + 1
  elsif threat > 0.45 && active_notes.length > 1
    active_notes = active_notes.dup
    active_notes[0] = active_notes[0] + 1
  end
  
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
# WALD-PROGRESSION
# ----------------------
live_loop :forest_progression_clock do
  set :forest_step, (get(:forest_step) + 1) % 4
  sleep 4
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
  set :forest_step, 0
  
  update_html(
    years[year_index],
    temperature[year_index],
    temperature_anomaly[year_index],
    co2_emissions[year_index],
    biodiversity[year_index]
  )
end