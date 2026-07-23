import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../providers/notification_provider.dart';
import '../../providers/customer_dashboard_provider.dart';
import '../../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, prov, __) {
              if (prov.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: prov.markAllRead,
                child: Text(
                  'Tandai semua dibaca',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, prov, _) {
          if (prov.loading) return const AppLoading();
          if (prov.error != null) {
            return AppErrorView(message: prov.error!, onRetry: prov.load);
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: prov.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _InvoiceAlerts(),
                if (prov.all.isEmpty)
                  _EmptyState(hasAlerts: _hasInvoiceAlerts(context))
                else
                  _NotificationList(items: prov.all),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasInvoiceAlerts(BuildContext context) {
    final dash = context.read<CustomerDashboardProvider>().dashboard;
    if (dash == null) return false;
    return dash.overdueInvoices > 0 || dash.unpaidInvoices > 0;
  }
}

// ── Invoice Alerts ─────────────────────────────────────────────────────────

class _InvoiceAlerts extends StatelessWidget {
  const _InvoiceAlerts();

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<CustomerDashboardProvider>().dashboard;
    if (dash == null) return const SizedBox.shrink();

    final widgets = <Widget>[];

    if (dash.overdueInvoices > 0) {
      widgets.add(
        _AlertCard(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          title: 'Tagihan Jatuh Tempo',
          subtitle:
              'Anda memiliki ${dash.overdueInvoices} tagihan yang sudah jatuh tempo. Segera lakukan pembayaran.',
          titleColor: const Color(0xFFB91C1C),
          subtitleColor: const Color(0xFFEF4444),
        ),
      );
    }

    if (dash.unpaidInvoices > 0) {
      widgets.add(
        _AlertCard(
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFFF97316),
          bgColor: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFED7AA),
          title: 'Tagihan Belum Lunas',
          subtitle:
              'Anda memiliki ${dash.unpaidInvoices} tagihan yang belum dibayar.',
          titleColor: const Color(0xFFC2410C),
          subtitleColor: const Color(0xFFEA580C),
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (int i = 0; i < widgets.length; i++) ...[
          widgets[i],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    height: 1.4,
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

// ── Notification List ──────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  const _NotificationList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _NotificationTile(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// Keep backward-compatible alias used elsewhere
// typedef _AnnouncementList = _NotificationList;

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  bool get _isAnnouncement => item.type == 'announcement';

  IconData get _icon {
    switch (item.type) {
      case 'announcement':
        return Icons.campaign_outlined;
      case 'paid':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.hourglass_empty_outlined;
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'unpaid':
        return Icons.receipt_long_outlined;
      case 'ticket_update':
        return Icons.confirmation_num_outlined;
      case 'ticket_message':
        return Icons.message_outlined;
      case 'complaint_update':
        return Icons.support_agent_outlined;
      case 'complaint_reply':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<NotificationProvider>().markRead(
          item.id,
          isAnnouncement: _isAnnouncement,
        );
        _showDetail(context, item);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFFFE0C0),
          ),
          boxShadow: [
            BoxShadow(
              color: item.isRead
                  ? const Color(0xFF0F172A).withOpacity(0.04)
                  : AppColors.primary.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.isRead
                    ? const Color(0xFFF1F5F9)
                    : AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                size: 18,
                color: item.isRead ? const Color(0xFF94A3B8) : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: item.isRead
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                          color: item.isRead
                              ? const Color(0xFF64748B)
                              : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                          color: item.isRead
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  void _showDetail(BuildContext context, AppNotification item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnnouncementDetailSheet(item: item),
    );
  }
}

// ── Detail Bottom Sheet ────────────────────────────────────────────────────

class _AnnouncementDetailSheet extends StatelessWidget {
  final AppNotification item;
  const _AnnouncementDetailSheet({required this.item});

  String get _label {
    switch (item.type) {
      case 'announcement':
        return 'PENGUMUMAN';
      case 'paid':
        return 'PEMBAYARAN BERHASIL';
      case 'pending':
        return 'PEMBAYARAN DIPROSES';
      case 'overdue':
        return 'TAGIHAN JATUH TEMPO';
      case 'unpaid':
        return 'TAGIHAN BARU';
      case 'ticket_update':
        return 'UPDATE TIKET';
      case 'complaint_update':
        return 'STATUS PENGADUAN';
      case 'complaint_reply':
        return 'BALASAN PENGADUAN';
      default:
        return 'NOTIFIKASI';
    }
  }

  IconData get _icon {
    switch (item.type) {
      case 'announcement':
        return Icons.campaign_outlined;
      case 'paid':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.hourglass_empty_outlined;
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'unpaid':
        return Icons.receipt_long_outlined;
      case 'ticket_update':
        return Icons.confirmation_num_outlined;
      case 'complaint_update':
        return Icons.support_agent_outlined;
      case 'complaint_reply':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
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
            // Header strip
            Container(
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_icon, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.createdAt.split('T').first,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SafeArea(
                top: false,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasAlerts;
  const _EmptyState({required this.hasAlerts});

  @override
  Widget build(BuildContext context) {
    if (hasAlerts) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFFCBD5E1),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua notifikasi akan muncul di sini',
            style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}
