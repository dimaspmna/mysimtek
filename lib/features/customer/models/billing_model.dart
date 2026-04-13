import 'invoice_model.dart';

class BillingStats {
  final int totalTagihan;
  final double totalNominal;
  final int overdueCount;

  const BillingStats({
    this.totalTagihan = 0,
    this.totalNominal = 0,
    this.overdueCount = 0,
  });

  factory BillingStats.fromJson(Map<String, dynamic> json) => BillingStats(
    totalTagihan: (json['total_tagihan'] as num? ?? 0).toInt(),
    totalNominal: (json['total_nominal'] as num? ?? 0).toDouble(),
    overdueCount: (json['overdue_count'] as num? ?? 0).toInt(),
  );
}

class BillingInfo {
  final BillingStats stats;
  final List<Invoice> invoices;

  const BillingInfo({required this.stats, required this.invoices});

  /// First unpaid/overdue invoice (for quick "active billing" display)
  Invoice? get activeInvoice => invoices.isNotEmpty ? invoices.first : null;

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    final statsData = json['stats'] as Map<String, dynamic>? ?? {};
    final invoiceList = json['invoices'] as List? ?? [];
    return BillingInfo(
      stats: BillingStats.fromJson(statsData),
      invoices: invoiceList
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
