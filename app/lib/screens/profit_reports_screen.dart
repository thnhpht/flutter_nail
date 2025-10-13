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
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  // Thống kê lợi nhuận
  double _totalImportedAmount = 0.0;
  double _totalSoldAmount = 0.0;
  double _profit = 0.0;

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
      final serviceDetails = await widget.api.getServiceDetails();

      setState(() {
        _orders = orders;
        _serviceDetails = serviceDetails;
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
    // Tính tổng tiền nhập (chi phí - dựa trên ServiceDetails.importPrice)
    _totalImportedAmount = 0.0;

    for (final serviceDetail in _serviceDetails) {
      // Áp dụng lọc theo thời gian nếu có
      if (_selectedDateRange != null) {
        final importDate = serviceDetail.importDate;
        if (importDate.isBefore(_selectedDateRange!.start) ||
            importDate.isAfter(
                _selectedDateRange!.end.add(const Duration(days: 1)))) {
          continue;
        }
      }
      _totalImportedAmount += serviceDetail.importPrice;
    }

    // Tính tổng tiền bán (dựa trên orders)
    _totalSoldAmount = 0.0;
    for (final order in _orders) {
      if (_selectedDateRange != null) {
        final orderDate = order.createdAt;
        if (orderDate.isBefore(_selectedDateRange!.start) ||
            orderDate.isAfter(
                _selectedDateRange!.end.add(const Duration(days: 1)))) {
          continue;
        }
      }
      _totalSoldAmount += order.totalPrice;
    }

    // Tính lợi nhuận
    _profit = _totalSoldAmount - _totalImportedAmount;
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
                    _buildProfitSummaryCards(l10n),

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
          Row(
            children: [
              Expanded(
                child: _buildProfitCard(
                  title: l10n.totalImportedAmount,
                  value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(_totalImportedAmount),
                  icon: Icons.input,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildProfitCard(
                  title: l10n.totalSoldAmount,
                  value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(_totalSoldAmount),
                  icon: Icons.sell,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildProfitCard(
            title: l10n.profit,
            value: NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                .format(_profit),
            icon: Icons.trending_up,
            color: _profit >= 0 ? Colors.green : Colors.red,
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
    final maxValue = [_totalImportedAmount, _totalSoldAmount]
        .reduce((a, b) => a > b ? a : b);
    final importedPercentage =
        maxValue > 0 ? (_totalImportedAmount / maxValue) : 0.0;
    final soldPercentage = maxValue > 0 ? (_totalSoldAmount / maxValue) : 0.0;

    return Column(
      children: [
        // Imported Amount Bar
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                l10n.totalImportedAmount,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: importedPercentage > 0.01
                    ? FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: importedPercentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(_totalImportedAmount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Sold Amount Bar
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                l10n.totalSoldAmount,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: soldPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(_totalSoldAmount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
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
                l10n.profitAnalysis,
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
                ? 'Cửa hàng đang có lãi ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_profit)}'
                : 'Cửa hàng đang lỗ ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_profit.abs())}',
            style: TextStyle(
              fontSize: 12,
              color: _profit >= 0 ? Colors.green[600] : Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }
}
