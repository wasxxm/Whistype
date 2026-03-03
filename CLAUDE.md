# Whistype — Project Instructions

## Overview
Whistype is a native macOS menu bar speech-to-text app for Apple Silicon. It supports two on-device transcription engines: WhisperKit (CoreML) and Qwen3-ASR (MLX). A floating capsule UI appears at the bottom-center of the screen during recording. Option+Space is the global hotkey.

## Tech Stack
- Swift 5.9+ / SwiftUI / AppKit hybrid
- macOS 14.0+ (Sonoma)
- WhisperKit (SPM, from 0.16.0) — CoreML-based transcription
- Qwen3-ASR (SPM, pinned commit) — MLX-based transcription (second engine)
- HotKey (SPM, from 0.2.1) — global keyboard shortcuts
- AVAudioEngine for microphone capture (16kHz mono Float32)
- SwiftData for transcription history
- XcodeGen (project.yml) to generate .xcodeproj — no Package.swift
- Non-sandboxed, Hardened Runtime with audio-input and apple-events entitlements

## Architecture
- Protocol-oriented services with dependency injection (DependencyContainer)
- Clean separation: Domain → Services → Coordination → Views
- TranscriptionCoordinator owns the state machine: idle → recording → transcribing → done / error
- All views are driven by TranscriptionState enum (5 cases: idle, recording, transcribing, done, error)
- DependencyContainer hot-swaps the active transcription service when user changes engine preference
- Max 450 lines per file

## Build
- Run `xcodegen generate` if project.yml changes
- Open the .xcodeproj in Xcode 16+
- SPM dependencies resolve automatically
- Build target: macOS 14.0+
- Entitlements: audio-input, apple-events (required for AppleScript paste)

## Key Directories
- Sources/Whistype/App/ — entry point (WhistypeApp), app delegate, DI container
- Sources/Whistype/Domain/ — TranscriptionState enum, TranscriptionError
- Sources/Whistype/Domain/Protocols/ — service protocols (AudioRecording, Transcription, HotkeyBinding, PermissionsChecking, OutputPasting)
- Sources/Whistype/Services/ — concrete implementations (AudioRecorderService, WhisperTranscriptionService, Qwen3TranscriptionService, HotkeyService, PasteService, PermissionsManager)
- Sources/Whistype/Coordination/ — TranscriptionCoordinator (state machine, hotkey wiring, SwiftData saving)
- Sources/Whistype/Models/ — SwiftData models (TranscriptionRecord)
- Sources/Whistype/Utilities/ — Constants (app name, defaults keys, UI layout values, audio config)
- Sources/Whistype/Views/Capsule/ — floating capsule UI, window controller, audio level indicator
- Sources/Whistype/Views/MenuBar/ — menu bar view and icon
- Sources/Whistype/Views/Settings/ — settings tabs (General, About)
- Sources/Whistype/Views/History/ — transcription history list
- Sources/Whistype/Views/Onboarding/ — 4-step onboarding flow (welcome, mic, accessibility, hotkey)
- Sources/Whistype/Views/Common/ — reusable components (KeyCapView)
- Resources/ — Assets.xcassets (AppIcon, MenuBarIcon)

## Conventions
- Use protocols for all services (testability)
- Coordinator pattern for orchestration (no business logic in views)
- @AppStorage for user preferences
- SwiftData for transcription history
- SF Symbols for all icons
- English-only for v1
- PasteService uses AppleScript for paste, falls back to clipboard-only without accessibility
