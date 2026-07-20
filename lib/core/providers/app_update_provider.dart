import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/api_constants.dart';
import '../models/app_update.dart';
import '../services/api_service.dart';
import '../utils/version_utils.dart';

enum AppUpdateState { initial, loading, needsUpdate, upToDate, error }

class AppUpdateProvider extends ChangeNotifier {
  final ApiService _api;

  AppUpdateState _state = AppUpdateState.initial;
  AppUpdate? _update;
  String? _error;
  String _currentVersion = '';

  AppUpdateState get state => _state;
  AppUpdate? get update => _update;
  String? get error => _error;
  String get currentVersion => _currentVersion;

  AppUpdateProvider(this._api);

  Future<void> check() async {
    _state = AppUpdateState.loading;
    _error = null;

    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;

      final res = await _api.get(ApiConstants.appUpdate, auth: false);
      _update = AppUpdate.fromJson(res as Map<String, dynamic>);

      if (_update!.appVersionNew.isEmpty ||
          _update!.appUpdateUrl.isEmpty) {
        _state = AppUpdateState.upToDate;
      } else if (VersionUtils.isOlder(_currentVersion, _update!.appVersionNew)) {
        _state = AppUpdateState.needsUpdate;
      } else {
        _state = AppUpdateState.upToDate;
      }
    } catch (e) {
      _error = e.toString();
      _state = AppUpdateState.error;
      debugPrint('AppUpdateProvider error: $e');
    }

    notifyListeners();
  }
}
