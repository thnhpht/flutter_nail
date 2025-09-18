import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';

class SalonInfoScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback? onSalonInfoUpdated;

  const SalonInfoScreen({
    super.key,
    required this.api,
    this.onSalonInfoUpdated,
  });

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
  Uint8List? _selectedLogoBytes;
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
        AppWidgets.showFlushbar(
          context,
          'Không thể tải thông tin salon: $e',
          type: MessageType.error,
        );
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
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isQRCode) {
            _selectedQRCodeBytes = bytes;
          } else {
            _selectedLogoBytes = bytes;
          }
        });
      }
    } catch (e) {
      AppWidgets.showFlushbar(
        context,
        'Lỗi chọn hình ảnh: $e',
        type: MessageType.error,
      );
    }
  }

  Future<void> _saveInformation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? logoBase64;
      String? qrCodeBase64;

      if (_selectedLogoBytes != null) {
        logoBase64 = base64Encode(_selectedLogoBytes!);
      }

      if (_selectedQRCodeBytes != null) {
        qrCodeBase64 = base64Encode(_selectedQRCodeBytes!);
      }

      final updatedInfo = Information(
        id: _information?.id ?? 0,
        salonName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        facebook: _facebookController.text.trim(),
        instagram: _instagramController.text.trim(),
        zalo: _zaloController.text.trim(),
        logo: logoBase64 ?? _logoUrl,
        qrCode: qrCodeBase64 ?? _qrCodeUrl,
        createdAt: _information?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.api.updateInformation(updatedInfo);

      setState(() {
        _information = updatedInfo;
        _selectedLogoBytes = null;
        _selectedQRCodeBytes = null;
        if (logoBase64 != null) _logoUrl = logoBase64;
        if (qrCodeBase64 != null) _qrCodeUrl = qrCodeBase64;
      });

      AppWidgets.showFlushbar(
        context,
        'Cập nhật thông tin salon thành công!',
        type: MessageType.success,
      );

      if (widget.onSalonInfoUpdated != null) {
        widget.onSalonInfoUpdated!();
      }
    } catch (e) {
      AppWidgets.showFlushbar(
        context,
        'Lỗi cập nhật thông tin: $e',
        type: MessageType.error,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Thông tin Salon',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          AppWidgets.iconButton(
            icon: Icons.refresh,
            onPressed: _loadInformation,
            size: 40,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryPink,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: AppTheme.cardDecoration(elevated: true),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: AppTheme.textOnPrimary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin Salon',
                                  style: AppTheme.headingSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Cập nhật thông tin chi tiết về salon của bạn',
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Images Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevated: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppTheme.radiusLarge),
                                topRight: Radius.circular(AppTheme.radiusLarge),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.image,
                                  color: AppTheme.info,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Text(
                                  'Logo và QR Code',
                                  style: AppTheme.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildImageSelector(
                                    title: 'Logo Salon',
                                    imageBytes: _selectedLogoBytes,
                                    imageUrl: _logoUrl,
                                    onTap: () => _pickImage(isQRCode: false),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: _buildImageSelector(
                                    title: 'QR Code',
                                    imageBytes: _selectedQRCodeBytes,
                                    imageUrl: _qrCodeUrl,
                                    onTap: () => _pickImage(isQRCode: true),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Basic Information Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevated: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppTheme.radiusLarge),
                                topRight: Radius.circular(AppTheme.radiusLarge),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: AppTheme.primaryPink,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Text(
                                  'Thông tin cơ bản',
                                  style: AppTheme.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: AppTheme.inputDecoration(
                                    label: 'Tên Salon',
                                    prefixIcon: Icons.store,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập tên salon';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: AppTheme.inputDecoration(
                                    label: 'Địa chỉ',
                                    prefixIcon: Icons.location_on,
                                  ),
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập địa chỉ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        decoration: AppTheme.inputDecoration(
                                          label: 'Số điện thoại',
                                          prefixIcon: Icons.phone,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Vui lòng nhập số điện thoại';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        decoration: AppTheme.inputDecoration(
                                          label: 'Email',
                                          prefixIcon: Icons.email,
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty) {
                                            if (!RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'Email không hợp lệ';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Social Media Section
                    Container(
                      decoration: AppTheme.cardDecoration(elevated: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppTheme.radiusLarge),
                                topRight: Radius.circular(AppTheme.radiusLarge),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.share,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Text(
                                  'Mạng xã hội & Liên hệ',
                                  style: AppTheme.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _websiteController,
                                  decoration: AppTheme.inputDecoration(
                                    label: 'Website',
                                    prefixIcon: Icons.language,
                                  ),
                                  keyboardType: TextInputType.url,
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                TextFormField(
                                  controller: _facebookController,
                                  decoration: AppTheme.inputDecoration(
                                    label: 'Facebook',
                                    prefixIcon: Icons.facebook,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _instagramController,
                                        decoration: AppTheme.inputDecoration(
                                          label: 'Instagram',
                                          prefixIcon: Icons.camera_alt,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _zaloController,
                                        decoration: AppTheme.inputDecoration(
                                          label: 'Zalo',
                                          prefixIcon: Icons.chat,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: AppWidgets.primaryButton(
                        label: _isSaving ? 'Đang lưu...' : 'Lưu thông tin',
                        onPressed: _isSaving ? null : _saveInformation,
                        icon: _isSaving ? null : Icons.save,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSelector({
    required String title,
    required Uint8List? imageBytes,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 2,
              ),
            ),
            child: imageBytes != null
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium - 2),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                  )
                : imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium - 2),
                        child: _buildImageFromBase64(imageUrl),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: AppTheme.textTertiary,
                            size: 32,
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Chọn hình ảnh',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      if (base64String.startsWith('data:image')) {
        // Remove data:image/xxx;base64, prefix if present
        final base64Data = base64String.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        );
      } else {
        // Try to decode directly
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        );
      }
    } catch (e) {
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: AppTheme.textTertiary,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Lỗi hiển thị',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
