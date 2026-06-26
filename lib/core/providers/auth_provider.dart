import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
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
      // Sync FCM token now that the user is authenticated
      try {
        await FcmService.syncToken();
      } catch (e) {
        debugPrint('[Auth] FCM token sync failed on checkAuth: $e');
        // Don't fail auth check if FCM sync fails
      }
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
      // Request notification permission first (Android 13+)
      await FcmService.requestPermission();

      // Get FCM token with retries (token may not be immediately available after permission grant)
      String? fcmToken;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          fcmToken = await FcmService.getToken();
        } catch (e) {
          debugPrint('[Auth] Attempt $attempt: Cannot fetch FCM token: $e');
        }
        if (fcmToken != null) break;
        debugPrint('[Auth] Attempt $attempt: FCM token is null, retrying...');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2 * attempt));
        }
      }

      final loginBody = {
        'email': email,
        'password': password,
        'device_name': 'Mobile_App',
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
      final res = await _api.post(ApiConstants.login, loginBody, auth: false);
      final token = res['token']?.toString() ?? '';
      final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      final role = user.role.toLowerCase().trim();
      if (role != 'customer') {
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
      // Sync FCM token after successful login
      try {
        await FcmService.syncToken();
      } catch (e) {
        debugPrint('[Auth] FCM token sync failed after login: $e');
        // Don't fail login if FCM sync fails, but log the error
      }
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
      // Clear FCM token on server before revoking session, then delete locally.
      await FcmService.clearToken();
      await _api.post(ApiConstants.logout, {});
    } catch (_) {}
    await _storage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
