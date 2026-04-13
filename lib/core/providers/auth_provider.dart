import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isCustomer => _user?.role == 'customer';
  bool get isTeknisi => _user?.role == 'teknisi';

  AuthProvider(this._api, this._storage);

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final token = await _storage.getToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      final res = await _api.get(ApiConstants.me);
      final userData = (res is Map && res.containsKey('user'))
          ? res['user'] as Map<String, dynamic>
          : res as Map<String, dynamic>;
      _user = UserModel.fromJson(userData);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _storage.clearAll();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post(ApiConstants.login, {
        'email': email,
        'password': password,
      }, auth: false);
      final token = res['token']?.toString() ?? '';
      final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      final role = user.role.toLowerCase().trim();
      if (role != 'customer' && role != 'teknisi') {
        _error =
            'Akun ini tidak memiliki akses ke aplikasi. '
            'Hubungi administrator jika ini adalah kesalahan.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      await _storage.saveToken(token);
      _user = user;
      await _storage.saveRole(role);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan tidak terduga. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout, {});
    } catch (_) {}
    await _storage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
