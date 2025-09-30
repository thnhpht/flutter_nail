import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models.dart';

// Stub implementation for non-web platforms
Future<void> downloadPdfOnWeb(
    BuildContext context, Uint8List pdfBytes, Order order,
    {String? salonName}) async {
  // This should never be called on non-web platforms
  throw UnsupportedError('Web download is only supported on web platform');
}
