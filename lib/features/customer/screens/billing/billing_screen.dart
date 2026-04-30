import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/invoice_model.dart';
import '../../providers/billing_provider.dart';
import 'invoice_detail_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'lunas':
      return const Color(0xFF10B981);
    case 'overdue':
      return const Color(0xFFEF4444);
    case 'unpaid':
      return const Color(0xFFF97316);
    default:
      return const Color(0xFF94A3B8);
  }
}

String _statusLabel(String status) {
  const map = {
    'paid': 'Lunas',
    'lunas': 'Lunas',
    'overdue': 'Jatuh Tempo',
    'unpaid': 'Belum Bayar',
    'pending': 'Pending',
  };
  return map[status.toLowerCase()] ?? status;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with WidgetsBindingObserver {
  bool _awaitingPayment = false;
  // IDs of invoices that were UNPAID before the user went to pay.
  // The billing API only returns unpaid/overdue — so if one disappears
  // after reload it means it just got paid.
  Set<int> _unpaidBeforePayment = {};

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
    // The billing API only returns unpaid/overdue invoices.
    // If any previously-unpaid ID is now absent → it got paid.
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
    // Save IDs of all currently unpaid invoices (the billing API only
    // returns unpaid/overdue, so every entry in this list is unpaid).
    _unpaidBeforePayment = (provider.activeBilling?.invoices ?? [])
        .map((inv) => inv.id)
        .toSet();
    _awaitingPayment = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tagihan Internet',
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
        onPaymentInitiated: _onPaymentInitiated,
      ),
    );
  }
}

// ─── Tab: Tagihan ─────────────────────────────────────────────────────────────

class _TagihanTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onPaymentInitiated;
  const _TagihanTab({
    required this.onRefresh,
    required this.onPaymentInitiated,
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
        final lunas = invoices.where((inv) => inv.isPaid).length;
        final totalBayar = invoices
            .where((inv) => !inv.isPaid)
            .fold<double>(0, (s, inv) => s + inv.amount);
        final fmt = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        final summaryCard = _SummaryCard(
          total: invoices.length,
          lunas: lunas,
          totalBayar: fmt.format(totalBayar),
        );

        if (invoices.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: summaryCard,
              ),
              Expanded(child: Center(child: _buildEmptyTagihan())),
            ],
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              summaryCard,
              const SizedBox(height: 12),
              ...invoices.map(
                (inv) => _InvoiceActiveCard(
                  invoice: inv,
                  onPaymentInitiated: onPaymentInitiated,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTagihan() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 3, 152, 83),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_outlined,
            color: Color.fromARGB(255, 255, 255, 255),
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Semua tagihan lunas!',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tidak ada tagihan yang perlu dibayar.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int total;
  final int lunas;
  final String totalBayar;

  const _SummaryCard({
    required this.total,
    required this.lunas,
    required this.totalBayar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalBayar,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active Invoice Card ──────────────────────────────────────────────────────

class _InvoiceActiveCard extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback? onPaymentInitiated;
  const _InvoiceActiveCard({required this.invoice, this.onPaymentInitiated});

  @override
  State<_InvoiceActiveCard> createState() => _InvoiceActiveCardState();
}

class _InvoiceActiveCardState extends State<_InvoiceActiveCard> {
  bool _loadingPay = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isOverdue = inv.isOverdue;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoiceId: inv.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusPill(inv.status),
                        const SizedBox(height: 6),
                        Text(
                          inv.formattedPeriod,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (isOverdue && inv.dueDate.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Jatuh tempo: ${inv.dueDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          inv.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(inv.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _loadingPay
                            ? null
                            : () => _handlePay(context, inv),
                        child: AnimatedOpacity(
                          opacity: _loadingPay ? 0.6 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 5),
                                Text(
                                  _loadingPay
                                      ? 'Memproses...'
                                      : 'Bayar Sekarang',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePay(BuildContext context, Invoice inv) async {
    setState(() => _loadingPay = true);
    final provider = context.read<BillingProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final paymentUrl = await provider.getPaymentUrl(inv.id);
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

    final uri = Uri.parse(paymentUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    widget.onPaymentInitiated?.call();
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
