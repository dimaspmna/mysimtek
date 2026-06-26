import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/customer_dashboard_model.dart';

enum LoadState { initial, loading, loaded, error }

class CustomerDashboardProvider extends ChangeNotifier {
  final ApiService _api;

  LoadState _state = LoadState.initial;
  CustomerDashboard? _dashboard;
  String? _error;
  Timer? _pollingTimer;

  LoadState get state => _state;
  CustomerDashboard? get dashboard => _dashboard;
  String? get error => _error;

  CustomerDashboardProvider(this._api);

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.customerDashboard);
      _dashboard = CustomerDashboard.fromJson(res as Map<String, dynamic>);
      _state = LoadState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    } catch (e, st) {
      debugPrint('DashboardProvider error: $e\n$st');
      _error = 'Terjadi kesalahan saat memuat data.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => _silentRefresh());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _silentRefresh() async {
    try {
      final res = await _api.get(ApiConstants.customerDashboard);
      _dashboard = CustomerDashboard.fromJson(res as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      // abaikan error saat polling background
    }
  }
}
