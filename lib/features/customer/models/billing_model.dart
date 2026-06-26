import 'invoice_model.dart';

class BillingStats {
  final int totalTagihan;
  final double totalNominal;
  final int overdueCount;
  final String? nextDueDate;

  const BillingStats({
    this.totalTagihan = 0,
    this.totalNominal = 0,
    this.overdueCount = 0,
    this.nextDueDate,
  });

  factory BillingStats.fromJson(Map<String, dynamic> json) => BillingStats(
    totalTagihan: (json['total_tagihan'] as num? ?? 0).toInt(),
    totalNominal: (json['total_nominal'] as num? ?? 0).toDouble(),
    overdueCount: (json['overdue_count'] as num? ?? 0).toInt(),
    nextDueDate: json['next_due_date']?.toString(),
  );
}

class CustomerPaymentInfo {
  final String? method;
  final String? number;
  final String? channel;

  const CustomerPaymentInfo({this.method, this.number, this.channel});

  bool get isMidtrans => method == 'midtrans';
  bool get isBriva => method == 'briva';

  factory CustomerPaymentInfo.fromJson(Map<String, dynamic> json) =>
      CustomerPaymentInfo(
        method: json['method']?.toString(),
        number: json['number']?.toString(),
        channel: json['channel']?.toString(),
      );
}

class BillingInfo {
  final BillingStats stats;
  final List<Invoice> invoices;
  final CustomerPaymentInfo? customerPayment;

  const BillingInfo({
    required this.stats,
    required this.invoices,
    this.customerPayment,
  });

  /// First unpaid/overdue invoice (for quick "active billing" display)
  Invoice? get activeInvoice => invoices.isNotEmpty ? invoices.first : null;

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    final statsData = json['stats'] as Map<String, dynamic>? ?? {};
    final invoiceList = json['invoices'] as List? ?? [];
    final paymentData = json['customer_payment'] as Map<String, dynamic>?;
    return BillingInfo(
      stats: BillingStats.fromJson(statsData),
      invoices: invoiceList
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      customerPayment: paymentData != null
          ? CustomerPaymentInfo.fromJson(paymentData)
          : null,
    );
  }
}
