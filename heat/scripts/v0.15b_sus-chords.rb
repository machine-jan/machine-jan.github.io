# ============================================================
# CIRCULAR SOUNDS – VERSION 0.15b SAFE
# ============================================================
#
# Basis: stabile 0.14d
#
# Änderungen:
# - HTML aus
# - Ablaufdauer bleibt 6 Minuten
# - bei funktionierender Umwelt: offenere, schwebendere Akkorde
# - Wald wieder etwas freier, nur punktuell an Skalen andockend
# - vordergründiges Motiv leiser, manchmal 3–6 Töne, aber selten
# - mehr hollow, weniger prophet
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

# ----------------------
# HARMONIE SAFE 0.15b
# ----------------------
define :jump_level_for_decade do |idx|
  return 0 if idx <= 0
  
  co2_prev = [co2_emissions[idx - 1], 0.0001].max
  bio_prev = [biodiversity[idx - 1], 0.0001].max
  
  co2_jump  = (co2_emissions[idx] - co2_emissions[idx - 1]).abs / co2_prev.to_f
  temp_jump = (temperature_anomaly[idx] - temperature_anomaly[idx - 1]).abs
  bio_jump  = (biodiversity[idx] - biodiversity[idx - 1]).abs / bio_prev.to_f
  
  score = 0
  score += 1 if co2_jump  > 0.18
  score += 1 if co2_jump  > 0.35
  score += 1 if temp_jump > 0.12
  score += 1 if temp_jump > 0.22
  score += 1 if bio_jump  > 0.06
  score += 1 if bio_jump  > 0.12
  
  return 3 if score >= 5
  return 2 if score >= 3
  return 1 if score >= 1
  0
end

define :env_ok_for_decade do |idx|
  biodiversity[idx] > 0.72 &&
    temperature_anomaly[idx] < 0.45 &&
    co2_emissions[idx] < 20
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

# ----------------------
# WEICHERER MIX
# mehr hollow, weniger prophet
# ----------------------
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

# ----------------------
# aktueller Vorsignal-Puls
# früh weiter / später enger
# ----------------------
define :pre_signal_unit do |idx|
  temp_factor = map_lin(temperature[idx], TEMP_MIN, TEMP_MAX, 0.0, 1.0)
  co2_factor = map_lin(co2_emissions[idx], CO2_MIN, CO2_MAX, 0.0, 1.0)
  tension = (temp_factor * 0.6 + co2_factor * 0.4)
  map_lin(tension, 0.0, 1.0, 0.70, 0.26)
end

# ----------------------
# Wald-Melodieevents mit echten Pausen, inkl. langen Pausen
# ----------------------
define :forest_phrase_events do |idx, variant|
  u = get(:pre_signal_unit_val) || pre_signal_unit(idx)
  b = biodiversity[idx]
  
  if b > 0.65
    case variant
    when 0
      [
        [:note, 1.0 * u],
        [:rest, 1.0 * u],
        [:note, 0.8 * u],
        [:rest, 2.5 * u],
        [:note, 1.2 * u],
        [:rest, 4.0 * u]
      ].ring
    when 1
      [
        [:rest, 1.5 * u],
        [:note, 0.7 * u],
        [:rest, 1.0 * u],
        [:note, 0.9 * u],
        [:rest, 5.0 * u]
      ].ring
    else
      [
        [:note, 0.6 * u],
        [:rest, 0.8 * u],
        [:note, 1.1 * u],
        [:rest, 3.8 * u]
      ].ring
    end
  elsif b > 0.30
    case variant
    when 0
      [
        [:note, 0.8 * u],
        [:rest, 0.7 * u],
        [:note, 0.6 * u],
        [:rest, 2.0 * u],
        [:note, 0.8 * u],
        [:rest, 4.5 * u]
      ].ring
    when 1
      [
        [:rest, 1.0 * u],
        [:note, 0.5 * u],
        [:rest, 1.3 * u],
        [:note, 0.7 * u],
        [:rest, 5.5 * u]
      ].ring
    else
      [
        [:note, 0.5 * u],
        [:rest, 0.6 * u],
        [:note, 0.5 * u],
        [:rest, 3.5 * u]
      ].ring
    end
  else
    case variant
    when 0
      [
        [:note, 0.5 * u],
        [:rest, 1.2 * u],
        [:rest, 4.5 * u],
        [:note, 0.4 * u],
        [:rest, 7.0 * u]
      ].ring
    when 1
      [
        [:rest, 3.0 * u],
        [:note, 0.35 * u],
        [:rest, 6.5 * u]
      ].ring
    else
      [
        [:note, 0.4 * u],
        [:rest, 5.5 * u]
      ].ring
    end
  end
