import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/bill_helper.dart';
import '../ui/design_system.dart';
import '../config/salon_config.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_order_screen.dart';

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
  DateTimeRange? _selectedDateRange;
  String? _currentEmployeeId;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    // Mặc định chọn hôm nay
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    _loadCurrentUserInfo();
    _loadData();
    _loadInformation();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserRole = prefs.getString('user_role');
      _currentEmployeeId = prefs.getString('employee_id');
    } catch (e) {
      // Handle error silently
    }
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

  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await widget.api.getOrders();
      await widget.api.getCategories(); // Load categories but don't store them
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

  List<Order> get _filteredOrders {
    List<Order> filtered = _orders;

    // Lọc theo nhân viên hiện tại nếu là employee
    if (_currentUserRole == 'employee' && _currentEmployeeId != null) {
      filtered = filtered.where((order) {
        return order.employeeIds.contains(_currentEmployeeId!);
      }).toList();
    }

    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.customerName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            order.customerPhone.contains(_searchQuery) ||
            order.id.contains(_searchQuery);
      }).toList();
    }

    // Áp dụng lọc theo khoảng thời gian
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

    // Sắp xếp theo thời gian mới nhất
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  List<Service> _getServicesForOrder(Order order) {
    if (order.serviceIds.isEmpty) {
      return [];
    }

    // Try to parse as JSON first if it's a string
    if (order.serviceIds is String) {
      try {
        final serviceIdsString = order.serviceIds as String;
        if (serviceIdsString.startsWith('[') &&
            serviceIdsString.endsWith(']')) {
          final decoded = jsonDecode(serviceIdsString) as List<dynamic>;
          final serviceIdList = decoded.cast<String>();

          final services = _allServices
              .where((service) => serviceIdList.contains(service.id))
              .toList();
          return services;
        }
      } catch (e) {
        // Ignore parsing errors and fall back to direct matching
      }
    }

    // Fallback: try direct string matching
    final services = _allServices
        .where((service) => order.serviceIds.contains(service.id))
        .toList();
    return services;
  }

  void _showBill(Order order) {
    final services = _getServicesForOrder(order);
    if (services.isEmpty) {
      AppWidgets.showFlushbar(
          context, 'Không tìm thấy thông tin dịch vụ cho đơn hàng này',
          type: MessageType.error);
      return;
    }

    BillHelper.showBillDialog(
      context: context,
      order: order,
      services: services,
      api: widget.api, // Thêm parameter này
      salonName: _information?.salonName,
      salonAddress: _information?.address,
      salonPhone: _information?.phone,
      salonQRCode: _information?.qrCode,
    );
  }

  bool _canUpdateOrder(Order order) {
    // Check if order is from today
    final today = DateTime.now();
    final orderDate = DateTime(
      order.createdAt.year,
      order.createdAt.month,
      order.createdAt.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);

    return orderDate.isAtSameMomentAs(todayDate);
  }

  void _showUpdateOrderDialog(Order order) {
    if (!_canUpdateOrder(order)) {
      AppWidgets.showFlushbar(
        context,
        'Chỉ có thể cập nhật đơn hàng trong ngày hôm nay',
        type: MessageType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateOrderScreen(
        api: widget.api,
        order: order,
        onOrderUpdated: () {
          // Refresh data after update
          refreshData();
        },
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatBillId(String orderId) {
    // Kiểm tra nếu ID rỗng
    if (orderId.isEmpty) {
      return "TẠM THỜI";
    }

    // Nếu ID có format GUID, lấy 8 ký tự đầu
    if (orderId.contains('-') && orderId.length >= 8) {
      return orderId.substring(0, 8).toUpperCase();
    }

    // Nếu ID có độ dài hợp lệ khác, lấy 8 ký tự đầu
    if (orderId.length >= 8) {
      return orderId.substring(0, 8).toUpperCase();
    }

    // Trường hợp khác, trả về ID gốc
    return orderId.toUpperCase();
  }

  double _getOriginalTotal(Order order) {
    // Tính thành tiền gốc từ tổng thanh toán, giảm giá và tip
    // totalPrice = originalTotal * (1 - discountPercent/100) + tip
    // originalTotal = (totalPrice - tip) / (1 - discountPercent/100)
    return (order.totalPrice - order.tip) / (1 - order.discountPercent / 100);
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Loại bỏ tất cả ký tự không phải số
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Kiểm tra nếu số điện thoại có 10 số
    if (cleanPhone.length == 10) {
      // Format: 0xxx xxx xxx
      return '${cleanPhone.substring(0, 4)} ${cleanPhone.substring(4, 7)} ${cleanPhone.substring(7)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('84')) {
      // Format cho số có mã quốc gia 84: +84 xxx xxx xxx
      return '+${cleanPhone.substring(0, 2)} ${cleanPhone.substring(2, 5)} ${cleanPhone.substring(5, 8)} ${cleanPhone.substring(8)}';
    } else if (cleanPhone.length == 9 && !cleanPhone.startsWith('0')) {
      // Format cho số không có số 0 đầu: 0xxx xxx xxx
      return '0${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }

    // Nếu không phù hợp với format Việt Nam, trả về số gốc
    return phoneNumber;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryStart,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
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

  Future<void> _showDateFilterDialog() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lọc theo thời gian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Chọn khoảng thời gian để xem hóa đơn',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Custom Date Range Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await _selectDateRange();
                        },
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryStart.withValues(alpha: 0.1),
                                AppTheme.primaryStart.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color:
                                  AppTheme.primaryStart.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryStart,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chọn khoảng thời gian tùy chỉnh',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Chọn ngày bắt đầu và kết thúc',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingM),

                    // Preset Buttons
                    Text(
                      'Chọn nhanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingM),

                    _buildPresetButtonsGrid(),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  void _setPresetDateRange(String preset) {
    final now = DateTime.now();
    DateTimeRange? newRange;

    switch (preset) {
      case 'today':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        newRange = DateTimeRange(
          start: DateTime(yesterday.year, yesterday.month, yesterday.day),
          end: DateTime(yesterday.year, yesterday.month, yesterday.day),
        );
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        newRange = DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'last30days':
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
    }

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
      // Close the dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) return '';

    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDate = dateFormat.format(_selectedDateRange!.start);
    final endDate = dateFormat.format(_selectedDateRange!.end);

    if (_selectedDateRange!.start.isAtSameMomentAs(_selectedDateRange!.end)) {
      return startDate;
    }

    return '$startDate - $endDate';
  }

  String _getEmptyStateTitle() {
    if (_currentUserRole == 'employee') {
      if (_selectedDateRange != null) {
        return 'Không có hóa đơn của bạn trong khoảng thời gian này';
      }
      if (_searchQuery.isNotEmpty) {
        return 'Không tìm thấy hóa đơn của bạn';
      }
      return 'Bạn chưa có hóa đơn nào';
    }

    if (_selectedDateRange != null) {
      return 'Không có hóa đơn trong khoảng thời gian này';
    }
    if (_searchQuery.isNotEmpty) {
      return 'Không tìm thấy hóa đơn';
    }
    return 'Chưa có hóa đơn nào';
  }

  String _getEmptyStateMessage() {
    if (_currentUserRole == 'employee') {
      if (_selectedDateRange != null) {
        return 'Thử chọn khoảng thời gian khác hoặc xóa bộ lọc thời gian';
      }
      if (_searchQuery.isNotEmpty) {
        return 'Thử tìm kiếm với từ khóa khác';
      }
      return 'Tạo đơn hàng đầu tiên để xem hóa đơn của bạn ở đây';
    }

    if (_selectedDateRange != null) {
      return 'Thử chọn khoảng thời gian khác hoặc xóa bộ lọc thời gian';
    }
    if (_searchQuery.isNotEmpty) {
      return 'Thử tìm kiếm với từ khóa khác';
    }
    return 'Tạo đơn hàng đầu tiên để xem hóa đơn ở đây';
  }

  String _getStatsTitle(String baseTitle) {
    if (_selectedDateRange != null) {
      return '$baseTitle đã lọc';
    }
    return 'Tổng $baseTitle';
  }

  Widget _buildPresetButtonsGrid() {
    final presets = [
      {
        'label': 'Hôm nay',
        'preset': 'today',
        'icon': Icons.today,
        'color': Colors.green
      },
      {
        'label': 'Hôm qua',
        'preset': 'yesterday',
        'icon': Icons.history,
        'color': Colors.orange
      },
      {
        'label': 'Tuần này',
        'preset': 'week',
        'icon': Icons.view_week,
        'color': Colors.blue
      },
      {
        'label': 'Tháng này',
        'preset': 'month',
        'icon': Icons.calendar_view_month,
        'color': Colors.purple
      },
      {
        'label': '30 ngày qua',
        'preset': 'last30days',
        'icon': Icons.trending_up,
        'color': Colors.teal
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingS,
        mainAxisSpacing: AppTheme.spacingS,
        childAspectRatio: 3.5,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        return _buildPresetButton(
          preset['label'] as String,
          preset['preset'] as String,
          preset['icon'] as IconData,
          preset['color'] as Color,
        );
      },
    );
  }

  Widget _buildPresetButton(
      String label, String preset, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPresetDateRange(preset),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.controlHeight / 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryStart.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _showDateFilterDialog,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: refreshData,
            color: AppTheme.primaryStart,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppWidgets.gradientHeader(
                    icon: Icons.receipt,
                    title: 'Hóa đơn',
                    subtitle: 'Quản lý hóa đơn',
                    fullWidth: true,
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Search Bar
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm hóa đơn...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  // Date Range Info Display (only show when date range is selected)
                  if (_selectedDateRange != null) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primaryStart.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: AppTheme.primaryStart,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _formatDateRange(),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryStart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _clearDateRange,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.clear,
                                size: 16,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingL),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: _getStatsTitle('Hóa đơn'),
                          value: _filteredOrders.length.toString(),
                          icon: Icons.receipt,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: _buildStatCard(
                          title: _getStatsTitle('Doanh thu'),
                          value:
                              '${_formatPrice(_filteredOrders.fold(0.0, (sum, order) => sum + order.totalPrice))} ${SalonConfig.currency}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  // Orders List
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryStart),
                      ),
                    )
                  else if (_filteredOrders.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredOrders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final order = entry.value;
                      return AppWidgets.animatedItem(
                        index: index,
                        child: _buildOrderCard(order),
                      );
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final canUpdate = _canUpdateOrder(order);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showBill(order),
          onLongPress: canUpdate ? () => _showUpdateOrderDialog(order) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (canUpdate) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _formatPhoneNumber(order.customerPhone),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: order.isPaid
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order.isPaid
                                      ? 'Đã thanh toán'
                                      : 'Chưa thanh toán',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: order.isPaid
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryStart.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: AppTheme.primaryStart.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '#${_formatBillId(order.id)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryStart,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Services
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.spa,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: _buildServicesDisplay(order),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Employee and Date
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.employeeNames.join(', '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatTime(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Total Price
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Column(
                    children: [
                      if (order.discountPercent > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giảm ${order.discountPercent.toStringAsFixed(0)}%:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '-${_formatPrice(_getOriginalTotal(order) * order.discountPercent / 100)} ${SalonConfig.currency}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng tiền:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_formatPrice(order.totalPrice)} ${SalonConfig.currency}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesDisplay(Order order) {
    // First try to get services from the loaded services list
    final services = _getServicesForOrder(order);

    if (services.isNotEmpty) {
      final displayServices = services.take(2).map((s) => s.name).join(', ');
      if (services.length > 2) {
        return Text(
          '${displayServices}...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        );
      }
      return Text(
        displayServices,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      );
    }

    // Fallback to serviceNames from order if no services found in loaded list
    if (order.serviceNames.isNotEmpty) {
      final displayServices = order.serviceNames.take(2).join(', ');
      if (order.serviceNames.length > 2) {
        return Text(
          '${displayServices}...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        );
      }
      return Text(
        displayServices,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      );
    }

    // If no service names available, show a placeholder
    return Text(
      'Không có dịch vụ',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
