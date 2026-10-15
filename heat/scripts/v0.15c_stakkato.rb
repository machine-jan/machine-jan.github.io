# ============================================================
# CIRCULAR SOUNDS – VERSION 0.15c
# ============================================================

use_bpm 60
use_debug false

# ----------------------
# DATEN
# ----------------------
years = (1800..2100).step(10).to_a

temperature_anomaly = [-0.30,-0.28,-0.27,-0.25,-0.24,-0.22,-0.20,-0.18,
                       -0.15,-0.12,-0.08,-0.03,0.02,0.08,0.15,0.22,
                       0.30,0.40,0.52,0.65,0.80,0.95,1.12,1.30,
                       1.52,1.75,2.00,2.25,2.50,2.75,3.00]

baseline_temp = 13.7
temperature = temperature_anomaly.map { |a| (baseline_temp + a).round(2) }

co2_emissions = [0.02,0.03,0.05,0.08,0.12,0.18,0.28,0.45,
                 0.70,1.00,1.50,2.30,3.50,5.20,7.80,11.0,
                 15.0,20.0,25.0,31.0,36.0,40.0,43.0,46.0,
                 48.0,50.0,51.0,52.0,53.0,54.0,55.0]

biodiversity = [1.00,0.995,0.990,0.985,0.975,0.965,0.950,0.930,
                0.905,0.875,0.840,0.800,0.755,0.705,0.650,0.590,
                0.530,0.470,0.410,0.350,0.295,0.245,0.200,0.160,
                0.125,0.095,0.072,0.055,0.043,0.035,0.030]

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

define :map_lin do |val, in_min, in_max, out_min, out_max|
  return out_min if in_max == in_min
  t = (val - in_min) / (in_max - in_min).to_f
  t = clamp01(t)
  out_min + (out_max - out_min) * t
end

# ----------------------
# ECO TENSION
# ----------------------
define :eco_tension_for_decade do |idx|
  temp_n = map_lin(temperature[idx], TEMP_MIN, TEMP_MAX, 0.0, 1.0)
  co2_n  = map_lin(co2_emissions[idx], CO2_MIN, CO2_MAX, 0.0, 1.0)
  bio_n  = map_lin(biodiversity[idx], BIO_MIN, BIO_MAX, 1.0, 0.0)
  
  clamp01(temp_n * 0.42 + co2_n * 0.33 + bio_n * 0.25)
end

# ----------------------
# PALETTE
# ----------------------
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

# ----------------------
# HARMONIE (neu)
# ----------------------
define :safe_chord_from_scale do |sc, idx|
  tension = eco_tension_for_decade(idx)
  
  if tension < 0.25
    [[0,4,7,9],[0,2,7,9],[0,4,8,11],[0,5,7,10]].choose.map{|i| sc[i]}
  elsif tension < 0.6
    [[0,2,4,6],[1,3,4,6],[0,3,4,7]].choose.map{|i| sc[i]}
  else
    [[0,2,5,8],[1,3,6,8],[0,1,4,7]].choose.map{|i| sc[i]}
  end.uniq.sort
end

define :chord_for_decade do |idx|
  root, mode = epoch_palette(years[idx])
  sc = scale(root, mode, num_octaves: 3)
  safe_chord_from_scale(sc, idx)
end

# ----------------------
# MIX
# ----------------------
define :forest_gain do |b| 0.35 + b end
define :choir_gain do |b| 0.35 + (1.0 - b) * 0.8 end

# ----------------------
# PULSE
# ----------------------
define :pre_signal_unit do |idx|
  map_lin(eco_tension_for_decade(idx), 0.0, 1.0, 0.72, 0.24)
end

# ----------------------
# INIT
# ----------------------
set :men_chord, chord_for_decade(year_index)
set :women_chord, chord_for_decade(year_index).map{|n| n+12}
set :pre_signal_unit_val, pre_signal_unit(year_index)

# ----------------------
# RAIN
# ----------------------
live_loop :rain do
  g = forest_gain(biodiversity[year_index])
  u = get(:pre_signal_unit_val)
  
  synth :noise,
    amp: 0.018 * g,
    sustain: 0.5 * u,
    release: 0.25 * u
  
  sleep 0.6 * u
end

# ----------------------
# BIRDS (neu probabilistisch)
# ----------------------
live_loop :forest_birds do
  idx = year_index
  b = biodiversity[idx]
  g = forest_gain(b)
  u = get(:pre_signal_unit_val)
  
  if rand < map_lin(b,0,1,0.15,0.45)
    chord_notes = get(:women_chord)
    note = chord_notes.choose + [12,19].choose
    
    synth :sine,
      note: note,
      sustain: 0.05,
      release: 0.1,
      amp: 0.05 * g,
      pan: rrand(-0.8,0.8)
    
    sleep [0.2,0.4,0.8,1.2].choose * u
  else
    sleep [1,2,4].choose * u
  end
end

# ----------------------
# MEN (beweglicher)
# ----------------------
live_loop :men do
  chord_notes = get(:men_chord)
  idx = year_index
  
  offset = idx % chord_notes.length
  active = chord_notes.rotate(offset).take(3)
  
  active.each do |n|
    synth :hollow, note: n-12, amp: 0.08
    sleep 0.05
  end
  
  sleep 1.2
end

# ----------------------
# WOMEN (spannungsabhängig)
# ----------------------
live_loop :women do
  idx = year_index
  tension = eco_tension_for_decade(idx)
  chord_notes = get(:women_chord)
  
  active = chord_notes.rotate(idx).take(3)
  
  active.each do |n|
    synth :hollow,
      note: n,
      amp: map_lin(tension,0,1,0.22,0.16),
      attack: map_lin(tension,0,1,0.3,0.1),
      release: map_lin(tension,0,1,1.4,0.8)
    
    sleep 0.05
  end
  
  sleep 1.2
end

# ----------------------
# TIME
# ----------------------
live_loop :time do
  sleep seconds_per_year
  year_index = (year_index + 1) % years_count
  
  set :men_chord, chord_for_decade(year_index)
  set :women_chord, chord_for_decade(year_index).map{|n| n+12}
  set :pre_signal_unit_val, pre_signal_unit(year_index)
end