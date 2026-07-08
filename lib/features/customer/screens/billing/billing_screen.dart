import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../models/invoice_model.dart';
import '../../providers/billing_provider.dart';
import 'payment_history_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with WidgetsBindingObserver {
  bool _awaitingPayment = false;
  Set<int> _unpaidBeforePayment = {};
  bool _loadingPay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadActiveBilling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingPayment) {
      _awaitingPayment = false;
      _reloadAndCheckPayment();
    }
  }

  Future<void> _reloadAndCheckPayment() async {
    if (!mounted) return;
    final provider = context.read<BillingProvider>();
    await provider.loadActiveBilling();
    if (!mounted) return;
    final currentUnpaidIds = (provider.activeBilling?.invoices ?? [])
        .map((inv) => inv.id)
        .toSet();
    final anyPaid = _unpaidBeforePayment.any(
      (id) => !currentUnpaidIds.contains(id),
    );
    if (anyPaid) {
      _showPaidBanner();
    }
  }

  void _showPaidBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tagihan berhasil dibayar! Terima kasih.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _onPaymentInitiated() {
    final provider = context.read<BillingProvider>();
    _unpaidBeforePayment = (provider.activeBilling?.invoices ?? [])
        .map((inv) => inv.id)
        .toSet();
    _awaitingPayment = true;
  }

  Future<void> _handleMidtransPay(Invoice inv) async {
    setState(() => _loadingPay = true);
    final prov = context.read<BillingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final paymentUrl = await prov.getPaymentUrl(inv.id);
    if (!mounted) return;
    setState(() => _loadingPay = false);

    if (paymentUrl == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan link pembayaran'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final launched = await launchUrl(
      Uri.parse(paymentUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka browser. Coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _onPaymentInitiated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pembayaran Midtrans',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: _TagihanTab(
        onRefresh: () => context.read<BillingProvider>().loadActiveBilling(),
        onPay: _handleMidtransPay,
        loadingPay: _loadingPay,
      ),
    );
  }
}

class _TagihanTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final Future<void> Function(Invoice) onPay;
  final bool loadingPay;
  const _TagihanTab({
    required this.onRefresh,
    required this.onPay,
    required this.loadingPay,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BillingProvider>(
      builder: (context, prov, _) {
        if (prov.billingLoading) return const AppLoading();
        if (prov.billingError != null) {
          return AppErrorView(message: prov.billingError!, onRetry: onRefresh);
        }

        final invoices = prov.activeBilling?.invoices ?? [];
        final fmt = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        if (invoices.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _MetodePembayaranHeader(),
              const SizedBox(height: 14),
              ...invoices.map(
                (inv) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InvoiceCard(
                    invoice: inv,
                    fmt: fmt,
                    loadingPay: loadingPay,
                    onPay: () => onPay(inv),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: const _MetodePembayaranHeader(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 52,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tagihan lunas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tidak ada tagihan yang perlu dibayar.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentHistoryScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Riwayat Pembayaran',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetodePembayaranHeader extends StatelessWidget {
  const _MetodePembayaranHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Midtrans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'GoPay, QRIS, Transfer Bank dan lainnya',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat fmt;
  final bool loadingPay;
  final VoidCallback onPay;

  const _InvoiceCard({
    required this.invoice,
    required this.fmt,
    required this.loadingPay,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final inv = invoice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inv.formattedPeriod,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (inv.isPaid
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF97316))
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inv.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: inv.isPaid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF97316),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (inv.paidAt != null) ...[
              const SizedBox(height: 8),
              _row('Tanggal Bayar', inv.paidAt!.split('T').first),
            ],
            if (inv.paymentMethod != null) ...[
              const SizedBox(height: 8),
              _row('Metode Bayar', _formatPaymentMethod(inv.paymentMethod!)),
            ],
            const SizedBox(height: 16),
            if (inv.items.isNotEmpty) ...[
              ...inv.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Text(
                        fmt.format(item.amount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  fmt.format(inv.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (!inv.isPaid) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loadingPay ? null : onPay,
                  icon: loadingPay
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.payment_rounded, size: 18),
                  label: loadingPay
                      ? const SizedBox.shrink()
                      : const Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    final upper = method.toUpperCase();
    if (!upper.startsWith('VIA ')) return 'VIA $upper';
    return upper;
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
