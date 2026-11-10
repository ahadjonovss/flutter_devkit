import 'package:shared_preferences/shared_preferences.dart';

/// Where scenarios added at runtime are kept between app launches.
abstract interface class ScenarioStorage {
  /// The saved JSON, or null when nothing was saved yet.
  Future<String?> read();

  /// Replaces the saved JSON with [json].
  Future<void> write(String json);
}

/// Keeps scenarios in `SharedPreferences` under [key]. The default storage.
class SharedPreferencesScenarioStorage implements ScenarioStorage {
  /// Creates a storage using [key].
  const SharedPreferencesScenarioStorage({this.key = 'flutter_devkit.custom_scenarios'});

  /// Preferences key the JSON is stored under.
  final String key;

  @override
  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String json) async => (await SharedPreferences.getInstance()).setString(key, json);
}
