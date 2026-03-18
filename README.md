# daft_bass

A norns script / bass line sequencer with 44 patterns from the complete Daft Punk discography. Plays through the internal MollyThePoly synth engine or out via MIDI.

## Controls

| Control | Action |
|---|---|
| ENC1 | Select bass line |
| ENC2 | BPM |
| ENC3 | Transpose (±24 semitones) |
| KEY2 | Play / Pause |
| KEY3 | Randomize step order (Fisher-Yates shuffle) |

## PARAMS

**Output** — `Internal Synth` or `MIDI Out`

**Synth Voice** (Internal mode) — four preset voices:
- **Analog Sub** — warm saw with sub octave, slow envelope
- **Acid 303** — high resonance, punchy VarSaw, zero sustain decay
- **Juno Chorus** — lush saw with chorus mix, Daft Punk flavoured
- **Pulse Sync** — gritty square wave with noise, à la Robot Rock

**MIDI** — Device (1–4), Channel (1–16)

**Playback** — Velocity, Gate %, Swing %

## Discography (44 patterns)

**Homework (1997)** — Around the World, Da Funk, Burnin', Revolution 909, Fresh, Phoenix, High Fidelity, Teachers, Rollin' & Scratchin', Oh Yeah

**Discovery (2001)** — One More Time, Harder Better, Digital Love, Superheroes, Something About Us, Voyager, Face to Face, Too Long, Short Circuit, High Life

**Human After All (2005)** — Robot Rock, Technologic, Human After All, The Brainwasher, Steam Machine, Make Love, Television Rules the Nation, Emotion

**Tron: Legacy (2010)** — Derezzed, The Grid, Flynn Lives, Outlands, End of Line

**Random Access Memories (2013)** — Give Life Back to Music, The Game of Love, Giorgio by Moroder, Within, Instant Crush, Lose Yourself to Dance, Touch, Get Lucky, Beyond, Motherboard, Fragments of Time, Doin' It Right, Contact

## Requirements

- [norns](https://monome.org/norns) or norns shield
- MollyThePoly engine (included with norns)
- MIDI device optional

## Installation

Via [maiden](http://norns.local) REPL:

```
;install https://github.com/jamminstein/daft_bass
```

Or manually: copy `daft_bass.lua` to `~/dust/code/daft_bass/daft_bass.lua`
