import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  final _connectionRestoredController = StreamController<void>.broadcast();
  Stream<void> get onConnectionRestored =>
      _connectionRestoredController.stream;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    Connectivity().checkConnectivity().then(_handleResult);
    _sub = Connectivity().onConnectivityChanged.listen(_handleResult);
  }

  void _handleResult(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline == _isOffline) return;
    final wasOffline = _isOffline;
    _isOffline = offline;
    notifyListeners();
    if (wasOffline && !offline) {
      _connectionRestoredController.add(null);
    }
  }

  Future<void> check() async {
    final results = await Connectivity().checkConnectivity();
    _handleResult(results);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connectionRestoredController.close();
    super.dispose();
  }
}
