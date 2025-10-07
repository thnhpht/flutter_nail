import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models.dart' as models;
import '../ui/design_system.dart';
import '../api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'audio_service.dart';

class NotificationService {
  static const String _notificationsKey = 'notifications';
  static const String _unreadCountKey = 'unread_notifications_count';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  ApiClient? _apiClient;
  final AudioService _audioService = AudioService();

  // Stream controller for real-time updates
  final ValueNotifier<List<models.Notification>> _notificationsNotifier =
      ValueNotifier<List<models.Notification>>([]);
  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<models.Notification?> _newNotificationNotifier =
      ValueNotifier<models.Notification?>(null);

  // Polling timer for real-time updates
  Timer? _pollingTimer;

  ValueNotifier<List<models.Notification>> get notificationsNotifier =>
      _notificationsNotifier;
  ValueNotifier<int> get unreadCountNotifier => _unreadCountNotifier;
  ValueNotifier<models.Notification?> get newNotificationNotifier =>
      _newNotificationNotifier;

  List<models.Notification> get notifications => _notificationsNotifier.value;
  int get unreadCount => _unreadCountNotifier.value;

  /// Initialize the notification service
  Future<void> initialize({ApiClient? apiClient}) async {
    _apiClient = apiClient;
    await _loadNotifications();
    await _loadUnreadCount();

    // Initialize audio service
    await _audioService.initialize();

    // Start polling for real-time updates if API client is available
    if (_apiClient != null) {
      _startPolling();
    }
  }

