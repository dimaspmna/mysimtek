import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final int invoiceId;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.invoiceId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _pageLoading = true;
  bool _paymentDone = false;
  bool _deepLinkLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _pageLoading = true),
          onPageFinished: (url) {
            setState(() => _pageLoading = false);
            // Deteksi halaman hasil pembayaran dari server kita
            if (_isPaymentResultUrl(url)) {
              setState(() => _paymentDone = true);
            }
          },
          onNavigationRequest: _onNavigationRequest,
          onWebResourceError: (_) => setState(() => _pageLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// URL /pay/{token}/finish — digunakan untuk navigasi setelah deep link.
  String get _finishUrl {
    final base = widget.paymentUrl.split('?').first;
    final clean = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$clean/finish';
  }

  /// Bangun halaman HTML "menunggu konfirmasi" yang ditampilkan di WebView
  /// saat user sedang di app e-wallet.
  ///
  /// Menggunakan `visibilitychange` JS event: ketika user kembali ke app
  /// (dokumen jadi visible lagi setelah hidden), otomatis redirect ke
  /// /pay/{token}/finish tanpa bergantung pada Flutter lifecycle observer.
  String _buildWaitingHtml() {
    final finishUrl = _finishUrl;
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Menunggu Pembayaran</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
      display:flex;flex-direction:column;align-items:center;justify-content:center;
      min-height:100vh;background:#f8fafc;color:#1e293b;padding:32px}
    .spinner{width:52px;height:52px;border:4px solid #f1f5f9;
      border-top-color:#f97316;border-radius:50%;
      animation:spin .9s linear infinite;margin-bottom:24px}
    @keyframes spin{to{transform:rotate(360deg)}}
    h2{font-size:17px;font-weight:700;margin-bottom:10px;text-align:center}
    p{font-size:13px;color:#64748b;text-align:center;line-height:1.6}
  </style>
</head>
<body>
  <div class="spinner"></div>
  <h2>Menunggu Konfirmasi Pembayaran</h2>
  <p>Pembayaran Anda sedang diverifikasi.<br>Mohon tunggu sebentar...</p>
  <script>
    // Ketika halaman pertama kali dimuat (sebelum user pergi ke e-wallet),
    // catat bahwa kita belum "hidden" dulu.
    var wasHidden = false;
    var redirected = false;
    function goToFinish() {
      if (!redirected) {
        redirected = true;
        window.location.href = '$finishUrl';
      }
    }
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'hidden') {
        wasHidden = true;
      } else if (document.visibilityState === 'visible' && wasHidden) {
        // User kembali dari app e-wallet — tunggu 1.5s lalu cek status
        setTimeout(goToFinish, 1500);
      }
    });
  </script>
