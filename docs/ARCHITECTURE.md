# Architecture Document

## 1. Directory Structure
We use a feature-first architecture, separating logic by feature domains and separating concerns into presentation, domain, and data layers.

```text
lib/
├── core/             # Application-wide core configurations (routing, theme, di, errors)
├── data/             # Global data layer (database setup, remote services, global models)
├── domain/           # Global domain layer (entities, use cases)
├── features/         # Feature modules
│   ├── dashboard/
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── domain/
│   │   └── data/
│   └── ...
├── shared/           # Shared UI widgets, components, and dialogs
└── l10n/             # Localization files
```

## 2. State Management
**Tool**: `flutter_riverpod`
**Reasoning**:
- Riverpod allows for safe, compile-time checked dependency injection and state management.
- It provides a robust way to handle asynchronous data streams, which is vital for our reactive local database requirements (SQLite/Drift).
- It scales well for large applications and does not mix business logic with UI heavily.

## 3. Dependency Injection
**Tool**: `get_it` and `flutter_riverpod`
- `get_it` is used to register singletons for services that are completely decoupled from the UI lifecycle (e.g., the Database instance, SharedPreferences).
- `flutter_riverpod` `Provider`s are used to inject repositories and use cases into the presentation layer.

## 4. Routing
**Tool**: `go_router`
- Standard declarative routing solution endorsed by Flutter.

## 5. Localization
**Tool**: `flutter_localizations` with `gen-l10n`
- The `l10n.yaml` generates `AppLocalizations` directly in `lib/l10n` to prevent IDE missing-reference errors.

## 6. Theme
- Centralized `AppTheme` class providing `lightTheme` and `darkTheme` leveraging `Material 3` and `ColorScheme.fromSeed`.
