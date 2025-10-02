import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../config/salon_config.dart';
import '../api_client.dart';
import 'design_system.dart';
import '../generated/l10n/app_localizations.dart';

// Conditional import cho web
import 'web_download_helper.dart'
    if (dart.library.io) 'web_download_helper_stub.dart';

class PdfBillGenerator {
  static pw.Font? _vietnameseFont;
  static pw.Font? _vietnameseFontBold;

  static Future<void> generateAndShareBill({
    required BuildContext context,
    required Order order,
    required List<ServiceWithQuantity> services,
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
      final pdf = await _createPdf(
        context: context,
        order: order,
        services: services,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
        contact: salonInfo?.contact ?? '',
        thankYouMessage: salonInfo?.thankYouMessage ?? '',
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _savePdf(context, pdf, order);
      } catch (e) {
        // Nếu không thể lưu file, sử dụng bytes trực tiếp
        pdfBytes = await pdf.save();
      }

      // Đóng loading dialog
      Navigator.of(context).pop();

      // Hiển thị dialog chọn cách chia sẻ
      await _showShareOptions(context, file, pdfBytes, order.customerPhone,
          salonName: displaySalonName);
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hiển thị thông báo lỗi chi tiết hơn
      String errorMessage =
          AppLocalizations.of(context)!.pdfErrorCreating(e.toString());
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = AppLocalizations.of(context)!.pdfErrorPluginNotSupported;
      }

      AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
    }
  }

  // Phương thức mới để tự động gửi PDF tới Zalo hoặc download trên web
  static Future<void> generateAndSendToZalo({
    required BuildContext context,
    required Order order,
    required List<ServiceWithQuantity> services,
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
      final pdf = await _createPdf(
        context: context,
        order: order,
        services: services,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
        contact: salonInfo?.contact ?? '',
        thankYouMessage: salonInfo?.thankYouMessage ?? '',
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _savePdf(context, pdf, order);
      } catch (e) {
        // Nếu không thể lưu file, sử dụng bytes trực tiếp
        pdfBytes = await pdf.save();
        if (kDebugMode) {
          print('Using PDF bytes directly: $e');
        }
      }

      // Đóng loading dialog
      Navigator.of(context).pop();

      // Kiểm tra platform và sử dụng phương thức phù hợp
      if (kIsWeb) {
        // Trên web: download file PDF với file picker
        await downloadPdfOnWeb(context, pdfBytes ?? await pdf.save(), order,
            salonName: displaySalonName);
      } else {
        // Trên mobile: tự động gửi tới Zalo mà không hiển thị dialog
        await _shareDirectlyToZalo(context, file, pdfBytes, order.customerPhone,
            salonName: displaySalonName);
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hiển thị thông báo lỗi chi tiết hơn
      String errorMessage =
          AppLocalizations.of(context)!.pdfErrorCreating(e.toString());
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = AppLocalizations.of(context)!.pdfErrorPluginNotSupported;
      }

      AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
    }
  }

  // Phương thức chia sẻ tới Zalo với trải nghiệm tốt nhất có thể

  static Future<void> _shareDirectlyToZalo(BuildContext context, File? file,
      Uint8List? pdfBytes, String customerPhone,
      {String? salonName}) async {
    try {
      // Trên desktop, Zalo không hoạt động tốt, chuyển sang chia sẻ thông thường
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await _shareFileDirectly(context, file, pdfBytes, salonName: salonName);
        return;
      }

      // Trên mobile, thử mở Zalo trước
      final zaloUrl = 'zalo://chat?phone=$customerPhone';

      if (await canLaunchUrl(Uri.parse(zaloUrl))) {
        // Mở Zalo với LaunchMode.externalApplication để tránh dialog
        await launchUrl(
          Uri.parse(zaloUrl),
          mode: LaunchMode.externalApplication,
        );

        // Đợi Zalo mở
        await Future.delayed(const Duration(seconds: 2));

        // Hiển thị thông báo hướng dẫn người dùng
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.pdfZaloOpened,
            type: MessageType.info);
      } else {
        // Nếu không có Zalo, chia sẻ file thông thường
        await _shareFileDirectly(context, file, pdfBytes, salonName: salonName);
      }
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.pdfErrorSharingZalo(e.toString()),
          type: MessageType.error);

      // Fallback: chia sẻ file thông thường
      await _shareFileDirectly(context, file, pdfBytes, salonName: salonName);
    }
  }

  // Phương thức chia sẻ file trực tiếp mà không hiển thị dialog
  static Future<void> _shareFileDirectly(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    try {
      // Kiểm tra platform và sử dụng phương pháp phù hợp
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await _shareFileDesktopDirectly(context, file, pdfBytes,
            salonName: salonName);
      } else {
        await _shareFileMobileDirectly(context, file, pdfBytes,
            salonName: salonName);
      }
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.pdfErrorSharingFile(e.toString()),
          type: MessageType.error);
    }
  } // Chia sẻ file trên mobile mà không hiển thị dialog

  static Future<void> _shareFileMobileDirectly(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    // Thử gửi trực tiếp tới Zalo trước
    try {
      if (file != null && await file.exists()) {
        // Sử dụng file nếu có - chia sẻ với Zalo
        await Share.shareXFiles(
          [XFile(file.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
          subject: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
        );
      } else if (pdfBytes != null) {
        // Sử dụng bytes trực tiếp nếu không có file
        final tempFile = File('temp_bill.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
          subject: AppLocalizations.of(context)!
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
          AppLocalizations.of(context)!.pdfErrorCannotShare(e.toString()),
          type: MessageType.error);
    }
  }

  // Chia sẻ file trên desktop mà không hiển thị dialog
  static Future<void> _shareFileDesktopDirectly(
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
          subject: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
        );
      } else if (pdfBytes != null) {
        final tempFile = File('temp_bill.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: AppLocalizations.of(context)!
              .pdfBillFrom(salonName ?? SalonConfig.salonName),
          subject: AppLocalizations.of(context)!
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

  static Future<pw.Document> _createPdf({
    required BuildContext context,
    required Order order,
    required List<ServiceWithQuantity> services,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
    required String contact,
    required String thankYouMessage,
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
            _buildSalonHeader(
                context, salonName, salonAddress, salonPhone, order.id),

            pw.SizedBox(height: 6),

            // Customer Info
            _buildCustomerInfo(context, order),

            pw.SizedBox(height: 12),

            // Services - có thể cắt tự nhiên
            _buildServicesTable(context, services),

            pw.SizedBox(height: 12),

            // Total
            _buildTotalSection(context, order),

            pw.SizedBox(height: 12),

            // Contact Information
            _buildContactSection(context, contact, thankYouMessage),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSalonHeader(BuildContext context, String salonName,
      String salonAddress, String salonPhone, String orderId) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: pw.Column(
        children: [
          // Title luôn nằm giữa
          pw.Text(
            salonName,
            style: _getVietnameseTextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          // Order ID nằm ở dòng riêng, căn phải
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                _formatBillId(context, orderId),
                style: _getVietnameseTextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(BuildContext context, Order order) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Dòng đầu: TKH và SDT nằm cùng một hàng
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'TKH: ',
                      style: _getVietnameseTextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.TextSpan(
                      text: order.customerName,
                      style: _getVietnameseTextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: AppLocalizations.of(context)!.pdfPhoneLabel,
                      style: _getVietnameseTextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.TextSpan(
                      text: _formatPhoneNumber(order.customerPhone),
                      style: _getVietnameseTextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Địa chỉ (nếu có)
          if (order.customerAddress != null &&
              order.customerAddress!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: AppLocalizations.of(context)!.pdfAddressLabel,
                    style: _getVietnameseTextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.TextSpan(
                    text: order.customerAddress!,
                    style: _getVietnameseTextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildServicesTable(
      BuildContext context, List<ServiceWithQuantity> services) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(25), // TT
        1: const pw.FixedColumnWidth(200), // Tên sản phẩm (mở rộng)
        2: const pw.FixedColumnWidth(60), // Số lượng
        3: const pw.FixedColumnWidth(80), // Đơn giá
        4: const pw.FixedColumnWidth(80), // Thành tiền
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          children: [
            _buildTableCell(
              AppLocalizations.of(context)!.pdfSerialNumberHeader,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
            _buildTableCell(
              AppLocalizations.of(context)!.pdfProductNameHeader,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
            _buildTableCell(
              AppLocalizations.of(context)!.pdfQuantityHeader,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
            _buildTableCell(
              AppLocalizations.of(context)!.pdfUnitPriceHeader,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
            _buildTableCell(
              AppLocalizations.of(context)!.pdfTotalAmountHeader,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
          ],
        ),
        // Data rows
        ...services.asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;

          return pw.TableRow(
            children: [
              _buildTableCell(
                (index + 1).toString(),
                alignment: pw.TextAlign.center,
              ),
              _buildTableCell(
                service.service.name,
                alignment: pw.TextAlign.left,
              ),
              _buildTableCell(
                service.quantity.toString(),
                alignment: pw.TextAlign.center,
              ),
              _buildTableCell(
                _formatPrice(service.service.price),
                alignment: pw.TextAlign.center,
              ),
              _buildTableCell(
                _formatPrice(service.totalPrice),
                alignment: pw.TextAlign.center,
                isBold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign alignment = pw.TextAlign.left,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: _getVietnameseTextStyle(
          fontSize: 12,
          fontWeight:
              isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
        ),
        textAlign: alignment,
      ),
    );
  }

  static pw.Widget _buildTotalSection(BuildContext context, Order order) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: pw.Column(
          children: [
            // Original Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  AppLocalizations.of(context)!.pdfSubtotal,
                  style: _getVietnameseTextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  _formatPriceForPayment(_getOriginalTotal(order)),
                  style: _getVietnameseTextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),

            // Discount (if any)
            if (order.discountPercent > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppLocalizations.of(context)!
                        .pdfDiscount(order.discountPercent.toStringAsFixed(0)),
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    '-${_formatPriceForPayment(_getOriginalTotal(order) * order.discountPercent / 100)}',
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],

            // Tip (if any)
            if (order.tip > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppLocalizations.of(context)!.pdfTip,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    '+${_formatPriceForPayment(order.tip)}',
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],

            // Tax (if any)
            if (order.taxPercent > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppLocalizations.of(context)!.tax,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    '+${_formatPrice(_getTaxAmount(order))}',
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],

            // Shipping Fee (if any)
            if (order.shippingFee > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppLocalizations.of(context)!.shippingFee,
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    '+${_formatPriceForPayment(order.shippingFee)}',
                    style: _getVietnameseTextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],

            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Divider(color: PdfColors.grey400, thickness: 1),
            ),

            // Final Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  AppLocalizations.of(context)!.pdfTotalPayment,
                  style: _getVietnameseTextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatPriceForPayment(order.totalPrice),
                  style: _getVietnameseTextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildContactSection(
      BuildContext context, String contact, String thankYouMessage) {
    if (contact.isEmpty && thankYouMessage.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(1), // Contact column
        1: const pw.FlexColumnWidth(1), // Thank you column
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          children: [
            _buildTableCell(
              AppLocalizations.of(context)!.pdfContactHeader,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
            _buildTableCell(
              AppLocalizations.of(context)!.thankYouMessage,
              isHeader: true,
              alignment: pw.TextAlign.center,
            ),
          ],
        ),
        // Content row
        pw.TableRow(
          children: [
            _buildTableCell(
              contact.isNotEmpty ? contact : '',
              alignment: pw.TextAlign.left,
            ),
            _buildTableCell(
              thankYouMessage.isNotEmpty
                  ? thankYouMessage
                  : AppLocalizations.of(context)!.pdfDefaultThankYouMessage,
              alignment: pw.TextAlign.left,
              isItalic: true,
            ),
          ],
        ),
      ],
    );
  }

  static Future<File> _savePdf(
      BuildContext context, pw.Document pdf, Order order) async {
    try {
      // Thử sử dụng path_provider trước
      final output = await getTemporaryDirectory();
      final fileName =
          'HoaDon_${_formatBillId(context, order.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');

      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      // Fallback: sử dụng thư mục hiện tại nếu path_provider không hoạt động
      if (kDebugMode) {
        print('path_provider failed, using fallback: $e');
      }

      final fileName =
          'HoaDon_${_formatBillId(context, order.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(fileName);

      await file.writeAsBytes(await pdf.save());
      return file;
    }
  }

  static Future<void> _showShareOptions(BuildContext context, File? file,
      Uint8List? pdfBytes, String customerPhone,
      {String? salonName}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pdfShareBillTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.pdfShareBillMessage),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Chia sẻ qua Zalo
                Column(
                  children: [
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareToZalo(
                            context, file, pdfBytes, customerPhone,
                            salonName: salonName);
                      },
                      icon:
                          const Icon(Icons.chat, size: 40, color: Colors.blue),
                    ),
                    Text(AppLocalizations.of(context)!.pdfShareZalo,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                // Chia sẻ thông thường
                Column(
                  children: [
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareFile(context, file, pdfBytes,
                            salonName: salonName);
                      },
                      icon: const Icon(Icons.share,
                          size: 40, color: Colors.green),
                    ),
                    Text(AppLocalizations.of(context)!.pdfShareOther,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.pdfCancel),
          ),
        ],
      ),
    );
  }

  static Future<void> _shareToZalo(BuildContext context, File? file,
      Uint8List? pdfBytes, String customerPhone,
      {String? salonName}) async {
    try {
      // Trên desktop, Zalo không hoạt động tốt, chuyển sang chia sẻ thông thường
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await _shareFile(context, file, pdfBytes, salonName: salonName);
        return;
      }

      // Tạo URL scheme cho Zalo (chỉ trên mobile)
      final zaloUrl = 'zalo://chat?phone=$customerPhone';

      // Thử mở Zalo trước
      if (await canLaunchUrl(Uri.parse(zaloUrl))) {
        await launchUrl(Uri.parse(zaloUrl));

        // Đợi một chút để Zalo mở, sau đó chia sẻ file
        await Future.delayed(const Duration(seconds: 2));
        await _shareFile(context, file, pdfBytes, salonName: salonName);
      } else {
        // Nếu không có Zalo, chia sẻ file thông thường
        await _shareFile(context, file, pdfBytes, salonName: salonName);
      }
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.pdfErrorSharingZalo(e.toString()),
          type: MessageType.error);

      // Fallback: chia sẻ file thông thường
      await _shareFile(context, file, pdfBytes, salonName: salonName);
    }
  }

  static Future<void> _shareFile(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    try {
      // Kiểm tra platform và sử dụng phương pháp phù hợp
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await _shareFileDesktop(context, file, pdfBytes, salonName: salonName);
      } else {
        await _shareFileMobile(context, file, pdfBytes, salonName: salonName);
      }
    } catch (e) {
      AppWidgets.showFlushbar(context,
          AppLocalizations.of(context)!.pdfErrorSharingFile(e.toString()),
          type: MessageType.error);
    }
  }

  static Future<void> _shareFileMobile(
      BuildContext context, File? file, Uint8List? pdfBytes,
      {String? salonName}) async {
    if (file != null && await file.exists()) {
      // Sử dụng file nếu có
      await Share.shareXFiles(
        [XFile(file.path)],
        text: AppLocalizations.of(context)!
            .pdfBillFrom(salonName ?? SalonConfig.salonName),
      );
    } else if (pdfBytes != null) {
      // Sử dụng bytes trực tiếp nếu không có file
      final tempFile = File('temp_bill.pdf');
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
        if (kDebugMode) {
          print('Could not delete temp file: $e');
        }
      }
    } else {
      throw Exception(AppLocalizations.of(context)!.pdfErrorNoFileData);
    }
  }

  static Future<void> _shareFileDesktop(
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
        final tempFile = File('temp_bill.pdf');
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
          if (kDebugMode) {
            print('Could not delete temp file: $e');
          }
        }
      }
    } catch (e) {
      // Nếu share_plus không hoạt động, sử dụng phương pháp thay thế
      if (kDebugMode) {
        print('Share_plus failed, using alternative method: $e');
      }
      await _shareFileAlternative(context, file, pdfBytes);
    }
  }

  static Future<void> _shareFileAlternative(
      BuildContext context, File? file, Uint8List? pdfBytes) async {
    // Phương pháp thay thế cho desktop
    String filePath = '';

    if (file != null && await file.exists()) {
      filePath = file.path;
    } else if (pdfBytes != null) {
      final tempFile = File('temp_bill.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      filePath = tempFile.path;
    } else {
      throw Exception(AppLocalizations.of(context)!.pdfErrorNoFileToShare);
    }

    // Hiển thị dialog với thông tin file
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pdfFileCreatedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.pdfFileCreatedSuccess),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.pdfFilePath(filePath)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.pdfYouCanDo),
            Text(AppLocalizations.of(context)!.pdfOpenWithApp),
            Text(AppLocalizations.of(context)!.pdfShareManually),
            Text(AppLocalizations.of(context)!.pdfSendViaEmail),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.pdfClose),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Thử mở file bằng ứng dụng mặc định
              try {
                if (Platform.isMacOS) {
                  await Process.run('open', [filePath]);
                } else if (Platform.isWindows) {
                  await Process.run('start', [filePath], runInShell: true);
                } else if (Platform.isLinux) {
                  await Process.run('xdg-open', [filePath]);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Could not open file: $e');
                }
                // Fallback: copy path to clipboard
                AppWidgets.showFlushbar(
                    context,
                    AppLocalizations.of(context)!
                        .pdfPathCopiedToClipboard(filePath),
                    type: MessageType.info);
              }
            },
            child: Text(AppLocalizations.of(context)!.pdfOpenFile),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double price) {
    // Chuyển đổi sang format k (40k, 200k)
    if (price >= 1000) {
      final kValue = (price / 1000).toStringAsFixed(0);
      return '${kValue}k';
    } else {
      return '${price.toStringAsFixed(0)}';
    }
  }

  static String _formatPriceForPayment(double price) {
    // Format cũ cho phần thanh toán (40.000 VNĐ)
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        )} ${SalonConfig.currency}';
  }

  static String _formatBillId(BuildContext context, String orderId) {
    // Kiểm tra nếu ID rỗng
    if (orderId.isEmpty) {
      return AppLocalizations.of(context)!.pdfTemporaryBillId;
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

  static double _getOriginalTotal(Order order) {
    // Tính thành tiền gốc từ tổng thanh toán, giảm giá, tip, phí ship và thuế
    // totalPrice = (originalTotal * (1 - discountPercent/100) + tip + shippingFee) * (1 + taxPercent/100)
    // originalTotal = ((totalPrice / (1 + taxPercent/100)) - tip - shippingFee) / (1 - discountPercent/100)
    final subtotalAfterDiscount =
        (order.totalPrice / (1 + order.taxPercent / 100)) -
            order.tip -
            order.shippingFee;
    return subtotalAfterDiscount / (1 - order.discountPercent / 100);
  }

  static double _getTaxAmount(Order order) {
    // Tính số tiền thuế
    // taxAmount = (originalTotal * (1 - discountPercent/100) + tip + shippingFee) * taxPercent/100
    final subtotalAfterDiscount =
        _getOriginalTotal(order) * (1 - order.discountPercent / 100);
    return (subtotalAfterDiscount + order.tip + order.shippingFee) *
        order.taxPercent /
        100;
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
