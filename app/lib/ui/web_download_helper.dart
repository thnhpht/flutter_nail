import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models.dart';
import '../generated/l10n/app_localizations.dart';
import 'design_system.dart';

Future<void> downloadPdfOnWeb(
    BuildContext context, Uint8List pdfBytes, Order order,
    {String? salonName}) async {
  try {
    // Tạo tên file với thông tin hóa đơn
    final fileName =
        'HoaDon_${_formatBillId(context, order.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Chuyển đổi bytes thành base64
    final base64String = base64Encode(pdfBytes);
    final dataUri = 'data:application/pdf;base64,$base64String';

    // Tạo anchor element để download
    final html.AnchorElement anchor = html.AnchorElement()
      ..href = dataUri
      ..download = fileName
      ..style.display = 'none';

    // Thêm vào DOM và click để download
    html.document.body?.append(anchor);
    anchor.click();

    // Xóa element sau khi download
    anchor.remove();

    // Hiển thị thông báo thành công
    AppWidgets.showFlushbar(
      context,
      AppLocalizations.of(context)!.pdfDownloadSuccess(fileName),
      type: MessageType.success,
    );
  } catch (e) {
    // Fallback: sử dụng Blob và createObjectUrl
    try {
      await _downloadPdfOnWebFallback(context, pdfBytes, order,
          salonName: salonName);
    } catch (fallbackError) {
      AppWidgets.showFlushbar(
        context,
        AppLocalizations.of(context)!.pdfErrorDownloadingWeb(e.toString()),
        type: MessageType.error,
      );
    }
  }
}

// Phương thức fallback cho download PDF trên web
Future<void> _downloadPdfOnWebFallback(
    BuildContext context, Uint8List pdfBytes, Order order,
    {String? salonName}) async {
  try {
    // Tạo tên file
    final fileName =
        'HoaDon_${_formatBillId(context, order.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Tạo Blob từ PDF bytes
    final html.Blob blob = html.Blob([pdfBytes], 'application/pdf');

    // Tạo URL từ Blob
    final String url = html.Url.createObjectUrl(blob);

    // Tạo anchor element để download
    final html.AnchorElement anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    // Thêm vào DOM và click để download
    html.document.body?.append(anchor);
    anchor.click();

    // Cleanup: xóa element và revoke URL
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    // Hiển thị thông báo thành công
    AppWidgets.showFlushbar(
      context,
      AppLocalizations.of(context)!.pdfDownloadSuccess(fileName),
      type: MessageType.success,
    );
  } catch (e) {
    throw Exception('Fallback download failed: $e');
  }
}

String _formatBillId(BuildContext context, String orderId) {
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
