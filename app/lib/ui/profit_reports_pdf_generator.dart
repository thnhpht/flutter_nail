import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../generated/l10n/app_localizations.dart';
import '../config/salon_config.dart';
import '../api_client.dart';
import '../models.dart';
import 'design_system.dart';

// Conditional import cho web
import 'web_profit_reports_download_helper.dart'
    if (dart.library.io) 'web_profit_reports_download_helper_stub.dart';

class ProfitReportsPdfGenerator {
  static pw.Font? _vietnameseFont;
  static pw.Font? _vietnameseFontBold;

  static Future<void> generateAndShareProfitReports({
    required BuildContext context,
    required double totalImportedAmount,
    required double totalSoldAmount,
    required double profit,
    DateTimeRange? dateRange,
    required ApiClient api,
  }) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Lấy thông tin salon từ database
      Information? salonInfo;
      try {
        salonInfo = await api.getInformation();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading salon info for PDF: $e');
        }
      }

      // Tạo PDF
      final pdf = await _createProfitReportsPdf(
        context: context,
        totalImportedAmount: totalImportedAmount,
        totalSoldAmount: totalSoldAmount,
        profit: profit,
        dateRange: dateRange,
        salonInfo: salonInfo,
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _saveProfitReportsPdf(context, pdf);
      } catch (e) {
        // Nếu không thể lưu file, sử dụng bytes trực tiếp
        pdfBytes = await pdf.save();
      }

      // Đóng loading dialog
      Navigator.of(context).pop();

      // Kiểm tra platform và sử dụng phương thức phù hợp
      if (kIsWeb) {
        // Trên web: download file PDF với file picker
        await downloadProfitReportsPdfOnWeb(
            context, pdfBytes ?? await pdf.save());
      } else {
        // Trên mobile: chia sẻ file
        await _shareProfitReportsFile(context, file, pdfBytes);
      }

      // Hiển thị thông báo thành công
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.exportProfitReportsSuccess,
          type: MessageType.success);
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hiển thị thông báo lỗi
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.exportProfitReportsError,
          type: MessageType.error);
    }
  }

  static Future<pw.Document> _createProfitReportsPdf({
    required BuildContext context,
    required double totalImportedAmount,
    required double totalSoldAmount,
    required double profit,
    DateTimeRange? dateRange,
    Information? salonInfo,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // Load fonts
    await _loadFonts();

    final pdf = pw.Document();

    // Tạo header
    final header = _buildHeader(l10n, dateRange, salonInfo);

    // Tạo thống kê tổng quan
    final summary =
        _buildProfitSummary(l10n, totalImportedAmount, totalSoldAmount, profit);

    // Tạo phân tích chi tiết
    final analysis = _buildProfitAnalysis(
        l10n, totalImportedAmount, totalSoldAmount, profit);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) =>
            context.pageNumber == 1 ? header : pw.SizedBox.shrink(),
        footer: (context) => _buildFooter(context, l10n),
        build: (context) => [
          // Tiêu đề báo cáo
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  l10n.profitReports,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: _vietnameseFontBold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  l10n.profitAnalysis,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                    font: _vietnameseFont,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // Thống kê tổng quan
          summary,

          pw.SizedBox(height: 20),

          // Phân tích chi tiết
          analysis,
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
      AppLocalizations l10n, DateTimeRange? dateRange, Information? salonInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(),
      child: pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              salonInfo?.salonName ?? SalonConfig.salonName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: _vietnameseFontBold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            if ((salonInfo?.address ?? SalonConfig.salonAddress)
                .isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                salonInfo?.address ?? SalonConfig.salonAddress,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                  font: _vietnameseFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
            if ((salonInfo?.phone ?? SalonConfig.salonPhone).isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                salonInfo?.phone ?? SalonConfig.salonPhone,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                  font: _vietnameseFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildProfitSummary(
    AppLocalizations l10n,
    double totalImportedAmount,
    double totalSoldAmount,
    double profit,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tóm tắt lợi nhuận',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: _vietnameseFontBold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildSummaryItem(
                  'Tổng tiền nhập',
                  currencyFormat.format(totalImportedAmount),
                  PdfColors.red600,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildSummaryItem(
                  'Tổng tiền bán',
                  currencyFormat.format(totalSoldAmount),
                  PdfColors.blue600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            child: _buildSummaryItem(
              'Lợi nhuận',
              currencyFormat.format(profit),
              profit >= 0 ? PdfColors.green600 : PdfColors.red600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
      String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
              font: _vietnameseFont,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
              font: _vietnameseFontBold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfitAnalysis(
    AppLocalizations l10n,
    double totalImportedAmount,
    double totalSoldAmount,
    double profit,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Phân tích chi tiết',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: _vietnameseFontBold,
            ),
          ),
          pw.SizedBox(height: 12),

          // Bảng phân tích
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Chỉ số', isHeader: true),
                  _buildTableCell('Giá trị', isHeader: true),
                  _buildTableCell('Ghi chú', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('Tổng tiền nhập'),
                  _buildTableCell(currencyFormat.format(totalImportedAmount)),
                  _buildTableCell('Chi phí đầu vào'),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('Tổng tiền bán'),
                  _buildTableCell(currencyFormat.format(totalSoldAmount)),
                  _buildTableCell('Doanh thu'),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('Lợi nhuận'),
                  _buildTableCell(currencyFormat.format(profit)),
                  _buildTableCell(profit >= 0 ? 'Có lãi' : 'Bị lỗ'),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Kết luận
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: profit >= 0 ? PdfColors.green50 : PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: profit >= 0 ? PdfColors.green200 : PdfColors.red200,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    profit >= 0
                        ? 'Cửa hàng đang hoạt động có lãi ${currencyFormat.format(profit)}'
                        : 'Cửa hàng đang bị lỗ ${currencyFormat.format(profit.abs())}, cần xem xét lại chiến lược kinh doanh',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color:
                          profit >= 0 ? PdfColors.green700 : PdfColors.red700,
                      font: _vietnameseFont,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.grey700,
          font: isHeader ? _vietnameseFontBold : _vietnameseFont,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${l10n.page} ${context.pageNumber}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              font: _vietnameseFont,
            ),
          ),
          pw.Text(
            '${l10n.generatedOn}: ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              font: _vietnameseFont,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _loadFonts() async {
    if (_vietnameseFont == null) {
      final fontData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      _vietnameseFont = pw.Font.ttf(fontData);
    }

    if (_vietnameseFontBold == null) {
      final fontBoldData =
          await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      _vietnameseFontBold = pw.Font.ttf(fontBoldData);
    }
  }

  static Future<File> _saveProfitReportsPdf(
      BuildContext context, pw.Document pdf) async {
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/profit_reports_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> _shareProfitReportsFile(
      BuildContext context, File? file, Uint8List? pdfBytes) async {
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${AppLocalizations.of(context)!.profitReports} - ${SalonConfig.salonName}',
      );
    } else if (pdfBytes != null) {
      // Fallback: tạo file tạm thời
      final directory = await getTemporaryDirectory();
      final tempFile = File('${directory.path}/profit_reports_temp.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text:
            '${AppLocalizations.of(context)!.profitReports} - ${SalonConfig.salonName}',
      );
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
