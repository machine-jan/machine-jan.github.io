# ============================================================
# CIRCULAR SOUNDS – VERSION 0.22 FOREST LOSS
# schreibt pro Zustand eine neue JSON-Datei in:
# C:/Users/FarmBot/Desktop/Heat/frames
# und zusätzlich immer:
# C:/Users/FarmBot/Desktop/Heat/latest.json
# ============================================================

use_bpm 60
use_debug false

require "json"
require "fileutils"

BASE_DIR = "C:/Users/FarmBot/Desktop/Heat/frames"
LATEST_PATH = "C:/Users/FarmBot/Desktop/Heat/latest.json"
FileUtils.mkdir_p(BASE_DIR)

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

# Neue Reihe:
# relativer Verlust / Abholzung von Waldflächen
# 0.00 = kaum Verlust, 1.00 = maximaler Verlust
forest_loss = [0.02, 0.02, 0.025, 0.03, 0.04, 0.05, 0.07, 0.09,
               0.12, 0.15, 0.18, 0.22, 0.26, 0.31, 0.36, 0.42,
               0.48, 0.54, 0.60, 0.65, 0.69, 0.72, 0.75, 0.77,
               0.79, 0.80, 0.805, 0.81, 0.815, 0.82, 0.825]

# ----------------------
# TIMING
# ----------------------
total_seconds = 2 * 60 * 60
years_count = years.length
seconds_per_year = total_seconds.to_f / years_count

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

CO2_MIN   = co2_emissions.min
CO2_MAX   = co2_emissions.max
TEMP_MIN  = temperature.min
TEMP_MAX  = temperature.max
BIO_MIN   = biodiversity.min
BIO_MAX   = biodiversity.max
LOSS_MIN  = forest_loss.min
LOSS_MAX  = forest_loss.max

define :eco_tension_for_decade do |idx|
  temp_n = map_lin(temperature[idx], TEMP_MIN, TEMP_MAX, 0.0, 1.0)
  co2_n  = map_lin(co2_emissions[idx], CO2_MIN, CO2_MAX, 0.0, 1.0)
  bio_n  = map_lin(biodiversity[idx], BIO_MIN, BIO_MAX, 1.0, 0.0)
  loss_n = map_lin(forest_loss[idx], LOSS_MIN, LOSS_MAX, 0.0, 1.0)
  
  clamp01(temp_n * 0.34 + co2_n * 0.26 + bio_n * 0.22 + loss_n * 0.18)
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

define :jump_level_for_decade do |idx|
  return 0 if idx <= 0
  
  co2_prev  = [co2_emissions[idx - 1], 0.0001].max
  bio_prev  = [biodiversity[idx - 1], 0.0001].max
  loss_prev = [forest_loss[idx - 1], 0.0001].max
  
  co2_jump  = (co2_emissions[idx] - co2_emissions[idx - 1]).abs / co2_prev.to_f
  temp_jump = (temperature_anomaly[idx] - temperature_anomaly[idx - 1]).abs
  bio_jump  = (biodiversity[idx] - biodiversity[idx - 1]).abs / bio_prev.to_f
  loss_jump = (forest_loss[idx] - forest_loss[idx - 1]).abs / loss_prev.to_f
  
  score = 0
  score += 1 if co2_jump  > 0.18
  score += 1 if co2_jump  > 0.35
  score += 1 if temp_jump > 0.12
  score += 1 if temp_jump > 0.22
  score += 1 if bio_jump  > 0.06
  score += 1 if bio_jump  > 0.12
  score += 1 if loss_jump > 0.08
  score += 1 if loss_jump > 0.16
  
  return 3 if score >= 6
  return 2 if score >= 4
  return 1 if score >= 2
  0
end

define :env_ok_for_decade do |idx|
  biodiversity[idx] > 0.72 &&
    temperature_anomaly[idx] < 0.45 &&
    co2_emissions[idx] < 20 &&
    forest_loss[idx] < 0.32
end

define :safe_chord_from_scale do |sc, idx|
  lvl = jump_level_for_decade(idx)
  
  if env_ok_for_decade(idx)
    phase = idx % 4
    
    case phase
    when 0
      [sc[0], sc[1], sc[4], sc[7]].uniq.sort
    when 1
      [sc[0], sc[3], sc[4], sc[7]].uniq.sort
    when 2
      [sc[0], sc[1], sc[4], sc[8]].uniq.sort
    else
      [sc[0], sc[2], sc[4], sc[6]].uniq.sort
    end
  elsif lvl == 0
    [sc[0], sc[2], sc[4], sc[6]].uniq.sort
  elsif lvl == 1
    [sc[1], sc[3], sc[4], sc[6]].uniq.sort
  elsif lvl == 2
    [sc[0], sc[3], sc[4], sc[7]].uniq.sort
  else
    [sc[0], sc[2], sc[5], sc[8]].uniq.sort
  end
