import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../models.dart';
import '../config/salon_config.dart';

class PdfBillGenerator {
  static pw.Font? _vietnameseFont;
  static pw.Font? _vietnameseFontBold;
  static Future<void> generateAndShareBill({
    required BuildContext context,
    required Order order,
    required List<Service> services,
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

      // Use SalonConfig defaults if any value is null or empty
      final displaySalonName = (salonName != null && salonName.isNotEmpty)
          ? salonName
          : SalonConfig.salonName;
      final displaySalonAddress =
          (salonAddress != null && salonAddress.isNotEmpty)
              ? salonAddress
              : SalonConfig.salonAddress;
      final displaySalonPhone = (salonPhone != null && salonPhone.isNotEmpty)
          ? salonPhone
          : SalonConfig.salonPhone;

      // Tạo PDF
      final pdf = await _createPdf(
        order: order,
        services: services,
        salonName: displaySalonName,
        salonAddress: displaySalonAddress,
        salonPhone: displaySalonPhone,
        salonQRCode: salonQRCode,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  static Future<void> _loadVietnameseFont() async {
    if (_vietnameseFont == null || _vietnameseFontBold == null) {
      // Trên Flutter Web, sử dụng font system thay vì load từ assets
      if (kIsWeb) {
        if (kDebugMode) {
          print(
              'Running on Flutter Web, using system fonts for Vietnamese support');
        }
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

        if (kDebugMode) {
          print('Loaded Noto Sans fonts for Vietnamese support');
        }
      } catch (e) {
        try {
          // Fallback: thử DejaVu Sans (hỗ trợ Unicode tốt)
          final fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
          _vietnameseFont = pw.Font.ttf(fontData);
          _vietnameseFontBold = pw.Font.ttf(fontData);

          if (kDebugMode) {
            print('Loaded DejaVu Sans font for Vietnamese support');
          }
        } catch (e1) {
          try {
            // Fallback: thử Liberation Sans
            final fontData = await rootBundle
                .load('assets/fonts/LiberationSans-Regular.ttf');
            _vietnameseFont = pw.Font.ttf(fontData);
            _vietnameseFontBold = pw.Font.ttf(fontData);

            if (kDebugMode) {
              print('Loaded Liberation Sans font for Vietnamese support');
            }
          } catch (e2) {
            try {
              // Fallback: thử OpenSans
              final fontData =
                  await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
              _vietnameseFont = pw.Font.ttf(fontData);
              _vietnameseFontBold = pw.Font.ttf(fontData);
              if (kDebugMode) {
                print('Loaded OpenSans font for Vietnamese support');
              }
            } catch (e3) {
              try {
                // Fallback: thử Roboto
                final fontData =
                    await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
                _vietnameseFont = pw.Font.ttf(fontData);
                _vietnameseFontBold = pw.Font.ttf(fontData);
                if (kDebugMode) {
                  print('Loaded Roboto font for Vietnamese support');
                }
              } catch (e4) {
                // Cuối cùng: sử dụng font mặc định với fallback tốt hơn
                if (kDebugMode) {
                  print(
                      'Could not load Vietnamese font from assets, using default: $e4');
                }
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

  // Tạo QR code cho VNPay
  static Future<pw.Widget> _generateQRCode(Order order) async {
    try {
      // Tạo URL thanh toán VNPay (ví dụ)
      final vnpayUrl = _generateVNPayUrl(order);

      // Tạo QR code
      final qrValidationResult = QrValidator.validate(
        data: vnpayUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;

        // Tạo image từ QR code
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: false,
        );

        // Convert thành image bytes
        final picData =
            await painter.toImageData(200, format: ui.ImageByteFormat.png);
        if (picData != null) {
          final image = pw.MemoryImage(picData.buffer.asUint8List());

          return pw.Container(
            width: 200,
            height: 200,
            child: pw.Column(
              children: [
                pw.Image(image, width: 150, height: 150),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Quét mã để thanh toán',
                  style: _getVietnameseTextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'VNPay',
                  style: _getVietnameseTextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating QR code: $e');
      }
    }

    // Fallback: hiển thị thông báo lỗi
    return pw.Container(
      width: 200,
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          'QR Code\nKhông khả dụng',
          style: _getVietnameseTextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  // Tạo URL thanh toán VNPay
  static String _generateVNPayUrl(Order order) {
    // Đây là ví dụ URL VNPay, trong thực tế cần tích hợp với API VNPay
    final baseUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    final params = {
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': 'YOUR_TMN_CODE', // Cần thay bằng mã TMN thực tế
      'vnp_Amount': (order.totalPrice * 100)
          .toInt()
          .toString(), // VNPay yêu cầu amount * 100
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': order.id,
      'vnp_OrderInfo': 'Thanh toan hoa don ${_formatBillId(order.id)}',
      'vnp_OrderType': 'other',
      'vnp_Locale': 'vn',
      'vnp_ReturnUrl':
          'https://your-domain.com/return', // URL trả về sau thanh toán
      'vnp_IpAddr': '127.0.0.1',
      'vnp_CreateDate': DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[-:T.]'), '')
          .substring(0, 14),
    };

    // Tạo query string (trong thực tế cần hash và sign)
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
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

    // Generate QR code widget before creating the PDF page
    final qrCodeWidget = await _buildQRCodeSection(order);

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

              // QR Code for Payment
              qrCodeWidget,

              pw.Spacer(),

              // Footer
              _buildFooter(),

              // QR Code
              if (salonQRCode != null && salonQRCode.isNotEmpty)
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.only(top: 20),
                  child: pw.Image(
                    pw.MemoryImage(base64Decode(salonQRCode)),
                    width: 100,
                    height: 100,
                  ),
                ),
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

  static Future<pw.Widget> _buildQRCodeSection(Order order) async {
    final qrCodeWidget = await _generateQRCode(order);

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
            'THANH TOÁN QUA QR CODE',
            style: _getVietnameseTextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 15),
          pw.Center(
            child: qrCodeWidget,
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Quét mã QR bằng ứng dụng VNPay để thanh toán',
            style: _getVietnameseTextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Số tiền: ${_formatPrice(order.totalPrice)}',
            style: _getVietnameseTextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
            textAlign: pw.TextAlign.center,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chia sẻ Zalo: $e'),
          backgroundColor: Colors.orange,
        ),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chia sẻ file: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Đã copy đường dẫn file vào clipboard: $filePath'),
                    backgroundColor: Colors.blue,
                  ),
                );
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
