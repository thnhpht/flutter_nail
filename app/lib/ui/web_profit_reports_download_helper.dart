import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:html' as html;

Future<void> downloadProfitReportsPdfOnWeb(
    BuildContext context, Uint8List pdfBytes) async {
  try {
    // Tạo blob từ bytes
    final blob = html.Blob([pdfBytes], 'application/pdf');

    // Tạo URL cho blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Tạo link download
    html.AnchorElement(href: url)
      ..setAttribute('download',
          'profit_reports_${DateTime.now().millisecondsSinceEpoch}.pdf')
      ..click();

    // Cleanup URL
    html.Url.revokeObjectUrl(url);

    // Hiển thị thông báo thành công
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải xuống báo cáo lợi nhuận...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải xuống: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
