# FreeWhisper — Project Instructions

## Overview
FreeWhisper is a native macOS menu bar speech-to-text app. It uses WhisperKit (CoreML) for on-device transcription on Apple Silicon. The app has a unique floating capsule UI that appears at the bottom-center of the screen during recording. Option+Space is the global hotkey.

## Tech Stack
- Swift 5.9+ / SwiftUI / AppKit hybrid
- macOS 14.0+ (Sonoma)
- WhisperKit (SPM) for speech recognition
- HotKey (SPM) for global keyboard shortcuts
- AVAudioEngine for microphone capture
- SwiftData for transcription history
- Non-sandboxed (Developer ID distribution)

## Architecture
- Protocol-oriented services with dependency injection
- Clean separation: Domain → Services → Coordination → Views
- TranscriptionCoordinator owns the state machine (idle → recording → transcribing → done)
- All views are driven by TranscriptionState enum
- Max 450 lines per file

## Build
- Open the .xcodeproj in Xcode 16+
- SPM dependencies resolve automatically
- Build target: macOS 14.0+
- No sandbox entitlement (required for CGEvent paste)

## Key Directories
- Sources/FreeWhisper/App/ — entry point, app delegate, DI container
- Sources/FreeWhisper/Domain/ — state enum, service protocols
- Sources/FreeWhisper/Services/ — concrete service implementations
- Sources/FreeWhisper/Coordination/ — TranscriptionCoordinator
- Sources/FreeWhisper/Views/ — all SwiftUI views organized by feature

## Conventions
- Use protocols for all services (testability)
- Coordinator pattern for orchestration (no business logic in views)
- @AppStorage for user preferences
- SwiftData for transcription history
- SF Symbols for all icons
- English-only for v1
