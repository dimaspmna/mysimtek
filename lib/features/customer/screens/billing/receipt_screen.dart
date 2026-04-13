import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/invoice_model.dart';

class ReceiptScreen extends StatelessWidget {
  final Invoice invoice;
  const ReceiptScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Struk Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final text = _buildReceiptText(fmt);
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Struk disalin ke clipboard'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pembayaran Berhasil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(invoice.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    _receiptRow('No. Invoice', invoice.invoiceNumber),
                    if (invoice.customerName != null)
                      _receiptRow('Pelanggan', invoice.customerName!),
                    if (invoice.packageName != null)
                      _receiptRow('Paket', invoice.packageName!),
                    if (invoice.period != null)
                      _receiptRow('Periode', invoice.period!),
                    if (invoice.paidAt != null)
                      _receiptRow(
                        'Tanggal Bayar',
                        invoice.paidAt!.split('T').first,
                      ),
                    if (invoice.paymentMethod != null)
                      _receiptRow('Metode Bayar', invoice.paymentMethod!),
                    const SizedBox(height: 12),
                    const Divider(
                      color: AppColors.cardBorder,
                      thickness: 2,
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Dibayar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          fmt.format(invoice.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LUNAS',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MySimtek — Terima kasih telah melakukan pembayaran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _buildReceiptText(NumberFormat fmt) {
    final sb = StringBuffer();
    sb.writeln('=== STRUK PEMBAYARAN MYSIMTEK ===');
    sb.writeln('No. Invoice : ${invoice.invoiceNumber}');
    if (invoice.customerName != null) {
      sb.writeln('Pelanggan   : ${invoice.customerName}');
    }
    if (invoice.packageName != null) {
      sb.writeln('Paket       : ${invoice.packageName}');
    }
    if (invoice.period != null) {
      sb.writeln('Periode     : ${invoice.period}');
    }
    if (invoice.paidAt != null) {
      sb.writeln('Tgl Bayar   : ${invoice.paidAt!.split('T').first}');
    }
    sb.writeln('Total       : ${fmt.format(invoice.amount)}');
    sb.writeln('Status      : LUNAS');
    sb.writeln('================================');
    return sb.toString();
  }
}
