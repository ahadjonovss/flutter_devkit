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

/// Saves and opens scenario files for the scenarios page, so QA can share
/// scenarios as `.json` files.
///
/// DevKit ships no file plugin of its own. Implement this with the plugin of
/// your choice (the README shows one built on `file_picker`) and pass it to
/// `DevKit.init`; without it the page copies and pastes JSON instead.
abstract interface class ScenarioFiles {
  /// Saves [json] as a file named [fileName]. Returns false when the user
  /// cancelled.
  Future<bool> save(String fileName, String json);

  /// Lets the user pick a file and returns its text, or null when cancelled.
  Future<String?> pick();
}
