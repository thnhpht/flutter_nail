import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'dart:convert';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class SalonInfoScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback? onSalonInfoUpdated;

  const SalonInfoScreen(
      {super.key, required this.api, this.onSalonInfoUpdated});

  @override
  State<SalonInfoScreen> createState() => _SalonInfoScreenState();
}


class _SalonInfoScreenState extends State<SalonInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _zaloController = TextEditingController();

  Information? _information;
  bool _isLoading = true;
  bool _isSaving = false;
  String _logoUrl = '';
  String _qrCodeUrl = '';
  Uint8List? _selectedImageBytes;
  Uint8List? _selectedQRCodeBytes;

  @override
  void initState() {
    super.initState();
    _loadInformation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _zaloController.dispose();
    super.dispose();
  }


  Future<void> _loadInformation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final information = await widget.api.getInformation();
      setState(() {
        _information = information;
        _nameController.text = information.salonName;
        _addressController.text = information.address;
        _phoneController.text = information.phone;
        _emailController.text = information.email;
        _websiteController.text = information.website;
        _facebookController.text = information.facebook;
        _instagramController.text = information.instagram;
        _zaloController.text = information.zalo;
        _logoUrl = information.logo;
        _qrCodeUrl = information.qrCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppWidgets.showFlushbar(context, 
            'Không thể tải thông tin salon. Vui lòng kiểm tra kết nối mạng và thử lại.',
            type: MessageType.error);
      }
    }
  }

  Future<void> _pickImage({bool isQRCode = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        setState(() {
          if (isQRCode) {
            _selectedQRCodeBytes = bytes;
            _qrCodeUrl = '';
          } else {
            _selectedImageBytes = bytes;
            _logoUrl = '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showFlushbar(context, 
            'Không thể chọn hình ảnh. Vui lòng kiểm tra quyền truy cập thư viện ảnh và thử lại.',
            type: MessageType.error);
      }
    }
  }

  Future<void> _saveInformation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      String logoUrl = _logoUrl;
      // Upload new images if selected
      String qrCodeUrl = _qrCodeUrl;

      if (_selectedImageBytes != null) {
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
        try {
          logoUrl = await widget.api.uploadLogo(_selectedImageBytes!, fileName);
        } catch (e) {
          setState(() {
            _isSaving = false;
          });
          AppWidgets.showFlushbar(context, 'Lỗi khi upload logo lên server',
              type: MessageType.error);
          return;
        }
      }

      if (_selectedQRCodeBytes != null) {
        final fileName = 'qrcode_${DateTime.now().millisecondsSinceEpoch}.png';
        try {
          qrCodeUrl =
              await widget.api.uploadQRCode(_selectedQRCodeBytes!, fileName);
        } catch (e) {
          setState(() {
            _isSaving = false;
          });
          AppWidgets.showFlushbar(context, 'Lỗi khi upload QR code lên server',
              type: MessageType.error);
          return;
        }
      }

      final information = Information(
        id: _information?.id ?? 0,
        salonName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        facebook: _facebookController.text.trim(),
        instagram: _instagramController.text.trim(),
        zalo: _zaloController.text.trim(),
        logo: logoUrl,
        qrCode: qrCodeUrl,
        createdAt: _information?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.api.updateInformation(information);

      setState(() {
        _information = information;
        _logoUrl = logoUrl;
        _qrCodeUrl = qrCodeUrl;
        _selectedImageBytes = null;
        _selectedQRCodeBytes = null;
        _isSaving = false;
      });

      if (mounted) {
        AppWidgets.showFlushbar(context, 'Lưu thông tin salon thành công!',
            type: MessageType.success);
        // Call callback to refresh main screen
        widget.onSalonInfoUpdated?.call();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        AppWidgets.showFlushbar(context, 
            'Không thể lưu thông tin salon. Vui lòng kiểm tra kết nối mạng và thử lại.',
            type: MessageType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryStart),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: AppTheme.spacingXL),

              // Logo Section
              _buildLogoSection(),
              const SizedBox(height: AppTheme.spacingXL),

              // QR Code Section
              _buildQRCodeSection(),
              const SizedBox(height: AppTheme.spacingXL),

              // Basic Information
              _buildSectionTitle('Thông tin cơ bản'),
              const SizedBox(height: AppTheme.spacingL),
              _buildBasicInfoFields(),
              const SizedBox(height: AppTheme.spacingXL),

              // Social Media
              _buildSectionTitle('Mạng xã hội'),
              const SizedBox(height: AppTheme.spacingL),
              _buildSocialMediaFields(),
              const SizedBox(height: AppTheme.spacingXL),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryStart.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.business,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin Salon',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Quản lý thông tin và liên hệ của salon',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QR Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Center(
            child: InkWell(
              onTap: () => _pickImage(isQRCode: true),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: _selectedQRCodeBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _selectedQRCodeBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (_qrCodeUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _qrCodeUrl.startsWith('http')
                                ? Image.network(
                                    _qrCodeUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderQRCode(),
                                  )
                                : _buildImageWidget(_qrCodeUrl),
                          )
                        : _buildPlaceholderQRCode(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Center(
            child: TextButton.icon(
              onPressed: () => _pickImage(isQRCode: true),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Chọn QR Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderQRCode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.qr_code,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Chọn QR Code',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logo salon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Center(
            child: InkWell(
              onTap: _pickImage,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (_logoUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _logoUrl.startsWith('http')
                                ? Image.network(
                                    _logoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderLogo(),
                                  )
                                : _buildImageWidget(_logoUrl),
                          )
                        : _buildPlaceholderLogo(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Center(
            child: TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Thay đổi logo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.qr_code,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Chọn Logo',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image/')) {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } else if (imageUrl.startsWith('http://') ||
          imageUrl.startsWith('https://')) {
        return Image.network(imageUrl, fit: BoxFit.cover);
      } else if (imageUrl.startsWith('/')) {
        return Image.file(File(imageUrl), fit: BoxFit.cover);
      } else {
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(Icons.image, color: Colors.grey[600], size: 32),
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryStart),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
      ),
    );
  }

  Widget _buildBasicInfoFields() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Tên Salon',
            icon: Icons.business,
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTextField(
            controller: _addressController,
            label: 'Địa chỉ',
            icon: Icons.location_on,
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTextField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.language,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaFields() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _facebookController,
            label: 'Facebook',
            icon: Icons.facebook,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTextField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTextField(
            controller: _zaloController,
            label: 'Zalo',
            icon: Icons.chat,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryStart.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: _isSaving ? null : _saveInformation,
          child: Center(
            child: _isSaving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingM),
                      Text(
                        'Đang lưu...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.save,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Lưu thông tin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
}
