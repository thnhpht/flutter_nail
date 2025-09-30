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
import 'web_reports_download_helper.dart'
    if (dart.library.io) 'web_reports_download_helper_stub.dart';

class ReportsPdfGenerator {
  static pw.Font? _vietnameseFont;
  static pw.Font? _vietnameseFontBold;

  static Future<void> generateAndShareReports({
    required BuildContext context,
    required List<Order> orders,
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
      final pdf = await _createReportsPdf(
        context: context,
        orders: orders,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _saveReportsPdf(context, pdf);
      } catch (e) {
        // Nếu không thể lưu file, sử dụng bytes trực tiếp
        pdfBytes = await pdf.save();
      }

      // Đóng loading dialog
      Navigator.of(context).pop();

      // Kiểm tra platform và sử dụng phương thức phù hợp
      if (kIsWeb) {
        // Trên web: download file PDF với file picker
        await downloadReportsPdfOnWeb(context, pdfBytes ?? await pdf.save());
      } else {
        // Trên mobile: chia sẻ file
        await _shareReportsFile(context, file, pdfBytes,
            salonName: displaySalonName);
      }

      // Hiển thị thông báo thành công
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.exportReportsSuccess,
          type: MessageType.success);
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hiển thị thông báo lỗi chi tiết hơn
      String errorMessage =
          AppLocalizations.of(context)!.exportReportsError(e.toString());
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = AppLocalizations.of(context)!.pdfErrorPluginNotSupported;
      }

      AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
    }
  }

  static Future<void> _loadVietnameseFont() async {
    if (_vietnameseFont == null || _vietnameseFontBold == null) {
      // Trên Flutter Web, vẫn cần load font từ assets để hỗ trợ tiếng Việt
      if (kIsWeb) {
        try {
          // Ưu tiên Noto Sans (hỗ trợ tiếng Việt tốt nhất)
          final fontData =
              await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
          _vietnameseFont = pw.Font.ttf(fontData);

          if (kDebugMode) {
            print('Successfully loaded Noto Sans Regular for web PDF');
          }

          // Thử load Noto Sans Bold
          try {
            final fontBoldData =
                await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
            _vietnameseFontBold = pw.Font.ttf(fontBoldData);

            if (kDebugMode) {
              print('Successfully loaded Noto Sans Bold for web PDF');
            }
          } catch (e) {
            // Nếu không có bold, sử dụng regular font
            _vietnameseFontBold = _vietnameseFont;
            if (kDebugMode) {
              print('Failed to load Noto Sans Bold, using Regular: $e');
            }
          }
          return;
        } catch (e) {
          if (kDebugMode) {
            print('Failed to load Noto Sans Regular for web PDF: $e');
          }
          // Fallback cho web: sử dụng DejaVu Sans
          try {
            final fontData =
                await rootBundle.load('assets/fonts/DejaVuSans.ttf');
            _vietnameseFont = pw.Font.ttf(fontData);
            _vietnameseFontBold = pw.Font.ttf(fontData);

            if (kDebugMode) {
              print('Successfully loaded DejaVu Sans as fallback for web PDF');
            }
            return;
          } catch (e1) {
            if (kDebugMode) {
              print('Failed to load DejaVu Sans, using system fonts: $e1');
            }
            // Cuối cùng: sử dụng font system
            _vietnameseFont = pw.Font.helvetica();
            _vietnameseFontBold = pw.Font.helveticaBold();
            return;
          }
        }
      }

      try {
        // Ưu tiên Noto Sans (hỗ trợ tiếng Việt tốt nhất)
        final fontData =
            await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        _vietnameseFont = pw.Font.ttf(fontData);

        // Thử load Noto Sans Bold
        try {
          final fontBoldData =
              await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
          _vietnameseFontBold = pw.Font.ttf(fontBoldData);
        } catch (e) {
          // Nếu không có bold, sử dụng regular font
          _vietnameseFontBold = _vietnameseFont;
        }
      } catch (e) {
        try {
          // Fallback: thử DejaVu Sans (hỗ trợ Unicode tốt)
          final fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
          _vietnameseFont = pw.Font.ttf(fontData);
          _vietnameseFontBold = pw.Font.ttf(fontData);
        } catch (e1) {
          try {
            // Fallback: thử Liberation Sans
            final fontData = await rootBundle
                .load('assets/fonts/LiberationSans-Regular.ttf');
            _vietnameseFont = pw.Font.ttf(fontData);
            _vietnameseFontBold = pw.Font.ttf(fontData);
          } catch (e2) {
            try {
              // Fallback: thử OpenSans
              final fontData =
                  await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
              _vietnameseFont = pw.Font.ttf(fontData);
              _vietnameseFontBold = pw.Font.ttf(fontData);
            } catch (e3) {
              try {
                // Fallback: thử Roboto
                final fontData =
                    await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
                _vietnameseFont = pw.Font.ttf(fontData);
                _vietnameseFontBold = pw.Font.ttf(fontData);
              } catch (e4) {
                // Cuối cùng: sử dụng font mặc định với fallback tốt hơn
                _vietnameseFont = pw.Font.helvetica();
                _vietnameseFontBold = pw.Font.helveticaBold();
              }
            }
          }
        }
      }
    }
  }

  static pw.TextStyle _getVietnameseTextStyle({
    double fontSize = 14,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
    pw.FontStyle fontStyle = pw.FontStyle.normal,
  }) {
    // Chọn font phù hợp dựa trên fontWeight
    pw.Font? selectedFont;
    if (fontWeight == pw.FontWeight.bold && _vietnameseFontBold != null) {
      selectedFont = _vietnameseFontBold;
    } else {
      selectedFont = _vietnameseFont;
    }

    // Tạo font fallback tốt hơn cho tiếng Việt
    List<pw.Font> fontFallback = [];

    // Sử dụng font fallback tốt hơn cho tiếng Việt trên tất cả platforms
    fontFallback = [
      pw.Font.helvetica(),
      pw.Font.times(),
      pw.Font.courier(),
    ];

    return pw.TextStyle(
      font: selectedFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      fontFallback: fontFallback,
    );
  }

  static Future<pw.Document> _createReportsPdf({
    required BuildContext context,
    required List<Order> orders,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
  }) async {
    // Load font hỗ trợ tiếng Việt
    await _loadVietnameseFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context pdfContext) {
          return [
            // Header - Salon Info
            _buildSalonHeader(context, salonName, salonAddress, salonPhone),

            pw.SizedBox(height: 20),

            // Orders Table
            _buildOrdersTable(context, orders),

            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(context),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSalonHeader(BuildContext context, String salonName,
      String salonAddress, String salonPhone) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            salonName,
            style: _getVietnameseTextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            salonAddress,
            style: _getVietnameseTextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _formatPhoneNumber(salonPhone),
            style: _getVietnameseTextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrdersTable(BuildContext context, List<Order> orders) {
    final l10n = AppLocalizations.of(context)!;

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    l10n.billCode,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    l10n.customerName,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    l10n.customerPhone,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    l10n.customerAddress,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    l10n.totalAmount,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...orders
              .map((order) => _buildOrderRow(context, order, isLast: false))
              .toList(),

          // Total Payment Row
          _buildTotalPaymentRow(context, orders),
        ],
      ),
    );
  }

  static pw.Widget _buildOrderRow(BuildContext context, Order order,
      {bool isLast = false}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '#${_formatOrderId(order.id)}',
              style: _getVietnameseTextStyle(
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              order.customerName,
              style: _getVietnameseTextStyle(
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatPhoneNumber(order.customerPhone),
              style: _getVietnameseTextStyle(
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              order.customerAddress ?? '-',
              style: _getVietnameseTextStyle(
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatPrice(order.totalPrice),
              style: _getVietnameseTextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalPaymentRow(
      BuildContext context, List<Order> orders) {
    final l10n = AppLocalizations.of(context)!;
    final totalAmount =
        orders.fold(0.0, (sum, order) => sum + order.totalPrice);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(8),
          bottomRight: pw.Radius.circular(8),
        ),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 8,
            child: pw.Text(
              l10n.totalPayment,
              style: _getVietnameseTextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _formatPrice(totalAmount),
              style: _getVietnameseTextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            l10n.pdfThankYouMessage,
            style: _getVietnameseTextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.pdfSeeYouAgainMessage,
            style: _getVietnameseTextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Future<File> _saveReportsPdf(
      BuildContext context, pw.Document pdf) async {
    try {
      // Thử sử dụng path_provider trước
      final output = await getTemporaryDirectory();
      final fileName = 'BaoCao_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');

      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      // Fallback: sử dụng thư mục hiện tại nếu path_provider không hoạt động
      if (kDebugMode) {
        print('path_provider failed, using fallback: $e');
      }

      final fileName = 'BaoCao_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(fileName);

      await file.writeAsBytes(await pdf.save());
      return file;
    }
  }

  static Future<void> _shareReportsFile(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    try {
      // Kiểm tra platform và sử dụng phương pháp phù hợp
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await _shareReportsFileDesktop(context, file, pdfBytes,
            salonName: salonName);
      } else {
        await _shareReportsFileMobile(context, file, pdfBytes,
            salonName: salonName);
      }
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.exportReportsError(e.toString()),
          type: MessageType.error);
    }
  }

  static Future<void> _shareReportsFileMobile(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    try {
      if (file != null && await file.exists()) {
        // Sử dụng file nếu có
        await Share.shareXFiles(
          [XFile(file.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
        );
      } else if (pdfBytes != null) {
        // Sử dụng bytes trực tiếp nếu không có file
        final tempFile = File('temp_reports.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
        );

        // Xóa file tạm
        try {
          await tempFile.delete();
        } catch (e) {
          return;
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.pdfErrorNoFileData);
      }
    } catch (e) {
      // Nếu không thể chia sẻ, hiển thị thông báo
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.exportReportsError(e.toString()),
          type: MessageType.error);
    }
  }

  static Future<void> _shareReportsFileDesktop(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    // Trên desktop, sử dụng phương pháp khác
    try {
      // Thử sử dụng share_plus trước
      if (file != null && await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
        );
      } else if (pdfBytes != null) {
        final tempFile = File('temp_reports.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
        );

        // Xóa file tạm
        try {
          await tempFile.delete();
        } catch (e) {
          return;
        }
      }
    } catch (e) {
      // Nếu share_plus không hoạt động, hiển thị thông báo
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.pdfFileCreatedManualShare,
          type: MessageType.info);
    }
  }

  static String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        )} ${SalonConfig.currency}';
  }

  static String _formatOrderId(String orderId) {
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

  static String _formatPhoneNumber(String phoneNumber) {
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
}
