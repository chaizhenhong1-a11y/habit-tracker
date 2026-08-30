import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStore {
  static const _usernameKey = 'registered_username';
  static const _passwordKey = 'registered_password';

  Future<bool> verifyCredentials({
    required String username,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_usernameKey) == username &&
        preferences.getString(_passwordKey) == password;
  }

  Future<bool> usernameExists(String username) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_usernameKey) == username;
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_usernameKey, username);
    await preferences.setString(_passwordKey, password);
  }
}
