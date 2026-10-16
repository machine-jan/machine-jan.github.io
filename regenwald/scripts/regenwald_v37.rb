# Copyright (c) 2025-2026 Jan Buchenau
# SPDX-License-Identifier: MIT
# https://machine-jan.github.io

# ============================================
# REGENWALD v37
# Organisch lebendig · Tiefenstaffelung
# ============================================

use_random_seed rrand_i(1000,9999)

set :predator, false

############################################
# 🎧 DISTANZ-FUNKTION
############################################

define :forest_voice do |synth_type, note, dist, pan_pos, amp_base, atk, sus, rel|
  
  cutoff = case dist
  when :far then 45
  when :mid then 80
  when :near then 120
  end
  
  amp = case dist
  when :far then amp_base * 0.5
  when :mid then amp_base * 0.8
  when :near then amp_base
  end
  
  with_fx :lpf, cutoff: cutoff do
    synth synth_type,
      note: note,
      attack: atk,
      sustain: sus,
      release: rel,
      amp: amp,
      pan: pan_pos
  end
end

############################################
# 🌧 REGEN (konstant, lebendig)
############################################

live_loop :rain do
  with_fx :hpf, cutoff: 50 do
    synth :noise,
      attack: 2,
      sustain: 3,
      release: 4,
      amp: 0.02,
      pan: rrand(-0.5,0.5)
  end
  sleep rrand(4,7)
end

############################################
# 🌿 WALDBETT
############################################

live_loop :forest_bed do
  with_fx :lpf, cutoff: 70 do
    synth :noise,
      attack: 3,
      sustain: 5,
      release: 6,
      amp: 0.03,
      pan: rrand(-0.4,0.4)
  end
  sleep rrand(5,8)
end

############################################
# 🐒 MEHRERE AFFEN (überlappend)
############################################

live_loop :monkeys do
  sleep rrand(10,25)
  
  base = rrand(55,75)
  dist = [:far,:mid,:near].choose
  
  reps = rrand_i(2,5)
  
  reps.times do
    forest_voice :fm,
      base + rrand(-2,2),
      dist,
      rrand(-0.9,0.9),
      0.15,
      0.1,
      0.2,
      0.4
    sleep rrand(0.2,0.6)
  end
end

############################################
# 🐦 VOGEL-EBENE 1
############################################

live_loop :birds_layer1 do
  sleep rrand(6,15)
  
  forest_voice :sine,
    rrand(85,110),
    [:far,:mid].choose,
    rrand(-1,1),
    0.1,
    0.05,
    0.2,
    0.4
end

############################################
# 🐦 VOGEL-EBENE 2 (rhythmischer)
############################################

live_loop :birds_layer2 do
  sleep rrand(8,18)
  
  base = rrand(80,100)
  interval = [5,7].choose
  
  3.times do
    forest_voice :sine, base, :mid, rrand(-0.7,0.7), 0.1, 0.05, 0.15, 0.3
    sleep 0.2
    forest_voice :sine, base+interval, :mid, rrand(-0.7,0.7), 0.1, 0.05, 0.15, 0.3
    sleep rrand(1.5,3)
  end
end

############################################
# 🦜 MACAW (gelegentlich dominant)
############################################

live_loop :macaw do
  sleep rrand(25,50)
  
  n = rrand(95,110)
  s = synth :saw,
    note: n,
    sustain: 0.4,
    release: 0.8,
    amp: 0.14,
    pan: rrand(-0.7,0.7),
    note_slide: 0.4
  
  control s, note: n - rrand(4,8)
end

############################################
# 🐝 INSEKTEN (permanent, aber subtil)
############################################

live_loop :insects do
  sleep rrand(4,10)
  
  with_fx :slicer, phase: rrand(0.1,0.3), mix: 0.4 do
    forest_voice :noise,
      0,
      [:far,:mid].choose,
      rrand(-1,1),
      0.03,
      0.01,
      0.1,
      0.2
  end
end

############################################
# 🪵 SUBTILE WALDEREIGNISSE
############################################

live_loop :forest_motion do
  sleep rrand(20,40)
  
  sample :perc_snap,
    amp: 0.05,
    pan: rrand(-0.6,0.6)
end

############################################
# 🔔 ATMOSPHÄRISCHE GLOCKEN (sehr tief)
############################################

live_loop :high_bell do
  sleep rrand(80,150)
  
  with_fx :lpf, cutoff: 25 do
    with_fx :reverb, mix: 0.98 do
      synth :tri,
        note: rrand(100,115),
        attack: 3,
        sustain: 0.6,
        release: 6,
        amp: 0.0018,
        pan: rrand(-0.2,0.2)
    end
  end
end