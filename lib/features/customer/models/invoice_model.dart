class InvoiceItem {
  final String description;
  final double amount;

  const InvoiceItem({required this.description, required this.amount});

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    description:
        json['description']?.toString() ?? json['keterangan']?.toString() ?? '',
    amount:
        double.tryParse(json['amount']?.toString() ?? '') ??
        double.tryParse(json['nominal']?.toString() ?? '') ??
        0.0,
  );
}

class Invoice {
  final int id;
  final String invoiceNumber;
  final double amount;
  final String status;
  final String dueDate;
  final String createdAt;
  final String? paidAt;
  final String? paymentMethod;
  final List<InvoiceItem> items;
  final String? customerName;
  final String? packageName;
  final String? period;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.items = const [],
    this.customerName,
    this.packageName,
    this.period,
  });

  bool get isPaid => ['paid', 'lunas'].contains(status.toLowerCase());
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isOverdue => status.toLowerCase() == 'overdue';

  Invoice copyWith({String? status, String? paidAt, String? paymentMethod}) =>
      Invoice(
        id: id,
        invoiceNumber: invoiceNumber,
        amount: amount,
        status: status ?? this.status,
        dueDate: dueDate,
        createdAt: createdAt,
        paidAt: paidAt ?? this.paidAt,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        items: items,
        customerName: customerName,
        packageName: packageName,
        period: period,
      );

  /// Format paidAt ISO string ke "12 Juni 2026\n18.09 WIB"
  String? get formattedPaidAt {
    if (paidAt == null || paidAt!.isEmpty) return null;
    try {
      final dt = DateTime.parse(paidAt!);
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      final date = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      final time =
          '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} WIB';
      return '$date\n$time';
    } catch (_) {
      return null;
    }
  }

  /// Format period_month (e.g. "2025-01") to "Januari 2025"
  String get formattedPeriod {
    final p = period;
    if (p == null || p.isEmpty) return '-';
    try {
      final parts = p.split('-');
      if (parts.length >= 2) {
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        const months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        return '${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return p;
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'] as List?;
    return Invoice(
      id: (json['id'] as num).toInt(),
      invoiceNumber:
          json['invoice_number']?.toString() ??
          json['no_invoice']?.toString() ??
          '',
      amount:
          double.tryParse(json['amount']?.toString() ?? '') ??
          double.tryParse(json['nominal']?.toString() ?? '') ??
          0.0,
      status: json['status']?.toString() ?? '',
      dueDate:
          json['due_at']?.toString() ??
          json['due_date']?.toString() ??
          json['jatuh_tempo']?.toString() ??
          '',
      createdAt:
          json['issued_at']?.toString() ?? json['created_at']?.toString() ?? '',
      paidAt: json['paid_at']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      items:
          itemsData
              ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customerName:
          json['customer_name']?.toString() ??
          json['customer']?['name']?.toString(),
      packageName:
          json['package_name']?.toString() ??
          json['paket']?.toString() ??
          json['customer']?['service_package']?.toString(),
      period:
          json['period_month']?.toString() ??
          json['period']?.toString() ??
          json['periode']?.toString(),
    );
  }
}
