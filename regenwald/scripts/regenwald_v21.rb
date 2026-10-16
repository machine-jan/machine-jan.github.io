# Copyright (c) 2025-2026 Jan Buchenau
# SPDX-License-Identifier: MIT
# https://machine-jan.github.io

use_random_seed rrand_i(1000,9999)

###############################################
# GLOBAL MIX – cineastisch & tiefenbetont
###############################################

with_fx :compressor, threshold: 0.35, clamp_time: 0.01, relax_time: 0.25 do
  with_fx :lpf, cutoff: 90 do
    with_fx :reverb, mix: 0.5, room: 1 do
      
      set :phase, :day
      set :rain_level, 0.4
      set :bio, 1.0
      
      ########################################
      # 🌗 3 MIN TAG/NACHT
      ########################################
      live_loop :cycle do
        set :phase, (get(:phase) == :day ? :night : :day)
        sleep 180
      end
      
      ########################################
      # 🌳 WALDKÖRPER – weniger Rauschen
      ########################################
      live_loop :forest_body do
        synth :noise,
          amp: 0.07,
          attack: 6,
          sustain: 20,
          release: 10
        sleep 16
      end
      
      ########################################
      # 🌊 TIEFE WALDENERGIE (betont)
      ########################################
      live_loop :deep_forest do
        base = rrand(22,30)
        
        4.times do
          synth :sine,
            note: base,
            attack: 0.8,
            sustain: 0.8,
            release: 2,
            amp: 0.09,
            pan: rrand(-0.4,0.4)
          sleep rrand(2,4)
        end
        
        sleep rrand(12,20)
      end
      
      ########################################
      # 🦗 INSEKTEN – 4 Typen
      ########################################
      
      # Kleine Zikaden
      live_loop :cicadas_small do
        with_fx :rbpf, centre: rrand(105,115), res: 0.4 do
          synth :noise,
            amp: 0.008,
            sustain: 2,
            release: 2,
            pan: rrand(-1,1)
        end
        sleep rrand(1.5,3)
      end
      
      # Mittlere Pulsierer
      live_loop :cicadas_mid do
        sleep rrand(4,8)
        4.times do
          synth :noise,
            amp: 0.01,
            sustain: 0.5,
            release: 0.8,
            pan: rrand(-1,1)
          sleep 0.7
        end
      end
      
      # Große Brummer (bewegend)
      live_loop :beetles do
        sleep rrand(10,25)
        6.times do |i|
          synth :saw,
            note: rrand(45,60),
            attack: 0.05,
            sustain: 0.2,
            release: 0.3,
            amp: 0.03,
            pan: -1 + (i * 0.4)
          sleep 0.25
        end
      end
      
      # Tiefe Nachtinsekten
      live_loop :low_insects do
        sleep rrand(6,12)
        synth :fm,
          note: rrand(40,55),
          depth: 2,
          divisor: 2,
          sustain: 1,
          release: 2,
          amp: 0.05,
          pan: rrand(-1,1)
      end
      
      ########################################
      # 🐦 VÖGEL – 5 Typen
      ########################################
      
      # Rhythmische Tagvögel
      live_loop :songbirds do
        if get(:phase) == :day
          sleep rrand(5,12)
          3.times do
            synth :sine,
              note: rrand(70,88),
              sustain: 0.3,
              release: 1,
              amp: 0.06,
              pan: rrand(-1,1)
            sleep rrand(0.5,1.2)
          end
        else
          sleep 10
        end
      end
      
      # Territorial
      live_loop :territorial do
        if get(:phase) == :day
          sleep rrand(20,40)
          4.times do
            synth :tri,
              note: rrand(80,95),
              sustain: 0.2,
              release: 0.6,
              amp: 0.05,
              pan: [-0.7,0.7].choose
            sleep 0.8
          end
        else
          sleep 20
        end
      end
      
      # Fernes Echo-Vogel
      live_loop :distant_bird do
        sleep rrand(15,30)
        with_fx :lpf, cutoff: 65 do
          synth :sine,
            note: rrand(60,75),
            sustain: 1,
            release: 2,
            amp: 0.04,
            pan: rrand(-0.5,0.5)
        end
      end
      
      ########################################
      # 🐒 AFFEN – 3 Typen
      ########################################
      
      # Kleine hektische
      live_loop :small_monkeys do
        if get(:phase) == :day
          sleep rrand(50,100)
          5.times do
            synth :fm,
              note: rrand(75,95),
              sustain: 0.4,
              release: 1,
              amp: 0.12,
              pan: rrand(-1,1)
            sleep rrand(0.4,0.8)
          end
        else
          sleep 40
        end
      end
      
      # Brüllaffe
      live_loop :howler do
        if get(:phase) == :day
          sleep rrand(80,150)
          synth :fm,
            note: rrand(28,40),
            sustain: 3,
            release: 4,
            amp: 0.2,
            pan: rrand(-0.6,0.6)
        else
          sleep 60
        end
      end
      
      ########################################
      # 🐆 PREDATOR – 2 Charaktere
      ########################################
      
      live_loop :big_cat do
        if get(:phase) == :night
          sleep rrand(70,140)
          4.times do |i|
            synth :fm,
              note: rrand(26,38),
              sustain: 1.5,
              release: 3,
              amp: 0.22,
              pan: -1 + (i * 0.5)
            sleep 1
          end
        else
          sleep 50
        end
      end
      
      # Fernes Raubtier
      live_loop :distant_predator do
        if get(:phase) == :night
          sleep rrand(120,200)
          with_fx :lpf, cutoff: 55 do
            synth :fm,
              note: rrand(22,30),
              sustain: 2,
              release: 4,
              amp: 0.15,
              pan: rrand(-0.8,0.8)
          end
        else
          sleep 80
        end
      end
      
      ########################################
      # 🐸 FRÖSCHE
      ########################################
      live_loop :frogs do
        if get(:phase) == :night
          sleep rrand(6,14)
          synth :fm,
            note: rrand(30,50),
            sustain: 0.8,
            release: 2,
            amp: 0.18,
            pan: rrand(-1,1)
        else
          sleep 10
        end
      end
      
    end
  end
end