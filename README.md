# timbre

> what did you say again?

**Timbre is a free, open-source voice notetaker built for the AI-native workflow.** It's the missing layer between Granola (smart meeting capture, but locked in their cloud) and Obsidian (you own your files, but you write them by hand). Record a meeting → on-device transcription → analysis through whichever LLM you trust → every meeting persists as a flat `.md` file your agents can read, edit, and reason over.

## why timbre

Most meeting tools force a trade-off:

- **Cloud notetakers** (Granola, Fathom, Otter): smart, but your audio leaves the device and your notes live in their database. Your data isn't your data.
- **Personal knowledge tools** (Obsidian, Notion, Logseq): you own the files, but you're the one writing them. No transcription, no smart synthesis.
- **DIY scripts**: whisper.cpp + a folder of `.md` files works, but there's no app, no UI, no place to *use* the notes once they exist.

Timbre is what happens when you treat both ends as load-bearing. Transcription is on-device (WhisperKit + speaker diarization, no audio uploaded anywhere). Analysis is opt-in and goes through *your* OpenAI key, *your* local LLM, or — if you don't want any of that — a copy-paste prompt you can hand to ChatGPT, Claude, or any LLM you trust, then paste the result back. Everything saves as a structured `.md` file in a folder you control.

That folder is the point. Your AI coding agent (Claude Code, Cursor, Aider, etc.) can read these `.md` files directly. Your Obsidian vault can point at them. A future agent of your own design can subscribe to them. The app is the UI layer over markdown — not a database that traps your meetings.

## the pitch in one paragraph

If you live in an agentic workflow — running an AI coding agent every day, writing in Obsidian, managing context across tools — and you want a productivity hub that captures voice, surfaces structure, and **outputs to flat files your agents already understand**, that's Timbre. It's a personal command center for your meetings that happens to also be just a folder of `.md` files.

## the four surfaces

- **record** — one button. Press to record, press to stop. Live waveform. Saves as `.m4a` in your library.
- **decode** — sidebar of your meetings, transcript on the right. Click-to-seek, speaker rename, find/replace, in-place edit, export to Markdown / SRT / JSON / plaintext. The sparkle `prompt` button runs analysis.
- **browse** — every recording is a card. Filter by speaker, time range, or free-text keyword. Click any card → side panel with the full structured analysis (summary, decisions, action items, open questions, detailed notes, transcript). Click `edit` → every card becomes inline-editable; save round-trips back into structured data and re-writes the `.md`.
- **debrief** — cross-meeting aggregation. Every open question / decision / action across all your memos, in three columns. Each card tags its source meeting and offers one action: `answer` (for questions and decisions, opens a text input that saves as a `> blockquote` under the bullet) or `complete` (for actions, marks done + a pixel dolphin slides across the screen because the joy matters).

## the AI-native architecture

Three layers, each independently swappable.

