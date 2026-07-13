import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';

class OtaAccessProvider extends ChangeNotifier {
  final ApiService _api;

  bool _loading = false;
  String? _error;
  String? _customerName;
  String? _customerPhone;

  bool get loading => _loading;
  String? get error => _error;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  bool get isRegistered => _customerName != null;

  static final Map<String, List<DateTime>> _checkPhoneLog = {};

  OtaAccessProvider(this._api);

  static String? _checkThrottle(String phone) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));
    final history = _checkPhoneLog[phone] ?? [];
    _checkPhoneLog[phone] = history.where((t) => t.isAfter(cutoff)).toList();

    if (_checkPhoneLog[phone]!.length >= 5) {
      return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
    }
    return null;
  }

  static void _recordCheckPhone(String phone) {
    _checkPhoneLog.putIfAbsent(phone, () => []).add(DateTime.now());
  }

  Future<String?> checkPhone(String phone) async {
    final throttleMsg = _checkThrottle(phone);
    if (throttleMsg != null) {
      _error = throttleMsg;
      notifyListeners();
      return throttleMsg;
    }

    _loading = true;
    _error = null;
    _customerName = null;
    _customerPhone = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.requestAccess,
        {'phone': phone},
        auth: false,
      );
      _recordCheckPhone(phone);
      if (res is Map && res['status'] == 'success') {
        final data = res['data'];
        _customerName = data?['name']?.toString() ?? '';
        _customerPhone = data?['phone']?.toString() ?? phone;
        _loading = false;
        notifyListeners();
        return null;
      }
      final msg = res is Map
          ? (res['message']?.toString() ?? 'Nomor tidak terdaftar.')
          : 'Nomor tidak terdaftar.';
      _error = msg;
      return msg;
    } on ApiException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      _error = 'Terjadi kesalahan jaringan. Coba lagi.';
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void reset() {
    _loading = false;
    _error = null;
    _customerName = null;
    _customerPhone = null;
    notifyListeners();
  }
}
