import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central access to env values. Safe defaults so the app runs
/// even if `.env` is missing (e.g. CI / fresh clone).
class AppEnv {
  const AppEnv._();

  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'https://api.roadmate.lk';

  static String get apiKey => dotenv.maybeGet('API_KEY') ?? '';

  static String get googleMapsApiKey =>
      dotenv.maybeGet('GOOGLE_MAPS_API_KEY') ?? '';

  static String get envName => dotenv.maybeGet('ENV_NAME') ?? 'dev';

  static bool get isDev => envName == 'dev';
}
