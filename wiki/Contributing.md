# Contributing

Contributions are welcome — bug fixes, new features, documentation improvements, and translations.

## Reporting Bugs

Open an issue at [github.com/wasxxm/Whistype/issues](https://github.com/wasxxm/Whistype/issues) with:
- macOS version
- Mac model (chip generation)
- Steps to reproduce
- Expected vs actual behaviour
- Any relevant logs from Console.app

## Suggesting Features

Open an issue with the `enhancement` label. Describe the use case and expected behaviour.

## Submitting Code

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature`
3. Set up the dev environment — see [Building from Source](Building-from-Source)
4. Make your changes
5. Ensure the app builds and runs without errors
6. Commit with a clear message
7. Open a pull request against `main`

## Code Style

- Follow existing patterns — protocol-oriented, coordinator-driven, no logic in views
- Max 450 lines per file — refactor if needed
- Use SF Symbols for icons
- `@AppStorage` for preferences, SwiftData for persistent records
- No third-party dependencies without discussion

## Architecture Notes

See the [Architecture](Architecture) page before making structural changes. All services must conform to the protocol defined in `Domain/Protocols/`.

## License

By contributing you agree that your contributions will be licensed under the MIT License.
