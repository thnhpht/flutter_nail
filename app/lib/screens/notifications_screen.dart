import '../generated/l10n/app_localizations.dart';
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
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
    } else {
      return AppLocalizations.of(context)!.justNow;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.add_shopping_cart;
      case 'booking_created':
        return Icons.shopping_cart;
      case 'order_updated':
        return Icons.edit;
      case 'order_paid':
        return Icons.payment;
      case 'order_delivered':
        return Icons.local_shipping;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.green;
      case 'booking_created':
        return Colors.purple;
      case 'order_updated':
        return Colors.blue;
      case 'order_paid':
        return Colors.orange;
      case 'order_delivered':
        return Colors.teal;
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
            final allServices = await _apiClient!.getServices();
            final services = allServices
                .where((service) => order.serviceIds.contains(service.id))
                .toList();

            // Tạo ServiceWithQuantity từ Order nếu có serviceQuantities
            List<models.ServiceWithQuantity>? servicesWithQuantity;
            if (order.serviceQuantities.isNotEmpty &&
                order.serviceQuantities.length == order.serviceIds.length) {
              servicesWithQuantity = [];
              for (int i = 0; i < order.serviceIds.length; i++) {
                final serviceId = order.serviceIds[i];
                final quantity = order.serviceQuantities[i];
                final service = services.firstWhere(
                  (s) => s.id == serviceId,
                  orElse: () => services.first, // Fallback
                );
                servicesWithQuantity.add(models.ServiceWithQuantity(
                  service: service,
                  quantity: quantity,
                ));
              }
            }

            // Show bill helper
            await BillHelper.showBillDialog(
              context: context,
              order: order,
              services: servicesWithQuantity == null ? services : null,
              servicesWithQuantity: servicesWithQuantity,
              api: _apiClient!,
            );
          } else {
            AppWidgets.showFlushbar(
              context,
              AppLocalizations.of(context)!.orderNotFound,
              type: MessageType.error,
            );
          }
        } catch (e) {
          AppWidgets.showFlushbar(
            context,
            AppLocalizations.of(context)!.errorLoadingOrder(e.toString()),
            type: MessageType.error,
          );
        }
      } else {
        AppWidgets.showFlushbar(
          context,
          AppLocalizations.of(context)!.cannotConnectToServer,
          type: MessageType.error,
        );
      }
    } else {
      AppWidgets.showFlushbar(
        context,
        AppLocalizations.of(context)!.notificationNoOrderInfo,
        type: MessageType.warning,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    AppWidgets.showFlushbar(
      context,
      AppLocalizations.of(context)!.allNotificationsMarkedAsRead,
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
        AppLocalizations.of(context)!.notificationDeleted,
        type: MessageType.success,
      );
    } catch (e) {
      AppWidgets.showFlushbar(
        context,
        AppLocalizations.of(context)!.errorDeletingNotification(e.toString()),
        type: MessageType.error,
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAllNotifications),
        content:
            Text(AppLocalizations.of(context)!.confirmDeleteAllNotifications),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
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
          AppLocalizations.of(context)!.allNotificationsDeleted,
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          AppLocalizations.of(context)!
              .errorDeletingAllNotifications(e.toString()),
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
        title: Text(AppLocalizations.of(context)!.notifications),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: AppLocalizations.of(context)!.markAllAsReadTooltip,
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.clear_all),
              tooltip: AppLocalizations.of(context)!.clearAllTooltip,
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
            AppLocalizations.of(context)!.noNotificationsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.newNotificationsWillAppearHere,
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
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.deleteAction),
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
