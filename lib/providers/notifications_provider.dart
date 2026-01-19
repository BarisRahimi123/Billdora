import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get unreadNotifications =>
      _notifications.where((n) => n['is_read'] != true).toList();

  Future<void> loadNotifications(String userId) async {
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _supabaseService.getNotifications(userId);
      _unreadCount = await _supabaseService.getUnreadNotificationCount(userId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    if (_userId == null) return;
    try {
      _unreadCount = await _supabaseService.getUnreadNotificationCount(_userId!);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabaseService.markNotificationAsRead(id);
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    try {
      await _supabaseService.markAllNotificationsAsRead(_userId!);
      for (var n in _notifications) {
        n['is_read'] = true;
        n['read_at'] = DateTime.now().toIso8601String();
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _supabaseService.deleteNotification(id);
      final wasUnread = _notifications.firstWhere((n) => n['id'] == id)['is_read'] != true;
      _notifications.removeWhere((n) => n['id'] == id);
      if (wasUnread) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    _userId = null;
    notifyListeners();
  }
}
