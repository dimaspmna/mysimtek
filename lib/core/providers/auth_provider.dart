import 'dart:async';

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
  String? _loadingMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  String? get loadingMessage => _loadingMessage;
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

  Future<Map<String, dynamic>> _prepareLoginPayload() async {
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

    if (fcmToken == null) {
      try {
        fcmToken = await FcmService.waitForToken(
          timeout: const Duration(seconds: 10),
        );
        debugPrint('[Auth] FCM token received from refresh event: $fcmToken');
      } catch (e) {
        debugPrint('[Auth] FCM token refresh fallback failed: $e');
      }
    }

    return {
      'device_name': 'Mobile_App',
      if (fcmToken != null) 'fcm_token': fcmToken,
    };
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    _loadingMessage = 'Sedang memeriksa data Anda…';
    notifyListeners();
    try {
      final loginPayload = await _prepareLoginPayload();
      final loginBody = {'email': email, 'password': password, ...loginPayload};

      for (int i = 0; i < ApiConstants.ispList.length; i++) {
        final isp = ApiConstants.ispList[i];
        ApiConstants.baseUrl = isp['baseUrl']!;
        try {
          final res = await _api.post(
            ApiConstants.login,
            loginBody,
            auth: false,
          );
          final token = res['token']?.toString() ?? '';
          final user = UserModel.fromJson(
            res['user'] as Map<String, dynamic>,
          );
          final role = user.role.toLowerCase().trim();
          if (role != 'customer') {
            _error =
                'Akun ini tidak memiliki akses ke aplikasi. '
                'Hubungi administrator jika ini adalah kesalahan.';
            _status = AuthStatus.unauthenticated;
            _loadingMessage = null;
            notifyListeners();
            return false;
          }
          await _storage.saveToken(token);
          await _storage.saveIspId(isp['id']!);
          _user = user;
          await _storage.saveRole(role);
          _status = AuthStatus.authenticated;
          _loadingMessage = null;
          notifyListeners();

          try {
            await FcmService.syncToken();
          } catch (e) {
            debugPrint('[Auth] FCM token sync failed after login: $e');
          }
          return true;
        } on ApiException catch (e) {
          if (i < ApiConstants.ispList.length - 1) {
            _loadingMessage = 'Mencoba server lain…';
            notifyListeners();
            continue;
          }
          _error = e.message;
        }
      }

      _status = AuthStatus.unauthenticated;
      _loadingMessage = null;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan tidak terduga. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      _loadingMessage = null;
      notifyListeners();
      return false;
    }
  }

  static final Map<String, List<DateTime>> _otpRequestLog = {};

  static String? _checkOtpThrottle(String phone) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));
    final history = _otpRequestLog[phone] ?? [];
    _otpRequestLog[phone] = history.where((t) => t.isAfter(cutoff)).toList();

    if (_otpRequestLog[phone]!.length >= 5) {
      return 'Terlalu banyak permintaan OTP. Silakan coba lagi nanti.';
    }
    return null;
  }

  static void _recordOtpRequest(String phone) {
    _otpRequestLog.putIfAbsent(phone, () => []).add(DateTime.now());
  }

  Future<String?> requestOtp(String phone) async {
    final throttleMsg = _checkOtpThrottle(phone);
    if (throttleMsg != null) {
      _error = throttleMsg;
      notifyListeners();
      return throttleMsg;
    }

    _status = AuthStatus.loading;
    _error = null;
    _loadingMessage = 'Mengirim kode OTP…';
    notifyListeners();
    try {
      final payload = await _prepareLoginPayload();
      final body = {'phone': phone, ...payload};

      for (int i = 0; i < ApiConstants.ispList.length; i++) {
        final isp = ApiConstants.ispList[i];
        ApiConstants.baseUrl = isp['baseUrl']!;
        try {
          await _api.post(ApiConstants.otpRequest, body, auth: false);
          await _storage.saveIspId(isp['id']!);
          _recordOtpRequest(phone);
          _status = AuthStatus.unauthenticated;
          _loadingMessage = null;
          notifyListeners();
          return null;
        } on ApiException catch (e) {
          if (i < ApiConstants.ispList.length - 1) {
            _loadingMessage = 'Mencoba server lain…';
            notifyListeners();
            continue;
          }
          _error = e.message;
        }
      }

      _status = AuthStatus.unauthenticated;
      _loadingMessage = null;
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Terjadi kesalahan tidak terduga. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      _loadingMessage = null;
      notifyListeners();
      return _error;
    }
  }

  Future<bool> loginWithOtp(String phone, String otpCode) async {
    _status = AuthStatus.loading;
    _error = null;
    _loadingMessage = 'Memverifikasi kode OTP…';
    notifyListeners();
    try {
      final payload = await _prepareLoginPayload();
      final body = {'phone': phone, 'otp_code': otpCode, ...payload};

      for (int i = 0; i < ApiConstants.ispList.length; i++) {
        final isp = ApiConstants.ispList[i];
        ApiConstants.baseUrl = isp['baseUrl']!;
        try {
          final res = await _api.post(
            ApiConstants.otpVerify,
            body,
            auth: false,
          );
          final token = res['token']?.toString() ?? '';
          final user = UserModel.fromJson(
            res['user'] as Map<String, dynamic>,
          );
          final role = user.role.toLowerCase().trim();
          if (role != 'customer') {
            _error =
                'Akun ini tidak memiliki akses ke aplikasi. '
                'Hubungi administrator jika ini adalah kesalahan.';
            _status = AuthStatus.unauthenticated;
            _loadingMessage = null;
            notifyListeners();
            return false;
          }
          await _storage.saveToken(token);
          await _storage.saveIspId(isp['id']!);
          _user = user;
          await _storage.saveRole(role);
          _status = AuthStatus.authenticated;
          _loadingMessage = null;
          notifyListeners();

          try {
            await FcmService.syncToken();
          } catch (e) {
            debugPrint('[Auth] FCM token sync failed after OTP login: $e');
          }
          return true;
        } on ApiException catch (e) {
          if (i < ApiConstants.ispList.length - 1) {
            _loadingMessage = 'Mencoba server lain…';
            notifyListeners();
            continue;
          }
          _error = e.message;
        }
      }

      _status = AuthStatus.unauthenticated;
      _loadingMessage = null;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan tidak terduga. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      _loadingMessage = null;
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
    _error = null;
    _loadingMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
