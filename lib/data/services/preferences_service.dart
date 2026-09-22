import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyHasCompletedOnboarding = 'hasCompletedOnboarding';
  static const String _keyDefaultCurrency = 'defaultCurrency';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  bool getHasCompletedOnboarding() {
    return _prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    await _prefs.setBool(_keyHasCompletedOnboarding, value);
  }

  String getDefaultCurrency() {
    return _prefs.getString(_keyDefaultCurrency) ?? 'TND';
  }

  Future<void> setDefaultCurrency(String currency) async {
    await _prefs.setString(_keyDefaultCurrency, currency);
  }
}
