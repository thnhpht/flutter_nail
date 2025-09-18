import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  Information? _information;
  List<Order> _orders = [];
  List<Service> _allServices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default to today
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    _loadData();
    _loadInformation();
  }

  Future<void> _loadInformation() async {
    try {
      final info = await widget.api.getInformation();
      if (mounted) {
        setState(() {
          _information = info;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await widget.api.getOrders();
      final services = await widget.api.getServices();

      setState(() {
        _orders = orders;
        _allServices = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppWidgets.showFlushbar(context, 'Lỗi tải dữ liệu: $e',
          type: MessageType.error);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  List<Order> get _filteredOrders {
    List<Order> filtered = _orders;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.customerName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            order.customerPhone.contains(_searchQuery) ||
            order.id.contains(_searchQuery);
      }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((order) {
        final orderDate = DateTime(
            order.createdAt.year, order.createdAt.month, order.createdAt.day);
        final startDate = DateTime(_selectedDateRange!.start.year,
            _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final endDate = DateTime(_selectedDateRange!.end.year,
            _selectedDateRange!.end.month, _selectedDateRange!.end.day);
        return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryPink,
              onPrimary: AppTheme.textOnPrimary,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  Color _getStatusColor(Order order) {
    // You can customize this based on order status
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Hóa đơn',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          AppWidgets.iconButton(
            icon: Icons.refresh,
            onPressed: _refreshData,
            size: 40,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý hóa đơn và đơn hàng',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Search Field
                AppWidgets.searchField(
                  hintText: 'Tìm theo tên, SĐT hoặc mã đơn...',
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: AppWidgets.secondaryButton(
                        label: _selectedDateRange != null
                            ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                            : 'Chọn thời gian',
                        onPressed: _selectDateRange,
                        icon: Icons.date_range,
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 12),
                      AppWidgets.iconButton(
                        icon: Icons.clear,
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                        },
                        backgroundColor: AppTheme.error.withOpacity(0.1),
                        iconColor: AppTheme.error,
                        size: 40,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Summary Stats
          if (_filteredOrders.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(elevated: true),
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tổng đơn',
                      _filteredOrders.length.toString(),
                      Icons.receipt_long,
                      AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Doanh thu',
                      _formatPrice(_filteredOrders.fold(
                          0.0, (sum, order) => sum + order.totalPrice)),
                      Icons.attach_money,
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPink,
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: AppTheme.primaryPink,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          title,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty || _selectedDateRange != null
                ? Icons.search_off
                : Icons.receipt_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedDateRange != null
                ? 'Không tìm thấy kết quả'
                : 'Chưa có hóa đơn nào',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedDateRange != null
                ? 'Thử tìm kiếm với từ khóa khác hoặc thay đổi bộ lọc'
                : 'Tạo đơn hàng đầu tiên để bắt đầu',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order).withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        Icons.receipt,
                        color: _getStatusColor(order),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.id.substring(0, 8).toUpperCase()}',
                            style: AppTheme.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_formatDate(order.createdAt)} - ${_formatTime(order.createdAt)}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppWidgets.statusBadge(
                      text: _formatPrice(order.totalPrice),
                      color: AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Customer Info
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        '${order.customerName} - ${order.customerPhone}',
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),

                // Services Count
                Row(
                  children: [
                    Icon(
                      Icons.spa,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      '${order.serviceNames.length} dịch vụ',
                      style: AppTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: AppTheme.floatingCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.textOnPrimary.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppTheme.textOnPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi tiết hóa đơn',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '#${order.id.substring(0, 8).toUpperCase()}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textOnPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppWidgets.iconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                      iconColor: AppTheme.textOnPrimary,
                      size: 40,
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info
                      _buildDetailRow('Thời gian',
                          '${_formatDate(order.createdAt)} - ${_formatTime(order.createdAt)}'),
                      _buildDetailRow('Khách hàng', order.customerName),
                      _buildDetailRow('Số điện thoại', order.customerPhone),
                      _buildDetailRow(
                          'Nhân viên', order.employeeNames.join(', ')),

                      const SizedBox(height: AppTheme.spacingL),

                      // Services
                      Text(
                        'Dịch vụ đã sử dụng',
                        style: AppTheme.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      ...order.serviceNames.asMap().entries.map((entry) {
                        final index = entry.key;
                        final serviceName = entry.value;
                        // Try to find service price from all services
                        final service = _allServices
                            .where((s) => s.name == serviceName)
                            .firstOrNull;
                        final price = service?.price ?? 0.0;

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: AppTheme.spacingS),
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: AppTheme.primaryPink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Text(
                                  serviceName,
                                  style: AppTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                _formatPrice(price),
                                style: AppTheme.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: AppTheme.spacingL),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        decoration: BoxDecoration(
                          gradient: AppTheme.softPinkGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng thanh toán',
                              style: AppTheme.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _formatPrice(order.totalPrice),
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.primaryPink,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
