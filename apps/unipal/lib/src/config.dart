/// API base URL, set per build: `flutter run --dart-define=UNIPAL_API_URL=http://localhost:8000`.
/// Release builds for staging pass https://staging-api.unipal.group.
const apiUrl = String.fromEnvironment('UNIPAL_API_URL', defaultValue: 'https://api.unipal.group');
