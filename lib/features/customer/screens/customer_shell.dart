import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/fcm_service.dart';
import '../../customer/providers/billing_provider.dart';
import '../../customer/providers/complaint_provider.dart';
import '../../customer/providers/customer_dashboard_provider.dart';
import '../../customer/providers/notification_provider.dart';
import '../../customer/providers/ticket_provider.dart';
import '../models/notification_model.dart';
import 'customer_dashboard_screen.dart';
import 'customer_profile_screen.dart';
import 'billing/payment_method_selection_screen.dart';
import 'lapor_screen.dart';
import 'notifications/notification_screen.dart';
import 'complaints/complaint_detail_screen.dart';
import 'tickets/ticket_detail_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell>
    with WidgetsBindingObserver {
  int _index = 0;

  StreamSubscription? _fcmTapSub;
  StreamSubscription? _fcmMessageSub;

  final _screens = const [CustomerDashboardScreen(), CustomerProfileScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenFcmMessages();
      _listenFcmTap();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  void _refreshAll() {
    if (!mounted) return;
    context.read<CustomerDashboardProvider>().load();
    context.read<BillingProvider>().loadActiveBilling();
    context.read<NotificationProvider>().load();
    context.read<TicketProvider>().loadTickets();
    context.read<ComplaintProvider>().load();
  }

  /// Immediate refresh when a foreground FCM message arrives.
  void _listenFcmMessages() {
    _fcmMessageSub = FcmService.onForegroundMessage.listen((msg) {
      if (!mounted) return;
      final type = msg.data['type'] ?? '';
      if (type == 'paid') {
        context.read<BillingProvider>().loadActiveBilling();
        context.read<CustomerDashboardProvider>().load();
        context.read<NotificationProvider>().load();
        _showPaymentSuccessPopup(msg.data);
      } else if (type == 'unpaid' ||
          type == 'pending' ||
          type == 'overdue' ||
          type == 'briva_rejected') {
        context.read<BillingProvider>().loadActiveBilling();
        context.read<CustomerDashboardProvider>().load();
        context.read<NotificationProvider>().load();
      } else if (type == 'ticket_update' || type == 'ticket_message') {
        context.read<TicketProvider>().loadTickets();
        context.read<NotificationProvider>().load();
        context.read<CustomerDashboardProvider>().load();
      } else if (type == 'complaint_update' || type == 'complaint_reply') {
        context.read<ComplaintProvider>().load();
        context.read<NotificationProvider>().load();
        context.read<CustomerDashboardProvider>().load();
      } else if (type == 'announcement') {
        context.read<NotificationProvider>().load();
      } else {
        _refreshAll();
      }
    });
  }

  /// Navigate to the relevant screen when the user taps a push notification.
  void _listenFcmTap() {
    _fcmTapSub = FcmService.onNotificationTap.listen((msg) {
      if (!mounted) return;
      _handleNotificationTap(msg.data);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? '';

    // Always refresh all providers when arriving from a tapped notification
    _refreshAll();

    if (type == 'unpaid' ||
        type == 'paid' ||
        type == 'pending' ||
        type == 'overdue' ||
        type == 'briva_rejected') {
      // Push Billing screen
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PaymentMethodSelectionScreen()));
    } else if (type == 'ticket_update' || type == 'ticket_message') {
      final ticketId = int.tryParse(data['ticket_id'] ?? '');
      if (ticketId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(ticketId: ticketId),
          ),
        );
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LaporScreen()));
      }
    } else if (type == 'complaint_update' || type == 'complaint_reply') {
      final complaintId = int.tryParse(data['complaint_id'] ?? '');
      if (complaintId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(complaintId: complaintId),
          ),
        );
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LaporScreen()));
      }
    } else if (type == 'announcement') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
    }
  }

  void _showPaymentSuccessPopup(Map<String, dynamic> data) {
    if (!mounted) return;
    final notif = AppNotification.fromFcmData(data);
    final amount = notif.amount ?? 0;
    final amountStr = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (notif.invoiceNumber != null) ...[
                const SizedBox(height: 4),
                Text(
                  notif.invoiceNumber!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              if (amount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  amountStr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
              if (notif.paymentMethod != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notif.paymentMethod!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcmTapSub?.cancel();
    _fcmMessageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_outlined),
            activeIcon: Icon(Icons.person_outline_outlined),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
