import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../models.dart' as models;
import '../ui/design_system.dart';
import '../ui/bill_helper.dart';
import '../api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  late List<models.Notification> _notifications;
  ApiClient? _apiClient;

  @override
  void initState() {
    super.initState();
    _notifications = _notificationService.notifications;
    _notificationService.notificationsNotifier
        .addListener(_onNotificationsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadApiClient();
  }

  void _loadApiClient() {
    // Get API client from the route arguments
    final apiClient = ModalRoute.of(context)?.settings.arguments as ApiClient?;
    if (apiClient != null && _apiClient == null) {
      setState(() {
        _apiClient = apiClient;
      });
      // Set API client for NotificationService (it's a singleton)
      _notificationService.setApiClient(apiClient);
    }
  }

  @override
  void dispose() {
    _notificationService.notificationsNotifier
        .removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    setState(() {
      _notifications = _notificationService.notifications;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.add_shopping_cart;
      case 'order_updated':
        return Icons.edit;
      case 'order_paid':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.green;
      case 'order_updated':
        return Colors.blue;
      case 'order_paid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAsRead(models.Notification notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }
  }

  Future<void> _handleNotificationTap(models.Notification notification) async {
    // Mark as read first
    await _markAsRead(notification);

    // Check if notification has order data
    if (notification.data != null && notification.data!['orderId'] != null) {
      final orderId = notification.data!['orderId'] as String;

      if (_apiClient != null) {
        try {
          // Get the order details
          final order = await _apiClient!.getOrderById(orderId);
          if (order != null) {
            // Get all services for the bill
            final services = await _apiClient!.getServices();

            // Show bill helper
            await BillHelper.showBillDialog(
              context: context,
              order: order,
              services: services,
              api: _apiClient!,
            );
          } else {
            AppWidgets.showFlushbar(
              context,
              'Không tìm thấy thông tin đơn hàng',
              type: MessageType.error,
            );
          }
        } catch (e) {
          AppWidgets.showFlushbar(
            context,
            'Lỗi khi tải thông tin đơn hàng: $e',
            type: MessageType.error,
          );
        }
      } else {
        AppWidgets.showFlushbar(
          context,
          'Không thể kết nối đến server',
          type: MessageType.error,
        );
      }
    } else {
      AppWidgets.showFlushbar(
        context,
        'Thông báo không chứa thông tin đơn hàng',
        type: MessageType.warning,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    AppWidgets.showFlushbar(
      context,
      'Đã đánh dấu tất cả thông báo là đã đọc',
      type: MessageType.success,
    );
  }

  Future<void> _deleteNotification(models.Notification notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);

      // Refresh notifications to ensure UI is updated
      await _notificationService.refreshNotifications();

      AppWidgets.showFlushbar(
        context,
        'Đã xóa thông báo',
        type: MessageType.success,
      );
    } catch (e) {
      AppWidgets.showFlushbar(
        context,
        'Lỗi khi xóa thông báo: $e',
        type: MessageType.error,
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.clearAllNotifications();

        // Refresh notifications to ensure UI is updated
        await _notificationService.refreshNotifications();

        AppWidgets.showFlushbar(
          context,
          'Đã xóa tất cả thông báo',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi xóa tất cả thông báo: $e',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Xóa tất cả',
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo mới sẽ xuất hiện ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(models.Notification notification) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: notification.isRead
                                    ? Colors.grey[700]
                                    : Colors.black,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryStart,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        _deleteNotification(notification);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Xóa'),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
