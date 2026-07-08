import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _ispIdKey = 'isp_id';

  Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  Future<void> saveRole(String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_roleKey, role);
  }

  Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_roleKey);
  }

  Future<void> saveIspId(String ispId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_ispIdKey, ispId);
  }

  Future<String?> getIspId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_ispIdKey);
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
