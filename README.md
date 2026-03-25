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

# Open in Xcode
open Package.swift

# Or build from command line
xcodebuild -scheme Timbre -destination 'platform=macOS' build
```

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
