import 'package:flutter/material.dart';
import '../models.dart';
import '../config/salon_config.dart';
import 'design_system.dart';
import 'pdf_bill_generator.dart';
import 'salon_info_inherited.dart';

class BillHelper {
  static List<Service>? _currentServices;

  static Future<void> showBillDialog({
    required BuildContext context,
    required Order order,
    required List<Service> services,
    String? salonName,
    String? salonAddress,
    String? salonPhone,
    String? salonQRCode,
  }) async {
    // Lưu trữ services hiện tại
    _currentServices = services;

    final name = salonName ?? SalonConfig.salonName;
    final address = salonAddress ?? SalonConfig.salonAddress;
    final phone = salonPhone ?? SalonConfig.salonPhone;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SalonInfoInherited(
            salonName: name,
            salonAddress: address,
            salonPhone: phone,
            salonQRCode: salonQRCode,
            child: Dialog(
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
                          const Expanded(
                            child: Text(
                              'Hóa đơn thanh toán',
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
                          order: order,
                          services: services,
                          salonName: name,
                          salonAddress: address,
                          salonPhone: phone,
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
                              label: 'In',
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
            ));
      },
    );
  }

  static Widget _buildBillContent({
    required Order order,
    required List<Service> services,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
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
                displaySalonPhone,
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
                    'Mã hóa đơn:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '#${_formatBillId(order.id)}',
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
                    'Ngày tạo:',
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
                  const Text(
                    'Thông tin khách hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              _buildInfoRow('Tên khách hàng:', order.customerName),
              _buildInfoRow('Số điện thoại:', order.customerPhone),
              _buildInfoRow(
                  'Nhân viên phục vụ:', order.employeeNames.join(', ')),
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
                    const Text(
                      'Chi tiết dịch vụ',
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
                  const Text(
                    'Thành tiền:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatPrice(_getOriginalTotal(order)),
                    style: const TextStyle(
                      fontSize: 16,
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
                      'Giảm giá (${order.discountPercent.toStringAsFixed(0)}%):',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '-${_formatPrice(_getOriginalTotal(order) * order.discountPercent / 100)}',
                      style: const TextStyle(
                        fontSize: 16,
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
                    const Text(
                      'Tiền bo:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '+${_formatPrice(order.tip)}',
                      style: const TextStyle(
                        fontSize: 16,
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
                  const Text(
                    'Tổng thanh toán:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatPrice(order.totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
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

        // Footer
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
                SalonConfig.billFooter,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                SalonConfig.billFooter2,
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

  static Widget _buildInfoRow(String label, String value) {
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

  static String _formatBillId(String orderId) {
    // Kiểm tra nếu ID rỗng
    if (orderId.isEmpty) {
      return "TẠM THỜI";
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

  static void _printBill(BuildContext context, Order order) {
    // Lấy services từ biến static
    if (_currentServices == null || _currentServices!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin dịch vụ cho đơn hàng này'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Lấy thông tin salon từ dialog arguments nếu có
    final inherited = context
        .getElementForInheritedWidgetOfExactType<SalonInfoInherited>()
        ?.widget as SalonInfoInherited?;
    final salonName = inherited?.salonName;
    final salonAddress = inherited?.salonAddress;
    final salonPhone = inherited?.salonPhone;
    final salonQRCode = inherited?.salonQRCode;

    PdfBillGenerator.generateAndShareBill(
      context: context,
      order: order,
      services: _currentServices!,
      salonName: salonName,
      salonAddress: salonAddress,
      salonPhone: salonPhone,
      salonQRCode: salonQRCode,
    );
  }
}
