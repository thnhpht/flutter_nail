import '../generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import '../ui/reports_pdf_generator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Order> _orders = [];
  List<Employee> _employees = [];
  List<Customer> _customers = [];
  List<String> _customerGroups = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  Employee? _selectedEmployee;
  Customer? _selectedCustomer;
  String? _selectedPaymentStatus;
  String? _selectedGroup;
  String _searchQuery = '';

  // Thống kê
  double _totalRevenue = 0.0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    // Mặc định chọn hôm nay
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
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
      final employees = await widget.api.getEmployees();
      final customers = await widget.api.getCustomers();
      final groups = await widget.api.getCustomerGroups();

      setState(() {
        _orders = orders;
        _employees = employees;
        _customers = customers;
        _customerGroups = groups;
        _isLoading = false;
      });

      _updateFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.errorLoadingData(e.toString()),
          type: MessageType.error);
    }
  }

  void _calculateStatistics() {
    final filteredOrders = _getFilteredOrders();

    // Tính tổng doanh thu
    _totalRevenue =
        filteredOrders.fold(0.0, (sum, order) => sum + order.totalPrice);

    // Tính số lượng hóa đơn
    _totalOrders = filteredOrders.length;
  }

  List<Order> _getFilteredOrders() {
    List<Order> filtered = _orders;

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

    // Áp dụng lọc theo nhân viên
    if (_selectedEmployee != null) {
      filtered = filtered.where((order) {
        return order.employeeIds.contains(_selectedEmployee!.id);
      }).toList();
    }

    // Áp dụng lọc theo khách hàng
    if (_selectedCustomer != null) {
      filtered = filtered.where((order) {
        return order.customerPhone == _selectedCustomer!.phone;
      }).toList();
    }

    // Áp dụng lọc theo trạng thái thanh toán
    if (_selectedPaymentStatus != null) {
      filtered = filtered.where((order) {
        if (_selectedPaymentStatus == 'paid') {
          return order.isPaid;
        } else if (_selectedPaymentStatus == 'unpaid') {
          return !order.isPaid;
        }
        return true; // 'all' - hiển thị tất cả
      }).toList();
    }

    // Áp dụng lọc theo nhóm khách hàng
    if (_selectedGroup != null) {
      filtered = filtered.where((order) {
        // Tìm customer tương ứng với order
        final customer = _customers.firstWhere(
          (c) => c.phone == order.customerPhone,
          orElse: () => Customer(phone: '', name: ''),
        );
        return customer.group == _selectedGroup;
      }).toList();
    }

    // Sắp xếp theo thời gian mới nhất
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
              secondary: AppTheme.primaryEnd,
              onSecondary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: AppTheme.primaryStart,
              headerForegroundColor: Colors.white,
              rangeSelectionBackgroundColor:
                  AppTheme.primaryStart.withValues(alpha: 0.2),
              rangeSelectionOverlayColor: WidgetStateProperty.all(
                  AppTheme.primaryEnd.withValues(alpha: 0.1)),
              rangePickerBackgroundColor: Colors.white,
              rangePickerSurfaceTintColor: AppTheme.primaryStart,
              rangePickerHeaderBackgroundColor: AppTheme.primaryStart,
              rangePickerHeaderForegroundColor: Colors.white,
              rangePickerHeaderHelpStyle: TextStyle(color: Colors.white70),
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
      _updateFilters();
    }
  }

  void _updateFilters() {
    if (mounted) {
      _calculateStatistics();
      setState(() {});
    }
  }

  Future<void> _exportReports() async {
    final filteredOrders = _getFilteredOrders();

    if (filteredOrders.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.noOrdersToExport,
          type: MessageType.warning);
      return;
    }

    await ReportsPdfGenerator.generateAndShareReports(
      context: context,
      orders: filteredOrders,
      api: widget.api,
    );
  }

  Future<void> _showDateFilterDialog() async {
    final l10n = AppLocalizations.of(context)!;
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.filterByTime,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              l10n.selectTimeRangeToViewReports,
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

                // Content - Scrollable
                Flexible(
                  child: SingleChildScrollView(
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
                                    AppTheme.primaryStart
                                        .withValues(alpha: 0.1),
                                    AppTheme.primaryStart
                                        .withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                border: Border.all(
                                  color: AppTheme.primaryStart
                                      .withValues(alpha: 0.3),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.selectCustomTimeRange,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          l10n.selectStartAndEndDate,
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
                          l10n.quickSelect,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingM),

                        _buildPresetButtonsGrid(l10n),
                      ],
                    ),
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
                          child: Text(
                            l10n.close,
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
      ),
    );
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    _updateFilters();
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
      _updateFilters();
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

  Widget _buildPresetButtonsGrid(AppLocalizations l10n) {
    final presets = [
      {
        'label': l10n.today,
        'preset': 'today',
        'icon': Icons.today,
        'color': Colors.green
      },
      {
        'label': l10n.yesterday,
        'preset': 'yesterday',
        'icon': Icons.history,
        'color': Colors.orange
      },
      {
        'label': l10n.thisWeek,
        'preset': 'week',
        'icon': Icons.view_week,
        'color': Colors.blue
      },
      {
        'label': l10n.thisMonth,
        'preset': 'month',
        'icon': Icons.calendar_view_month,
        'color': Colors.purple
      },
      {
        'label': l10n.last30Days,
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

  Widget _buildSearchableEmployeeDropdown(AppLocalizations l10n) {
    return Autocomplete<Employee>(
      displayStringForOption: (Employee employee) => employee.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _employees;
        }
        return _employees.where((Employee employee) => employee.name
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (Employee selection) {
        setState(() {
          _selectedEmployee = selection;
        });
        _updateFilters();
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: AppTheme.inputDecoration(
            label: l10n.selectEmployee,
            prefixIcon: Icons.person,
          ).copyWith(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _selectedEmployee != null
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _selectedEmployee = null;
                        textEditingController.clear();
                      });
                      _updateFilters();
                    },
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Employee> onSelected,
          Iterable<Employee> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: Icon(Icons.people, color: Colors.grey[600]),
                      title: Text(AppLocalizations.of(context)!.allEmployees),
                      onTap: () {
                        setState(() {
                          _selectedEmployee = null;
                        });
                        _updateFilters();
                        // Close the autocomplete overlay
                        FocusScope.of(context).unfocus();
                      },
                      selected: _selectedEmployee == null,
                    );
                  }

                  final employee = options.elementAt(index - 1);
                  return ListTile(
                    leading: Icon(Icons.person, color: Colors.grey[600]),
                    title: Text(employee.name),
                    onTap: () {
                      onSelected(employee);
                    },
                    selected: _selectedEmployee?.id == employee.id,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchableCustomerDropdown(AppLocalizations l10n) {
    return Autocomplete<Customer>(
      displayStringForOption: (Customer customer) => customer.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _customers;
        }
        return _customers.where((Customer customer) =>
            customer.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()) ||
            customer.phone.contains(textEditingValue.text));
      },
      onSelected: (Customer selection) {
        setState(() {
          _selectedCustomer = selection;
        });
        _updateFilters();
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: AppTheme.inputDecoration(
            label: l10n.selectCustomer,
            prefixIcon: Icons.person_outline,
          ).copyWith(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _selectedCustomer != null
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = null;
                        textEditingController.clear();
                      });
                      _updateFilters();
                    },
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Customer> onSelected,
          Iterable<Customer> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: Icon(Icons.people, color: Colors.grey[600]),
                      title: Text(AppLocalizations.of(context)!.allCustomers),
                      onTap: () {
                        setState(() {
                          _selectedCustomer = null;
                        });
                        _updateFilters();
                        // Close the autocomplete overlay
                        FocusScope.of(context).unfocus();
                      },
                      selected: _selectedCustomer == null,
                    );
                  }

                  final customer = options.elementAt(index - 1);
                  return ListTile(
                    leading:
                        Icon(Icons.person_outline, color: Colors.grey[600]),
                    title: Text(customer.name),
                    subtitle: Text(customer.phone),
                    onTap: () {
                      onSelected(customer);
                    },
                    selected: _selectedCustomer?.phone == customer.phone,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchableGroupDropdown(AppLocalizations l10n) {
    return Autocomplete<String>(
      displayStringForOption: (String group) => group,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _customerGroups;
        }
        return _customerGroups.where((String group) =>
            group.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        setState(() {
          _selectedGroup = selection;
        });
        _updateFilters();
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: AppTheme.inputDecoration(
            label: l10n.groupFilter,
            prefixIcon: Icons.group,
          ).copyWith(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _selectedGroup != null
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _selectedGroup = null;
                        textEditingController.clear();
                      });
                      _updateFilters();
                    },
                  )
                : null,
          ),
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: Icon(Icons.group, color: Colors.grey[600]),
                      title: Text(AppLocalizations.of(context)!.allGroups),
                      onTap: () {
                        setState(() {
                          _selectedGroup = null;
                        });
                        _updateFilters();
                        // Close the autocomplete overlay
                        FocusScope.of(context).unfocus();
                      },
                      selected: _selectedGroup == null,
                    );
                  }

                  final group = options.elementAt(index - 1);
                  return ListTile(
                    leading: Icon(Icons.group, color: Colors.grey[600]),
                    title: Text(group),
                    onTap: () {
                      onSelected(group);
                    },
                    selected: _selectedGroup == group,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredOrders = _getFilteredOrders();

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
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Export Reports Button
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppTheme.controlHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _exportReports,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(
                    Icons.print,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // Date Filter Button
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppTheme.controlHeight / 2),
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
            ],
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
                    title: l10n.revenueReports,
                    subtitle: l10n.statisticsAndRevenueReports,
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
                        _updateFilters();
                      },
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
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
                                  _updateFilters();
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

                  const SizedBox(height: AppTheme.spacingL),

                  // Employee Filter
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: _buildSearchableEmployeeDropdown(l10n),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Group Filter
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: _buildSearchableGroupDropdown(l10n),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Customer Filter
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: _buildSearchableCustomerDropdown(l10n),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Payment Status Filter
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: DropdownButtonFormField<String>(
                      decoration: AppTheme.inputDecoration(
                        label: l10n.paymentStatus,
                        prefixIcon: Icons.payment,
                      ).copyWith(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      initialValue: _selectedPaymentStatus,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child:
                              Text(AppLocalizations.of(context)!.allStatuses),
                        ),
                        DropdownMenuItem<String>(
                          value: 'paid',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.paid),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'unpaid',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.unpaid),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPaymentStatus = value;
                        });
                        _updateFilters();
                      },
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

                  // Thống kê tổng quan
                  _buildSummaryCards(l10n),

                  const SizedBox(height: AppTheme.spacingL),

                  // Danh sách hóa đơn
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryStart),
                      ),
                    )
                  else if (filteredOrders.isEmpty)
                    _buildEmptyState(l10n)
                  else
                    ...filteredOrders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final order = entry.value;
                      return AppWidgets.animatedItem(
                        index: index,
                        child: _buildOrderCard(order, l10n),
                      );
                    }).toList(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AppLocalizations l10n) {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: l10n.bills,
              value: _totalOrders.toString(),
              icon: Icons.receipt,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: _buildSummaryCard(
              title: l10n.revenue,
              value: NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ')
                  .format(_totalRevenue),
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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

  Widget _buildOrderCard(Order order, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            // Có thể thêm action khi tap vào order card
          },
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
                                  order.isPaid ? l10n.paid : l10n.unpaid,
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
                          if (order.customerAddress != null &&
                              order.customerAddress!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.customerAddress!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                        '#${_formatOrderId(order.id)}',
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
                        Icons.shopping_cart,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: _buildServicesDisplay(order, l10n),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingS),

                // Employee/Booking and Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      order.isBooking
                          ? Icons.shopping_bag_outlined
                          : Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.isBooking
                                ? (order.deliveryMethod == 'pickup'
                                    ? AppLocalizations.of(context)!
                                        .pickupAtStore
                                    : AppLocalizations.of(context)!
                                        .homeDelivery)
                                : order.employeeNames.join(', '),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          // Show delivery staff for booking orders with delivery method
                          if (order.isBooking &&
                              order.deliveryMethod == 'delivery' &&
                              order.employeeNames.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.deliveryStaff}: ${order.employeeNames.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Show delivery status for booking orders with delivery method
                          if (order.isBooking &&
                              order.deliveryMethod == 'delivery') ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: 12,
                                  color: _getDeliveryStatusColor(
                                      order.deliveryStatus),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDeliveryStatusText(
                                      context, order.deliveryStatus),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getDeliveryStatusColor(
                                        order.deliveryStatus),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.totalAmount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_formatPrice(order.totalPrice)} VNĐ',
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

  Widget _buildEmptyState(AppLocalizations l10n) {
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
            _getEmptyStateTitle(l10n),
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _getEmptyStateMessage(l10n),
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

  String _getEmptyStateTitle(AppLocalizations l10n) {
    if (_selectedDateRange != null) {
      return l10n.noOrdersInTimeRange;
    }
    if (_searchQuery.isNotEmpty) {
      return l10n.noOrdersFound;
    }
    return l10n.noOrdersYet;
  }

  String _getEmptyStateMessage(AppLocalizations l10n) {
    if (_selectedDateRange != null) {
      return l10n.tryDifferentTimeRange;
    }
    if (_searchQuery.isNotEmpty) {
      return l10n.tryDifferentSearch;
    }
    return l10n.createFirstOrderToViewReports;
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

  String _formatOrderId(String orderId) {
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

  String _getDeliveryStatusText(BuildContext context, String deliveryStatus) {
    final l10n = AppLocalizations.of(context)!;
    switch (deliveryStatus) {
      case 'pending':
        return l10n.pendingDelivery;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.deliveryCancelled;
      default:
        return l10n.pendingDelivery;
    }
  }

  Color _getDeliveryStatusColor(String deliveryStatus) {
    switch (deliveryStatus) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildServicesDisplay(Order order, AppLocalizations l10n) {
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
      l10n.noServices,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
