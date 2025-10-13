import 'dart:typed_data';
import 'package:flutter/material.dart';

// Stub implementation for non-web platforms
Future<void> downloadInventoryReportsPdfOnWeb(
    BuildContext context, Uint8List pdfBytes) async {
  // This function is not used on non-web platforms
  throw UnsupportedError('Web download is not supported on this platform');
}
