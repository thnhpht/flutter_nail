import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../config/salon_config.dart';
import '../api_client.dart';
import 'design_system.dart';
import '../generated/l10n/app_localizations.dart';

// Conditional import cho web
import 'web_inventory_reports_download_helper.dart'
    if (dart.library.io) 'web_inventory_reports_download_helper_stub.dart';

class InventoryReportsPdfGenerator {
  static pw.Font? _vietnameseFont;
  static pw.Font? _vietnameseFontBold;

  static Future<void> generateAndShareInventoryReports({
    required BuildContext context,
    required List<ServiceInventory> inventoryData,
    required List<Service> services,
    required ApiClient api,
    String? salonName,
    String? salonAddress,
    String? salonPhone,
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

      // Sử dụng thông tin từ database hoặc fallback về tham số truyền vào hoặc SalonConfig
      final displaySalonName =
          salonInfo?.salonName ?? salonName ?? SalonConfig.salonName;
      final displaySalonAddress =
          salonInfo?.address ?? salonAddress ?? SalonConfig.salonAddress;
      final displaySalonPhone =
          salonInfo?.phone ?? salonPhone ?? SalonConfig.salonPhone;

      // Tạo PDF
      final pdf = await _createInventoryReportsPdf(
        context: context,
        inventoryData: inventoryData,
        services: services,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _saveInventoryReportsPdf(context, pdf);
      } catch (e) {
        // Nếu không thể lưu file, sử dụng bytes trực tiếp
        pdfBytes = await pdf.save();
      }

      // Đóng loading dialog
      Navigator.of(context).pop();

      // Kiểm tra platform và sử dụng phương thức phù hợp
      if (kIsWeb) {
        // Trên web: download file PDF với file picker
        await downloadInventoryReportsPdfOnWeb(
            context, pdfBytes ?? await pdf.save());
      } else {
        // Trên mobile: chia sẻ file
        await _shareInventoryReportsFile(context, file, pdfBytes,
            salonName: displaySalonName);
      }

      // Hiển thị thông báo thành công
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.exportInventoryReportsSuccess,
          type: MessageType.success);
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hiển thị thông báo lỗi
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.exportInventoryReportsError,
          type: MessageType.error);
    }
  }

  static Future<pw.Document> _createInventoryReportsPdf({
    required BuildContext context,
    required List<ServiceInventory> inventoryData,
    required List<Service> services,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // Load fonts
    await _loadFonts();

    final pdf = pw.Document();

    // Tạo header
    final header = _buildHeader(salonName, salonAddress, salonPhone, l10n);

    // Tạo bảng dữ liệu
    final table = _buildInventoryTable(inventoryData, services, l10n);

    // Tạo thống kê tổng quan
    final summary = _buildSummarySection(inventoryData, l10n);

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
                  l10n.inventoryReports,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: _vietnameseFontBold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  l10n.inventoryStatisticsAndReports,
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

          // Bảng dữ liệu
          table,
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String salonName, String salonAddress,
      String salonPhone, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(),
      child: pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              salonName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: _vietnameseFontBold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            if (salonAddress.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                salonAddress,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                  font: _vietnameseFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
            if (salonPhone.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                salonPhone,
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

  static pw.Widget _buildSummarySection(
      List<ServiceInventory> inventoryData, AppLocalizations l10n) {
    final totalImported =
        inventoryData.fold(0, (sum, item) => sum + item.totalImported);
    final totalOrdered =
        inventoryData.fold(0, (sum, item) => sum + item.totalOrdered);
    final totalRemaining =
        inventoryData.fold(0, (sum, item) => sum + item.remainingQuantity);
    final outOfStockCount =
        inventoryData.where((item) => item.isOutOfStock).length;

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
            l10n.summary,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: _vietnameseFontBold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(l10n.totalImported, totalImported.toString(),
                  PdfColors.green),
              _buildSummaryItem(
                  l10n.totalOrdered, totalOrdered.toString(), PdfColors.blue),
              _buildSummaryItem(l10n.remainingQuantity,
                  totalRemaining.toString(), PdfColors.orange),
              _buildSummaryItem(
                  l10n.outOfStock, outOfStockCount.toString(), PdfColors.red),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color,
            font: _vietnameseFontBold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
            font: _vietnameseFont,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _buildInventoryTable(List<ServiceInventory> inventoryData,
      List<Service> services, AppLocalizations l10n) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Service Name
        1: const pw.FlexColumnWidth(1.5), // Imported
        2: const pw.FlexColumnWidth(1.5), // Ordered
        3: const pw.FlexColumnWidth(1.5), // Remaining
        4: const pw.FlexColumnWidth(1.5), // Status
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeaderCell(l10n.serviceName),
            _buildTableHeaderCell(l10n.imported),
            _buildTableHeaderCell(l10n.ordered),
            _buildTableHeaderCell(l10n.remaining),
            _buildTableHeaderCell(l10n.status),
          ],
        ),
        // Data rows
        ...inventoryData.map((inventory) {
          final service = services.firstWhere(
            (s) => s.id == inventory.serviceId,
            orElse: () => Service(
                id: '', categoryId: '', name: 'Unknown Service', price: 0),
          );

          return pw.TableRow(
            children: [
              _buildTableCell(service.name),
              _buildTableCell(inventory.totalImported.toString()),
              _buildTableCell(inventory.totalOrdered.toString()),
              _buildTableCell(inventory.remainingQuantity.toString()),
              _buildTableCell(
                inventory.isOutOfStock ? l10n.outOfStock : l10n.inStock,
                color: inventory.isOutOfStock ? PdfColors.red : PdfColors.green,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          font: _vietnameseFontBold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColors.black,
          font: _vietnameseFont,
        ),
        textAlign: pw.TextAlign.center,
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

  static Future<File> _saveInventoryReportsPdf(
      BuildContext context, pw.Document pdf) async {
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/inventory_reports_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> _shareInventoryReportsFile(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {required String salonName}) async {
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${AppLocalizations.of(context)!.inventoryReports} - $salonName',
      );
    } else if (pdfBytes != null) {
      // Fallback: tạo file tạm thời
      final directory = await getTemporaryDirectory();
      final tempFile = File('${directory.path}/inventory_reports_temp.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: '${AppLocalizations.of(context)!.inventoryReports} - $salonName',
      );
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Web helper function - được import từ web_inventory_reports_download_helper.dart
