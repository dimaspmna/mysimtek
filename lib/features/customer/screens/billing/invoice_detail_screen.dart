import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../providers/billing_provider.dart';
import 'receipt_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen>
    with WidgetsBindingObserver {
  bool _awaitingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadInvoiceDetail(widget.invoiceId);
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
    final prov = context.read<BillingProvider>();
    await prov.loadInvoiceDetail(widget.invoiceId);
    if (!mounted) return;
    if (prov.currentInvoice?.isPaid ?? false) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Tagihan',
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
          if (prov.invoiceLoading) return const AppLoading();
          if (prov.invoiceError != null) {
            return AppErrorView(
              message: prov.invoiceError!,
              onRetry: () => prov.loadInvoiceDetail(widget.invoiceId),
            );
          }
          final inv = prov.currentInvoice;
          if (inv == null) return const AppLoading();

          final fmt = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inv.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          StatusBadge(inv.status),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.cardBorder),
                      _row('Nama Pelanggan', inv.customerName ?? '-'),
                      _row('Paket Internet', inv.packageName ?? '-'),
                      _row('Periode', inv.formattedPeriod),
                      _row('Tanggal Invoice', inv.createdAt.split('T').first),
                      _row('Jatuh Tempo', inv.dueDate),
                      if (inv.paidAt != null)
                        _row('Tanggal Bayar', inv.paidAt!.split('T').first),
                      if (inv.paymentMethod != null)
                        _row('Metode Bayar', inv.paymentMethod!),
                      const Divider(height: 24, color: AppColors.cardBorder),
                      if (inv.items.isNotEmpty) ...[
                        const Text(
                          'Rincian Tagihan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...inv.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  fmt.format(item.amount),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 16, color: AppColors.cardBorder),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (inv.isPaid)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptScreen(invoice: inv),
                    ),
                  ),
                  icon: const Icon(Icons.receipt),
                  label: const Text('Lihat Struk / Bukti Bayar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    final prov = context.read<BillingProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final paymentUrl = await prov.getPaymentUrl(inv.id);
                    if (!context.mounted) return;
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
                    if (!context.mounted) return;
                    if (!launched) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Gagal membuka browser. Coba lagi.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    _awaitingPayment = true;
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Bayar Tagihan Ini'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
