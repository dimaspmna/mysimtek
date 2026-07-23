import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class DetailAkunScreen extends StatefulWidget {
  const DetailAkunScreen({super.key});

  @override
  State<DetailAkunScreen> createState() => _DetailAkunScreenState();
}

class _DetailAkunScreenState extends State<DetailAkunScreen> {
  String? _address;
  String? _paymentMethod;
  String? _customerStatus;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await context.read<ApiService>().get(
        ApiConstants.customerProfile,
      );
      final customer = res['customer'] as Map<String, dynamic>?;
      if (customer != null && mounted) {
        setState(() {
          _address = customer['address']?.toString();
          _paymentMethod = customer['payment_method']?.toString();
          _customerStatus = customer['customer_status']?.toString();
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'new':
        return 'Pasang Baru';
      case 'not_installed':
        return 'Belum Dipasang';
      case 'survey':
        return 'Survey';
      case 'failed_install':
        return 'Gagal Pasang';
      case 'terminated':
        return 'Diputus';
      default:
        return status ?? '-';
    }
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'manual':
        return 'Manual (Transfer)';
      case 'midtrans':
        return 'Online (Midtrans)';
      case 'briva':
        return 'Online (QRIS / TF Mandiri)';
      default:
        return method ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Akun',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pelanggan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _infoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                    bgColor: const Color(0xFF5C6BC0),
                    isFirst: true,
                  ),
                  if (user.phone != null) ...[
                    _divider(),
                    _infoTile(
                      icon: Icons.phone_outlined,
                      label: 'No HP',
                      value: user.phone!,
                      bgColor: const Color(0xFF43A047),
                    ),
                  ],
                  if (user.customerNumber != null) ...[
                    _divider(),
                    _infoTile(
                      icon: Icons.badge_outlined,
                      label: 'No Pelanggan',
                      value: user.customerNumber!,
                      bgColor: const Color(0xFFFF8F00),
                    ),
                  ],
                  if (_address != null) ...[
                    _divider(),
                    _infoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat Rumah',
                      value: _address!,
                      bgColor: const Color(0xFFE53935),
                    ),
                  ],
                  if (_paymentMethod != null) ...[
                    _divider(),
                    _infoTile(
                      icon: Icons.payment_outlined,
                      label: 'Metode Pembayaran',
                      value: _paymentLabel(_paymentMethod),
                      bgColor: const Color(0xFF7B1FA2),
                    ),
                  ],
                  if (_customerStatus != null) ...[
                    _divider(),
                    _infoTile(
                      icon: Icons.account_circle_outlined,
                      label: 'Status Customer',
                      value: _statusLabel(_customerStatus),
                      bgColor: const Color(0xFF00897B),
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gagal memuat data profil',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 52, color: AppColors.cardBorder);
}
