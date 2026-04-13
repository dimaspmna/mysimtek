import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../models/invoice_model.dart';
import '../../providers/billing_provider.dart';
import 'invoice_detail_screen.dart';
import 'receipt_screen.dart';

Color _histStatusColor(String status) {
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

String _histStatusLabel(String status) {
  const map = {
    'paid': 'Lunas',
    'lunas': 'Lunas',
    'overdue': 'Jatuh Tempo',
    'unpaid': 'Belum Bayar',
    'pending': 'Pending',
  };
  return map[status.toLowerCase()] ?? status;
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _filter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadHistory();
    });
  }

  void _applyFilter(String value) {
    setState(() => _filter = value);
    context.read<BillingProvider>().loadHistory(
      status: value.isEmpty ? null : value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Riwayat Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Consumer<BillingProvider>(
        builder: (context, prov, _) {
          if (prov.historyLoading) return const AppLoading();
          if (prov.historyError != null) {
            return AppErrorView(
              message: prov.historyError!,
              onRetry: () =>
                  prov.loadHistory(status: _filter.isEmpty ? null : _filter),
            );
          }

          final history = prov.history;
          final fmt = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          final totalLunas = history.where((inv) => inv.isPaid).length;
          final totalBayar = history
              .where((inv) => !inv.isPaid)
              .fold<double>(0, (s, inv) => s + inv.amount);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _applyFilter(_filter),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                _SummaryCard(
                  total: history.length,
                  lunas: totalLunas,
                  totalBayar: fmt.format(totalBayar),
                ),
                const SizedBox(height: 12),
                // Filter row
                _HistFilterRow(current: _filter, onChanged: _applyFilter),
                const SizedBox(height: 12),
                // List
                if (history.isEmpty)
                  _buildEmpty()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: List.generate(history.length, (i) {
                          final isLast = i == history.length - 1;
                          return Column(
                            children: [
                              _HistTile(invoice: history[i], fmt: fmt),
                              if (!isLast)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF8FAFC),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_outlined,
              color: Color(0xFFCBD5E1),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada riwayat pembayaran.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

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
                const SizedBox(height: 2),
                Text(
                  '$lunas dari $total tagihan lunas',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
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

// ── Filter Row ────────────────────────────────────────────────────────────────

class _HistFilterRow extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _HistFilterRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('', 'Semua'),
      ('paid', 'Lunas'),
      ('overdue', 'Jatuh Tempo'),
      ('unpaid', 'Belum Bayar'),
    ];
    return Row(
      children: [
        for (int i = 0; i < filters.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filters[i].$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: current == filters[i].$1
                      ? AppColors.primary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: current == filters[i].$1
                      ? null
                      : Border.all(
                          color: const Color(
                            0xFF000000,
                          ).withValues(alpha: 0.10),
                          width: 1,
                        ),
                ),
                child: Text(
                  filters[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: current == filters[i].$1
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── History Tile ──────────────────────────────────────────────────────────────

class _HistTile extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat fmt;

  const _HistTile({required this.invoice, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    final dotColor = _histStatusColor(inv.status);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoiceId: inv.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12, top: 3),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.formattedPeriod,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inv.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(inv.amount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                if (inv.isPaid)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(invoice: inv),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 11,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Struk',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: dotColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: dotColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _histStatusLabel(inv.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: dotColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
