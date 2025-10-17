import '../generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import '../ui/profit_reports_pdf_generator.dart';

class ProfitReportsScreen extends StatefulWidget {
  const ProfitReportsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ProfitReportsScreen> createState() => _ProfitReportsScreenState();
}

class _ProfitReportsScreenState extends State<ProfitReportsScreen> {
  List<ServiceDetails> _serviceDetails = [];
  List<Order> _orders = [];
  List<Service> _services = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  // Thống kê lợi nhuận toàn bộ (không xét thời gian)
  double _totalImportedAmountAll = 0.0;
  double _totalSoldAmountAll = 0.0;
  double _profitAll = 0.0;

  // Thống kê lợi nhuận theo thời gian được chọn
  double _totalImportedAmount = 0.0;
  double _totalSoldAmount = 0.0;
  double _profit = 0.0;

  // Chi tiết theo ngày (khi chọn khoảng thời gian > 1 ngày)
  List<Map<String, dynamic>> _dailyBreakdown = [];

  @override
  void initState() {
    super.initState();
    // Mặc định chọn hôm nay (bắt đầu từ 00:00 để bao phủ cả ngày)
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
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
      final serviceDetails = await widget.api.getServiceDetails();
      final services = await widget.api.getServices();

      setState(() {
        _orders = orders;
        _serviceDetails = serviceDetails;
        _services = services;
        _isLoading = false;
      });

      _calculateProfitStatistics();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.errorLoadingData(e.toString()),
          type: MessageType.error);
    }
  }

  void _calculateProfitStatistics() {
    // Tính tổng tiền nhập và bán toàn bộ (không xét thời gian)
    _totalImportedAmountAll = 0.0;
    _totalSoldAmountAll = 0.0;

    // Tính tổng tiền nhập toàn bộ
    for (final serviceDetail in _serviceDetails) {
      _totalImportedAmountAll +=
          (serviceDetail.importPrice * serviceDetail.quantity);
    }

    // Tính tổng tiền bán toàn bộ
    final Map<String, double> servicePriceById = {
      for (final s in _services) s.id: s.price
    };

    for (final order in _orders) {
      double orderLineTotal = 0.0;
      final int lineCount = order.serviceIds.length;
      for (int i = 0; i < lineCount; i++) {
        final String serviceId = order.serviceIds[i];
        final int quantity = (i < order.serviceQuantities.length)
            ? order.serviceQuantities[i]
            : 1;
        final double unitPrice = servicePriceById[serviceId] ?? 0.0;
        orderLineTotal += unitPrice * quantity;
      }
      _totalSoldAmountAll += orderLineTotal;
    }

    // Tính lợi nhuận toàn bộ
    _profitAll = _totalSoldAmountAll - _totalImportedAmountAll;

    // Tính tổng tiền nhập theo thời gian được chọn
    // Dựa trên số lượng thực tế đã bán được trong khoảng thời gian
    _totalImportedAmount = 0.0;
    _totalSoldAmount = 0.0;

    // Tạo map để theo dõi số lượng đã bán của từng service
    final Map<String, int> soldQuantityByService = {};

    // Tính tổng tiền bán và thu thập số lượng bán theo thời gian
    for (final order in _orders) {
      if (_selectedDateRange != null) {
        final orderDate = order.createdAt;
        if (orderDate.isBefore(_selectedDateRange!.start) ||
            orderDate.isAfter(
                _selectedDateRange!.end.add(const Duration(days: 1)))) {
          continue;
        }
      }

      // Tính tổng tiền bán và thu thập số lượng bán
      double orderLineTotal = 0.0;
      final int lineCount = order.serviceIds.length;
      for (int i = 0; i < lineCount; i++) {
        final String serviceId = order.serviceIds[i];
        final int quantity = (i < order.serviceQuantities.length)
            ? order.serviceQuantities[i]
            : 1;
        final double unitPrice = servicePriceById[serviceId] ?? 0.0;
        orderLineTotal += unitPrice * quantity;

        // Thu thập số lượng bán cho từng service
        soldQuantityByService[serviceId] =
            (soldQuantityByService[serviceId] ?? 0) + quantity;
      }

      _totalSoldAmount += orderLineTotal;
    }

    // Tính tổng tiền nhập dựa trên số lượng thực tế đã bán
    // Sử dụng cùng logic với _calculateDailyBreakdown()
    final Map<String, Map<DateTime, double>> importPricesByServiceAndDate = {};

    // Thu thập giá nhập theo ngày cho từng service
    // Lưu ý: Không lọc theo thời gian để có thể tìm giá nhập cuối cùng trước đó
    for (final serviceDetail in _serviceDetails) {
      final serviceId = serviceDetail.serviceId;
      final importDate = DateTime(serviceDetail.importDate.year,
          serviceDetail.importDate.month, serviceDetail.importDate.day);

      if (!importPricesByServiceAndDate.containsKey(serviceId)) {
        importPricesByServiceAndDate[serviceId] = {};
      }
      importPricesByServiceAndDate[serviceId]![importDate] =
          serviceDetail.importPrice;
    }

    // Tính chi tiết theo ngày trước (nếu khoảng thời gian > 1 ngày)
    _calculateDailyBreakdown();

    // Tính tổng tiền nhập từ daily breakdown để đảm bảo tính chính xác
    _totalImportedAmount = 0.0;
    if (_dailyBreakdown.isNotEmpty) {
      // Nếu có chi tiết theo ngày, tính tổng từ đó
      for (final dayData in _dailyBreakdown) {
        _totalImportedAmount += (dayData['importedAmount'] as double);
      }
    } else {
      // Nếu không có chi tiết theo ngày (khoảng thời gian <= 1 ngày), tính trực tiếp
      // Sử dụng logic tương tự _calculateDailyBreakdown() nhưng cho 1 ngày
      final targetDay = _selectedDateRange?.start ?? DateTime.now();

      for (final serviceId in soldQuantityByService.keys) {
        final soldQuantity = soldQuantityByService[serviceId]!;

        // Tìm giá nhập cho service này trong ngày này hoặc ngày gần nhất trước đó
        double? importPrice = _findLatestImportPrice(
            serviceId, targetDay, importPricesByServiceAndDate);

        if (importPrice != null && soldQuantity > 0) {
          _totalImportedAmount += (importPrice * soldQuantity);
        }
      }
    }

    // Tính lợi nhuận theo thời gian
    _profit = _totalSoldAmount - _totalImportedAmount;
  }

  void _calculateDailyBreakdown() {
    _dailyBreakdown.clear();

    if (_selectedDateRange == null) return;

    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;
    final daysDifference = endDate.difference(startDate).inDays;

    // Chỉ tính chi tiết khi khoảng thời gian > 1 ngày
    if (daysDifference <= 1) return;

    // Map nhanh từ serviceId -> price để tính dòng chi tiết
    final Map<String, double> servicePriceById = {
      for (final s in _services) s.id: s.price
    };

    // Tạo danh sách các ngày trong khoảng thời gian
    final List<DateTime> daysInRange = [];
    for (int i = 0; i <= daysDifference; i++) {
      daysInRange
          .add(DateTime(startDate.year, startDate.month, startDate.day + i));
    }

    // Tạo map để lưu giá nhập theo service và ngày
    final Map<String, Map<DateTime, double>> importPricesByServiceAndDate = {};

    // Thu thập giá nhập theo ngày cho từng service
    // Lưu ý: Không lọc theo thời gian để có thể tìm giá nhập cuối cùng trước đó
    for (final serviceDetail in _serviceDetails) {
      final serviceId = serviceDetail.serviceId;
      final importDate = DateTime(serviceDetail.importDate.year,
          serviceDetail.importDate.month, serviceDetail.importDate.day);

      if (!importPricesByServiceAndDate.containsKey(serviceId)) {
        importPricesByServiceAndDate[serviceId] = {};
      }
      importPricesByServiceAndDate[serviceId]![importDate] =
          serviceDetail.importPrice;
    }

    // Tính toán cho từng ngày
    for (final day in daysInRange) {
      double dayImportedAmount = 0.0;
      double daySoldAmount = 0.0;

      // Thu thập số lượng bán trong ngày này
      final Map<String, int> soldQuantityByService = {};

      for (final order in _orders) {
        final orderDate = DateTime(
            order.createdAt.year, order.createdAt.month, order.createdAt.day);
        if (orderDate.isAtSameMomentAs(day)) {
          final int lineCount = order.serviceIds.length;
          for (int i = 0; i < lineCount; i++) {
            final String serviceId = order.serviceIds[i];
            final int quantity = (i < order.serviceQuantities.length)
                ? order.serviceQuantities[i]
                : 1;

            soldQuantityByService[serviceId] =
                (soldQuantityByService[serviceId] ?? 0) + quantity;

            // Tính tổng tiền bán
            final double unitPrice = servicePriceById[serviceId] ?? 0.0;
            daySoldAmount += unitPrice * quantity;
          }
        }
      }

      // Tính tổng tiền nhập cho ngày này
      for (final serviceId in soldQuantityByService.keys) {
        final soldQuantity = soldQuantityByService[serviceId]!;

        // Tìm giá nhập cho service này trong ngày này hoặc ngày gần nhất trước đó
        double? importPrice = _findLatestImportPrice(
            serviceId, day, importPricesByServiceAndDate);

        if (importPrice != null) {
          dayImportedAmount += importPrice * soldQuantity;
        }
      }

      final dayProfit = daySoldAmount - dayImportedAmount;

      _dailyBreakdown.add({
        'date': day,
        'importedAmount': dayImportedAmount,
        'soldAmount': daySoldAmount,
        'profit': dayProfit,
      });
    }
  }

  double? _findLatestImportPrice(String serviceId, DateTime targetDate,
      Map<String, Map<DateTime, double>> importPricesByServiceAndDate) {
    if (!importPricesByServiceAndDate.containsKey(serviceId)) {
      return null;
    }

    final serviceImportPrices = importPricesByServiceAndDate[serviceId]!;

    // Tìm giá nhập gần nhất (trong hoặc trước targetDate)
    DateTime? latestDate;
    for (final date in serviceImportPrices.keys) {
      if (date.isBefore(targetDate) || date.isAtSameMomentAs(targetDate)) {
        if (latestDate == null || date.isAfter(latestDate)) {
          latestDate = date;
        }
      }
    }

    return latestDate != null ? serviceImportPrices[latestDate] : null;
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
      });
      _calculateProfitStatistics();
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    _calculateProfitStatistics();
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
      _calculateProfitStatistics();
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

  Future<void> _exportProfitReports() async {
    if (_totalImportedAmount == 0 && _totalSoldAmount == 0) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.noDataToExport,
          type: MessageType.warning);
      return;
    }

    await ProfitReportsPdfGenerator.generateAndShareProfitReports(
      context: context,
      totalImportedAmount: _totalImportedAmount,
      totalSoldAmount: _totalSoldAmount,
      profit: _profit,
      dateRange: _selectedDateRange,
      api: widget.api,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
              // Print Reports Button
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
                  onPressed: _exportProfitReports,
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
                    icon: Icons.trending_up,
                    title: l10n.profitReports,
                    subtitle: l10n.profitAnalysis,
                    fullWidth: true,
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Date Range Info Display (only show when date range is selected)
                  if (_selectedDateRange != null) ...[
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
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Thống kê lợi nhuận
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryStart),
                      ),
                    )
                  else
                    Column(
                      children: [
                        _buildProfitSummaryCards(l10n),

                        // Hiển thị chi tiết từng ngày nếu có
                        if (_dailyBreakdown.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingXL),
                          _buildDailyBreakdown(l10n),
                        ],
                      ],
                    ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Biểu đồ phân tích
                  _buildProfitAnalysisChart(l10n),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitSummaryCards(AppLocalizations l10n) {
    return Container(
      child: Column(
        children: [
          // Tổng toàn bộ (không xét thời gian)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.all_inclusive,
                        color: Colors.grey[600], size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Tổng toàn bộ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfitCard(
                        title: 'Tổng nhập (toàn bộ)',
                        value:
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                .format(_totalImportedAmountAll),
                        icon: Icons.input,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _buildProfitCard(
                        title: 'Tổng bán (toàn bộ)',
                        value:
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                .format(_totalSoldAmountAll),
                        icon: Icons.sell,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildProfitCard(
                  title: 'Lợi nhuận (toàn bộ)',
                  value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(_profitAll),
                  icon: Icons.trending_up,
                  color: _profitAll >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Tổng theo thời gian được chọn
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryStart.withValues(alpha: 0.05),
                  AppTheme.primaryEnd.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryStart.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule,
                        color: AppTheme.primaryStart, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      _selectedDateRange != null
                          ? 'Tổng theo thời gian (${_formatDateRange()})'
                          : 'Tổng theo thời gian (hôm nay)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryStart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfitCard(
                        title: l10n.totalImportedAmount,
                        value:
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                .format(_totalImportedAmount),
                        icon: Icons.input,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: _buildProfitCard(
                        title: l10n.totalSoldAmount,
                        value:
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                .format(_totalSoldAmount),
                        icon: Icons.sell,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildProfitCard(
                  title: l10n.profit,
                  value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(_profit),
                  icon: Icons.trending_up,
                  color: _profit >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard({
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

  Widget _buildProfitAnalysisChart(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.primaryStart,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                l10n.revenueVsCost,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Biểu đồ thanh đơn giản
          _buildSimpleBarChart(l10n),

          const SizedBox(height: AppTheme.spacingL),

          // Thông tin chi tiết
          _buildDetailedAnalysis(l10n),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(AppLocalizations l10n) {
    // Sử dụng dữ liệu theo thời gian được chọn cho biểu đồ
    final combined = _totalImportedAmount + _totalSoldAmount;
    final importedFraction =
        combined > 0 ? (_totalImportedAmount / combined) : 0.0;
    final soldFraction = combined > 0 ? (_totalSoldAmount / combined) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Single combined stacked bar
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: combined > 0
                ? Row(
                    children: [
                      if (importedFraction > 0)
                        Expanded(
                          flex:
                              (importedFraction * 1000).round().clamp(1, 1000),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red[400]!,
                                  Colors.red[600]!,
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (soldFraction > 0)
                        Expanded(
                          flex: (soldFraction * 1000).round().clamp(1, 1000),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[300]!,
                                  Colors.blue[500]!,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Container(
                    color: Colors.grey[100],
                  ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingS),

        // Legend with amounts (responsive, avoids overflow)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendItem(
                color: Colors.red[500]!,
                label: '${l10n.totalImportedAmount}: ',
                amount: _totalImportedAmount,
                percent: importedFraction,
              ),
              _buildLegendItem(
                color: Colors.blue[500]!,
                label: '${l10n.totalSoldAmount}: ',
                amount: _totalSoldAmount,
                percent: soldFraction,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double amount,
    required double percent,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '(${(percent * 100).toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalysis(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: _profit >= 0
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: _profit >= 0
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _profit >= 0 ? Icons.trending_up : Icons.trending_down,
                color: _profit >= 0 ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Phân tích theo thời gian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _profit >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _profit >= 0
                ? 'Trong ${_selectedDateRange != null ? _formatDateRange() : 'hôm nay'}, cửa hàng có lãi ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_profit)}'
                : 'Trong ${_selectedDateRange != null ? _formatDateRange() : 'hôm nay'}, cửa hàng lỗ ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_profit.abs())}',
            style: TextStyle(
              fontSize: 12,
              color: _profit >= 0 ? Colors.green[600] : Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_day,
                color: AppTheme.primaryStart,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Chi tiết theo ngày',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Header của bảng
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ngày',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryStart,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tổng nhập',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryStart,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tổng bán',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryStart,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Lợi nhuận',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryStart,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingS),

          // Dữ liệu từng ngày
          ..._dailyBreakdown.map((dayData) => _buildDailyRow(dayData)),

          const SizedBox(height: AppTheme.spacingM),

          // Tổng kết
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'TỔNG CỘNG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                        .format(_totalImportedAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                        .format(_totalSoldAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                        .format(_profit),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _profit >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRow(Map<String, dynamic> dayData) {
    final DateTime date = dayData['date'];
    final double importedAmount = dayData['importedAmount'];
    final double soldAmount = dayData['soldAmount'];
    final double profit = dayData['profit'];

    final dateFormat = DateFormat('dd/MM/yyyy');
    final isToday = date.isAtSameMomentAs(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primaryStart.withValues(alpha: 0.05) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: isToday
            ? Border.all(color: AppTheme.primaryStart.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  dateFormat.format(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color:
                        isToday ? AppTheme.primaryStart : AppTheme.textPrimary,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryStart,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(importedAmount),
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(soldAmount),
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(profit),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: profit >= 0 ? Colors.green[600] : Colors.red[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
