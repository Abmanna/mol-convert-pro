# MolConvert Pro

A refined, production-optimized, and fully documented solution for chemical solution preparation.

## Structure

- `flutter_app/`: The cross-platform mobile/desktop application built with Flutter.
- `web_app/`: The web application built with Next.js.
- `assets/`: Shared assets including the universal substance database.

## Features

- **Clean Architecture**: Separation of concerns (Data, Domain, Presentation).
- **Type Safety**: Strong typing in both Dart and TypeScript.
- **Performance**: Optimized calculations and state management.
- **Accessibility**: High contrast modes and screen reader support.
- **Universal Database**: `substances.json` acts as a single source of truth.

## Setup

### Flutter App
1. Navigate to `flutter_app/`.
2. Run `flutter pub get`.
3. Run `flutter run`.

### Web App
1. Navigate to `web_app/`.
2. Run `npm install`.
3. Run `npm run dev`.

## Testing

- **Flutter**: Run `flutter test` in the `flutter_app` directory.
- **Web**: Run `npm test` (if configured) in the `web_app` directory.

## License
MIT