  /// Set API client for the notification service
  void setApiClient(ApiClient? apiClient) {
    _apiClient = apiClient;
    if (_apiClient != null) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  /// Public method to refresh notifications from API
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  /// Load notifications from API or SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      // Try to load from API first if available
      if (_apiClient != null) {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          try {
            final response = await _apiClient!.getNotifications(shopName);
            if (response['success'] == true) {
              final List<dynamic> notificationsList =
                  response['notifications'] ?? [];
              final notifications = notificationsList
                  .map((json) {
                    try {
                      final notification = models.Notification.fromJson(
                          json as Map<String, dynamic>);
                      return notification;
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((notification) => notification != null)
                  .cast<models.Notification>()
                  .toList();

              // Sort by creation date (newest first)
              notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              _notificationsNotifier.value = notifications;

              // Update unread count
              final unreadCount = notifications.where((n) => !n.isRead).length;
              _unreadCountNotifier.value = unreadCount;

              await _saveNotifications(); // Cache locally
              await _saveUnreadCount(); // Save unread count
              return;
            }
          } catch (e) {
            // Fall back to local storage if API fails
          }
        }
      }

      // Fall back to local storage
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);

      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        final notifications = notificationsList
            .map((json) =>
                models.Notification.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by creation date (newest first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _notificationsNotifier.value = notifications;

        // Update unread count
        final unreadCount = notifications.where((n) => !n.isRead).length;
        _unreadCountNotifier.value = unreadCount;
      } else {
        _notificationsNotifier.value = [];
        _unreadCountNotifier.value = 0;
      }
    } catch (e) {
      _notificationsNotifier.value = [];
    }
  }

  /// Load unread count from SharedPreferences
  Future<void> _loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unreadCount = prefs.getInt(_unreadCountKey) ?? 0;
      _unreadCountNotifier.value = unreadCount;
    } catch (e) {
      _unreadCountNotifier.value = 0;
    }
  }

  /// Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
          _notificationsNotifier.value.map((n) => n.toJson()).toList());
      await prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Save unread count to SharedPreferences
  Future<void> _saveUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unreadCountKey, _unreadCountNotifier.value);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Add a new notification
  Future<void> addNotification(models.Notification notification) async {
    final updatedNotifications = [
      notification,
      ..._notificationsNotifier.value
    ];
    _notificationsNotifier.value = updatedNotifications;

    // Update unread count
    _unreadCountNotifier.value = _unreadCountNotifier.value + 1;

    await _saveNotifications();
    await _saveUnreadCount();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    // Try to mark as read via API first
    if (_apiClient != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          await _apiClient!.markNotificationRead(
            shopName: shopName,
            notificationId: notificationId,
          );
        }
      } catch (e) {
        // Fall back to local update if API fails
      }
    }

    // Update local state
    final updatedNotifications =
        _notificationsNotifier.value.map((notification) {
      if (notification.id == notificationId && !notification.isRead) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    _notificationsNotifier.value = updatedNotifications;

    // Update unread count
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    _unreadCountNotifier.value = unreadCount;

    await _saveNotifications();
    await _saveUnreadCount();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    // Try to mark all as read via API first
    if (_apiClient != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          await _apiClient!.markAllNotificationsRead(shopName: shopName);
        }
      } catch (e) {
        // Fall back to local update if API fails
      }
    }

    // Update local state
    final updatedNotifications =
        _notificationsNotifier.value.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    _notificationsNotifier.value = updatedNotifications;
    _unreadCountNotifier.value = 0;

    await _saveNotifications();
    await _saveUnreadCount();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final notification = _notificationsNotifier.value.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );

    // Try to delete via API first
    if (_apiClient != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          final response = await _apiClient!.deleteNotification(
            shopName: shopName,
            notificationId: notificationId,
          );

          // If API call was successful, refresh notifications from server
          if (response['success'] == true) {
            await _loadNotifications();
            // Recalculate unread count after refreshing from server
            final unreadCount =
                _notificationsNotifier.value.where((n) => !n.isRead).length;
            _unreadCountNotifier.value = unreadCount;
            await _saveUnreadCount();
            return; // Exit early since we've refreshed from server
          }
        }
      } catch (e) {
        // Fall back to local update if API fails
      }
    }

    // Update local state (fallback if API failed)
    final updatedNotifications = _notificationsNotifier.value
        .where((n) => n.id != notificationId)
        .toList();

    _notificationsNotifier.value = updatedNotifications;

    // Update unread count if the deleted notification was unread
    if (!notification.isRead) {
      _unreadCountNotifier.value = _unreadCountNotifier.value - 1;
    }

    await _saveNotifications();
    await _saveUnreadCount();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    // Try to clear via API first
    if (_apiClient != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          final response = await _apiClient!.clearAllNotifications(
            shopName: shopName,
          );

          // If API call was successful, refresh notifications from server
          if (response['success'] == true) {
            await _loadNotifications();
            // Recalculate unread count after refreshing from server
            final unreadCount =
                _notificationsNotifier.value.where((n) => !n.isRead).length;
            _unreadCountNotifier.value = unreadCount;
            await _saveUnreadCount();
            return; // Exit early since we've refreshed from server
          }
        }
      } catch (e) {
        // Fall back to local update if API fails
      }
    }

    // Update local state (fallback if API failed)
    _notificationsNotifier.value = [];
    _unreadCountNotifier.value = 0;

    await _saveNotifications();
    await _saveUnreadCount();
  }

  /// Create a notification for order created
  Future<void> createOrderCreatedNotification({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String employeeName,
    required double totalPrice,
    bool isDemo = false,
    BuildContext? context,
    String? currentUserRole, // Add user role parameter
  }) async {
    if (isDemo) {
      // Demo mode: only create local notification
      const uuid = Uuid();
      final notification = models.Notification(
        id: uuid.v4(),
        title: 'Đơn hàng mới',
        message:
            'Nhân viên $employeeName đã tạo đơn cho khách hàng $customerName (${customerPhone}) với tổng tiền ${_formatCurrency(totalPrice)}',
        type: 'order_created',
        createdAt: DateTime.now(),
        data: {
          'orderId': orderId,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'employeeName': employeeName,
          'totalPrice': totalPrice,
        },
      );
      await addNotification(notification);

      // Show Flushbar only for shop owners if context is available
      if (context != null && currentUserRole == 'shop_owner') {
        showNotification(context, notification);
        // Play notification sound for shop owner
        _audioService.playNotificationSound();
      }
      return;
    }

    // Real mode: send via API first, then create local notification
    // Only send notification to shop owner if employee created the order
    if (_apiClient != null && currentUserRole == 'employee') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          await _apiClient!.sendNotification(
            shopName: shopName,
            title: 'Đơn hàng mới',
            message:
                'Nhân viên $employeeName đã tạo đơn cho khách hàng $customerName (${customerPhone}) với tổng tiền ${_formatCurrency(totalPrice)}',
            type: 'order_created',
            orderId: orderId,
            customerName: customerName,
            customerPhone: customerPhone,
            employeeName: employeeName,
            totalPrice: totalPrice,
          );

          // Refresh notifications from API
          await _loadNotifications();

          // Show Flushbar only for shop owners if context is available
          if (context != null && currentUserRole == 'shop_owner') {
            // Find the notification that was just created from API
            final newNotification = _notificationsNotifier.value.firstWhere(
              (n) => n.type == 'order_created' && n.data?['orderId'] == orderId,
              orElse: () => models.Notification(
                id: '',
                title: 'Đơn hàng mới',
                message:
                    'Nhân viên $employeeName đã tạo đơn cho khách hàng $customerName (${customerPhone}) với tổng tiền ${_formatCurrency(totalPrice)}',
                type: 'order_created',
                createdAt: DateTime.now(),
                data: {
                  'orderId': orderId,
                  'customerName': customerName,
                  'customerPhone': customerPhone,
                  'employeeName': employeeName,
                  'totalPrice': totalPrice,
                },
              ),
            );
            showNotification(context, newNotification);
            // Play notification sound for shop owner
            _audioService.playNotificationSound();
          }
          return;
        } else {
          // Fall back to local notification if API fails
        }
      } catch (e) {
        // Fall back to local notification if API fails
      }
    }

    // Fall back to local notification
    const uuid = Uuid();
    final notification = models.Notification(
      id: uuid.v4(),
      title: 'Đơn hàng mới',
      message:
          'Nhân viên $employeeName đã tạo đơn cho khách hàng $customerName (${customerPhone}) với tổng tiền ${_formatCurrency(totalPrice)}',
      type: 'order_created',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'employeeName': employeeName,
        'totalPrice': totalPrice,
      },
    );

    await addNotification(notification);
  }

  /// Create a notification for order updated
  Future<void> createOrderUpdatedNotification({
    required String orderId,
    required String customerName,
    required String employeeName,
    bool isDemo = false,
    String? currentUserRole, // Add user role parameter
  }) async {
    if (isDemo) {
      // Demo mode: only create local notification
      const uuid = Uuid();
      final notification = models.Notification(
        id: uuid.v4(),
        title: 'Đơn hàng được cập nhật',
        message:
            'Nhân viên $employeeName đã cập nhật đơn cho khách hàng $customerName',
        type: 'order_updated',
        createdAt: DateTime.now(),
        data: {
          'orderId': orderId,
          'customerName': customerName,
          'employeeName': employeeName,
        },
      );
      await addNotification(notification);
      return;
    }

    // Real mode: send via API first, then create local notification
    // Only send notification to shop owner if employee updated the order
    if (_apiClient != null && currentUserRole == 'employee') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          await _apiClient!.sendNotification(
            shopName: shopName,
            title: 'Đơn hàng được cập nhật',
            message:
                'Nhân viên $employeeName đã cập nhật đơn cho khách hàng $customerName',
            type: 'order_updated',
            orderId: orderId,
            customerName: customerName,
            customerPhone: '',
            employeeName: employeeName,
            totalPrice: 0,
          );

          // Refresh notifications from API
          await _loadNotifications();
        }
      } catch (e) {
        // Fall back to local notification if API fails
      }
    }

    // Always create local notification for immediate display
    const uuid = Uuid();
    final notification = models.Notification(
      id: uuid.v4(),
      title: 'Đơn hàng được cập nhật',
      message:
          'Nhân viên $employeeName đã cập nhật đơn cho khách hàng $customerName',
      type: 'order_updated',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'customerName': customerName,
        'employeeName': employeeName,
      },
    );

    await addNotification(notification);
  }

  /// Create a notification for booking created
  Future<void> createBookingCreatedNotification({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required double totalPrice,
    bool isDemo = false,
    BuildContext? context,
    String? currentUserRole, // Add user role parameter
  }) async {
    if (isDemo) {
      // Demo mode: only create local notification
      const uuid = Uuid();
      final notification = models.Notification(
        id: uuid.v4(),
        title: 'Đơn đặt hàng mới',
        message:
            'Khách hàng $customerName (${customerPhone}) đã tạo đơn đặt hàng với tổng tiền ${_formatCurrency(totalPrice)}',
        type: 'booking_created',
        createdAt: DateTime.now(),
        data: {
          'orderId': orderId,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'totalPrice': totalPrice,
        },
      );
      await addNotification(notification);

      // Show Flushbar only for shop owners if context is available
      if (context != null && currentUserRole == 'shop_owner') {
        showNotification(context, notification);
        // Play notification sound for shop owner
        _audioService.playNotificationSound();
      }
      return;
    }

    // Real mode: send via API first, then create local notification
    // Always send notification to shop owner for booking orders
    if (_apiClient != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          await _apiClient!.sendNotification(
            shopName: shopName,
            title: 'Đơn đặt hàng mới',
            message:
                'Khách hàng $customerName (${customerPhone}) đã tạo đơn đặt hàng với tổng tiền ${_formatCurrency(totalPrice)}',
            type: 'booking_created',
            orderId: orderId,
            customerName: customerName,
            customerPhone: customerPhone,
            employeeName: '', // No employee for booking
            totalPrice: totalPrice,
          );

          // Refresh notifications from API
          await _loadNotifications();

          // Show Flushbar only for shop owners if context is available
          if (context != null && currentUserRole == 'shop_owner') {
            // Find the notification that was just created from API
            final newNotification = _notificationsNotifier.value.firstWhere(
              (n) =>
                  n.type == 'booking_created' && n.data?['orderId'] == orderId,
              orElse: () => models.Notification(
                id: '',
                title: 'Đơn đặt hàng mới',
                message:
                    'Khách hàng $customerName (${customerPhone}) đã tạo đơn đặt hàng với tổng tiền ${_formatCurrency(totalPrice)}',
                type: 'booking_created',
                createdAt: DateTime.now(),
                data: {
                  'orderId': orderId,
                  'customerName': customerName,
                  'customerPhone': customerPhone,
                  'totalPrice': totalPrice,
                },
              ),
            );
            showNotification(context, newNotification);
            // Play notification sound for shop owner
            _audioService.playNotificationSound();
          }
          return;
        } else {
          // Fall back to local notification if API fails
        }
      } catch (e) {
        // Fall back to local notification if API fails
      }
    }

    // Fall back to local notification
    const uuid = Uuid();
    final notification = models.Notification(
      id: uuid.v4(),
      title: 'Đơn đặt hàng mới',
      message:
          'Khách hàng $customerName (${customerPhone}) đã tạo đơn đặt hàng với tổng tiền ${_formatCurrency(totalPrice)}',
      type: 'booking_created',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'totalPrice': totalPrice,
      },
    );

    await addNotification(notification);
  }

  /// Create a notification for order paid
  Future<void> createOrderPaidNotification({
    required String orderId,
    required String customerName,
    required double totalPrice,
    bool isDemo = false,
    String? currentUserRole, // Add user role parameter
  }) async {
    if (isDemo) {
      // Demo mode: only create local notification
      const uuid = Uuid();
      final notification = models.Notification(
        id: uuid.v4(),
        title: 'Đơn hàng đã thanh toán',
        message:
            'Đơn hàng cho khách hàng $customerName đã được thanh toán ${_formatCurrency(totalPrice)}',
        type: 'order_paid',
        createdAt: DateTime.now(),
        data: {
          'orderId': orderId,
          'customerName': customerName,
          'totalPrice': totalPrice,
        },
      );
      await addNotification(notification);
      return;
    }

    // Real mode: send via API first, then create local notification
    // Only send notification to shop owner if employee processed the payment
    if (_apiClient != null && currentUserRole == 'employee') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final shopName = prefs.getString('shop_email') ??
            prefs.getString('user_email') ??
            prefs.getString('salon_name');

        if (shopName != null && shopName.isNotEmpty) {
          await _apiClient!.sendNotification(
            shopName: shopName,
            title: 'Đơn hàng đã thanh toán',
            message:
                'Đơn hàng cho khách hàng $customerName đã được thanh toán ${_formatCurrency(totalPrice)}',
            type: 'order_paid',
            orderId: orderId,
            customerName: customerName,
            customerPhone: '',
            employeeName: '',
            totalPrice: totalPrice,
          );

          // Refresh notifications from API
          await _loadNotifications();
        }
      } catch (e) {
        // Fall back to local notification if API fails
      }
    }

    // Always create local notification for immediate display
    const uuid = Uuid();
    final notification = models.Notification(
      id: uuid.v4(),
      title: 'Đơn hàng đã thanh toán',
      message:
          'Đơn hàng cho khách hàng $customerName đã được thanh toán ${_formatCurrency(totalPrice)}',
      type: 'order_paid',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'customerName': customerName,
        'totalPrice': totalPrice,
      },
    );

    await addNotification(notification);
  }

  /// Show notification using Flushbar
  static void showNotification(
    BuildContext context,
    models.Notification notification, {
    Duration duration = const Duration(seconds: 4),
  }) {
    MessageType messageType;

    switch (notification.type) {
      case 'order_created':
        messageType = MessageType.success;
        break;
      case 'booking_created':
        messageType = MessageType.success;
        break;
      case 'order_updated':
        messageType = MessageType.info;
        break;
      case 'order_paid':
        messageType = MessageType.success;
        break;
      default:
        messageType = MessageType.info;
    }

    AppWidgets.showFlushbar(
      context,
      notification.message,
      type: messageType,
      duration: duration,
    );
  }

  /// Format currency for display
  static String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return amount
            .toStringAsFixed(0)
            .replaceAllMapped(formatter, (Match m) => '${m[1]},') +
        ' VNĐ';
  }

  /// Start polling for real-time updates
  void _startPolling() {
    _stopPolling(); // Stop any existing timer

    // Poll every 10 seconds for new notifications
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pollForNewNotifications();
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Poll for new notifications from API
  Future<void> _pollForNewNotifications() async {
    if (_apiClient == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName =
          prefs.getString('shop_email') ?? prefs.getString('user_email');

      if (shopName != null && shopName.isNotEmpty) {
        final response = await _apiClient!.getNotifications(shopName);

        if (response['success'] == true) {
          final List<dynamic> notificationsList =
              response['notifications'] ?? [];
          final newNotifications = notificationsList
              .map((json) {
                try {
                  return models.Notification.fromJson(
                      json as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .where((notification) => notification != null)
              .cast<models.Notification>()
              .toList();

          // Sort by creation date (newest first)
          newNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Check if there are new notifications
          final currentNotifications = _notificationsNotifier.value;

          // Find the newest notification that wasn't in the previous list
          models.Notification? newestNotification;

          if (newNotifications.isNotEmpty && currentNotifications.isNotEmpty) {
            // Find notifications that are not in the current list
            for (final newNotif in newNotifications) {
              final exists = currentNotifications
                  .any((current) => current.id == newNotif.id);
              if (!exists) {
                newestNotification = newNotif;
                break; // Take the first new notification (which is the newest)
              }
            }
          } else if (newNotifications.isNotEmpty &&
              currentNotifications.isEmpty) {
            // First time loading notifications
            newestNotification = newNotifications.first;
          }

          // Always update the notifications list if there are notifications
          if (newNotifications.isNotEmpty) {
            _notificationsNotifier.value = newNotifications;

            // Update unread count
            final unreadCount = newNotifications.where((n) => !n.isRead).length;
            _unreadCountNotifier.value = unreadCount;

            // Save to local storage
            await _saveNotifications();
            await _saveUnreadCount();

            // Notify UI about new notification
            if (newestNotification != null) {
              _newNotificationNotifier.value = newestNotification;
              // Play notification sound for new notifications (only for shop owners)
              // Note: We can't check user role here as this is polling, but the main app will handle this
            }
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear the new notification (call this after showing Flushbar)
  void clearNewNotification() {
    _newNotificationNotifier.value = null;
  }

  /// Dispose resources
  void dispose() {
    _stopPolling();
    _notificationsNotifier.dispose();
    _unreadCountNotifier.dispose();
    _newNotificationNotifier.dispose();
  }
}
