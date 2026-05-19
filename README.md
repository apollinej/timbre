# timbre

Local voice memo transcription with speaker diarization. Transcription runs fully on-device — no cloud, no accounts, no subscriptions. Optional GPT-4o analysis is opt-in and uses your own OpenAI key (stored in macOS Keychain).

Drop in a voice recording (or record one directly) and get a clean, speaker-attributed transcript. Transcription uses [WhisperKit](https://github.com/argmaxinc/WhisperKit) (CoreML Whisper on Apple Neural Engine) and [SpeakerKit](https://github.com/argmaxinc/WhisperKit) (on-device pyannote diarization).

## Status

**v0.1.0** — pre-1.0 while features stabilize.

| Surface | State |
|---|---|
| Import + transcribe + diarize | stable |
| Record directly in-app | restored in 0.1.0 — please report bugs |
| Browse (filter / search / calendar / cards) | restored in 0.1.0 — please report bugs |
| Threads (open conversations) | stable |
| Settings (transcription model, storage) | stable |
| Analysis (GPT-4o decode) | requires your own OpenAI key |

## Features

- **Record in-app** — capture audio directly without leaving timbre
- **Speaker diarization** — automatically identifies and labels different speakers
- **Click-to-seek** — click any transcript segment or the waveform to jump to that point
- **Live highlight** — current segment highlights as audio plays
- **Speaker rename** — rename "Speaker 1" to actual names, applied globally
- **Browse** — search, filter by person/time, card / list / calendar views
- **Copy transcript** — one click to copy the full transcript to clipboard
- **Folder organization** — create folders, rename files, drag to organize
- **Export** — Markdown, plain text, SRT subtitles, JSON
- **Multiple models** — tiny, base, small, large-v3 (auto-downloaded on first use)
- **Local-first** — transcription never leaves your device; analysis is opt-in

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon recommended (M1/M2/M3/M4) for fast transcription
- Xcode 16+ or Swift 5.9+ command line tools
- ~150MB disk for the base model, ~3GB for large-v3

## Build

```bash
git clone https://github.com/apollinej/apolline-production.git
cd apolline-production/Timbre
./build.sh
open Timbre.app
```

Or for a release build installed to /Applications:

```bash
./build.sh install
```

### Build options

| Command | What it does |
|---------|-------------|
| `./build.sh` | Debug build, creates Timbre.app in project dir |
| `./build.sh release` | Optimized release build |
| `./build.sh install` | Release build + copy to /Applications |
| `./build.sh clean` | Remove build artifacts |

### Open in Xcode

```bash
open Package.swift
```

Then select the `Timbre` scheme and hit ⌘R.

## Supported formats

`.m4a` `.mp3` `.wav` `.flac` `.aac` `.caf` `.aiff` `.aac` `.m4p` `.aifc` `.mp4`

## How it works

1. Import a voice memo (drag-and-drop or file picker)
2. Click "start transcription" — WhisperKit transcribes on the Neural Engine
3. SpeakerKit runs pyannote diarization to identify speakers
4. Segments are merged by speaker into readable blocks
5. Transcript is saved locally and mirrored as a .txt file

Models are downloaded automatically on first use from HuggingFace. No token required — the community pyannote model (CC-BY-4.0) is used by default.

## Storage

By default, files are stored in `~/Documents/Timbre/`. You can change this in Settings.

```
~/Documents/Timbre/
├── library/        # Imported audio files
├── transcripts/    # Plain text transcript mirrors
├── models/         # WhisperKit model cache
└── timbre.store    # SwiftData database
```

## Tech stack

- **Swift 5.9+** / **SwiftUI** (macOS native, no Electron)
- **WhisperKit** — CoreML Whisper on Apple Neural Engine
- **SpeakerKit** — on-device pyannote speaker diarization
- **SwiftData** — local persistence
- **AVFoundation** — audio playback and waveform extraction

## Contributing

Issues and pull requests welcome at [github.com/apollinej/apolline-production](https://github.com/apollinej/apolline-production). For bugs, please include macOS version, the surface you were on (record / browse / etc.), and steps to reproduce.

## License

MIT — see [LICENSE](LICENSE).
