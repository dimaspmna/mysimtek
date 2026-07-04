class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? customerNumber;
  final String? packageName;
  final String? paymentMethod;
  final String? customerStatus;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.customerNumber,
    this.packageName,
    this.paymentMethod,
    this.customerStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    phone: json['phone']?.toString(),
    address: json['address']?.toString(),
    customerNumber: (json['customer_number'] ?? json['no_pelanggan'])
        ?.toString(),
    packageName: (json['package_name'] ?? json['paket'])?.toString(),
    paymentMethod: json['payment_method']?.toString(),
    customerStatus: json['customer_status']?.toString(),
  );
}
