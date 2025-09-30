import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import 'design_system.dart';

Future<void> downloadReportsPdfOnWeb(
    BuildContext context, Uint8List pdfBytes) async {
  try {
    // Tạo tên file cho báo cáo
    final fileName = 'BaoCao_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
      AppLocalizations.of(context)!.exportReportsSuccess,
      type: MessageType.success,
    );
  } catch (e) {
    // Fallback: sử dụng Blob và createObjectUrl
    try {
      await _downloadReportsPdfOnWebFallback(context, pdfBytes);
    } catch (fallbackError) {
      AppWidgets.showFlushbar(
        context,
        AppLocalizations.of(context)!.exportReportsError(e.toString()),
        type: MessageType.error,
      );
    }
  }
}

// Phương thức fallback cho download PDF báo cáo trên web
Future<void> _downloadReportsPdfOnWebFallback(
    BuildContext context, Uint8List pdfBytes) async {
  try {
    // Tạo tên file
    final fileName = 'BaoCao_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
      AppLocalizations.of(context)!.exportReportsSuccess,
      type: MessageType.success,
    );
  } catch (e) {
    throw Exception('Fallback download failed: $e');
  }
}
