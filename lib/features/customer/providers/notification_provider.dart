import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api;

  bool _loading = false;
  List<AppNotification> _announcements = [];
  List<AppNotification> _customerNotifications = [];
  String? _error;
  Timer? _pollingTimer;

  bool get loading => _loading;
  List<AppNotification> get announcements => _announcements;
  List<AppNotification> get customerNotifications => _customerNotifications;

  /// Combined, newest-first list shown in the notification screen.
  List<AppNotification> get all {
    final combined = [..._announcements, ..._customerNotifications];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  String? get error => _error;
  int get unreadCount => all.where((n) => !n.isRead).length;

  NotificationProvider(this._api);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Load both in parallel
      final results = await Future.wait([
        _api.get(ApiConstants.announcements),
        _api.get(ApiConstants.customerNotifications),
      ]);

      // Announcements
      final rawAnn = results[0];
      final annList = rawAnn is List
          ? rawAnn
          : rawAnn is Map
          ? (rawAnn['announcements'] ?? [])
          : [];
      _announcements = (annList as List)
          .map(
            (e) => AppNotification.fromJson(
              e as Map<String, dynamic>,
              type: 'announcement',
            ),
          )
          .toList();

      // Customer notifications (invoice paid, ticket updates, etc.)
      final rawCust = results[1];
      final custList = rawCust is List
          ? rawCust
          : rawCust is Map
          ? (rawCust['notifications'] ?? [])
          : [];
      _customerNotifications = (custList as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(int id, {bool isAnnouncement = true}) async {
    final list = isAnnouncement ? _announcements : _customerNotifications;
    final idx = list.indexWhere((n) => n.id == id);
    if (idx == -1 || list[idx].isRead) return;

    final updated = list[idx];
    list[idx] = AppNotification(
      id: updated.id,
      title: updated.title,
      body: updated.body,
      type: updated.type,
      createdAt: updated.createdAt,
      isRead: true,
    );
    notifyListeners();

    try {
      if (isAnnouncement) {
        await _api.post(ApiConstants.announcementMarkRead(id), {});
      } else {
        await _api.post(ApiConstants.customerNotificationMarkRead(id), {});
      }
    } catch (_) {
      list[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final unread = all.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    // Optimistically update both lists
    _announcements = _announcements
        .map((n) => n.isRead ? n : _asRead(n))
        .toList();
    _customerNotifications = _customerNotifications
        .map((n) => n.isRead ? n : _asRead(n))
        .toList();
    notifyListeners();

    // Mark announcements and customer notifications in parallel
    try {
      await Future.wait([
        Future.wait(
          unread
              .where((n) => n.type == 'announcement')
              .map(
                (n) => _api.post(ApiConstants.announcementMarkRead(n.id), {}),
              ),
        ),
        _api.post(ApiConstants.customerNotificationsReadAll, {}),
      ]);
    } catch (_) {}
  }

  AppNotification _asRead(AppNotification n) => AppNotification(
    id: n.id,
    title: n.title,
    body: n.body,
    type: n.type,
    createdAt: n.createdAt,
    isRead: true,
  );

  /// Silent refresh — hanya memperbarui unread count tanpa mengganti loading state.
  Future<void> _silentRefresh() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConstants.announcements),
        _api.get(ApiConstants.customerNotifications),
      ]);

      final rawAnn = results[0];
      final annList = rawAnn is List
          ? rawAnn
          : rawAnn is Map
          ? (rawAnn['announcements'] ?? [])
          : [];
      _announcements = (annList as List)
          .map(
            (e) => AppNotification.fromJson(
              e as Map<String, dynamic>,
              type: 'announcement',
            ),
          )
          .toList();

      final rawCust = results[1];
      final custList = rawCust is List
          ? rawCust
          : rawCust is Map
          ? (rawCust['notifications'] ?? [])
          : [];
      _customerNotifications = (custList as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (e) {
      // Abaikan error saat polling background
    }
  }

  /// Mulai polling background setiap [interval].
  void startPolling({Duration interval = const Duration(minutes: 1)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => _silentRefresh());
  }

  /// Hentikan polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