end

define :chord_for_decade do |idx|
  y = years[idx]
  root, mode = epoch_palette(y)
  sc = scale(root, mode, num_octaves: 3)
  safe_chord_from_scale(sc, idx)
end

define :forest_scale_for_decade do |idx|
  y = years[idx]
  root, mode = epoch_palette(y)
  
  if env_ok_for_decade(idx)
    scale(root, :minor_pentatonic, num_octaves: 3)
  elsif jump_level_for_decade(idx) <= 1
    scale(root, mode, num_octaves: 3)
  else
    scale(root, :minor_pentatonic, num_octaves: 3)
  end
end

define :soft_prophet_voice do |note, amp_val|
  with_fx :lpf, cutoff: 80 do
    synth :prophet,
      note: note,
      amp: amp_val * 0.45,
      attack: 0.38,
      sustain: 0.90,
      release: 1.10,
      cutoff: 82,
      res: 0.55
    
    synth :prophet,
      note: note + 0.05,
      amp: amp_val * 0.18,
      attack: 0.40,
      sustain: 0.85,
      release: 1.15,
      cutoff: 76,
      res: 0.45
    
    synth :hollow,
      note: note,
      amp: amp_val * 0.75,
      attack: 0.16,
      sustain: 0.85,
      release: 1.20
  end
end

define :pre_signal_unit do |idx|
  tension = eco_tension_for_decade(idx)
  map_lin(tension, 0.0, 1.0, 0.70, 0.26)
end

define :forest_phrase_events do |idx, variant|
  u = get(:pre_signal_unit_val) || pre_signal_unit(idx)
  b = biodiversity[idx]
  
  if b > 0.65
    case variant
    when 0
      [[:note, 1.0 * u], [:rest, 1.2 * u], [:note, 0.8 * u], [:rest, 3.0 * u], [:note, 1.2 * u], [:rest, 5.0 * u]].ring
    when 1
      [[:rest, 1.8 * u], [:note, 0.7 * u], [:rest, 1.2 * u], [:note, 0.9 * u], [:rest, 5.8 * u]].ring
    else
      [[:note, 0.6 * u], [:rest, 1.0 * u], [:note, 1.1 * u], [:rest, 4.6 * u]].ring
    end
  elsif b > 0.30
    case variant
    when 0
      [[:note, 0.8 * u], [:rest, 0.9 * u], [:note, 0.6 * u], [:rest, 2.5 * u], [:note, 0.8 * u], [:rest, 5.3 * u]].ring
    when 1
      [[:rest, 1.2 * u], [:note, 0.5 * u], [:rest, 1.7 * u], [:note, 0.7 * u], [:rest, 6.2 * u]].ring
    else
      [[:note, 0.5 * u], [:rest, 0.8 * u], [:note, 0.5 * u], [:rest, 4.1 * u]].ring
    end
  else
    case variant
    when 0
      [[:note, 0.5 * u], [:rest, 1.4 * u], [:rest, 5.2 * u], [:note, 0.4 * u], [:rest, 7.8 * u]].ring
    when 1
      [[:rest, 3.4 * u], [:note, 0.35 * u], [:rest, 7.4 * u]].ring
    else
      [[:note, 0.4 * u], [:rest, 6.2 * u]].ring
    end
  end
end

define :write_frame do |idx, changed=false|
  frame = tick(:json_frame)
  year = years[idx]
  root, mode = epoch_palette(year)
  
  payload = {
    frame: frame,
    year: year,
    year_index: idx,
    temperature: temperature[idx].round(2),
    temperature_anomaly: temperature_anomaly[idx].round(2),
    co2: co2_emissions[idx].round(2),
    biodiversity: biodiversity[idx].round(3),
    forest_loss: forest_loss[idx].round(3),
    forest_loss_percent: (forest_loss[idx] * 100).round(1),
    eco_tension: eco_tension_for_decade(idx).round(3),
    jump_level: jump_level_for_decade(idx),
    env_ok: env_ok_for_decade(idx),
    men_voices: voices_from_co2(co2_emissions[idx]),
    women_voices: voices_from_temp(temperature[idx]),
    choir_gain: choir_gain(biodiversity[idx]).round(3),
    forest_gain: forest_gain(biodiversity[idx]).round(3),
    forest_density: biodiversity[idx].round(3),
    pre_signal_unit: pre_signal_unit(idx).round(3),
    decade_change_pulse: changed ? 1 : 0,
    epoch_root: root,
    epoch_mode: mode,
    written_at: Time.now.to_f
  }
  
  frame_path = "#{BASE_DIR}/frame_%05d.json" % frame
  json = JSON.pretty_generate(payload)
  
  File.write(frame_path, json)
  File.write(LATEST_PATH, json)
