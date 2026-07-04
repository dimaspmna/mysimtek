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

  OtaAccessProvider(this._api);

  Future<String?> checkPhone(String phone) async {
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