</body>
</html>
''';
  }

  /// Fallback: jika JS visibilitychange tidak terpicu (edge case Android tertentu),
  /// lifecycle Flutter tetap menavigasi ke finish URL saat user kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _deepLinkLaunched) {
      _deepLinkLaunched = false;
      if (mounted && !_paymentDone) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted && !_paymentDone) {
            _controller.loadRequest(Uri.parse(_finishUrl));
          }
        });
      }
    }
  }

  /// URL dari server kita yang menandakan pembayaran selesai (sukses/pending/gagal).
  bool _isPaymentResultUrl(String url) {
    return url.contains('/pay/') &&
        (url.contains('/finish') || url.contains('/receipt'));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest req) {
    final url = req.url;
    final uri = Uri.tryParse(url);

    // Intercept non-http(s) schemes → buka app pembayaran eksternal (GoPay, DANA, dll)
    if (uri != null &&
        uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        uri.scheme != 'about') {
      _deepLinkLaunched = true;
      // Langsung ganti halaman Midtrans dengan halaman "menunggu" agar JS-nya
      // tidak bisa me-retrigger deep link saat user kembali ke app.
      Future.microtask(() {
        if (mounted) _controller.loadHtmlString(_buildWaitingHtml());
      });
      _launchDeepLink(url);
      return NavigationDecision.prevent;
    }

    // Semua URL http/https diizinkan — termasuk /pay/{token}/finish dari server kita
    return NavigationDecision.navigate;
  }

  /// Parse Android intent:// URL:
  /// intent://host/path?query#Intent;scheme=SCHEME;package=PACKAGE;S.browser_fallback_url=URL;end
  /// → kembalikan Map berisi 'deepLink' dan 'fallbackUrl'
  Map<String, String?> _parseIntentUrl(Uri intentUri) {
    final fragment =
        intentUri.fragment; // "Intent;scheme=dana;package=id.dana;...;end"
    final params = <String, String>{};

    if (fragment.startsWith('Intent;')) {
      for (final part in fragment.split(';')) {
        final idx = part.indexOf('=');
        if (idx > 0) {
          params[part.substring(0, idx)] = part.substring(idx + 1);
        }
      }
    }

    final scheme = params['scheme'];
    String? deepLink;
    if (scheme != null && scheme.isNotEmpty) {
      // Rekonstruksi: scheme://host/path?query
      final host = intentUri.host;
      final path = intentUri.path;
      final query = intentUri.query;
      deepLink = '$scheme://$host$path${query.isNotEmpty ? '?$query' : ''}';
    }

    final fallback = params['S.browser_fallback_url'];
    return {
      'deepLink': deepLink,
      'fallbackUrl': fallback != null ? Uri.decodeComponent(fallback) : null,
      'package': params['package'],
    };
  }

  /// Ekstrak deep link dari market:// (Play Store / GetApps)
  String? _extractDeepLinkFromMarket(Uri marketUri) {
    final raw = marketUri.queryParameters['deep_link_value'];
    if (raw != null && raw.isNotEmpty) return Uri.decodeComponent(raw);

    final referrer = marketUri.queryParameters['referrer'];
    if (referrer != null && referrer.isNotEmpty) {
      final decoded = Uri.decodeComponent(referrer);
      final refUri = Uri.tryParse('x://x?$decoded');
      if (refUri != null) {
        final afDp = refUri.queryParameters['af_dp'];
        if (afDp != null && afDp.isNotEmpty) return Uri.decodeComponent(afDp);
        final dlv = refUri.queryParameters['deep_link_value'];
        if (dlv != null && dlv.isNotEmpty) return Uri.decodeComponent(dlv);
      }
    }
    return null;
  }

  Future<void> _launchDeepLink(String url) async {
    try {
      final uri = Uri.parse(url);

      // ── intent:// (DANA, ShopeePay, dll) ──────────────────────────────────
      if (uri.scheme == 'intent') {
        final parsed = _parseIntentUrl(uri);
        final deepLink = parsed['deepLink'];
        final fallbackUrl = parsed['fallbackUrl'];

        if (deepLink != null) {
          final deepUri = Uri.tryParse(deepLink);
          if (deepUri != null) {
            final ok = await launchUrl(
              deepUri,
              mode: LaunchMode.externalApplication,
            );
            if (ok) return;
          }
        }
        // Fallback ke browser/store jika app tidak terinstall
        if (fallbackUrl != null) {
          await launchUrl(
            Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        return;
      }

      // ── market:// (GetApps / Play Store dengan embedded deep link) ─────────
      if (uri.scheme == 'market') {
        final deepLink = _extractDeepLinkFromMarket(uri);
        if (deepLink != null) {
          final deepUri = Uri.tryParse(deepLink);
          if (deepUri != null) {
            final ok = await launchUrl(
              deepUri,
              mode: LaunchMode.externalApplication,
            );
            if (ok) return;
          }
        }
        // Fallback ke app store
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      // ── Skema langsung: gopay://, ovo://, linkaja://, shopeeid://, dll ─────
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi pembayaran tidak ditemukan.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka aplikasi pembayaran.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        // Tampilkan tombol "Selesai" setelah halaman hasil pembayaran termuat
        actions: _paymentDone
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_pageLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