end

# ----------------------
# INITIAL STATE
# ----------------------
set :year_index, 0

idx = get(:year_index) || 0
set :men_chord, chord_for_decade(idx)
set :women_chord, chord_for_decade(idx).map { |n| n + 12 }
set :forest_scale, forest_scale_for_decade(idx)
set :decade_change_pulse, 1
set :pre_signal_unit_val, pre_signal_unit(idx)

write_frame(idx, true)

# ----------------------
# AUDIO LOOPS
# ----------------------
live_loop :rain do
  idx = get(:year_index) || 0
  b = biodiversity[idx]
  g = forest_gain(b)
  u = get(:pre_signal_unit_val) || pre_signal_unit(idx)
  
  with_fx :hpf, cutoff: 95 do
    synth :noise,
      amp: (0.014 + rand * 0.010) * g,
      attack: 0.02 + rand * 0.03,
      sustain: (0.35 + rand * 0.45) * u,
      release: (0.16 + rand * 0.22) * u,
      pan: rrand(-0.6, 0.6)
  end
  
  sleep (0.38 + rand * 0.42) * u
end

live_loop :forest_bed do
  idx = get(:year_index) || 0
  b = biodiversity[idx]
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
  idx = get(:year_index) || 0
  b = biodiversity[idx]
  g = forest_gain(b)
  
  if b > 0.18
    event = forest_phrase_events(idx, 0).tick(:birds_phrase)
    kind = event[0]
    dur = event[1]
    
    if kind == :note
      sc = get(:forest_scale)
      chord_notes = get(:women_chord)
      
      note_pool =
      if rand < 0.28
        (sc.take(6) + chord_notes).uniq
      else
        base = chord_notes.choose
        [base - 2, base + 1, base + 3, base + 6, base + 10]
      end
      
      synth :sine,
        note: note_pool.choose + [12, 19].choose,
        attack: 0.01,
        sustain: [0.05, dur * 0.22].max,
        release: [0.08, dur * 0.22].max,
        amp: 0.046 * g,
        pan: rrand(-0.8, 0.8)
    end
    
    sleep dur * (0.9 + rand * 0.35)
  else
    sleep 2.0
  end
end

live_loop :forest_insects do
  idx = get(:year_index) || 0
  b = biodiversity[idx]
  g = forest_gain(b)
  
  if b > 0.28
    event = forest_phrase_events(idx, 1).tick(:insects_phrase)
    kind = event[0]
    dur = event[1]
    
    if kind == :note
      sc = get(:forest_scale)
      chord_notes = get(:men_chord)
      
      note_choice =
      if rand < 0.22
        sc.choose + 24
      else
        chord_notes.choose + [12, 13, 18].choose
      end
      
      with_fx :hpf, cutoff: 110 do
        synth :pulse,
          note: note_choice,
          amp: 0.014 * g,
          attack: 0.01,
          sustain: [0.02, dur * 0.16].max,
          release: [0.04, dur * 0.12].max,
          pulse_width: 0.2,
          pan: rrand(-0.9, 0.9)
      end
    end
    
    sleep dur * (0.9 + rand * 0.4)
  else
    sleep 2.0
  end
end

live_loop :forest_harmony do
  idx = get(:year_index) || 0
  b = biodiversity[idx]
  g = forest_gain(b)
  
  if b > 0.14
    event = forest_phrase_events(idx, 2).tick(:harmony_phrase)
    kind = event[0]
    dur = event[1]
    
    if kind == :note
      chord_notes = get(:women_chord)
      base = chord_notes.choose - 12
      forest_note =
      if rand < 0.32
        base
      else
        base + [-2, 1, 5, 6].choose
      end
      
      with_fx :reverb, room: 0.84, mix: 0.24 do
        synth :hollow,
          note: forest_note,
          amp: 0.022 * g,
          attack: dur * 0.20,
          sustain: dur * 0.30,
          release: dur * 0.40
      end
    end
    
    sleep dur * (0.92 + rand * 0.36)
  else
    sleep 2.5
  end
