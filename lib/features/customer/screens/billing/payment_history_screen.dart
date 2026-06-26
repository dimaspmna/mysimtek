import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../models/invoice_model.dart';
import '../../providers/billing_provider.dart';
import 'receipt_screen.dart';

String _histStatusLabel(String status) {
  const map = {
    'paid': 'Lunas',
    'lunas': 'Lunas',
    'overdue': 'Terlambat',
    'unpaid': 'Belum Bayar',
    'pending': 'Pending',
  };
  return map[status.toLowerCase()] ?? status;
}

Color _statusBg(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'lunas':
      return const Color(0xFFD1FAE5);
    case 'overdue':
      return const Color(0xFFFEE2E2);
    case 'unpaid':
      return const Color(0xFFFEF3C7);
    default:
      return const Color(0xFFF1F5F9);
  }
}

Color _statusText(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'lunas':
      return const Color(0xFF065F46);
    case 'overdue':
      return const Color(0xFF991B1B);
    case 'unpaid':
      return const Color(0xFF92400E);
    default:
      return const Color(0xFF475569);
  }
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
              onRetry: prov.loadHistory,
            );
          }

          final history = prov.history;
          final fmt = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => prov.loadHistory(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                _SummaryCard(history: history, fmt: fmt),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  _buildEmpty()
                else
                  ...history.map((inv) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistTile(invoice: inv, fmt: fmt),
                  )),
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
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
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

class _SummaryCard extends StatelessWidget {
  final List<Invoice> history;
  final NumberFormat fmt;

  const _SummaryCard({required this.history, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final totalLunas = history.where((inv) => inv.isPaid).length;
    final totalUnpaid = history.where((inv) => !inv.isPaid).length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalLunas Lunas',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalUnpaid Belum dibayar',
                  style: const TextStyle(
                    fontSize: 14,
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
              Icons.receipt_long_outlined,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistTile extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat fmt;

  const _HistTile({required this.invoice, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final inv = invoice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (inv.isPaid) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptScreen(invoice: inv),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Silakan bayar tagihan dari halaman Tagihan Internet.',
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.formattedPeriod,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (inv.formattedPaidAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        inv.formattedPaidAt!,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(inv.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg(inv.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _histStatusLabel(inv.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusText(inv.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
