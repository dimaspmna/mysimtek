import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Wraps [child] and shows a non-dismissible bottom sheet whenever the
/// device loses network connectivity. The sheet is removed automatically
/// once connectivity is restored, or when the user taps "Coba Lagi" and
/// the connection has come back.
class NoInternetOverlay extends StatefulWidget {
  final Widget child;
  const NoInternetOverlay({super.key, required this.child});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay> {
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  bool _offline = false;
  bool _sheetVisible = false;

  @override
  void initState() {
    super.initState();
    // Check immediately, then listen for changes
    Connectivity().checkConnectivity().then(_handleResult);
    _sub = Connectivity().onConnectivityChanged.listen(_handleResult);
  }

  void _handleResult(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline == _offline) return;
    setState(() => _offline = offline);
    if (offline) {
      _showSheet();
    } else {
      _dismissSheet();
    }
  }

  void _showSheet() {
    if (_sheetVisible || !mounted) return;
    _sheetVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _NoInternetSheet(onRetry: _onRetry),
      ).then((_) => _sheetVisible = false);
    });
  }

  void _dismissSheet() {
    if (!_sheetVisible || !mounted) return;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  Future<void> _onRetry() async {
    final results = await Connectivity().checkConnectivity();
    _handleResult(results);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NoInternetSheet extends StatefulWidget {
  final Future<void> Function() onRetry;
  const _NoInternetSheet({required this.onRetry});

  @override
  State<_NoInternetSheet> createState() => _NoInternetSheetState();
}

class _NoInternetSheetState extends State<_NoInternetSheet> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFEF4444),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Koneksi Internet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Periksa koneksi Wi-Fi atau data seluler Anda,\nlalu coba lagi.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking
                  ? null
                  : () async {
                      setState(() => _checking = true);
                      await widget.onRetry();
                      if (mounted) setState(() => _checking = false);
                    },
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_checking ? 'Memeriksa...' : 'Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
