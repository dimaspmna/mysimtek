import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_error_view.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/notification_provider.dart';
import '../models/customer_dashboard_model.dart';
import '../../../core/widgets/app_webview.dart';
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
  late final NotificationProvider _notifProv;
  late final CustomerDashboardProvider _dashboardProv;
  final Set<int> _popUpShownForIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dashboardProv = context.read<CustomerDashboardProvider>();
      _dashboardProv.load();
      _dashboardProv.startPolling();
      _notifProv = context.read<NotificationProvider>();
      _notifProv.startPolling();
      context.read<TicketProvider>().loadTickets();
    });
  }

  @override
  void dispose() {
    _dashboardProv.stopPolling();
    _notifProv.stopPolling();
    super.dispose();
  }

  void _checkAndShowPopUp(List<PopUpBanner> banners) {
    final toShow = <PopUpBanner>[];
    for (final banner in banners) {
      if (_popUpShownForIds.contains(banner.id)) continue;
      _popUpShownForIds.add(banner.id);
      toShow.add(banner);
    }
    if (toShow.isEmpty || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PopUpSliderWidget(
        banners: toShow,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
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
        title: Image.asset('assets/logo/ofa_logo.png', height: 40),
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, notifProv, __) {
              final unread = notifProv.unreadCount;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
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
          if (d.popUpBanners.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _checkAndShowPopUp(d.popUpBanners);
            });
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _HeroCard(dashboard: d),
                const SizedBox(height: 16),
                _StatisticsSection(
                  unpaidInvoices: d.unpaidInvoices,
                  openComplaints: context
                      .watch<TicketProvider>()
                      .tickets
                      .where(
                        (t) => t.status == 'open' || t.status == 'in_progress',
                      )
                      .length,
                  onTagihanTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BillingScreen()),
                  ),
                  onKomplainTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LaporScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _QuickMenu(),
                const SizedBox(height: 20),
                if (d.banners.isNotEmpty) ...[
                  _BannerSection(banners: d.banners),
                  const SizedBox(height: 16),
                ],
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
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          fontSize: 16,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pelanggan Internet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
                      const SizedBox(width: 5),
                      Text(
                        statusInfo.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _infoChip(
                  Icons.wifi_rounded,
                  'PAKET INTERNET',
                  dashboard.packageName,
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Icons.speed_rounded,
                  'KECEPATAN INTERNET',
                  dashboard.speed ?? '—',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(
                  Icons.receipt_rounded,
                  'TAGIHAN INTERNET',
                  dashboard.tagihan,
                ),
                const SizedBox(width: 12),
                _infoChip(
                  Icons.calendar_today_rounded,
                  'JATUH TEMPO',
                  dashboard.jatuhTempo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
          const Color(0xFF93C5FD),
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

// ── Statistics Section ────────────────────────────────────────────────────────

class _StatisticsSection extends StatelessWidget {
  final int unpaidInvoices;
  final int openComplaints;
  final VoidCallback onTagihanTap;
  final VoidCallback onKomplainTap;

  const _StatisticsSection({
    required this.unpaidInvoices,
    required this.openComplaints,
    required this.onTagihanTap,
    required this.onKomplainTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Tagihan',
            value: unpaidInvoices.toString(),
            icon: Icons.receipt_long_rounded,
            accentColor: const Color(0xFFFF6B00),
            bgColor: const Color(0xFFFFF3E0),
            onTap: onTagihanTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Komplain',
            value: openComplaints.toString(),
            icon: Icons.report_problem_rounded,
            accentColor: const Color(0xFFFF6B00),
            bgColor: const Color(0xFFFFF3E0),
            onTap: onKomplainTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
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
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Menu ────────────────────────────────────────────────────────────────

class _QuickMenu extends StatelessWidget {
  const _QuickMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.receipt_long_rounded,
                label: 'Tagihan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BillingScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.history_rounded,
                label: 'Riwayat',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentHistoryScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.headset_mic_rounded,
                label: 'Komplain',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LaporScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.menu_book_rounded,
                label: 'Panduan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppWebView(
                      title: 'Panduan Aplikasi',
                      url: 'https://billing.simtek.co.id/guide',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (badgeCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INFORMASI & PROMO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 0.8,
              ),
            ),
            if (widget.banners.length > 1)
              Text(
                '${_currentPage + 1}/${widget.banners.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
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
                    borderRadius: BorderRadius.circular(14),
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
                                    color: Colors.white.withValues(alpha: 0.7),
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
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
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

class _PopUpSliderWidget extends StatefulWidget {
  final List<PopUpBanner> banners;
  final VoidCallback onClose;

  const _PopUpSliderWidget({required this.banners, required this.onClose});

  @override
  State<_PopUpSliderWidget> createState() => _PopUpSliderWidgetState();
}

class _PopUpSliderWidgetState extends State<_PopUpSliderWidget> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1080 / 1350,
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: banners
                    .map((b) => _buildImagePage(context, b))
                    .toList(),
              ),
            ),
          ),
          if (banners.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: _buildDots(banners.length),
            ),
          Positioned(
            right: -8,
            top: -8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onClose,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePage(BuildContext context, PopUpBanner b) {
    return Image.network(
      b.imageUrl,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF97316) : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
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
