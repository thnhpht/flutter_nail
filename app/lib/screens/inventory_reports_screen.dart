import '../generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import '../ui/inventory_reports_pdf_generator.dart';

class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen> {
  List<ServiceInventory> _inventoryData = [];
  List<Service> _services = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  String _sortBy =
      'serviceName'; // 'serviceName', 'totalImported', 'totalOrdered', 'remainingQuantity'
  bool _sortAscending = true;
  String? _selectedStockStatus; // 'all', 'inStock', 'outOfStock'

  // Thống kê tổng quan
  int _totalImported = 0;
  int _totalOrdered = 0;
  int _totalRemaining = 0;
  int _outOfStockCount = 0;

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
      final inventory = await widget.api.getServiceInventory();
      final services = await widget.api.getServices();

      setState(() {
        _inventoryData = inventory;
        _services = services;
        _isLoading = false;
      });

      _calculateStatistics();
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
    final filteredInventory = _getFilteredInventory();
    _totalImported =
        filteredInventory.fold(0, (sum, item) => sum + item.totalImported);
    _totalOrdered =
        filteredInventory.fold(0, (sum, item) => sum + item.totalOrdered);
    _totalRemaining =
        filteredInventory.fold(0, (sum, item) => sum + item.remainingQuantity);
    _outOfStockCount =
        filteredInventory.where((item) => item.isOutOfStock).length;
  }

  List<ServiceInventory> _getFilteredInventory() {
    List<ServiceInventory> filtered = _inventoryData;

    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final service = _services.firstWhere(
          (s) => s.id == item.serviceId,
          orElse: () => Service(id: '', categoryId: '', name: '', price: 0),
        );
        return service.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Áp dụng lọc theo trạng thái stock
    if (_selectedStockStatus != null && _selectedStockStatus != 'all') {
      filtered = filtered.where((item) {
        if (_selectedStockStatus == 'inStock') {
          return !item.isOutOfStock;
        } else if (_selectedStockStatus == 'outOfStock') {
          return item.isOutOfStock;
        }
        return true;
      }).toList();
    }

    // Sắp xếp
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'serviceName':
          final serviceA = _services.firstWhere(
            (s) => s.id == a.serviceId,
            orElse: () => Service(id: '', categoryId: '', name: '', price: 0),
          );
          final serviceB = _services.firstWhere(
            (s) => s.id == b.serviceId,
            orElse: () => Service(id: '', categoryId: '', name: '', price: 0),
          );
          comparison = serviceA.name.compareTo(serviceB.name);
          break;
        case 'totalImported':
          comparison = a.totalImported.compareTo(b.totalImported);
          break;
        case 'totalOrdered':
          comparison = a.totalOrdered.compareTo(b.totalOrdered);
          break;
        case 'remainingQuantity':
          comparison = a.remainingQuantity.compareTo(b.remainingQuantity);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
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
        _calculateStatistics();
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _calculateStatistics();
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
        _calculateStatistics();
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

  Future<void> _exportInventoryReports() async {
    final filteredInventory = _getFilteredInventory();

    if (filteredInventory.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.noDataToExport,
          type: MessageType.warning);
      return;
    }

    await InventoryReportsPdfGenerator.generateAndShareInventoryReports(
      context: context,
      inventoryData: filteredInventory,
      services: _services,
      api: widget.api,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredInventory = _getFilteredInventory();

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
                  onPressed: _exportInventoryReports,
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
                    icon: Icons.inventory_2,
                    title: l10n.inventoryReports,
                    subtitle: l10n.inventoryStatisticsAndReports,
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
                          _calculateStatistics();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: l10n.searchServices,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _calculateStatistics();
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

                  const SizedBox(height: AppTheme.spacingL),

                  // Sort Options
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: AppTheme.inputDecoration(
                              label: l10n.sortBy,
                              prefixIcon: Icons.sort,
                            ).copyWith(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            value: _sortBy,
                            items: [
                              DropdownMenuItem<String>(
                                value: 'serviceName',
                                child: Text(l10n.serviceName),
                              ),
                              DropdownMenuItem<String>(
                                value: 'totalImported',
                                child: Text(l10n.totalImported),
                              ),
                              DropdownMenuItem<String>(
                                value: 'totalOrdered',
                                child: Text(l10n.totalOrdered),
                              ),
                              DropdownMenuItem<String>(
                                value: 'remainingQuantity',
                                child: Text(l10n.remainingQuantity),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                _sortBy = value!;
                                _calculateStatistics();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                              _calculateStatistics();
                            });
                          },
                          icon: Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: AppTheme.primaryStart,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Stock Status Filter
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: DropdownButtonFormField<String>(
                      decoration: AppTheme.inputDecoration(
                        label: l10n.stockStatus,
                        prefixIcon: Icons.inventory_2,
                      ).copyWith(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      value: _selectedStockStatus,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child:
                              Text(AppLocalizations.of(context)!.allStatuses),
                        ),
                        DropdownMenuItem<String>(
                          value: 'inStock',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(l10n.inStock),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'outOfStock',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(l10n.outOfStock),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedStockStatus = value;
                          _calculateStatistics();
                        });
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

                  // Danh sách sản lượng
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryStart),
                      ),
                    )
                  else if (filteredInventory.isEmpty)
                    _buildEmptyState(l10n)
                  else
                    ...filteredInventory.asMap().entries.map((entry) {
                      final index = entry.key;
                      final inventory = entry.value;
                      return AppWidgets.animatedItem(
                        index: index,
                        child: _buildInventoryCard(inventory, l10n),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.totalImported,
                  value: _totalImported.toString(),
                  icon: Icons.add_box,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.totalOrdered,
                  value: _totalOrdered.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.remainingQuantity,
                  value: _totalRemaining.toString(),
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.outOfStock,
                  value: _outOfStockCount.toString(),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
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

  Widget _buildInventoryCard(
      ServiceInventory inventory, AppLocalizations l10n) {
    final service = _services.firstWhere(
      (s) => s.id == inventory.serviceId,
      orElse: () =>
          Service(id: '', categoryId: '', name: 'Unknown Service', price: 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            // Có thể thêm action khi tap vào inventory card
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
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (service.unit != null && service.unit!.isNotEmpty)
                            Text(
                              '${l10n.unit}: ${service.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: inventory.isOutOfStock
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: inventory.isOutOfStock
                              ? Colors.red.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        inventory.isOutOfStock ? l10n.outOfStock : l10n.inStock,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: inventory.isOutOfStock
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingM),

                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.add_box,
                        label: l10n.imported,
                        value: inventory.totalImported.toString(),
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.shopping_cart,
                        label: l10n.ordered,
                        value: inventory.totalOrdered.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.inventory,
                        label: l10n.remaining,
                        value: inventory.remainingQuantity.toString(),
                        color: Colors.orange,
                      ),
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Text(
            l10n.noInventoryData,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            l10n.addServiceDetailsToViewInventory,
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
