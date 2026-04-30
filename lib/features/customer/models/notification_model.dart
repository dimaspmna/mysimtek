class AppNotification {
  final int id;
  final String title;
  final String body;
  final String
  type; // 'announcement' | 'customer' | 'invoice' | 'ticket_update'
  final String createdAt;
  final bool isRead;

  // Extra fields available on 'paid' notifications (from FCM data payload
  // and from the API response).
  final String? invoiceNumber;
  final String? customerName;
  final String? periodMonth;
  final String? paymentMethod;
  final String? paidAt;
  final int? amount;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.invoiceNumber,
    this.customerName,
    this.periodMonth,
    this.paymentMethod,
    this.paidAt,
    this.amount,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    String type = 'announcement',
  }) => AppNotification(
    id: json['id'] as int,
    title: json['title']?.toString() ?? json['judul']?.toString() ?? '',
    body:
        json['content']?.toString() ??
        json['body']?.toString() ??
        json['message']?.toString() ??
        json['isi']?.toString() ??
        '',
    type: json['type']?.toString() ?? type,
    createdAt: json['created_at']?.toString() ?? '',
    isRead: json['is_read'] == true || json['read_at'] != null,
    invoiceNumber: json['invoice_number']?.toString(),
    customerName: json['customer_name']?.toString(),
    periodMonth: json['period_month']?.toString(),
    paymentMethod: json['payment_method']?.toString(),
    paidAt: json['paid_at']?.toString(),
    amount: json['amount'] != null
        ? int.tryParse(json['amount'].toString())
        : null,
  );

  /// Build an [AppNotification] directly from an FCM data-only message payload.
  factory AppNotification.fromFcmData(Map<String, dynamic> data) =>
      AppNotification(
        id: int.tryParse(data['notif_id']?.toString() ?? '') ?? 0,
        title: data['title']?.toString() ?? '',
        body: data['body']?.toString() ?? '',
        type: data['type']?.toString() ?? 'paid',
        createdAt:
            data['paid_at']?.toString() ?? DateTime.now().toIso8601String(),
        isRead: false,
        invoiceNumber: data['invoice_number']?.toString(),
        customerName: data['customer_name']?.toString(),
        periodMonth: data['period_month']?.toString(),
        paymentMethod: data['payment_method']?.toString(),
        paidAt: data['paid_at']?.toString(),
        amount: int.tryParse(data['amount']?.toString() ?? ''),
      );
}