**1. Transcription** runs locally on your Mac via [WhisperKit](https://github.com/argmaxinc/WhisperKit) on the Apple Neural Engine. Pick a model size (tiny → large-v3) in Settings. Audio never leaves the device. Speaker diarization is handled on-device too via [SpeakerKit](https://github.com/argmaxinc/WhisperKit) (pyannote, CC-BY-4.0).

**2. Analysis** is opt-in and routes through whichever LLM you trust:

- **Bring your own OpenAI key**: paste it once in Settings (stored in macOS Keychain, never elsewhere). Click `prompt` and Timbre calls GPT-4o directly.
- **Bring your own LLM, any LLM**: click `prompt` without a key and Timbre copies a structured prompt to your clipboard. Paste it into Claude, ChatGPT, your local Ollama, whatever. Paste the response back into the app (or drop a `.md` file). The parser splits it into the same structured fields the API path produces.
- **No analysis at all**: just keep the on-device transcript. Browse it, search it, export it. Skip the AI layer entirely.

**3. Storage** is a flat directory of `.md` files. One file per meeting with YAML frontmatter (memo id, title, date, duration, analysis model, analyzed timestamp) and a strict body format:

```
## SUMMARY     — plain prose
## DECISIONS   — - [ ] / - [x] task bullets
## ACTIONS     — - [ ] / - [x] task bullets
## QUESTIONS   — - [ ] / - [x] task bullets
## NOTES       — free markdown, sub-headings allowed
```

Resolved items get rendered with `  > quoted answer` lines nested under the bullet. The format is **valid GitHub-flavored markdown**, so it works in Obsidian, VS Code, mdcat, the Logseq importer, `grep`, or whatever else you point at the folder.

The render/parse round-trip is symmetric: `AnalysisPromptBuilder.renderAnalysisMarkdown` ↔ `parseManualResponse`. Edit a memo in Timbre and the `.md` file updates. Edit the `.md` in Obsidian (today, manually re-open the app to re-read; live file-watching is a planned follow-up) and Timbre will reconcile. **Your agents can do the same** — anything that can read a markdown file with task lists and blockquotes can read Timbre's output.

## what's not in v0.1.0 (yet)

- Live `.md` file watching (today: app writes, doesn't yet auto-import external edits — round-trip works on app launch)
- Multi-provider LLM picker in the UI (the `AnalysisProvider` protocol exists in code; only `OpenAIProvider` is surfaced in Settings)
- iCloud / CloudKit sync for shared workspaces (planned — see the v3 spec)
- Recording from the iOS app (macOS only for now)
- A polished Record-screen waveform editor (record + stop + save works; trim/edit lives in decode's edit mode instead)

## requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon recommended (M1/M2/M3/M4) for fast on-device transcription
- Xcode 16+ or Swift 5.9+ command-line tools
- ~150 MB disk for the base WhisperKit model, ~3 GB for large-v3

## build

```bash
git clone https://github.com/apollinej/apolline-production.git
cd apolline-production/Timbre
./build.sh release
open Timbre.app
```

| Command | What it does |
|---------|-------------|
| `./build.sh` | Debug build, creates `Timbre.app` in the project dir |
| `./build.sh release` | Optimized release build |
| `./build.sh install` | Release build + copy to `/Applications` |
| `./build.sh clean` | Remove build artifacts |

Or open `Package.swift` in Xcode and hit ⌘R.

## supported audio formats

`.m4a` `.mp3` `.wav` `.flac` `.aac` `.caf` `.aiff` `.aifc` `.mp4`

## storage layout

```
<storage root>/
├── library/      # Imported audio files (uuid-named .m4a/.wav/...)
├── transcripts/  # Plain text transcript mirrors
├── analyses/     # YYYY-MM-DD_<slug>.md — the canonical analysis files
├── models/       # WhisperKit model cache
└── timbre.store  # SwiftData SQLite database
```

Default root is `~/Desktop/Code/apolline-production/timbre/data/`. Change it in Settings → Storage location.

## tech stack

- **Swift 5.9+** / **SwiftUI** — macOS-native, no Electron, no web view
- **SwiftData** — local persistence (the `.md` files are the canonical store; SwiftData is the cache)
- **[WhisperKit](https://github.com/argmaxinc/WhisperKit)** — CoreML Whisper on the Apple Neural Engine
- **[SpeakerKit](https://github.com/argmaxinc/WhisperKit)** — on-device pyannote speaker diarization
- **AVFoundation** — audio playback + waveform extraction
- **DotGothic16** (Google Fonts, SIL OFL) — the pixelated Y2K display font

Models are downloaded automatically on first use from HuggingFace. No token required.

## try it without setup

Settings (the person bubble bottom-right of Home) → developer → **seed demo data**. Timbre creates 5 example memos covering every UI state — un-analyzed, fresh analysis, partial resolutions, fully completed, and summary-only — so you can poke at Browse and Debrief end-to-end without recording anything or running an LLM. Click **reset all data** when you're done.

## contributing

Issues and pull requests welcome at [github.com/apollinej/apolline-production](https://github.com/apollinej/apolline-production). For bugs include macOS version, the surface you were on (record / decode / browse / debrief), and steps to reproduce.

## license

MIT — see [LICENSE](LICENSE).
