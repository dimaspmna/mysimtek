class BrivaPayment {
  final int id;
  final String status;
  final String statusLabel;
  final String? note;
  final String? rejectionReason;
  final String? submittedAt;
  final String? approvedAt;

  const BrivaPayment({
    required this.id,
    required this.status,
    required this.statusLabel,
    this.note,
    this.rejectionReason,
    this.submittedAt,
    this.approvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory BrivaPayment.fromJson(Map<String, dynamic> json) => BrivaPayment(
    id: (json['id'] as num).toInt(),
    status: json['status']?.toString() ?? '',
    statusLabel: json['status_label']?.toString() ?? '',
    note: json['note']?.toString(),
    rejectionReason: json['rejection_reason']?.toString(),
    submittedAt: json['submitted_at']?.toString(),
    approvedAt: json['approved_at']?.toString(),
  );
}

class BrivaPaymentStatus {
  final int invoiceId;
  final String invoiceNumber;
  final String invoiceStatus;
  final bool paid;
  final String? paidAt;
  final String? paymentMethod;
  final String? paymentChannel;
  final CustomerPayment? customerPayment;
  final BrivaPayment? brivaPayment;

  const BrivaPaymentStatus({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceStatus,
    required this.paid,
    this.paidAt,
    this.paymentMethod,
    this.paymentChannel,
    this.customerPayment,
    this.brivaPayment,
  });

  factory BrivaPaymentStatus.fromJson(Map<String, dynamic> json) =>
      BrivaPaymentStatus(
        invoiceId: (json['invoice_id'] as num).toInt(),
        invoiceNumber: json['invoice_number']?.toString() ?? '',
        invoiceStatus: json['invoice_status']?.toString() ?? '',
        paid: json['paid'] == true,
        paidAt: json['paid_at']?.toString(),
        paymentMethod: json['payment_method']?.toString(),
        paymentChannel: json['payment_channel']?.toString(),
        customerPayment: json['customer_payment'] is Map
            ? CustomerPayment.fromJson(
                Map<String, dynamic>.from(json['customer_payment'] as Map),
              )
            : null,
        brivaPayment: json['briva_payment'] is Map
            ? BrivaPayment.fromJson(
                Map<String, dynamic>.from(json['briva_payment'] as Map),
              )
            : null,
      );
}

class CustomerPayment {
  final String method;
  final String number;
  final String channel;

  const CustomerPayment({
    required this.method,
    required this.number,
    required this.channel,
  });

  factory CustomerPayment.fromJson(Map<String, dynamic> json) =>
      CustomerPayment(
        method: json['method']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        channel: json['channel']?.toString() ?? '',
      );
}
