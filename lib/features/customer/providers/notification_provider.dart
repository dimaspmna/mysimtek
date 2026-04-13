import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api;

  bool _loading = false;
  List<AppNotification> _announcements = [];
  String? _error;

  bool get loading => _loading;
  List<AppNotification> get announcements => _announcements;
  String? get error => _error;
  int get unreadCount => _announcements.where((n) => !n.isRead).length;

  NotificationProvider(this._api);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.get(ApiConstants.announcements);
      final list = raw is List
          ? raw
          : raw is Map
          ? (raw['announcements'] ?? [])
          : [];
      _announcements = (list as List)
          .map(
            (e) => AppNotification.fromJson(
              e as Map<String, dynamic>,
              type: 'announcement',
            ),
          )
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    final idx = _announcements.indexWhere((n) => n.id == id);
    if (idx == -1 || _announcements[idx].isRead) return;
    // Optimistically update UI
    final updated = _announcements[idx];
    _announcements[idx] = AppNotification(
      id: updated.id,
      title: updated.title,
      body: updated.body,
      type: updated.type,
      createdAt: updated.createdAt,
      isRead: true,
    );
    notifyListeners();
    try {
      await _api.post(ApiConstants.announcementMarkRead(id), {});
    } catch (_) {
      // Revert if failed
      _announcements[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final unread = _announcements.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    // Optimistically update
    _announcements = _announcements
        .map(
          (n) => n.isRead
              ? n
              : AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  createdAt: n.createdAt,
                  isRead: true,
                ),
        )
        .toList();
    notifyListeners();
    for (final n in unread) {
      try {
        await _api.post(ApiConstants.announcementMarkRead(n.id), {});
      } catch (_) {}
    }
  }
}
