import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import 'design_system.dart';

/// Download QR code image as PNG on web platform
Future<void> downloadQRCodeOnWeb(
  BuildContext context,
  Uint8List imageBytes,
  String fileName,
) async {
  try {
    // Convert bytes to base64
    final base64String = base64Encode(imageBytes);
    final dataUri = 'data:image/png;base64,$base64String';

    // Create anchor element for download
    final html.AnchorElement anchor = html.AnchorElement()
      ..href = dataUri
      ..download = fileName
      ..style.display = 'none';

    // Add to DOM and click to trigger download
    html.document.body?.append(anchor);
    anchor.click();

    // Remove element after download
    anchor.remove();

    // Show success message
    AppWidgets.showFlushbar(
      context,
      AppLocalizations.of(context)!.downloadSuccessful,
      type: MessageType.success,
    );
  } catch (e) {
    // Fallback: use Blob and createObjectUrl
    try {
      await _downloadQRCodeOnWebFallback(context, imageBytes, fileName);
    } catch (fallbackError) {
      AppWidgets.showFlushbar(
        context,
        AppLocalizations.of(context)!.errorSharingQrCode(e.toString()),
        type: MessageType.error,
      );
    }
  }
}

/// Fallback method for downloading QR code on web using Blob
Future<void> _downloadQRCodeOnWebFallback(
  BuildContext context,
  Uint8List imageBytes,
  String fileName,
) async {
  try {
    // Create Blob from image bytes
    final html.Blob blob = html.Blob([imageBytes], 'image/png');

    // Create URL from Blob
    final String url = html.Url.createObjectUrl(blob);

    // Create anchor element for download
    final html.AnchorElement anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    // Add to DOM and click to trigger download
    html.document.body?.append(anchor);
    anchor.click();

    // Cleanup: remove element and revoke URL
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    // Show success message
    AppWidgets.showFlushbar(
      context,
      AppLocalizations.of(context)!.downloadSuccessful,
      type: MessageType.success,
    );
  } catch (e) {
    throw Exception('Fallback download failed: $e');
  }
}
