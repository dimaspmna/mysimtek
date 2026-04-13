class DashboardBanner {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;

  const DashboardBanner({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
  });

  factory DashboardBanner.fromJson(Map<String, dynamic> json) =>
      DashboardBanner(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        imageUrl: json['image_url']?.toString() ?? '',
      );
}

class DashboardInvoice {
  final int id;
  final String invoiceNumber;
  final String? periodMonth;
  final double amount;
  final String formattedAmount;
  final String status;
  final String? issuedAt;
  final String? dueAt;

  const DashboardInvoice({
    required this.id,
    required this.invoiceNumber,
    this.periodMonth,
    required this.amount,
    required this.formattedAmount,
    required this.status,
    this.issuedAt,
    this.dueAt,
  });

  factory DashboardInvoice.fromJson(Map<String, dynamic> json) =>
      DashboardInvoice(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id'].toString()) ?? 0,
        invoiceNumber: json['invoice_number']?.toString() ?? '',
        periodMonth: json['period_month']?.toString(),
        amount: _parseDouble(json['amount']),
        formattedAmount: json['formatted_amount']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        issuedAt: json['issued_at']?.toString(),
        dueAt: json['due_at']?.toString(),
      );

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class CustomerDashboard {
  final String serviceStatus;
  final String? customerStatus;
  final String customerName;
  final String packageName;
  final String? speed;
  final String tagihan;
  final String jatuhTempo;
  final int openComplaints;
  final int unpaidInvoices;
  final int overdueInvoices;
  final List<DashboardInvoice> latestInvoices;
  final List<DashboardBanner> banners;

  const CustomerDashboard({
    required this.serviceStatus,
    this.customerStatus,
    required this.customerName,
    required this.packageName,
    this.speed,
    required this.tagihan,
    required this.jatuhTempo,
    this.openComplaints = 0,
    this.unpaidInvoices = 0,
    this.overdueInvoices = 0,
    this.latestInvoices = const [],
    this.banners = const [],
  });

  bool get hasPendingBilling => unpaidInvoices > 0 || overdueInvoices > 0;

  String get customerStatusLabel {
    const map = {
      'new': 'Pasang Baru',
      'active': 'Aktif',
      'not_installed': 'Belum Dipasang',
      'survey': 'Survey',
      'failed_install': 'Gagal Pasang',
      'terminated': 'Diputus',
    };
    return map[customerStatus] ?? customerStatus ?? '—';
  }

  factory CustomerDashboard.fromJson(Map<String, dynamic> json) {
    final stats = (json['customer_stats'] as Map<String, dynamic>?) ?? {};
    final invoiceStats = (json['invoice_stats'] as Map<String, dynamic>?) ?? {};
    final invoicesRaw = json['latest_invoices'] as List? ?? [];
    final bannersRaw = json['banners'] as List? ?? [];

    return CustomerDashboard(
      serviceStatus: stats['status']?.toString() ?? 'aktif',
      customerStatus: stats['customer_status']?.toString(),
      customerName: stats['name']?.toString() ?? '',
      packageName: stats['package']?.toString() ?? '-',
      speed: stats['speed']?.toString(),
      tagihan: stats['tagihan']?.toString() ?? '-',
      jatuhTempo: stats['jatuh_tempo']?.toString() ?? '-',
      openComplaints: _toInt(stats['pengaduan']),
      unpaidInvoices: _toInt(invoiceStats['unpaid_count']),
      overdueInvoices: _toInt(invoiceStats['overdue_count']),
      latestInvoices: invoicesRaw
          .map((e) => DashboardInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      banners: bannersRaw
          .map((e) => DashboardBanner.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
