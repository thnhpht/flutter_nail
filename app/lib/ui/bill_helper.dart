import 'package:flutter/material.dart';
import '../models.dart';
import '../config/salon_config.dart';
import 'design_system.dart';
import 'pdf_bill_generator.dart';
import '../api_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert'; // Added for base64Decode
import '../generated/l10n/app_localizations.dart';

class BillHelper {
  static List<Service>? _currentServices;
  static ApiClient? _apiClient;

  static Future<void> showBillDialog({
    required BuildContext context,
    required Order order,
    required List<Service> services,
    required ApiClient api,
    String? salonName,
    String? salonAddress,
    String? salonPhone,
    String? salonQRCode,
  }) async {
    // Lưu trữ services và api client hiện tại
    _currentServices = services;
    _apiClient = api;

    // Lấy thông tin salon từ database
    Information? salonInfo;
    try {
      salonInfo = await api.getInformation();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading salon info: $e');
      }
    }

    // Sử dụng thông tin từ database hoặc fallback về tham số truyền vào hoặc SalonConfig
    final name = salonInfo?.salonName ?? salonName ?? SalonConfig.salonName;
    final address =
        salonInfo?.address ?? salonAddress ?? SalonConfig.salonAddress;
    final phone = salonInfo?.phone ?? salonPhone ?? SalonConfig.salonPhone;
    final qrCode = salonInfo?.qrCode ?? salonQRCode;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity, // Thêm dòng này
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      topRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.billPaymentReceipt,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Bill Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: _buildBillContent(
                      context: context,
                      order: order,
                      services: services,
                      salonName: name,
                      salonAddress: address,
                      salonPhone: phone,
                      qrCode: qrCode, // Thêm parameter này
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusLarge),
                      bottomRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          onPressed: () => _printBill(context, order),
                          label: AppLocalizations.of(context)!.print,
                          icon: Icons.print,
                          color: AppTheme.primaryEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildBillContent({
    required BuildContext context,
    required Order order,
    required List<Service> services,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
    String? qrCode, // Thêm parameter này
  }) {
    // Use SalonConfig defaults if any value is null or empty
    final displaySalonName =
        (salonName.isNotEmpty) ? salonName : SalonConfig.salonName;
    final displaySalonAddress =
        (salonAddress.isNotEmpty) ? salonAddress : SalonConfig.salonAddress;
    final displaySalonPhone =
        (salonPhone.isNotEmpty) ? salonPhone : SalonConfig.salonPhone;
    return Column(
      children: [
        // Salon Info
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Text(
                displaySalonName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displaySalonAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.phoneNumber} ${_formatPhoneNumber(displaySalonPhone)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Bill Info
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.billCode,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '#${_formatBillId(context, order.id)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.of(context)!.createdDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Customer Info
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppTheme.primaryStart,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    AppLocalizations.of(context)!.customerInformation,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              _buildInfoRow(context, AppLocalizations.of(context)!.customerName,
                  order.customerName),
              _buildInfoRow(context, AppLocalizations.of(context)!.phoneNumber,
                  _formatPhoneNumber(order.customerPhone)),
              _buildInfoRow(context, AppLocalizations.of(context)!.servingStaff,
                  order.employeeNames.join(', ')),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Services
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMedium),
                    topRight: Radius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.spa,
                      color: AppTheme.primaryStart,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      AppLocalizations.of(context)!.serviceDetails,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Services List
              ...services.map((service) => _buildServiceItem(service)).toList(),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Total
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              // Original Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.subtotal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatPrice(_getOriginalTotal(order)),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Discount (if any)
              if (order.discountPercent > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.discount} (${order.discountPercent.toStringAsFixed(0)}%):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '-${_formatPrice(_getOriginalTotal(order) * order.discountPercent / 100)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],

              // Tip (if any)
              if (order.tip > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.tip,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '+${_formatPrice(order.tip)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Final Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalPayment,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatPrice(order.totalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // QR Code section - THÊM PHẦN NÀY
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: AppTheme.primaryStart,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    AppLocalizations.of(context)!.qrCodePayment,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: qrCode != null &&
                          qrCode.isNotEmpty &&
                          qrCode != AppLocalizations.of(context)!.noQrCode
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          child: Image.memory(
                            base64Decode(qrCode.startsWith('data:image/')
                                ? qrCode.split(',')[1]
                                : qrCode),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .qrCodeDisplayError,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            qrCode ?? AppLocalizations.of(context)!.noQrCode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                AppLocalizations.of(context)!.scanQrToPay,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Footer
        Container(
          width: double.infinity, // Thêm dòng này
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.billFooter,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                AppLocalizations.of(context)!.billFooter2,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildInfoRow(
      BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildServiceItem(Service service) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              service.name,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatPrice(service.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  static String _formatBillId(BuildContext context, String orderId) {
    // Kiểm tra nếu ID rỗng
    if (orderId.isEmpty) {
      return AppLocalizations.of(context)!.temporary;
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

  static String _formatPhoneNumber(String phoneNumber) {
    // Loại bỏ tất cả ký tự không phải số
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Kiểm tra nếu số điện thoại có 10 số
    if (cleanPhone.length == 10) {
      // Format: 0xxx xxx xxx
      return '${cleanPhone.substring(0, 4)} ${cleanPhone.substring(4, 7)} ${cleanPhone.substring(7)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('84')) {
      // Format cho số có mã quốc gia 84: +84 xxx xxx xxx
      return '+${cleanPhone.substring(0, 2)} ${cleanPhone.substring(2, 5)} ${cleanPhone.substring(5, 8)} ${cleanPhone.substring(8)}';
    } else if (cleanPhone.length == 9 && !cleanPhone.startsWith('0')) {
      // Format cho số không có số 0 đầu: 0xxx xxx xxx
      return '0${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }

    // Nếu không phù hợp với format Việt Nam, trả về số gốc
    return phoneNumber;
  }

  static Future<void> _printBill(BuildContext context, Order order) async {
    // Lấy services từ biến static
    if (_currentServices == null || _currentServices!.isEmpty) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.serviceNotFoundError,
          type: MessageType.error);
      return;
    }

    // Lấy thông tin salon từ database
    Information? salonInfo;
    try {
      if (_apiClient != null) {
        salonInfo = await _apiClient!.getInformation();
      }
    } catch (e) {
      return;
    }

    final salonName = salonInfo?.salonName;
    final salonAddress = salonInfo?.address;
    final salonPhone = salonInfo?.phone;

    PdfBillGenerator.generateAndSendToZalo(
      context: context,
      order: order,
      services: _currentServices!,
      api: _apiClient!,
      salonName: salonName,
      salonAddress: salonAddress,
      salonPhone: salonPhone,
    );
  }
}
