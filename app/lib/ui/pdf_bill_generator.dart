import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models.dart';
import '../config/salon_config.dart';
import '../api_client.dart';
import 'design_system.dart';

class PdfBillGenerator {
  static pw.Font? _vietnameseFont;
  static pw.Font? _vietnameseFontBold;

  static Future<void> generateAndShareBill({
    required BuildContext context,
    required Order order,
    required List<Service> services,
    required ApiClient api,
    String? salonName,
    String? salonAddress,
    String? salonPhone,
    String? salonQRCode,
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
      final displaySalonQRCode =
          salonInfo?.qrCode ?? salonQRCode ?? SalonConfig.salonQRCode;

      // Tạo PDF
      final pdf = await _createPdf(
        order: order,
        services: services,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
        salonQRCode: displaySalonQRCode,
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _savePdf(pdf, order);
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
      String errorMessage = 'Lỗi tạo PDF: $e';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage =
            'Lỗi: Plugin không được hỗ trợ trên platform này. Vui lòng chạy trên Android/iOS hoặc cài đặt CocoaPods cho macOS.';
      }

      AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
    }
  }

  // Phương thức mới để tự động gửi PDF tới Zalo
  static Future<void> generateAndSendToZalo({
    required BuildContext context,
    required Order order,
    required List<Service> services,
    required ApiClient api,
    String? salonName,
    String? salonAddress,
    String? salonPhone,
    String? salonQRCode,
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
      final displaySalonQRCode =
          salonInfo?.qrCode ?? salonQRCode ?? SalonConfig.salonQRCode;

      // Tạo PDF
      final pdf = await _createPdf(
        order: order,
        services: services,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
        salonQRCode: displaySalonQRCode,
      );

      // Lưu file PDF hoặc sử dụng bytes trực tiếp
      File? file;
      Uint8List? pdfBytes;

      try {
        file = await _savePdf(pdf, order);
      } catch (e) {
        // Nếu không thể lưu file, sử dụng bytes trực tiếp
        pdfBytes = await pdf.save();
        if (kDebugMode) {
          print('Using PDF bytes directly: $e');
        }
      }

      // Đóng loading dialog
      Navigator.of(context).pop();

      // Tự động gửi tới Zalo mà không hiển thị dialog
      await _shareDirectlyToZalo(context, file, pdfBytes, order.customerPhone,
          salonName: displaySalonName);
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Hiển thị thông báo lỗi chi tiết hơn
      String errorMessage = 'Lỗi tạo PDF: $e';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage =
            'Lỗi: Plugin không được hỗ trợ trên platform này. Vui lòng chạy trên Android/iOS hoặc cài đặt CocoaPods cho macOS.';
      }

      AppWidgets.showFlushbar(context, errorMessage, type: MessageType.error);
    }
  } // Phương thức chia sẻ tới Zalo với trải nghiệm tốt nhất có thể

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
        AppWidgets.showFlushbar(context,
            'Zalo đã mở! Vui lòng chọn Zalo trong menu chia sẻ để gửi hóa đơn.',
            type: MessageType.info);
      } else {
        // Nếu không có Zalo, chia sẻ file thông thường
        await _shareFileDirectly(context, file, pdfBytes, salonName: salonName);
      }
    } catch (e) {
      AppWidgets.showFlushbar(context, 'Lỗi chia sẻ Zalo: $e',
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
      AppWidgets.showFlushbar(context, 'Lỗi chia sẻ file: $e',
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
          text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
          subject: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
        );
      } else if (pdfBytes != null) {
        // Sử dụng bytes trực tiếp nếu không có file
        final tempFile = File('temp_bill.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
          subject: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
        );

        // Xóa file tạm
        try {
          await tempFile.delete();
        } catch (e) {
          return;
        }
      } else {
        throw Exception('Không có file PDF hoặc dữ liệu để chia sẻ');
      }
    } catch (e) {
      // Nếu không thể chia sẻ, hiển thị thông báo
      AppWidgets.showFlushbar(context, 'Không thể chia sẻ file: $e',
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
          text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
          subject: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
        );
      } else if (pdfBytes != null) {
        final tempFile = File('temp_bill.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
          subject: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
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
          context, 'File PDF đã được tạo. Vui lòng chia sẻ thủ công.',
          type: MessageType.info);
    }
  }

  static Future<void> _loadVietnameseFont() async {
    if (_vietnameseFont == null || _vietnameseFontBold == null) {
      // Trên Flutter Web, sử dụng font system thay vì load từ assets
      if (kIsWeb) {
        // Sử dụng font system có hỗ trợ Unicode tốt hơn
        _vietnameseFont = pw.Font.helvetica();
        _vietnameseFontBold = pw.Font.helveticaBold();
        return;
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

    if (kIsWeb) {
      // Trên web, sử dụng font system có hỗ trợ Unicode
      fontFallback = [
        pw.Font.helvetica(),
        pw.Font.times(),
        pw.Font.courier(),
      ];
    } else {
      // Trên mobile/desktop, sử dụng font fallback
      fontFallback = [
        pw.Font.helvetica(),
        pw.Font.times(),
        pw.Font.courier(),
      ];
    }

    return pw.TextStyle(
      font: selectedFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      fontFallback: fontFallback,
    );
  }

  // Hàm để lấy hình ảnh từ URL hoặc base64 - cách mới
  static Future<pw.ImageProvider?> _getImageFromUrlOrBase64(
      String? imageData) async {
    if (imageData == null || imageData.isEmpty) {
      return null;
    }

    try {
      // Kiểm tra nếu là base64
      if (imageData.startsWith('data:image/') ||
          (imageData.length > 100 && !imageData.startsWith('http'))) {
        // Xử lý base64
        String base64String = imageData;
        if (imageData.startsWith('data:image/')) {
          base64String = imageData.split(',')[1];
        }

        final bytes = base64Decode(base64String);

        // Tạo image provider với cách mới
        try {
          final imageProvider = pw.MemoryImage(bytes);
          return imageProvider;
        } catch (e) {
          return null;
        }
      } else if (imageData.startsWith('http')) {
        // Xử lý URL
        final uri = Uri.parse(imageData);
        final response = await HttpClient().getUrl(uri);
        final request = await response.close();
        final bytes = await consolidateHttpClientResponseBytes(request);
        return pw.MemoryImage(bytes);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  static Future<pw.Document> _createPdf({
    required Order order,
    required List<Service> services,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
    String? salonQRCode,
  }) async {
    // Load font hỗ trợ tiếng Việt
    await _loadVietnameseFont();

    // Lấy hình ảnh QRCode từ database
    pw.ImageProvider? qrCodeImageProvider;
    String? qrCodeText;

    if (salonQRCode != null &&
        salonQRCode.isNotEmpty &&
        salonQRCode != 'Chưa có mã QR Code') {
      qrCodeImageProvider = await _getImageFromUrlOrBase64(salonQRCode);
    } else {
      qrCodeText = salonQRCode ?? 'Chưa có mã QR Code';
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Salon Info
              _buildSalonHeader(salonName, salonAddress, salonPhone),

              pw.SizedBox(height: 20),

              // Bill Info
              _buildBillInfo(order),

              pw.SizedBox(height: 20),

              // Customer Info
              _buildCustomerInfo(order),

              pw.SizedBox(height: 20),

              // Services
              _buildServicesTable(services),

              pw.SizedBox(height: 20),

              // Total
              _buildTotalSection(order),

              pw.SizedBox(height: 20),

              // QR Code section - Based on official documentation
              pw.SizedBox(height: 20),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'QR CODE SALON',
                      style: _getVietnameseTextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 15),

                    // Sử dụng cách hiển thị đơn giản nhất
                    pw.Center(
                      child: qrCodeImageProvider != null
                          ? pw.Container(
                              width: 150,
                              height: 150,
                              child: pw.Image(
                                qrCodeImageProvider,
                                width: 150,
                                height: 150,
                              ),
                            )
                          : pw.Container(
                              width: 150,
                              height: 150,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey100,
                                border: pw.Border.all(
                                    color: PdfColors.black, width: 1),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  qrCodeText ?? 'Chưa có mã QR Code',
                                  style: _getVietnameseTextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey600,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                    ),

                    pw.SizedBox(height: 15),
                    pw.Text(
                      'Quét mã QR để liên hệ salon',
                      style: _getVietnameseTextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSalonHeader(
      String salonName, String salonAddress, String salonPhone) {
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
            'ĐT: $salonPhone',
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

  static pw.Widget _buildBillInfo(Order order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Mã hóa đơn:',
                style: _getVietnameseTextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                '#${_formatBillId(order.id)}',
                style: _getVietnameseTextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Ngày tạo:',
                style: _getVietnameseTextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                _formatDate(order.createdAt),
                style: _getVietnameseTextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(Order order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'THÔNG TIN KHÁCH HÀNG',
            style: _getVietnameseTextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Tên khách hàng:', order.customerName),
          _buildInfoRow('Số điện thoại:', order.customerPhone),
          _buildInfoRow('Nhân viên phục vụ:', order.employeeNames.join(', ')),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: _getVietnameseTextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            value,
            style: _getVietnameseTextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildServicesTable(List<Service> services) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              'CHI TIẾT DỊCH VỤ',
              style: _getVietnameseTextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          // Services
          ...services.map((service) => _buildServiceRow(service)).toList(),
        ],
      ),
    );
  }

  static pw.Widget _buildServiceRow(Service service) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              service.name,
              style: _getVietnameseTextStyle(
                fontSize: 14,
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              _formatPrice(service.price),
              style: _getVietnameseTextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalSection(Order order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          // Original Total
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thành tiền:',
                style: _getVietnameseTextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
              pw.Text(
                _formatPrice(_getOriginalTotal(order)),
                style: _getVietnameseTextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),

          // Discount (if any)
          if (order.discountPercent > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Giảm giá (${order.discountPercent.toStringAsFixed(0)}%):',
                  style: _getVietnameseTextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  '-${_formatPrice(_getOriginalTotal(order) * order.discountPercent / 100)}',
                  style: _getVietnameseTextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],

          // Tip (if any)
          if (order.tip > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Tiền bo:',
                  style: _getVietnameseTextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  '+${_formatPrice(order.tip)}',
                  style: _getVietnameseTextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // Final Total
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TỔNG THANH TOÁN:',
                style: _getVietnameseTextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _formatPrice(order.totalPrice),
                style: _getVietnameseTextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
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
            SalonConfig.billFooter,
            style: _getVietnameseTextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            SalonConfig.billFooter2,
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

  static Future<File> _savePdf(pw.Document pdf, Order order) async {
    try {
      // Thử sử dụng path_provider trước
      final output = await getTemporaryDirectory();
      final fileName =
          'HoaDon_${_formatBillId(order.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');

      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      // Fallback: sử dụng thư mục hiện tại nếu path_provider không hoạt động
      if (kDebugMode) {
        print('path_provider failed, using fallback: $e');
      }

      final fileName =
          'HoaDon_${_formatBillId(order.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
        title: const Text('Chia sẻ hóa đơn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn cách chia sẻ hóa đơn:'),
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
                    const Text('Zalo', style: TextStyle(fontSize: 12)),
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
                    const Text('Khác', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
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
      AppWidgets.showFlushbar(context, 'Lỗi chia sẻ Zalo: $e',
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
      AppWidgets.showFlushbar(context, 'Lỗi chia sẻ file: $e',
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
        text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
      );
    } else if (pdfBytes != null) {
      // Sử dụng bytes trực tiếp nếu không có file
      final tempFile = File('temp_bill.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
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
      throw Exception('Không có file PDF hoặc dữ liệu để chia sẻ');
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
          text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
        );
      } else if (pdfBytes != null) {
        final tempFile = File('temp_bill.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Hóa đơn từ ${salonName ?? SalonConfig.salonName}',
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
      throw Exception('Không có file PDF để chia sẻ');
    }

    // Hiển thị dialog với thông tin file
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File PDF đã được tạo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File PDF đã được tạo thành công!'),
            const SizedBox(height: 16),
            Text('Đường dẫn: $filePath'),
            const SizedBox(height: 16),
            const Text('Bạn có thể:'),
            const Text('• Mở file bằng ứng dụng PDF'),
            const Text('• Chia sẻ file thủ công'),
            const Text('• Gửi qua email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
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
                    context, 'Đã copy đường dẫn file vào clipboard: $filePath',
                    type: MessageType.info);
              }
            },
            child: const Text('Mở file'),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        )} ${SalonConfig.currency}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  static String _formatBillId(String orderId) {
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

  static double _getOriginalTotal(Order order) {
    // Tính thành tiền gốc từ tổng thanh toán, giảm giá và tip
    // totalPrice = originalTotal * (1 - discountPercent/100) + tip
    // originalTotal = (totalPrice - tip) / (1 - discountPercent/100)
    return (order.totalPrice - order.tip) / (1 - order.discountPercent / 100);
  }
}