end

# ----------------------
# HTML AUS
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
set :forest_scale, forest_scale_for_decade(year_index)
set :decade_change_pulse, 1
set :pre_signal_unit_val, pre_signal_unit(year_index)

# ----------------------
# REGENWALD BASIS
# dichter / weniger on-off
# ----------------------
live_loop :rain do
  b = biodiversity[year_index]
  g = forest_gain(b)
  u = get(:pre_signal_unit_val)
  
  with_fx :hpf, cutoff: 95 do
    synth :noise,
      amp: 0.018 * g,
      attack: 0.03,
      sustain: 0.55 * u,
      release: 0.25 * u,
      pan: rrand(-0.45, 0.45)
  end
  
  sleep 0.60 * u
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

# ----------------------
# WALD – freier, nur punktuell angebunden
# ----------------------
live_loop :forest_birds do
  idx = year_index
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
    
    sleep dur
  else
    sleep 2.0
  end
end

live_loop :forest_insects do
  idx = year_index
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
    
    sleep dur
  else
    sleep 2.0
  end
end

live_loop :forest_harmony do
  idx = year_index
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
    
    sleep dur
  else
    sleep 2.5
  end
end

# ----------------------
# VORDERGRÜNDIGES MOTIV
# leiser, weniger plakativ, manchmal länger
# ----------------------
live_loop :monkey_call do
  idx = year_index
  b = biodiversity[idx]
  
  if b > 0.35
    chord_notes = get(:women_chord)
    g = forest_gain(b)
    u = get(:pre_signal_unit_val)
    sc = get(:forest_scale)
    
    rare_long_phrase = (rand < 0.16)
    phrase_len =
    if rare_long_phrase
      [3, 4, 5, 6].choose
    else
      [2, 2, 3].choose
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
    
    sleep 6.8 + (1.0 - b) * 8.2
  else
    sleep 7.0
  end
end

# ----------------------
# JAHRZEHNTSPRUNG-MARKER
# luftiger, יותר hollow
# ----------------------
live_loop :decade_marker do
  if get(:decade_change_pulse) == 1
    b = biodiversity[year_index]
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

# ----------------------
# MÄNNERCHOR = CO2
# mehr hollow, weniger prophet
# ----------------------
live_loop :men do
  idx = year_index
  chord_notes = get(:men_chord)
  v = voices_from_co2(co2_emissions[idx])
  gain = choir_gain(biodiversity[idx])
  
  active_count = [v + 1, chord_notes.length].min
  active_notes = chord_notes.first(active_count)
  
  with_fx :reverb, room: 0.80, mix: 0.34 do
    active_notes.each do |note|
      soft_prophet_voice(note, 0.060 * gain)
      
      synth :hollow,
        note: note - 12,
        amp: 0.052 * gain,
        attack: 0.24,
        sustain: 1.00,
        release: 1.12
      
      sleep 0.05
    end
  end
  
  sleep 1.2
end

# ----------------------
# FRAUENCHOR = TEMPERATUR
# schwebender, offener
# ----------------------
live_loop :women do
  idx = year_index
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
# ZEIT
# ----------------------
live_loop :time do
  sleep seconds_per_year
  year_index = (year_index + 1) % years_count
  
  new_chord = chord_for_decade(year_index)
  
  set :men_chord, new_chord
  set :women_chord, new_chord.map { |n| n + 12 }
  set :forest_scale, forest_scale_for_decade(year_index)
  set :decade_change_pulse, 1
  set :pre_signal_unit_val, pre_signal_unit(year_index)
  
  update_html(
    years[year_index],
    temperature[year_index],
    temperature_anomaly[year_index],
    co2_emissions[year_index],
    biodiversity[year_index]
  )
end