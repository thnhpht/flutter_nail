import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import 'design_system.dart';

/// Stub implementation for non-web platforms
Future<void> downloadQRCodeOnWeb(
  BuildContext context,
  Uint8List imageBytes,
  String fileName,
) async {
  // This should never be called on non-web platforms
  AppWidgets.showFlushbar(
    context,
    AppLocalizations.of(context)!
        .errorSharingQrCode('Web download not supported on this platform'),
    type: MessageType.error,
  );
}