end

live_loop :monkey_call do
  idx = get(:year_index) || 0
  b = biodiversity[idx]
  
  if b > 0.35
    chord_notes = get(:women_chord)
    g = forest_gain(b)
    u = get(:pre_signal_unit_val) || pre_signal_unit(idx)
    sc = get(:forest_scale)
    
    rare_long_phrase = (rand < 0.22)
    phrase_len =
    if rare_long_phrase
      [3, 4, 5, 6].choose
    else
      [2, 3, 3, 4].choose
    end
    
    phrase_notes = []
    phrase_len.times do
      n =
      if rand < 0.45
        chord_notes.choose
      else
        sc.choose + [0, 12].choose
      end
      phrase_notes << n
    end
    
    with_fx :reverb, mix: 0.26, room: 0.70 do
      phrase_notes.each do |n|
        synth :fm,
          note: n,
          attack: 0.02,
          sustain: (0.10 + rand * 0.10) * u,
          release: (0.16 + rand * 0.18) * u,
          amp: (0.085 + rand * 0.03) * g,
          pan: rrand(-0.8, 0.8)
        
        sleep (0.22 + rand * 0.22) * u
      end
    end
    
    sleep 7.6 + (1.0 - b) * 9.4 + rand * 2.0
  else
    sleep 7.5 + rand * 1.8
  end
end

live_loop :decade_marker do
  idx = get(:year_index) || 0
  
  if get(:decade_change_pulse) == 1
    b = biodiversity[idx]
    gain = choir_gain(b)
    
    men_ch = get(:men_chord)
    women_ch = get(:women_chord)
    
    with_fx :reverb, room: 0.92, mix: 0.36 do
      men_ch.take(3).each do |n|
        soft_prophet_voice(n, 0.085 * gain)
        sleep 0.03
      end
      
      women_ch.take(4).each do |n|
        synth :hollow,
          note: n,
          amp: 0.19 * gain,
          attack: 0.06,
          sustain: 0.26,
          release: 0.90
        sleep 0.03
      end
    end
    
    set :decade_change_pulse, 0
  end
  
  sleep 0.25
end

live_loop :men do
  idx = get(:year_index) || 0
  chord_notes = get(:men_chord)
  v = voices_from_co2(co2_emissions[idx])
  gain = choir_gain(biodiversity[idx])
  
  active_count = [v + 1, chord_notes.length].min
  active_notes = chord_notes.first(active_count)
  
  with_fx :reverb, room: 0.80, mix: 0.34 do
    active_notes.each do |note|
      soft_prophet_voice(note, 0.095 * gain)
      
      synth :hollow,
        note: note - 12,
        amp: 0.082 * gain,
        attack: 0.24,
        sustain: 1.00,
        release: 1.12
      
      sleep 0.05
    end
  end
  
  sleep 1.2
end

live_loop :women do
  idx = get(:year_index) || 0
  chord_notes = get(:women_chord)
  v = voices_from_temp(temperature[idx])
  gain = choir_gain(biodiversity[idx])
  
  active_count = [v + 1, chord_notes.length].min
  active_notes = chord_notes.last(active_count)
  
  with_fx :reverb, room: 0.96, mix: 0.50 do
    active_notes.each do |note|
      synth :hollow,
        note: note,
        amp: 0.20 * gain,
        attack: 0.24,
        sustain: 1.24,
        release: 1.20
      
      if rand < 0.12
        synth :hollow,
          note: note + [2, 5, 7].choose,
          amp: 0.035 * gain,
          attack: 0.08,
          sustain: 0.18,
          release: 0.38
      end
      
      sleep 0.05
    end
  end
  
  sleep 1.2
end

# ----------------------
# TIME / STATE UPDATE
# ----------------------
live_loop :time do
  sleep seconds_per_year
  
  idx = get(:year_index) || 0
  idx = (idx + 1) % years_count
  set :year_index, idx
  
  new_chord = chord_for_decade(idx)
  
  set :men_chord, new_chord
  set :women_chord, new_chord.map { |n| n + 12 }
  set :forest_scale, forest_scale_for_decade(idx)
  set :decade_change_pulse, 1
  set :pre_signal_unit_val, pre_signal_unit(idx)
  
  write_frame(idx, true)
end