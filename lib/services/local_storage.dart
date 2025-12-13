import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveUser(String token, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('name', name);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> setResetDone(String monthYear) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_reset', monthYear);
  }

  static Future<String?> getLastReset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_reset');
  }
}
