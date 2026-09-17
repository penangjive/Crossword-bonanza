# Crossword Bonanza

A crossword game for 5–10 year olds, built in SwiftUI for iPhone and iPad.

Picture clues for children who cannot read yet, text clues for children who can,
and a 30-level ladder that carries them from one to the other. Every clue can be
read aloud. There is no fail state, no timer and no way to lose.

---

## Build it on an iPad (no Mac needed)

`CrosswordBonanza.swiftpm` is a Swift Playgrounds app package. Get that folder
onto the iPad — Files, iCloud Drive, or a git client like Working Copy — then tap
it. Swift Playgrounds opens it and the **Run** button builds and runs the game on
the iPad itself.

Requires **Swift Playgrounds 4.4 or newer**: the app uses `@Observable`, which
needs the iOS 17 SDK. On an older Swift Playgrounds it will fail to compile, and
the errors will look like code bugs when they are a tooling version problem.

Three things genuinely cannot be tested this way, and none of them is a bug:

- **Haptics do nothing on iPad.** Only iPhones have a Taptic Engine, so every
  `Haptics` call is a silent no-op there.
- **No simulator.** The game runs full screen on the iPad, so only the iPad
  layout gets exercised — iPhone SE crowding stays unverified.
- **No hardware mute switch.** Use silent mode in Control Centre instead; the
  `.ambient` audio session honours it.

The package is **generated**. `CrosswordBonanza/` is the source of truth:

```bash
python3 Tools/make_swiftpm.py          # regenerate after changing any source
python3 Tools/make_swiftpm.py --check  # fails if the two have drifted apart
```

## Build it on a Mac

```bash
open CrosswordBonanza.xcodeproj    # needs Xcode 16 or newer
```

Pick any iPhone or iPad simulator and press ⌘R. There are no dependencies, no
package resolution step and nothing to install.

**If Xcode refuses to open the project file**, regenerate it — the committed
`project.pbxproj` was written by hand, without a Mac available to test it on:

```bash
brew install xcodegen
rm -rf CrosswordBonanza.xcodeproj
xcodegen generate
open CrosswordBonanza.xcodeproj
```

Requirements: Xcode 16+, iOS 17.0+. Portrait only, iPhone and iPad.

---

## How the game works

### The difficulty ramp

| Tier | Levels | Grid | Words | Clue | Keyboard |
|---|---|---|---|---|---|
| **Picture Puzzles** | 1–10 | up to 5×5 | 2–5 | A large emoji, spoken aloud. Nothing to read. | Only the letters this puzzle needs, plus two decoys |
| **Word Builders** | 11–20 | up to 6×6 | 5–6 | A smaller emoji beside a short sentence | Full A–Z |
| **Real Crosswords** | 21–30 | up to 8×8 | 6–9 | The sentence alone | Full A–Z |

Finishing a level unlocks the next one. Word count and grid size never decrease
as you climb — `Tools/validate_levels.py` fails the build data if they ever do.

### No fail state

A wrong letter appears in the cell in red, shakes, and fades away. Nothing is
lost: no lives, no timer, no score penalty, no counter of mistakes. A wrong
letter is never written into the grid at all, which is why `PuzzleEngine.filled`
only ever holds correct letters.

The lightbulb button reveals one letter and is **always** available and
**never** limited. A stuck child must always have a way forward.

Stars are awarded on hints used, not mistakes: **3** for none, **2** for one or
two, **1** beyond that. Replaying can raise a level's stars but never lower
them.

### Reading support

Every clue has a speaker button at every tier. Tier 1 says the word itself
("Cat"); from tier 2 the narrator reads the clue sentence. When a word is
completed the narrator spells it out and then says it — that moment is the main
reading payoff in the game.

### Sound

There are no audio files in this repository. Every sound is synthesised at
runtime by `Audio/SynthAudioEngine.swift`, a small sine/triangle synth feeding an
`AVAudioSourceNode`. The background loop in `MusicBox.swift` is written entirely
in the C major pentatonic scale, so no two notes can clash.

The audio session is `.ambient`, so the hardware mute switch silences the game
and it never interrupts music the family already has playing.

### Privacy

No network code, no accounts, no analytics, no third-party SDKs, no external
links, no ads, no in-app purchases. The only thing stored is a star count per
level in `UserDefaults`. Nothing about the child leaves the device.

---

## Project layout

```
CrosswordBonanza.swiftpm/                generated iPad build -- do not edit
CrosswordBonanza/
  App/      entry point, routing, AppModel (owns navigation, sound and progress)
  Model/    Level + levels.json decoding, PuzzleEngine, ProgressStore
  View/     Theme, title, level map, puzzle screen, grid, keyboard, confetti
  Audio/    synth, music, sound effects, speech, haptics
  Resources/levels.json, Assets.xcassets
Tools/      the Python level pipeline (below)
```

`AppModel` is the single funnel for every sound, spoken clue and haptic, so the
mute switches are honoured in one place rather than checked in a dozen views.

---

## The level pipeline

Puzzles are not hand-placed. `Tools/` generates and checks them:

```bash
python3 Tools/word_bank.py           # lint the vocabulary
python3 Tools/generate_levels.py     # pack words into grids -> levels.json
python3 Tools/generate_levels.py --show   # ... and print every grid as ASCII
python3 Tools/validate_levels.py     # re-derive and check every grid
python3 Tools/simulate_play.py       # play all 30 levels through the engine rules
python3 Tools/check_project.py       # structural check of the .xcodeproj
python3 Tools/make_swiftpm.py --check     # iPad package is in sync with the sources
```

Generation is deterministic — a fixed seed per level means re-running produces
byte-identical output, so regenerating never churns the diff.

`validate_levels.py` is written independently of the generator and re-derives
each grid from the raw JSON. It checks that words fit, that every crossing
agrees on its letter, that no word butts into another or runs alongside one
(which would create an unclued word in the grid), that the grid is one connected
piece with no wasted edge rows, that clues never contain their own answer, that
no two words in a puzzle share a picture clue, and that the ladder never gets
easier.

`simulate_play.py` re-implements the Swift cursor logic and plays all 30 levels
three ways — a flawless run, a hints-only run, and a wrong-letter run — to prove
no puzzle can strand the cursor and that the star rules land where they should.

### Adding words or levels

Add to `WORDS` in `Tools/word_bank.py` (the rules for a good entry are in its
docstring), adjust `LEVEL_SPECS` in `generate_levels.py` if you want more levels,
then re-run generate → validate → simulate.

---

## Known limits

This was written in a Linux container with no Swift toolchain and no Xcode, so
**the Swift has never been compiled**. The Python pipeline above is the only
part that has actually been executed. Expect a first-build fix round, and treat
the layout, the animation timing and the sound of the music as unreviewed until
someone has run it.

There is no app icon artwork — `AppIcon.appiconset` is an empty placeholder.
