-- daft_bass.lua
-- Daft Punk complete discography bass line MIDI sequencer
-- with optional internal MollyThePoly synth voice
--
-- ENC1: select line    ENC2: bpm    ENC3: transpose
-- KEY2: play/pause     KEY3: randomize pattern
-- PARAMS: output mode, synth voice, MIDI device/channel, velocity, gate, swing

engine.name = 'MollyThePoly'

local midi_out
local opxy_out = nil
local function opxy_note_on(note, vel)
  if opxy_out then opxy_out:note_on(note, vel, params:get("opxy_channel")) end
end
local function opxy_note_off(note)
  if opxy_out then opxy_out:note_off(note, 0, params:get("opxy_channel")) end
end
local playing   = false
local step      = 1
local clock_id  = nil
local bpm       = 120
local transpose = 0
local selected  = 1
local modified  = {}
local STEPS     = 16
local note_id   = 0  -- rolling voice ID for MollyThePoly noteOn/noteOff

-- Bass lines: MIDI note numbers (C3=48), -1 = rest
-- 16-step patterns at 16th-note resolution (approximate transcriptions)
local lines = {

  -- ── HOMEWORK (1997) ────────────────────────────────────────────────────
  {
    -- MIDI-verified: bass track E3→F#3→E3→D3→B2→B2→A2 (A Dorian / E minor)
    album = "Homework '97",
    name  = "Around the World",
    notes = { 52, -1, -1, -1, 54, -1, 52, -1,
              50, -1, 47, -1, 47, -1, 45, -1 }
  },
  {
    -- Attack Mag confirmed: G minor 111bpm, TB-303 riff G2/Bb2/F2/Eb2
    album = "Homework '97",
    name  = "Da Funk",
    notes = { 43, -1, 46, -1, 41, -1, 43, -1,
              -1, 43, -1, 41, -1, 39, -1, 43 }
  },
  {
    -- bigbasstabs: D-str frets 4,6,7,8 / A-str frets 2,4,5,7 (chromatic ascent)
    album = "Homework '97",
    name  = "Burnin'",
    notes = { 54, 54, 56, 56, 57, 57, 58, 58,
              47, 47, 49, 49, 50, 50, 52, 52 }
  },
  {
    -- bigbasstabs: A-str frets 0,2 acid figure; break adds D3
    album = "Homework '97",
    name  = "Revolution 909",
    notes = { 47, 47, 45, -1, 47, 47, 45, -1,
              50, 50, 47, -1, 50, 50, 47, -1 }
  },
  {
    -- bigbasstabs: E-str frets 11,9 / A-str fret 11 (Eb/Db/Ab)
    album = "Homework '97",
    name  = "Fresh",
    notes = { 51, -1, 49, -1, -1, -1, -1, -1,
              56, -1, 56, -1, -1, -1, -1, -1 }
  },
  {
    -- bigbasstabs main riff: A-str 0,3,5,7 / D-str 5,4 (A Dorian)
    album = "Homework '97",
    name  = "Phoenix",
    notes = { 45, -1, 48, -1, 50, -1, 50, -1,
              52, -1, 52, -1, 50, -1, 45, -1 }
  },
  {
    album = "Homework '97",
    name  = "High Fidelity",
    notes = { 48, -1, 48, 48, -1, 48, -1, 48,
              47, -1, 47, 47, -1, 47, -1, 47 }
  },
  {
    album = "Homework '97",
    name  = "Teachers",
    notes = { 43, -1, 43, -1, 43, 45, 43, -1,
              43, -1, 43, -1, 43, 45, 48, -1 }
  },
  {
    album = "Homework '97",
    name  = "Rollin' & Scratchin'",
    notes = { 43, 43, 43, -1, 43, 43, -1, 43,
              43, 43, 43, -1, 43, 43, -1, -1 }
  },
  {
    album = "Homework '97",
    name  = "Oh Yeah",
    notes = { 53, -1, 53, -1, 53, -1, 55, -1,
              53, -1, 53, -1, 51, -1, 53, -1 }
  },

  -- ── DISCOVERY (2001) ───────────────────────────────────────────────────
  {
    -- bigbasstabs: E-str fret 3=G2 (main), fret 2=F#2; A-str 5=D3, 0=A2
    album = "Discovery '01",
    name  = "One More Time",
    notes = { 43, -1, 43, -1, 43, -1, -1, -1,
              43, -1, 43, -1, 50, -1, 45, -1 }
  },
  {
    album = "Discovery '01",
    name  = "Harder Better",
    notes = { 52, -1, 52, -1, 55, -1, 52, 50,
              52, -1, 52, -1, 57, 55, 52, -1 }
  },
  {
    album = "Discovery '01",
    name  = "Digital Love",
    notes = { 43, -1, 43, 47, 50, -1, 43, -1,
              43, -1, 47, -1, 50, 47, 43, -1 }
  },
  {
    album = "Discovery '01",
    name  = "Superheroes",
    notes = { 50, 50, -1, 50, -1, -1, 50, -1,
              50, 50, -1, 50, -1, -1, 53, -1 }
  },
  {
    -- Attack Mag: Bb major, roots Bb2/A2/D3/G2; slap/pop groove
    album = "Discovery '01",
    name  = "Something About Us",
    notes = { 46, -1, 46, -1, 45, -1, 45, -1,
              50, -1, 50, -1, 43, -1, 43, -1 }
  },
  {
    -- Attack Mag + bigbasstabs: E minor, A-str 7/0/5/6 = E3/A2/D3/Eb3
    album = "Discovery '01",
    name  = "Voyager",
    notes = { 52, -1, 52, -1, 45, -1, 50, -1,
              51, -1, 52, -1, 49, -1, -1, -1 }
  },
  {
    album = "Discovery '01",
    name  = "Face to Face",
    notes = { 48, -1, 48, 51, 48, -1, 43, -1,
              48, -1, 48, 51, 55, -1, 53, -1 }
  },
  {
    album = "Discovery '01",
    name  = "Too Long",
    notes = { 52, -1, 52, -1, 52, 52, -1, 52,
              -1, 52, 52, -1, 52, -1, 52, -1 }
  },
  {
    album = "Discovery '01",
    name  = "Short Circuit",
    notes = { 48, -1, -1, 48, -1, -1, 48, -1,
              -1, 48, -1, -1, 48, 51, -1, -1 }
  },
  {
    album = "Discovery '01",
    name  = "High Life",
    notes = { 50, -1, 50, 53, 50, -1, 48, -1,
              50, -1, 50, 53, 57, -1, 55, -1 }
  },

  -- ── HUMAN AFTER ALL (2005) ─────────────────────────────────────────────
  {
    -- bigbasstabs: A-str fret 5=D3 driven riff, D-str 2=E3 fill
    album = "H.A.A. '05",
    name  = "Robot Rock",
    notes = { 50, 50, -1, 50, -1, 50, 50, -1,
              50, 50, -1, 50, -1, 50, 52, -1 }
  },
  {
    -- bigbasstabs: A7=E3, E5=A2, E8=C3, A5=D3 (4-chord loop)
    album = "H.A.A. '05",
    name  = "Technologic",
    notes = { 52, -1, 52, -1, 45, -1, 45, -1,
              48, -1, 48, -1, 50, -1, 50, -1 }
  },
  {
    album = "H.A.A. '05",
    name  = "Human After All",
    notes = { 40, -1, 40, -1, 40, -1, 40, -1,
              40, 40, -1, 40, -1, 40, 47, -1 }
  },
  {
    album = "H.A.A. '05",
    name  = "The Brainwasher",
    notes = { 38, -1, 38, -1, 38, -1, 38, -1,
              38, 38, -1, 38, -1, 38, 45, -1 }
  },
  {
    album = "H.A.A. '05",
    name  = "Steam Machine",
    notes = { 43, -1, -1, 43, -1, -1, 43, -1,
              -1, 43, -1, -1, 43, -1, -1, 43 }
  },
  {
    album = "H.A.A. '05",
    name  = "Make Love",
    notes = { 45, -1, 45, -1, 43, -1, 43, -1,
              45, -1, 45, -1, 47, -1, 47, -1 }
  },
  {
    -- MIDI-verified root E2 (E minor); sparse hypnotic pulse E2/F#2
    album = "H.A.A. '05",
    name  = "Television Rules the Nation",
    notes = { 40, -1, -1, 40, -1, -1, 40, -1,
              -1, 40, -1, -1, 42, -1, 40, -1 }
  },
  {
    album = "H.A.A. '05",
    name  = "Emotion",
    notes = { 50, -1, 50, -1, 53, -1, 55, -1,
              57, -1, 55, -1, 53, -1, 50, -1 }
  },

  -- ── TRON: LEGACY (2010) ────────────────────────────────────────────────
  {
    -- MIDI shows Eb/Bb cluster → Bb minor; root Bb2=46, fill Db3=49/Eb3=51
    album = "Tron: Legacy '10",
    name  = "Derezzed",
    notes = { 46, -1, 46, 46, -1, 46, -1, 46,
              46, -1, 46, 46, -1, 49, 51, 46 }
  },
  {
    album = "Tron: Legacy '10",
    name  = "The Grid",
    notes = { 43, -1, -1, -1, 43, -1, -1, -1,
              45, -1, -1, -1, 47, -1, -1, -1 }
  },
  {
    album = "Tron: Legacy '10",
    name  = "Flynn Lives",
    notes = { 47, -1, 47, -1, 50, -1, 47, -1,
              47, -1, 50, -1, 52, -1, 50, -1 }
  },
  {
    album = "Tron: Legacy '10",
    name  = "Outlands",
    notes = { 40, -1, -1, 40, -1, -1, 40, -1,
              40, -1, -1, 43, -1, -1, 45, -1 }
  },
  {
    album = "Tron: Legacy '10",
    name  = "End of Line",
    notes = { 52, -1, 52, 55, 52, -1, 50, -1,
              52, -1, 52, 55, 57, -1, 55, -1 }
  },

  -- ── RANDOM ACCESS MEMORIES (2013) ──────────────────────────────────────
  {
    album = "R.A.M. '13",
    name  = "Give Life Back to Music",
    notes = { 40, -1, 40, 43, 40, -1, 38, -1,
              40, -1, 40, 43, 45, 43, 40, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "The Game of Love",
    notes = { 45, -1, 45, -1, 43, -1, 43, -1,
              45, -1, 45, -1, 47, -1, 48, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Giorgio by Moroder",
    notes = { 43, -1, -1, -1, 43, -1, -1, -1,
              43, -1, -1, -1, 43, -1, 45, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Within",
    notes = { 47, -1, -1, -1, 47, -1, -1, -1,
              48, -1, -1, -1, 50, -1, -1, -1 }
  },
  {
    -- Attack Mag: Bb minor (A# minor), Nathan East; root Bb2=46, Ab2=44
    album = "R.A.M. '13",
    name  = "Instant Crush",
    notes = { 46, -1, 46, -1, 44, -1, 44, -1,
              46, -1, 46, -1, 58, -1, 56, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Lose Yourself to Dance",
    notes = { 50, -1, 50, 53, 50, -1, 48, -1,
              50, -1, 50, 53, 55, -1, 53, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Touch",
    notes = { 43, -1, -1, -1, 43, -1, -1, -1,
              45, -1, -1, -1, 47, -1, -1, -1 }
  },
  {
    -- Attack Mag: B Dorian, Nathan East; A-str 2=B2, G-str 4=B3 (octave jumps)
    album = "R.A.M. '13",
    name  = "Get Lucky",
    notes = { 47, -1, 47, 47, 59, -1, -1, 47,
              47, -1, 59, -1, -1, 47, 49, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Beyond",
    notes = { 47, -1, 47, -1, 50, -1, 52, -1,
              53, -1, 52, -1, 50, -1, 48, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Motherboard",
    notes = { 43, -1, -1, 43, -1, -1, 43, -1,
              -1, 43, -1, -1, 45, -1, -1, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Fragments of Time",
    notes = { 52, -1, 52, -1, 50, -1, 48, -1,
              47, -1, 48, -1, 50, -1, 52, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Doin' It Right",
    notes = { 50, -1, -1, 50, -1, -1, 50, -1,
              -1, 50, -1, -1, 50, -1, -1, -1 }
  },
  {
    album = "R.A.M. '13",
    name  = "Contact",
    notes = { 43, -1, 43, 43, -1, 43, 43, -1,
              43, -1, 43, 43, -1, 43, -1, -1 }
  },
}

-- ─── Helpers ────────────────────────────────────────────────────────────────

-- MIDI note → Hz
local function midi_to_hz(note)
  return 440 * 2 ^ ((note - 69) / 12)
end

local function copy_line(idx)
  modified = {}
  for i = 1, STEPS do
    modified[i] = lines[idx].notes[i]
  end
end

local function all_notes_off()
  engine.noteKillAll()
  if midi_out then
    local ch = params:get("midi_ch")
    for ch = 1, 16 do
      midi_out:cc(123, 0, ch) -- all notes off
    end
  end
  if opxy_out then opxy_out:cc(123, 0, params:get("opxy_channel")) end
end

-- Set MollyThePoly to a deep, punchy bass voice
local function init_synth_voice()
  local voice = params:get("synth_voice")

  if voice == 1 then
    -- ── Analog Sub Bass (warm, sustained, slow attack) ───────────────────
    engine.oscWaveShape(1)         -- Saw
    engine.subOscLevel(0.7)        -- thick sub octave
    engine.subOscDetune(0)
    engine.noiseLevel(0.0)
    engine.lpFilterCutoff(400)
    engine.lpFilterResonance(0.2)
    engine.lpFilterCutoffModEnv(0.3)
    engine.lpFilterCutoffEnvSelect(1)  -- env2 drives filter
    engine.env2Attack(0.01)
    engine.env2Decay(0.25)
    engine.env2Sustain(0.6)
    engine.env2Release(0.3)
    engine.env1Attack(0.01)
    engine.env1Decay(0.2)
    engine.env1Sustain(0.5)
    engine.env1Release(0.2)
    engine.glide(0.0)
    engine.chorusMix(0.0)
    engine.amp(0.8)

  elseif voice == 2 then
    -- ── Acid 303 (resonant, punchy, aggressive) ──────────────────────────
    engine.oscWaveShape(0)         -- VarSaw (closest to 303 wave)
    engine.subOscLevel(0.0)
    engine.noiseLevel(0.0)
    engine.lpFilterCutoff(600)
    engine.lpFilterResonance(0.75)
    engine.lpFilterCutoffModEnv(0.8)
    engine.lpFilterCutoffEnvSelect(1)  -- env2
    engine.env2Attack(0.001)
    engine.env2Decay(0.18)
    engine.env2Sustain(0.0)
    engine.env2Release(0.1)
    engine.env1Attack(0.001)
    engine.env1Decay(0.18)
    engine.env1Sustain(0.0)
    engine.env1Release(0.1)
    engine.glide(0.0)
    engine.chorusMix(0.0)
    engine.amp(0.9)

  elseif voice == 3 then
    -- ── Juno Chorus Bass (lush, chorused, Daft-Punk-esque) ───────────────
    engine.oscWaveShape(1)         -- Saw
    engine.subOscLevel(0.3)
    engine.noiseLevel(0.0)
    engine.lpFilterCutoff(700)
    engine.lpFilterResonance(0.15)
    engine.lpFilterCutoffModEnv(0.2)
    engine.lpFilterCutoffEnvSelect(0)
    engine.env2Attack(0.005)
    engine.env2Decay(0.3)
    engine.env2Sustain(0.7)
    engine.env2Release(0.35)
    engine.env1Attack(0.005)
    engine.env1Decay(0.3)
    engine.env1Sustain(0.7)
    engine.env1Release(0.35)
    engine.glide(0.0)
    engine.chorusMix(0.6)
    engine.amp(0.75)

  elseif voice == 4 then
    -- ── Pulse Sync (Robot Rock, gritty square bass) ──────────────────────
    engine.oscWaveShape(2)         -- Pulse
    engine.subOscLevel(0.5)
    engine.noiseLevel(0.02)
    engine.lpFilterCutoff(900)
    engine.lpFilterResonance(0.4)
    engine.lpFilterCutoffModEnv(0.5)
    engine.lpFilterCutoffEnvSelect(1)
    engine.env2Attack(0.001)
    engine.env2Decay(0.12)
    engine.env2Sustain(0.3)
    engine.env2Release(0.15)
    engine.env1Attack(0.001)
    engine.env1Decay(0.12)
    engine.env1Sustain(0.3)
    engine.env1Release(0.15)
    engine.glide(0.0)
    engine.chorusMix(0.0)
    engine.amp(0.85)
  end
end

local function send_note(note, vel, gate_beats)
  local mode = params:get("output_mode")
  local n    = util.clamp(note + transpose, 0, 127)

  if mode == 1 then
    -- ── Internal MollyThePoly ────────────────────────────────────────────
    note_id = (note_id % 1000) + 1
    local id  = note_id
    local hz  = midi_to_hz(n)
    local v   = vel / 127
    engine.noteOn(id, hz, v)
    clock.run(function()
      clock.sync(gate_beats)
      engine.noteOff(id)
    end)
  else
    -- ── MIDI out ─────────────────────────────────────────────────────────
    if not midi_out then return end
    local ch = params:get("midi_ch")
    midi_out:note_on(n, vel, ch)
    clock.run(function()
      clock.sync(gate_beats)
      midi_out:note_off(n, 0, ch)
    end)
  end
  -- ── OP-XY out ──
  opxy_note_on(n, vel)
  clock.run(function()
    clock.sync(gate_beats)
    opxy_note_off(n)
  end)
end

local function step_seq()
  while true do
    clock.sync(1 / 4)  -- align to 16th-note grid

    local swing = params:get("swing")
    if step % 2 == 0 and swing > 0 then
      -- convert beat fraction to seconds for clock.sleep
      clock.sleep((1 / 4) * (swing / 200) * (60 / clock.tempo))
    end

    local note = modified[step]
    local vel  = params:get("velocity")
    local gate = params:get("gate") / 100

    if note and note >= 0 then
      send_note(note, vel, (1 / 4) * gate)
    end

    redraw()
    step = (step % STEPS) + 1
  end
end

-- ─── Norns lifecycle ────────────────────────────────────────────────────────

function init()
  params:add_separator("DAFT BASS")

  params:add_option("output_mode", "Output",
    {"Internal Synth", "MIDI Out"}, 1)
  params:set_action("output_mode", function(v)
    all_notes_off()
    if v == 1 then
      init_synth_voice()
    end
    redraw()
  end)

  params:add_option("synth_voice", "Synth Voice",
    {"Analog Sub", "Acid 303", "Juno Chorus", "Pulse Sync"}, 1)
  params:set_action("synth_voice", function(_)
    if params:get("output_mode") == 1 then
      init_synth_voice()
    end
  end)

  params:add_separator("MIDI")
  params:add_number("midi_dev", "MIDI Device",  1,  4,   1)
  params:add_number("midi_ch",  "MIDI Channel", 1,  16,  1)

  params:set_action("midi_dev", function(v)
    midi_out = midi.connect(v)
  end)

  params:add_separator("OP-XY")
  params:add_number("opxy_device","OP-XY MIDI Device",1,4,2)
  params:set_action("opxy_device",function(v)
    opxy_out=midi.connect(v)
  end)
  params:add_number("opxy_channel","OP-XY MIDI Channel",1,16,1)

  params:add_separator("PLAYBACK")
  params:add_number("velocity", "Velocity",     1,  127, 100)
  params:add_number("gate",     "Gate %",       10, 100, 80)
  params:add_number("swing",    "Swing %",      0,  100, 0)

  midi_out = midi.connect(params:get("midi_dev"))
  opxy_out = midi.connect(params:get("opxy_device"))
  params:set("clock_tempo", bpm)
  copy_line(selected)
  init_synth_voice()
  redraw()
end

function cleanup()
  all_notes_off()
  if clock_id then clock.cancel(clock_id) end
end

-- ─── Controls ───────────────────────────────────────────────────────────────

function enc(n, d)
  if n == 1 then
    selected = util.clamp(selected + d, 1, #lines)
    copy_line(selected)
  elseif n == 2 then
    bpm = util.clamp(bpm + d, 20, 300)
    params:set("clock_tempo", bpm)
  elseif n == 3 then
    transpose = util.clamp(transpose + d, -24, 24)
  end
  redraw()
end

function key(n, z)
  if z ~= 1 then return end

  if n == 2 then
    if playing then
      playing  = false
      if clock_id then clock.cancel(clock_id) end
      clock_id = nil
      all_notes_off()
    else
      playing  = true
      step     = 1
      clock_id = clock.run(step_seq)
    end
    redraw()

  elseif n == 3 then
    -- Fisher-Yates shuffle on working buffer
    for i = #modified, 2, -1 do
      local j = math.random(i)
      modified[i], modified[j] = modified[j], modified[i]
    end
    redraw()
  end
end

-- ─── Display ────────────────────────────────────────────────────────────────

function redraw()
  screen.clear()
  screen.aa(0)
  screen.font_face(1)
  screen.font_size(8)

  -- Title + status
  screen.level(4)
  screen.move(0, 8)
  screen.text("DAFT BASS")
  screen.level(playing and 15 or 5)
  screen.move(127, 8)
  screen.text_right(playing and "PLAY" or "STOP")

  -- Output mode indicator (dim, top right area)
  local mode_str = params:get("output_mode") == 1 and "INT" or "MIDI"
  screen.level(3)
  screen.move(127, 18)
  screen.text_right(mode_str)

  -- Album name (dim)
  screen.level(4)
  screen.move(64, 18)
  screen.text_center(lines[selected].album)

  -- Song name + position counter
  screen.level(15)
  screen.move(64, 28)
  screen.text_center(lines[selected].name ..
    " [" .. selected .. "/" .. #lines .. "]")

  -- BPM and transpose values
  screen.level(15)
  screen.move(0, 38)
  screen.text("BPM " .. bpm)
  screen.move(127, 38)
  screen.text_right("T " .. (transpose >= 0 and "+" or "") .. transpose)

  -- 16-step grid (16 x 7px rects with 1px gaps = 127px total)
  local gw  = 7
  local gap = 1
  local gy  = 46
  local gh  = 10
  local cur = (step == 1) and STEPS or (step - 1)  -- step just triggered

  for i = 1, STEPS do
    local x   = (i - 1) * (gw + gap)
    local has = (modified[i] and modified[i] >= 0)

    if playing and i == cur then
      screen.level(15)
      screen.rect(x, gy, gw, gh)
      screen.fill()
    elseif has then
      screen.level(7)
      screen.rect(x, gy, gw, gh)
      screen.fill()
    else
      screen.level(2)
      screen.rect(x, gy, gw, gh)
      screen.stroke()
    end
  end

  screen.update()
end
