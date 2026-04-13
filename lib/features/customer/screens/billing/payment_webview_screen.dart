import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/billing_provider.dart';

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

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            // Detect Midtrans finish/unfinish/error callbacks
            final url = req.url;
            if (url.contains('finish') ||
                url.contains('unfinish') ||
                url.contains('error')) {
              _handlePaymentResult(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentResult(String url) {
    context.read<BillingProvider>().checkPaymentStatus(widget.invoiceId);

    String message;
    Color color;
    if (url.contains('finish')) {
      message = 'Pembayaran berhasil!';
      color = AppColors.success;
    } else if (url.contains('unfinish')) {
      message = 'Pembayaran belum selesai.';
      color = AppColors.warning;
    } else {
      message = 'Pembayaran gagal.';
      color = AppColors.error;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
      Navigator.pop(context);
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
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
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
