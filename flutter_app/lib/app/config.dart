/// Base URL for the FastAPI backend. Override at build/run time with
/// `--dart-define=API_BASE=http://host:port`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:8000',
);
