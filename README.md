# Timbre

Native macOS app that converts voice recordings into clean, speaker-attributed transcripts. Fully local — no cloud, no API keys, no subscriptions.

## Features

- **Import** — Drag and drop audio files (.m4a, .wav, .mp3, .flac, .aac, .caf, .aiff) or browse your Voice Memos directly
- **Transcribe** — On-device transcription powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit) running on Apple's Neural Engine
- **Speaker Diarization** — Automatic speaker identification via [SpeakerKit](https://www.argmaxinc.com/blog/speakerkit) with pyannote CoreML models
- **Edit** — Color-coded speaker labels with inline renaming
- **Playback** — Click any segment to jump to that timestamp; synced waveform visualization
- **Export** — Markdown, plain text, SRT subtitles, or JSON

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1 or later recommended)
- Xcode 15+ to build from source

## Build

```bash
# Clone the repo
git clone https://github.com/apollinej/apolline-production.git
cd apolline-production/Timbre

# Open in Xcode (pick scheme "Timbre" in the toolbar, then Run ▶)
open Package.swift

# Or double-click `open-in-xcode.command` in Finder

# Command line
swift run
swift test

# Xcode command-line build (from this Timbre folder)
xcodebuild -scheme Timbre -destination 'platform=macOS' build
```

### Xcode tips

1. Open **`Package.swift`** (not the parent folder only)—Xcode loads the Swift package.
2. Wait for **Resolve Package Dependencies** to finish (WhisperKit pulls sub-dependencies).
3. Scheme **Timbre** should appear automatically; if not: **Product → Scheme → Timbre**.
4. **Run** builds the `Timbre` executable and launches the window.

## Where your data lives

All memos, transcripts, speaker renames, and folders are stored under **your Desktop**:

| What | Location |
|------|----------|
| **SwiftData database** (metadata + full transcript text + speaker names) | `~/Desktop/apolline-production/timbre/timbre.store` |
| **Imported audio files** (copies) | `~/Desktop/apolline-production/timbre/library/` |
| **Whisper ML models** (download cache) | `~/Library/Application Support/Timbre/Models/` |

On first launch, Timbre creates `~/Desktop/apolline-production/timbre/` and `library/` if needed. Imports **copy** the audio into `library/` so your library is self-contained on the Desktop.

**Note:** If you later wrap Timbre in a **sandboxed** Mac app, writing to the Desktop may require extra entitlements or a user-chosen folder—this setup targets the default non-sandboxed Swift package run from Xcode / `swift run`.

## Models

Timbre downloads transcription models on first use. Available models:

| Model | Size | Notes |
|-------|------|-------|
| tiny.en | ~75 MB | Fastest, English only |
| base.en | ~150 MB | Good balance (default) |
| small.en | ~500 MB | Higher accuracy, English only |
| large-v3 | ~3 GB | Best accuracy, multilingual. 16GB+ RAM recommended |

Models are cached in `~/Library/Application Support/Timbre/Models/`.

## Architecture

- **SwiftUI** with NavigationSplitView
- **SwiftData** for local persistence
- **WhisperKit** + **SpeakerKit** for on-device ML
- **AVFoundation** for audio playback
- **MVVM** with @Observable (Swift Observation framework)

## License

MIT
