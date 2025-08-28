import 'package:flutter/material.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/bill_helper.dart';
import '../ui/design_system.dart';
import '../config/salon_config.dart';
import 'dart:convert'; // Added for jsonDecode

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<Order> _orders = [];
  List<Service> _allServices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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
      final categories = await widget.api.getCategories();
      
      // Flatten all services from categories
      final allServices = <Service>[];
      for (final category in categories) {
        allServices.addAll(category.items);
      }

      setState(() {
        _orders = orders;
        _allServices = allServices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Lỗi tải dữ liệu: $e');
    }
  }

  List<Order> get _filteredOrders {
    List<Order> filtered = _orders;
    
    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.customerPhone.contains(_searchQuery) ||
               order.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.serviceNames.any((service) => service.toLowerCase().contains(_searchQuery.toLowerCase()));
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
        if (serviceIdsString.startsWith('[') && serviceIdsString.endsWith(']')) {
          final decoded = jsonDecode(serviceIdsString) as List<dynamic>;
          final serviceIdList = decoded.cast<String>();
          
          final services = _allServices.where((service) => serviceIdList.contains(service.id)).toList();
          return services;
        }
      } catch (e) {
        // Ignore parsing errors and fall back to direct matching
      }
    }
    
    // Fallback: try direct string matching
    final services = _allServices.where((service) => order.serviceIds.contains(service.id)).toList();
    return services;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showBill(Order order) {
    final services = _getServicesForOrder(order);
    if (services.isEmpty) {
      _showErrorSnackBar('Không tìm thấy thông tin dịch vụ cho đơn hàng này');
      return;
    }

    BillHelper.showBillDialog(
      context: context,
      order: order,
      services: services,
      salonName: SalonConfig.salonName,
      salonAddress: SalonConfig.salonAddress,
      salonPhone: SalonConfig.salonPhone,
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
    // Kiểm tra nếu ID là GUID mặc định hoặc rỗng
    if (orderId.isEmpty || 
        orderId == "00000000-0000-0000-0000-000000000000" ||
        orderId == "00000000000000000000000000000000") {
      return "TẠM THỜI";
    }
    
    // Nếu ID có độ dài hợp lệ, lấy 8 ký tự đầu
    if (orderId.length >= 8) {
      return orderId.substring(0, 8).toUpperCase();
    }
    
    // Trường hợp khác, trả về ID gốc
    return orderId.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      appBar: AppBar(
        title: const Text(
          'Quản lý hóa đơn',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryStart,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(AppTheme.spacingM),
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
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng hóa đơn',
                    value: _orders.length.toString(),
                    icon: Icons.receipt,
                    color: AppTheme.primaryStart,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng doanh thu',
                    value: '${_formatPrice(_orders.fold(0.0, (sum, order) => sum + order.totalPrice))} ${SalonConfig.currency}',
                    icon: Icons.attach_money,
                    color: AppTheme.primaryEnd,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryStart),
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return AppWidgets.animatedItem(
                            index: index,
                            child: _buildOrderCard(order),
                          );
                        },
                      ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showBill(order),
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
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.customerPhone,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                  color: AppTheme.primaryStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                      order.employeeName,
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
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
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
            _searchQuery.isEmpty ? 'Chưa có hóa đơn nào' : 'Không tìm thấy hóa đơn',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _searchQuery.isEmpty 
                ? 'Tạo đơn hàng đầu tiên để xem hóa đơn ở đây'
                : 'Thử tìm kiếm với từ khóa khác',
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
