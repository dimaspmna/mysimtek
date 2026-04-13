import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_error_view.dart';
import '../providers/customer_dashboard_provider.dart';
import '../models/customer_dashboard_model.dart';
import 'notifications/notification_screen.dart';
import 'billing/billing_screen.dart';
import 'billing/payment_history_screen.dart';
import 'lapor_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerDashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Image.asset('assets/icon/app_landscape.png', height: 32),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<CustomerDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.state == LoadState.loading ||
              provider.state == LoadState.initial) {
            return const AppLoading();
          }
          if (provider.state == LoadState.error) {
            return AppErrorView(
              message: provider.error ?? 'Gagal memuat data',
              onRetry: provider.load,
            );
          }
          final d = provider.dashboard!;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeroCard(dashboard: d),
                const SizedBox(height: 16),
                _StatsRow(dashboard: d),
                const SizedBox(height: 16),
                const _QuickMenu(),
                const SizedBox(height: 16),
                if (d.banners.isNotEmpty) ...[
                  _BannerSection(banners: d.banners),
                  const SizedBox(height: 16),
                ],
                const _PaymentInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final CustomerDashboard dashboard;
  const _HeroCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().user?.name ?? '';
    final statusInfo = _getStatusInfo(dashboard.customerStatus);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFEA580C), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.30),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Status row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PELANGGAN INTERNET',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusInfo.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusInfo.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.15),
              ),
            ),

            // Detail Grid 2x2
            Row(
              children: [
                Expanded(
                  child: _HeroDetail(
                    label: 'PAKET AKTIF',
                    value: dashboard.packageName,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HeroDetail(
                    label: 'KECEPATAN',
                    value: dashboard.speed ?? '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HeroDetail(
                    label: 'TAGIHAN / BULAN',
                    value: dashboard.tagihan,
                    bold: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HeroDetail(
                    label: 'JATUH TEMPO SETIAP',
                    value: dashboard.jatuhTempo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static _StatusInfo _getStatusInfo(String? status) {
    switch (status) {
      case 'new':
        return _StatusInfo(
          'Pasang Baru',
          const Color(0xFF3B82F6),
          const Color(0xFFBFDBFE),
        );
      case 'active':
        return _StatusInfo(
          'Aktif',
          const Color(0xFF10B981),
          const Color(0xFF6EE7B7),
        );
      case 'not_installed':
        return _StatusInfo(
          'Belum Dipasang',
          const Color(0xFFF59E0B),
          const Color(0xFFFDE68A),
        );
      case 'survey':
        return _StatusInfo(
          'Survey',
          const Color(0xFF8B5CF6),
          const Color(0xFFD8B4FE),
        );
      case 'failed_install':
        return _StatusInfo(
          'Gagal Pasang',
          const Color(0xFFEF4444),
          const Color(0xFFFECACA),
        );
      case 'terminated':
        return _StatusInfo(
          'Diputus',
          const Color(0xFF64748B),
          const Color(0xFFCBD5E1),
        );
      default:
        return _StatusInfo(
          'Aktif',
          const Color(0xFF10B981),
          const Color(0xFF6EE7B7),
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color dotColor;
  const _StatusInfo(this.label, this.color, this.dotColor);
}

class _HeroDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _HeroDetail({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.50),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final CustomerDashboard dashboard;
  const _StatsRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.receipt_long_outlined,
                count: dashboard.unpaidInvoices,
                label: 'Belum Lunas',
                color: const Color(0xFFF97316),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: _StatTile(
                icon: Icons.schedule_outlined,
                count: dashboard.overdueInvoices,
                label: 'Jatuh Tempo',
                color: const Color(0xFFF97316),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: _StatTile(
                icon: Icons.chat_bubble_outline,
                count: dashboard.openComplaints,
                label: 'Pengaduan',
                color: const Color(0xFFF97316),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ── Banner Section ────────────────────────────────────────────────────────────

class _BannerSection extends StatefulWidget {
  final List<DashboardBanner> banners;
  const _BannerSection({required this.banners});

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMASI & PROMO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 7,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return GestureDetector(
                onTap: () => _showBannerDetail(context, banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFF1F5F9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFFCBD5E1),
                            size: 32,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x8C000000)],
                            stops: [0.45, 1.0],
                          ),
                        ),
                      ),
                      // Title overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (banner.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Ketuk untuk selengkapnya',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.70),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  void _showBannerDetail(BuildContext context, DashboardBanner banner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerDetailSheet(banner: banner),
    );
  }
}

class _BannerDetailSheet extends StatelessWidget {
  final DashboardBanner banner;
  const _BannerDetailSheet({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Image
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFFCBD5E1),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                if (banner.description != null)
                  Text(
                    banner.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  )
                else
                  const Text(
                    'Tidak ada deskripsi tambahan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Menu ────────────────────────────────────────────────────────────────

class _QuickMenu extends StatelessWidget {
  const _QuickMenu();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickMenuItem(
          icon: Icons.receipt_long_rounded,
          label: 'Tagihan',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillingScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _QuickMenuItem(
          icon: Icons.history_rounded,
          label: 'Riwayat',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _QuickMenuItem(
          icon: Icons.support_agent_outlined,
          label: 'Lapor',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _QuickMenuItem(
          icon: Icons.menu_book_rounded,
          label: 'Panduan',
          onTap: () => _showPanduan(context),
        ),
      ],
    );
  }

  void _showPanduan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Panduan Penggunaan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ..._panduanItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$1, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _panduanItems = [
    (
      Icons.receipt_long_outlined,
      'Cek Tagihan',
      'Lihat dan bayar tagihan internet Anda lewat menu Tagihan.',
    ),
    (
      Icons.history_outlined,
      'Riwayat Pembayaran',
      'Pantau semua transaksi pembayaran yang sudah dilakukan.',
    ),
    (
      Icons.headset_mic_outlined,
      'Lapor Gangguan',
      'Buat tiket gangguan dan pantau status penanganan teknisi.',
    ),
    (
      Icons.account_circle_outlined,
      'Profil Akun',
      'Kelola informasi akun dan keamanan akun Anda.',
    ),
  ];
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment Info Card ─────────────────────────────────────────────────────────

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: Color(0xFF22C55E), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Informasi Pembayaran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pembayaran tagihan internet kini dapat dilakukan langsung '
                  'via menu Tagihan di aplikasi MySIMTEK. Mendukung berbagai '
                  'metode pembayaran: transfer bank, dompet digital, QRIS dan '
                  'sebagainya.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
