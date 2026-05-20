# timbre 🎙️

> what did you say again?

a free, open-source voice notetaker built for the AI-native workflow. transcription runs locally with whisperkit. every meeting gets written out as a flat `.md` file your agents can read, edit, and reason over. no cloud, no lock-in, no enterprise saas vibes.

![timbre home](screenshots/01-home.png)

## the why

wanted AI-native note-taking like obsidian, but for voice instead of typing. i use openclaw agents every day and needed a front-end layer between thinking out loud and what i'm actually working on. nothing on the market hit the brief — granola is closed-source and lives in their cloud. obsidian is yours but doesn't capture voice. whisper.cpp + a folder of `.md` files works but there's no UI to actually *use* the notes once they exist.

## the friction

paying for granola or otter when whisper runs free on your laptop. no good way to capture voice memos and turn them into searchable, AI-analyzed context that feeds back into your second brain. the moment you finish a meeting, the cost of having anything resembling structured notes goes up linearly with how much you care.

## the motivation

your everyday tools should spark delight. retro aesthetics, whimsical touches, DJ pad buttons you actually want to press. productivity doesn't have to look like enterprise saas. the goal is a personal command center where you record a voice memo and a `.md` file shows up that your agents can do something with — and the UI in between has chrome bubbles and a pixel dolphin that swims across when something completes.

## the name

timbre = the quality that makes a voice recognizable. also sounds like "timber" which is satisfying to say. has a microphone emoji 🎙️.

## the four surfaces

each card on the home screen is a verb. you record, you decode, you browse, you debrief.

- **record** — one button. press to start, press to stop. live waveform. saves as `.m4a` in your library.
- **decode** — transcript view of one meeting. on-device whisperkit transcription, speaker diarization, click-to-seek, edit mode, export. the sparkle `prompt` button runs analysis.
- **browse** — every meeting as a card. filter by speaker, time range, free-text keyword. click any card → a side panel with the full structured analysis (summary, decisions, action items, open questions, notes).
- **debrief** — cross-meeting aggregation. every open question / decision / action across all your meetings, in three columns. each card tags its source meeting and offers one action: `answer` (questions + decisions, opens a text input) or `complete` (actions, with a pixel dolphin slide-in because the joy matters).

![browse cards](screenshots/03-browse-cards.png)

![side panel reading view](screenshots/04-browse-sidepanel.png)

click `edit` and every card becomes inline-editable. summary and notes turn into text editors, each bullet becomes a row you can change / delete / add to. click `done` to save — the structured data updates and the `.md` file gets re-written.

![side panel edit mode](screenshots/05-browse-sidepanel-edit.png)

![debrief — three columns of cross-meeting threads](screenshots/06-debrief.png)

![answer modal mid-typing](screenshots/07-debrief-answer-sheet.png)

## the architecture (and why the `.md` file matters)

three layers, each independently swappable.

