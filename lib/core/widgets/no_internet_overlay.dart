import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class NoInternetOverlay extends StatefulWidget {
  final Widget child;
  const NoInternetOverlay({super.key, required this.child});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay> {
  bool _wasOffline = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cp = context.read<ConnectivityProvider>();
      cp.addListener(_onConnectivityChanged);
      _wasOffline = cp.isOffline;
      if (cp.isOffline) _showOfflineSnackbar();
    });
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    final cp = context.read<ConnectivityProvider>();
    if (cp.isOffline == _wasOffline) return;
    _wasOffline = cp.isOffline;

    if (cp.isOffline) {
      _showOfflineSnackbar();
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showConnectedSnackbar();
      setState(() => _checking = false);
    }
  }

  void _showOfflineSnackbar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tidak ada koneksi internet',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: _checking ? null : _retry,
              child: _checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  void _showConnectedSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Koneksi internet tersambung kembali'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    await context.read<ConnectivityProvider>().check();
    if (!mounted) return;
    final stillOffline = context.read<ConnectivityProvider>().isOffline;
    if (stillOffline) {
      setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    if (mounted) {
      try {
        context
            .read<ConnectivityProvider>()
            .removeListener(_onConnectivityChanged);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
