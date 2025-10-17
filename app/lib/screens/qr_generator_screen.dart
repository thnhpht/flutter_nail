import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../ui/design_system.dart';
import '../generated/l10n/app_localizations.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Conditional import for web download helper
import '../ui/web_qr_download_helper.dart'
    if (dart.library.io) '../ui/web_qr_download_helper_stub.dart';

class QRGeneratorScreen extends StatefulWidget {
  final ApiClient api;

  const QRGeneratorScreen({super.key, required this.api});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _salonNameController = TextEditingController();
  String? _generatedUrl;
  String? _errorMessage;
  bool _isGenerating = false;
  bool _salonExists = false;
  final GlobalKey _qrKey = GlobalKey();

  // QR Code type: 'app' or 'web'
  String _qrCodeType = 'web'; // Default to web for better accessibility

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    super.dispose();
  }

  Future<void> _loadShopName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? shopName;

      // Priority 1: Get from SharedPreferences (login info)
      // Employee/Delivery login saves 'shop_name'
      shopName = prefs.getString('shop_name');

      // Priority 2: Booking user saves 'salon_name'
      shopName ??= prefs.getString('salon_name');

      // Priority 3: Shop owner might save as 'database_name'
      shopName ??= prefs.getString('database_name');

      // Priority 4: Try to get from API (shop owner case)
      if (shopName == null || shopName.isEmpty) {
        try {
          final salonInfo = await widget.api.getInformation();
          if (salonInfo.salonName.isNotEmpty) {
            shopName = salonInfo.salonName;
          }
        } catch (e) {
          // API call failed, that's okay
          print('Could not load from API: $e');
        }
      }

      // Auto-fill the field if we found a shop name
      if (shopName != null && shopName.isNotEmpty) {
        setState(() {
          _salonNameController.text = shopName!;
        });
      }
    } catch (e) {
      // If error, just leave the field empty for manual input
      print('Error loading shop name: $e');
    }
  }

  Future<void> _generateQRCode() async {
    final salonName = _salonNameController.text.trim();

    if (salonName.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseEnterShopName;
        _generatedUrl = null;
        _salonExists = false;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Check if salon exists
      final exists = await widget.api.checkSalonExists(salonName);

      if (!exists) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context)!.shopNotExists(salonName);
          _generatedUrl = null;
          _salonExists = false;
          _isGenerating = false;
        });
        return;
      }

      // Generate URL based on selected type
      String url;
      if (_qrCodeType == 'app') {
        // Deep link - opens app directly
        url = 'fshop://booking?salon=${Uri.encodeComponent(salonName)}';
      } else {
        // Web link - opens in browser (works without app installed)
        // For web deployment, use your actual domain
        // Example: https://yourdomain.com/#/booking?salon=bephuongtubi@
        final webDomain =
            'https://fshop.sellers.vn'; // Change this to your domain
        url = '$webDomain/#/booking?salon=${Uri.encodeComponent(salonName)}';
      }

      setState(() {
        _generatedUrl = url;
        _salonExists = true;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _generatedUrl = null;
        _salonExists = false;
        _isGenerating = false;
      });
    }
  }

  Future<void> _shareQRCode() async {
    try {
      if (kIsWeb) {
        // On web, download the QR code as image
        await _downloadQRCodeWeb();
      } else {
        // On mobile/desktop, use share functionality
        await _shareQRCodeMobile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorSharingQrCode(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareQRCodeMobile() async {
    // Capture QR code as image
    RenderRepaintBoundary boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Save to temporary file with type suffix
    final tempDir = await getTemporaryDirectory();
    final qrType = _qrCodeType == 'app' ? '_app' : '_web';
    final file = await File(
            '${tempDir.path}/qr_code_${_salonNameController.text}$qrType.png')
        .create();
    await file.writeAsBytes(pngBytes);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'QR Code để đặt hàng tại ${_salonNameController.text}\nQuét mã để truy cập menu đặt hàng',
    );
  }

  Future<void> _downloadQRCodeWeb() async {
    try {
      // Capture QR code as image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Generate file name with type suffix
      final qrType = _qrCodeType == 'app' ? '_app' : '_web';
      final fileName = 'qr_code_${_salonNameController.text}$qrType.png';

      // Use the web download helper (conditional import)
      await downloadQRCodeOnWeb(context, pngBytes, fileName);
    } catch (e) {
      if (mounted) {
        AppWidgets.showFlushbar(
          context,
          AppLocalizations.of(context)!.errorSharingQrCode(e.toString()),
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryStart.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.qrCodeGeneratorTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.qrCodeGeneratorSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Input section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // QR Code Type Selection
                      Text(
                        AppLocalizations.of(context)!.qrCodeType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title:
                                  Text(AppLocalizations.of(context)!.qrCodeWeb),
                              subtitle: Text(
                                AppLocalizations.of(context)!.qrCodeWebSubtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: 'web',
                              groupValue: _qrCodeType,
                              onChanged: (value) {
                                setState(() {
                                  _qrCodeType = value!;
                                  // Clear generated QR when changing type
                                  _generatedUrl = null;
                                  _salonExists = false;
                                });
                              },
                              activeColor: AppTheme.primaryStart,
                            ),
                            Divider(height: 1, color: Colors.grey[300]),
                            RadioListTile<String>(
                              title:
                                  Text(AppLocalizations.of(context)!.qrCodeApp),
                              subtitle: Text(
                                AppLocalizations.of(context)!.qrCodeAppSubtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: 'app',
                              groupValue: _qrCodeType,
                              onChanged: (value) {
                                setState(() {
                                  _qrCodeType = value!;
                                  // Clear generated QR when changing type
                                  _generatedUrl = null;
                                  _salonExists = false;
                                });
                              },
                              activeColor: AppTheme.primaryStart,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        AppLocalizations.of(context)!.shopNameField,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _salonNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppTheme.primaryStart, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : _generateQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryStart,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.qr_code_scanner),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .generateQrCodeButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Code display
                if (_generatedUrl != null && _salonExists) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .shopConfirmed(_salonNameController.text),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // QR Code
                        RepaintBoundary(
                          key: _qrKey,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: _generatedUrl!,
                              version: QrVersions.auto,
                              size: 280,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // QR Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _qrCodeType == 'web'
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _qrCodeType == 'web'
                                  ? Colors.blue.withValues(alpha: 0.3)
                                  : Colors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _qrCodeType == 'web'
                                    ? Icons.language
                                    : Icons.phone_android,
                                size: 16,
                                color: _qrCodeType == 'web'
                                    ? Colors.blue
                                    : Colors.purple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _qrCodeType == 'web'
                                    ? AppLocalizations.of(context)!.qrCodeWeb
                                    : AppLocalizations.of(context)!.qrCodeApp,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _qrCodeType == 'web'
                                      ? Colors.blue
                                      : Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          AppLocalizations.of(context)!
                              .shopLabel(_salonNameController.text),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _generatedUrl!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _shareQRCode,
                                icon:
                                    Icon(kIsWeb ? Icons.download : Icons.share),
                                label: Text(kIsWeb
                                    ? AppLocalizations.of(context)!.download
                                    : AppLocalizations.of(context)!.share),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side:
                                      BorderSide(color: AppTheme.primaryStart),
                                  foregroundColor: AppTheme.primaryStart,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.instructions,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _qrCodeType == 'web'
                                    ? AppLocalizations.of(context)!
                                        .qrWebInstructions
                                    : AppLocalizations.of(context)!
                                        .qrAppInstructions,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
