import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/whatsapp_admin.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_update_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_update_bottom_sheet.dart';
import '../../../core/widgets/app_webview.dart';
import 'change_password_screen.dart';
import 'detail_akun_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isLoggingOut = false;
  String _appVersion = '';
  String? _ispId;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadIspId();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  Future<void> _loadIspId() async {
    final id = await StorageService().getIspId();
    if (mounted) {
      setState(() => _ispId = id);
    }
  }

  void _showNotifikasiInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF16A34A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notifikasi Aktif',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Notifikasi Anda aktif. Anda akan menerima pemberitahuan terkait tagihan, tiket, dan pengumuman.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchWA(String number, String message) async {
    final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showUpdateAplikasi() async {
    final updateProv = context.read<AppUpdateProvider>();
    await updateProv.check();
    if (!mounted) return;

    if (updateProv.state == AppUpdateState.needsUpdate &&
        updateProv.update != null) {
      AppUpdateBottomSheet.show(
        context,
        update: updateProv.update!,
        currentVersion: updateProv.currentVersion,
      );
      return;
    }

    if (!mounted) return;
    final isUpToDate = updateProv.state == AppUpdateState.upToDate;
    final message = isUpToDate
        ? 'Versi aplikasi sudah yang terbaru.'
        : 'Gagal memeriksa update. Silakan coba lagi.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color:
                      (isUpToDate
                              ? const Color(0xFF0F766E)
                              : const Color(0xFFDC2626))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isUpToDate ? Icons.check_circle_outline : Icons.error_outline,
                  color: isUpToDate
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isUpToDate ? 'Versi Sudah Terbaru' : 'Gagal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              if (updateProv.currentVersion.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Versi Saat Ini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          updateProv.currentVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUpToDate
                        ? const Color(0xFF0F766E)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Akun',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          user == null
              ? const AppLoading()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'INFORMASI AKUN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DetailAkunScreen(),
                            ),
                          ),
                          splashColor: AppColors.primary.withOpacity(0.06),
                          highlightColor: AppColors.primary.withOpacity(0.03),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
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
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Text(
                                        'Pelanggan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- Bantuan ---
                    const _SectionLabel(label: 'BANTUAN'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _menuTile(
                              icon: Icons.headset_mic_outlined,
                              label: 'Bantuan CS 24 Jam',
                              bgColor: const Color(0xFF1E88E5),
                              onTap: () => _launchWA(
                                WhatsappAdmin.csForIsp(_ispId),
                                'Halo Admin, saya butuh bantuan terkait layanan OFA Customer.',
                              ),
                              isFirst: true,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                            ),
                            _menuTile(
                              icon: Icons.developer_mode,
                              label: 'Bantuan Developer',
                              bgColor: const Color(0xFF43A047),
                              onTap: () => _launchWA(
                                WhatsappAdmin.developer,
                                'Halo Admin Cogline, saya butuh bantuan terkait kendala aplikasi OFA Customer.',
                              ),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- Tentang Aplikasi ---
                    const _SectionLabel(label: 'TENTANG APLIKASI'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _menuTile(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Kebijakan Privasi',
                              bgColor: const Color(0xFF8E24AA),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AppWebView(
                                    title: 'Kebijakan Privasi',
                                    url: 'https://ofa.my.id/kebijakan-privasi',
                                  ),
                                ),
                              ),
                              isFirst: true,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                            ),
                            _menuTile(
                              icon: Icons.system_update_alt,
                              label: 'Update Aplikasi',
                              bgColor: const Color(0xFFFF6B00),
                              onTap: _showUpdateAplikasi,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                            ),
                            _menuTile(
                              icon: Icons.language,
                              label: 'Website Resmi',
                              bgColor: const Color(0xFF00ACC1),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AppWebView(
                                    title: 'Website Resmi',
                                    url: 'https://ofa.my.id',
                                  ),
                                ),
                              ),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- Lainnya ---
                    const _SectionLabel(label: 'LAINNYA'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _menuTile(
                              icon: Icons.notifications_active,
                              label: 'Notifikasi Anda Aktif',
                              bgColor: const Color(0xFF16A34A),
                              onTap: () => _showNotifikasiInfo(context),
                              isFirst: true,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                            ),
                            _menuTile(
                              icon: Icons.lock_outline,
                              label: 'Reset Password',
                              bgColor: const Color(0xFF00897B),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.cardBorder,
                            ),
                            _menuTile(
                              icon: Icons.logout,
                              label: 'Keluar',
                              bgColor: const Color(0xFFDC2626),
                              onTap: () async {
                                final confirm = await showModalBottomSheet<bool>(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (ctx) => Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      20,
                                      24,
                                      32,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              200,
                                              200,
                                              200,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        const Icon(
                                          Icons.logout,
                                          size: 40,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Konfirmasi Keluar',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Anda yakin ingin keluar dari akun?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor:
                                                      AppColors.textPrimary,
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    48,
                                                  ),
                                                  elevation: 2,
                                                  shadowColor: Colors.black
                                                      .withValues(alpha: 0.15),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Color(0xFFE2E8F0),
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text('Batal'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.error,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    48,
                                                  ),
                                                  elevation: 3,
                                                  shadowColor: AppColors.error
                                                      .withValues(alpha: 0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Color(0xFFDC2626),
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text('Keluar'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  setState(() => _isLoggingOut = true);
                                  await context.read<AuthProvider>().logout();
                                }
                              },
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Footer
                    Column(
                      children: [
                        Text(
                          '${AppVersion.appName} — VERSI $_appVersion',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '${AppVersion.copyright}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color bgColor = AppColors.primary,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(12) : Radius.zero,
      bottom: isLast ? const Radius.circular(12) : Radius.zero,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      splashColor: AppColors.textSecondary.withOpacity(0.08),
      highlightColor: AppColors.textSecondary.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
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
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    Color bgColor = AppColors.primary,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      title: label.isEmpty
          ? null
          : Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 52, color: AppColors.cardBorder);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
