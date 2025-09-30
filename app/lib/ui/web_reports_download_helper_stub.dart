import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import 'design_system.dart';

Future<void> downloadReportsPdfOnWeb(
    BuildContext context, Uint8List pdfBytes) async {
  // Stub implementation for non-web platforms
  AppWidgets.showFlushbar(
    context,
    AppLocalizations.of(context)!
        .exportReportsError('Web download not supported on this platform'),
    type: MessageType.error,
  );
}
