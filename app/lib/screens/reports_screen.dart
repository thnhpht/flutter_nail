import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Order> _orders = [];
  List<Employee> _employees = [];
  List<Service> _services = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  String _selectedPeriod = 'today'; // today, week, month, custom

  // Statistics
  double _totalRevenue = 0.0;
  int _totalOrders = 0;
  int _totalCustomers = 0;
  double _averageOrderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _setDateRangeForPeriod('today');
    _loadData();
  }

  void _setDateRangeForPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'today':
          _selectedDateRange = DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day),
          );
          break;
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _selectedDateRange = DateTimeRange(
            start:
                DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
            end: DateTime(now.year, now.month, now.day),
          );
          break;
        case 'month':
          _selectedDateRange = DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day),
          );
          break;
      }
    });
    _calculateStatistics();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await widget.api.getOrders();
      final employees = await widget.api.getEmployees();
      final services = await widget.api.getServices();

      setState(() {
        _orders = orders;
        _employees = employees;
        _services = services;
        _isLoading = false;
      });

      _calculateStatistics();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppWidgets.showFlushbar(context, 'Lỗi tải dữ liệu: $e',
          type: MessageType.error);
    }
  }

  List<Order> _getFilteredOrders() {
    if (_selectedDateRange == null) return _orders;

    return _orders.where((order) {
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

  void _calculateStatistics() {
    final filteredOrders = _getFilteredOrders();

    _totalRevenue =
        filteredOrders.fold(0.0, (sum, order) => sum + order.totalPrice);
    _totalOrders = filteredOrders.length;

    // Count unique customers
    final uniqueCustomers = <String>{};
    for (final order in filteredOrders) {
      uniqueCustomers.add(order.customerPhone);
    }
    _totalCustomers = uniqueCustomers.length;

    _averageOrderValue = _totalOrders > 0 ? _totalRevenue / _totalOrders : 0.0;

    setState(() {});
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
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
        _selectedPeriod = 'custom';
      });
      _calculateStatistics();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  String _getPeriodDisplayName() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Hôm nay';
      case 'week':
        return 'Tuần này';
      case 'month':
        return 'Tháng này';
      case 'custom':
        return _selectedDateRange != null
            ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
            : 'Tùy chọn';
      default:
        return 'Hôm nay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Báo cáo',
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
            onPressed: _loadData,
            size: 40,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryPink,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryPink,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Period Selection
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: AppTheme.cardDecoration(elevated: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: AppTheme.primaryPink,
                                size: 24,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thống kê kinh doanh',
                                      style: AppTheme.headingSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Xem báo cáo doanh thu và hoạt động',
                                      style: AppTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingL),

                          // Period Selection
                          Text(
                            'Chọn khoảng thời gian',
                            style: AppTheme.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),

                          Wrap(
                            spacing: AppTheme.spacingS,
                            runSpacing: AppTheme.spacingS,
                            children: [
                              _buildPeriodChip('today', 'Hôm nay'),
                              _buildPeriodChip('week', 'Tuần này'),
                              _buildPeriodChip('month', 'Tháng này'),
                              _buildCustomPeriodChip(),
                            ],
                          ),

                          if (_selectedDateRange != null) ...[
                            const SizedBox(height: AppTheme.spacingM),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                border: Border.all(
                                  color: AppTheme.primaryPink.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    color: AppTheme.primaryPink,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text(
                                    _getPeriodDisplayName(),
                                    style: AppTheme.labelLarge.copyWith(
                                      color: AppTheme.primaryPink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Statistics Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildStatCard(
                          'Doanh thu',
                          _formatPrice(_totalRevenue),
                          Icons.attach_money,
                          AppTheme.success,
                        ),
                        _buildStatCard(
                          'Đơn hàng',
                          _totalOrders.toString(),
                          Icons.receipt_long,
                          AppTheme.info,
                        ),
                        _buildStatCard(
                          'Khách hàng',
                          _totalCustomers.toString(),
                          Icons.people,
                          AppTheme.primaryPink,
                        ),
                        _buildStatCard(
                          'Trung bình/đơn',
                          _formatPrice(_averageOrderValue),
                          Icons.trending_up,
                          AppTheme.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Top Services
                    _buildTopServicesSection(),
                    const SizedBox(height: 20),

                    // Top Employees
                    _buildTopEmployeesSection(),
                    const SizedBox(height: 20),

                    // Recent Orders
                    _buildRecentOrdersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => _setDateRangeForPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPink : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: isSelected ? AppTheme.textOnPrimary : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPeriodChip() {
    final isSelected = _selectedPeriod == 'custom';
    return GestureDetector(
      onTap: _selectCustomDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPink : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month,
              color: isSelected ? AppTheme.textOnPrimary : AppTheme.textPrimary,
              size: 16,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              'Tùy chọn',
              style: AppTheme.labelMedium.copyWith(
                color:
                    isSelected ? AppTheme.textOnPrimary : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: AppTheme.textTertiary,
                size: 16,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXXS),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServicesSection() {
    final filteredOrders = _getFilteredOrders();
    final serviceStats = <String, int>{};

    for (final order in filteredOrders) {
      for (final serviceName in order.serviceNames) {
        serviceStats[serviceName] = (serviceStats[serviceName] ?? 0) + 1;
      }
    }

    final sortedServices = serviceStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topServices = sortedServices.take(5).toList();

    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.spa,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Dịch vụ phổ biến',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (topServices.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu dịch vụ',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                children: topServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final serviceEntry = entry.value;
                  final percentage = serviceStats.values.isNotEmpty
                      ? (serviceEntry.value /
                              serviceStats.values
                                  .reduce((a, b) => a > b ? a : b)) *
                          100
                      : 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceEntry.key,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXXS),
                              Row(
                                children: [
                                  Expanded(
                                    flex: percentage.round(),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTheme.success,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 100 - percentage.round(),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTheme.borderLight,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          '${serviceEntry.value}',
                          style: AppTheme.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopEmployeesSection() {
    final filteredOrders = _getFilteredOrders();
    final employeeStats = <String, int>{};

    for (final order in filteredOrders) {
      for (final employeeName in order.employeeNames) {
        employeeStats[employeeName] = (employeeStats[employeeName] ?? 0) + 1;
      }
    }

    final sortedEmployees = employeeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEmployees = sortedEmployees.take(5).toList();

    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppTheme.info,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Nhân viên xuất sắc',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (topEmployees.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu nhân viên',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                children: topEmployees.asMap().entries.map((entry) {
                  final index = entry.key;
                  final employeeEntry = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppTheme.softPinkGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Center(
                            child: Text(
                              employeeEntry.key.isNotEmpty
                                  ? employeeEntry.key[0].toUpperCase()
                                  : 'N',
                              style: AppTheme.labelLarge.copyWith(
                                color: AppTheme.primaryPink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employeeEntry.key,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${employeeEntry.value} đơn hàng',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: AppTheme.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? AppTheme.warning.withOpacity(0.1)
                                : AppTheme.info.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: AppTheme.labelSmall.copyWith(
                              color:
                                  index == 0 ? AppTheme.warning : AppTheme.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    final filteredOrders = _getFilteredOrders();
    final recentOrders = filteredOrders.take(5).toList();

    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryPink,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Đơn hàng gần đây',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (recentOrders.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Center(
                child: Text(
                  'Chưa có đơn hàng nào',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                children: recentOrders.map((order) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: AppTheme.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXXS),
                              Text(
                                '${order.serviceNames.length} dịch vụ',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(order.totalPrice),
                              style: AppTheme.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXXS),
                            Text(
                              _formatDate(order.createdAt),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
