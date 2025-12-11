# Repository Guidelines

## Project Structure & Module Organization
- `MyDemo/App` hosts the SwiftUI entry point and shared app configuration.
- `MyDemo/Demo` contains feature demos; each subfolder (e.g., `Expense Tracker`, `Movable Cards with CoreData`) bundles its view, view model, and supporting models following MVVM.
- `MyDemo/Resources` stores assets such as `Assets.xcassets`.
- `MyDemo/Sample` gathers exploratory code and developer notes; keep production-ready samples under `Demo`.

## Build, Test, and Development Commands
- `open MyDemo.xcodeproj` launches Xcode with the configured schemes.
- `xcodebuild -project MyDemo.xcodeproj -scheme MyDemo -destination 'platform=iOS Simulator,name=iPhone 15' build` performs a command-line build; use before committing to catch compile issues.
- `xcodebuild -project MyDemo.xcodeproj -scheme MyDemo test` executes the test suite. If tests rely on previews, set `-destination 'platform=iOS Simulator,name=iPhone 15'`.
- `swift run --package-path Sample` is reserved for ad-hoc prototypes inside `Sample`.

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines: types in `UpperCamelCase`, properties and functions in `lowerCamelCase`.
- Prefer 4-space indentation; keep SwiftUI modifiers vertically aligned for readability.
- Organize views with extensions for preview providers and modifiers. State and bindings should live in `ViewModel` structs or classes under `Demo/...`.
- When adding dependencies, update `Resources/` and reference them through `Asset` names to avoid hard-coded strings.

## Testing Guidelines
- Tests live under future `MyDemoTests` targets; name files `<FeatureName>Tests.swift`.
- Use `XCTest` with descriptive methods like `testExpenseSummaryFiltersTransactions()`.
- Aim for coverage on view-model logic, data formatting, and any persistence layer under Core Data demos.
- Document manual exploratory steps for UI-heavy demos in `Sample/Doc`.

## Commit & Pull Request Guidelines
- Mirror existing history: use prefixes such as `feat:`, `fix:`, or `chore:` followed by a concise summary (e.g., `feat: Add WaterfallGrid animation polish`).
- Keep commits scoped to one demo or subsystem. Include build verification notes in the commit body when using `xcodebuild`.
- Pull requests should reference related issues, list impacted demos, attach simulator screenshots or screen recordings, and call out any schema or asset updates.

## Agent-Specific Instructions
- Before coding, log architectural decisions in `.claude/context/current_task.md`.
- Track progress in `.claude/progress/YYYY-MM-DD_progress.md` so teammates can resume incomplete demos.
- Record non-trivial refactors or new patterns in `.claude/analysis/` to maintain continuity across agents.
