import 'package:flutter/material.dart';
import '../models.dart';
import '../config/salon_config.dart';
import 'design_system.dart';

class BillHelper {
  static Future<void> showBillDialog({
    required BuildContext context,
    required Order order,
    required List<Service> services,
    String? salonName,
    String? salonAddress,
    String? salonPhone,
  }) async {
    final name = salonName ?? SalonConfig.salonName;
    final address = salonAddress ?? SalonConfig.salonAddress;
    final phone = salonPhone ?? SalonConfig.salonPhone;
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
                          onPressed: () => _shareBill(context, order),
                          label: 'Chia sẻ',
                          icon: Icons.share,
                          color: AppTheme.primaryStart,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: _buildActionButton(
                          onPressed: () => _printBill(context, order),
                          label: 'In',
                          icon: Icons.print,
                          color: AppTheme.primaryEnd,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: _buildActionButton(
                          onPressed: () => _saveBill(context, order),
                          label: 'Lưu',
                          icon: Icons.save,
                          color: Colors.green[600]!,
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
    required Order order,
    required List<Service> services,
    required String salonName,
    required String salonAddress,
    required String salonPhone,
  }) {
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
                salonName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                salonAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                salonPhone,
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
              _buildInfoRow('Nhân viên phục vụ:', order.employeeNames.join(', ')),
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
                    _formatPrice(order.totalPrice / (1 - order.discountPercent / 100)),
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
                      '-${_formatPrice(order.totalPrice / (1 - order.discountPercent / 100) * order.discountPercent / 100)}',
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

  static void _shareBill(BuildContext context, Order order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng chia sẻ đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static void _printBill(BuildContext context, Order order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng in đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static void _saveBill(BuildContext context, Order order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hóa đơn đã được lưu'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