**transcription** runs locally on your mac via [whisperkit](https://github.com/argmaxinc/WhisperKit) on the apple neural engine. pick a model size (tiny → large-v3) in settings. audio never leaves the device. speaker diarization happens on-device too via [speakerkit](https://github.com/argmaxinc/WhisperKit) (pyannote, CC-BY-4.0).

**analysis** is opt-in and routes through whatever LLM you trust:

- bring your own openai key. paste it once in settings (stored in macos keychain). click `prompt`, timbre calls gpt-4o directly.
- bring your own LLM, any LLM. click `prompt` without a key and timbre copies a structured prompt to your clipboard. paste it into claude, chatgpt, ollama, whatever. paste the response back (or drop a `.md` file). the parser splits it into the same structured fields the api path produces.
- no analysis at all. just keep the on-device transcript. skip the AI layer.

**storage** is a flat folder of `.md` files. one per meeting. valid github-flavored markdown. opens in obsidian, vs code, cursor, or anything else that reads markdown:

```markdown
---
timbre-memo-id: 07B04C51-934A-4552-BAA3-9386014C38E6
title: studio chat with noor
date: 2026-05-12T21:00:00Z
duration: 2478
model: demo-seed
analyzed: 2026-05-20T05:27:39Z
---

## SUMMARY
studio session with noor on the sample question. we were going to swap the
original sample because of clearance concerns, but talked through it and
agreed the song doesn't work without it.

## DECISIONS
- [x] cancel the alt-version tracking session — not needed
  > vinyl first, streaming follows. confirmed with the pressing plant friday.
- [ ] release vinyl first, streaming follows

## ACTIONS
- [x] me: call the publisher monday morning
- [ ] noor: pull the sample's metadata + previous use cases for the call

## QUESTIONS
- [x] what's the right vinyl-only window — a week, two, a month?
  > we landed on three weeks. enough to feel exclusive, not so long that
  > the streaming launch feels like an afterthought.

## NOTES
### the sample debate
- noor's worry: clearance might be expensive or blocked entirely
- my position: it's the whole emotional core of the song
```

resolved threads become `- [x]` with a nested `> blockquote` answer. unresolved stay as `- [ ]`. it's the same format whether the api wrote it or you did, whether timbre wrote it or you edited it by hand in obsidian. the file is the canonical store — swiftdata is the cache.

your agents can read these files directly. claude code, cursor, aider, openclaw — anything that can grep a folder of markdown can grep your meeting history. that's the whole point.

## settings + demo data

person bubble bottom-right of home opens settings. AI provider + openai key live there. there's also a developer section with **seed demo data** (drops in 5 example memos covering every UI state — un-analyzed, fresh, partially answered, fully resolved, summary-only) and **reset all data** (wipes everything for a clean install).

![settings + developer section](screenshots/02-settings-me.png)

## what's not in v0.1.0 yet

- live `.md` file watching (today: timbre writes, doesn't yet auto-import external edits — round-trip works on app launch)
- multi-provider LLM picker in the UI (the `AnalysisProvider` protocol exists in code; only `OpenAIProvider` is surfaced in settings)
- iCloud / cloudkit sync for shared workspaces (planned)
- iOS (macos only for now)
- record-screen waveform trim editor (record + stop + save works; trim/edit lives in decode's edit mode instead)

## requirements

- macos 14.0 (sonoma) or later
- apple silicon recommended (M1/M2/M3/M4) for fast on-device transcription
- xcode 16+ or swift 5.9+ command-line tools
- ~150 MB disk for the base whisperkit model, ~3 GB for large-v3

## build

```bash
git clone https://github.com/apollinej/apolline-production.git
cd apolline-production/Timbre
./build.sh release
open Timbre.app
```

| command | what it does |
|---------|-------------|
| `./build.sh` | debug build, creates `Timbre.app` in the project dir |
| `./build.sh release` | optimized release build |
| `./build.sh install` | release build + copy to `/Applications` |
| `./build.sh clean` | remove build artifacts |

or open `Package.swift` in xcode and hit ⌘R.

## supported audio formats

`.m4a` `.mp3` `.wav` `.flac` `.aac` `.caf` `.aiff` `.aifc` `.mp4`

## storage layout

```
<storage root>/
├── library/      # imported audio files (uuid-named)
├── transcripts/  # plain-text transcript mirrors
├── analyses/     # YYYY-MM-DD_<slug>.md — the canonical analysis files
├── models/       # whisperkit model cache
└── timbre.store  # swiftdata sqlite database
```

default root is `~/Desktop/Code/apolline-production/timbre/data/`. change it in settings → storage location.

## tech stack

- **swift 5.9+** / **swiftui** — macos-native, no electron, no web view
- **swiftdata** — local persistence (the `.md` files are canonical; swiftdata is the cache)
- **[whisperkit](https://github.com/argmaxinc/WhisperKit)** — coreml whisper on the apple neural engine
- **[speakerkit](https://github.com/argmaxinc/WhisperKit)** — on-device pyannote speaker diarization
- **avfoundation** — audio playback + waveform extraction
- **dotgothic16** (google fonts, SIL OFL) — the pixelated y2k display font

## contributing

issues + pull requests welcome at [github.com/apollinej/apolline-production](https://github.com/apollinej/apolline-production). bugs: include macos version, the surface (record / decode / browse / debrief), steps to reproduce.

## license

MIT — see [LICENSE](LICENSE).
