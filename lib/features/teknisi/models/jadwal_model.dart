class JadwalInstallation {
  final int id;
  final String customerName;
  final String address;
  final String scheduledDate;
  final String status;
  final String? technician;
  final String? phone;
  final String? packageName;
  final String? notes;

  const JadwalInstallation({
    required this.id,
    required this.customerName,
    required this.address,
    required this.scheduledDate,
    required this.status,
    this.technician,
    this.phone,
    this.packageName,
    this.notes,
  });

  factory JadwalInstallation.fromJson(
    Map<String, dynamic> json,
  ) => JadwalInstallation(
    id: json['id'] as int,
    customerName:
        json['customer_name']?.toString() ??
        json['nama_pelanggan']?.toString() ??
        json['customer']?['name']?.toString() ??
        '',
    address: json['address']?.toString() ?? json['alamat']?.toString() ?? '',
    scheduledDate:
        json['scheduled_date']?.toString() ?? json['tanggal']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    technician:
        json['technician_name']?.toString() ??
        json['teknisi']?['name']?.toString(),
    phone: json['phone']?.toString() ?? json['customer']?['phone']?.toString(),
    packageName: json['package_name']?.toString() ?? json['paket']?.toString(),
    notes: json['notes']?.toString() ?? json['catatan']?.toString(),
  );
}
