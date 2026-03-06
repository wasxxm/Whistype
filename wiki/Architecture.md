# Architecture

Whistype follows a protocol-oriented, layered architecture with clean separation between domain, services, coordination, and views.

## Layer Overview

```
Views          FloatingCapsuleView, MenuBarView, SettingsView, HistoryView, OnboardingView
    ↓
Coordination   TranscriptionCoordinator  (state machine, orchestration)
    ↓
Services       AudioRecorderService, WhisperTranscriptionService,
               Qwen3TranscriptionService, ParakeetTranscriptionService,
               HotkeyService, PasteService, PermissionsManager
    ↓
Domain         Protocols, TranscriptionState, TranscriptionError
```

## State Machine

`TranscriptionCoordinator` drives all state via `TranscriptionState`:

```
idle → recording → transcribing → done → idle
                               ↘ error → idle
```

All views observe `TranscriptionState` and render accordingly. No business logic lives in views.

## Dependency Injection

`DependencyContainer` wires all services at startup and is passed down through the view hierarchy. It hot-swaps the active transcription service when the user changes the engine preference in Settings.

## Key Files

| File | Purpose |
|------|---------|
| `App/WhistypeApp.swift` | Entry point, menu bar setup |
| `App/DependencyContainer.swift` | DI wiring |
| `Coordination/TranscriptionCoordinator.swift` | State machine |
| `Domain/TranscriptionState.swift` | State enum |
| `Domain/Protocols/` | Service contracts |
| `Services/AudioRecorderService.swift` | AVAudioEngine capture |
| `Services/WhisperTranscriptionService.swift` | WhisperKit engine |
| `Services/Qwen3TranscriptionService.swift` | Qwen3-ASR engine |
| `Services/ParakeetTranscriptionService.swift` | ParakeetASR engine |
| `Services/PasteService.swift` | AppleScript paste |
| `Views/Capsule/` | Floating capsule UI |
| `Utilities/Constants.swift` | App-wide constants |

## Conventions

- All services are behind protocols for testability
- `@AppStorage` for user preferences
- SwiftData for transcription history (`Models/TranscriptionRecord.swift`)
- SF Symbols for all icons
- Max 450 lines per file
