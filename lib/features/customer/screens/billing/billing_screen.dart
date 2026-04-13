import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../models/invoice_model.dart';
import '../../providers/billing_provider.dart';
import 'invoice_detail_screen.dart';
import 'payment_webview_screen.dart';

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

class _BillingScreenState extends State<BillingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadActiveBilling();
    });
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
      ),
    );
  }
}

// ─── Tab: Tagihan ─────────────────────────────────────────────────────────────

class _TagihanTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _TagihanTab({required this.onRefresh});

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
              ...invoices.map((inv) => _InvoiceActiveCard(invoice: inv)),
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
  const _InvoiceActiveCard({required this.invoice});

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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.credit_card_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
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
    final navigator = Navigator.of(context);

    final snap = await provider.getSnapToken(inv.id);
    if (!mounted) return;
    setState(() => _loadingPay = false);

    if (snap == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan token pembayaran'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            PaymentWebViewScreen(paymentUrl: snap, invoiceId: inv.id),
      ),
    );
    if (mounted) {
      provider.loadActiveBilling();
    }
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
