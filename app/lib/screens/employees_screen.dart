import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../api_client.dart';
import '../models.dart';
import 'package:flutter/services.dart';
import '../ui/design_system.dart';
import 'dart:convert';
import '../generated/l10n/app_localizations.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<List<Employee>> _future = widget.api.getEmployees();
  String _search = '';
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getEmployees();
    });
  }

  Future<void> _pickImage(Function(XFile?, Uint8List?) onImageSelected) async {
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
        onImageSelected(image, bytes);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppWidgets.showFlushbar(context, l10n.cannotSelectImage,
            type: MessageType.error);
      }
    }
  }

  Widget _buildEmployeeImagePlaceholder() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32,
          color: AppTheme.primaryStart,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.selectImage,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryStart,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector(
      String? imageUrl, Uint8List? selectedImageBytes, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: selectedImageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.memory(
                  selectedImageBytes,
                  fit: BoxFit.cover,
                ),
              )
            : (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildEmployeeImagePlaceholder();
                            },
                          )
                        : _buildImageWidget(imageUrl),
                  )
                : _buildEmployeeImagePlaceholder(),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image/')) {
        // Xử lý data URL (base64)
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

  Future<void> _showAddDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? imageUrl;
    XFile? pickedImage;
    Uint8List? selectedImageBytes;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.addEmployee,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              l10n.enterNewEmployeeInfo,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildImageSelector(
                            imageUrl,
                            selectedImageBytes,
                            () => _pickImage((image, bytes) {
                                  setState(() {
                                    pickedImage = image;
                                    selectedImageBytes = bytes;
                                    imageUrl = '';
                                  });
                                })),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.fullName,
                                    prefixIcon: Icon(Icons.person,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterFullName;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: phoneCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.phone,
                                    prefixIcon: Icon(Icons.phone,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterPhoneNumber;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: passwordCtrl,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.password,
                                    prefixIcon: Icon(Icons.lock,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterPassword;
                                    }
                                    if (value.length < 6) {
                                      return l10n.passwordTooShort;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryStart
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.save,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      final phone = phoneCtrl.text.trim();

      try {
        final existing = await widget.api.findEmployeeByPhone(phone);
        if (existing != null) {
          AppWidgets.showFlushbar(
              context, AppLocalizations.of(context)!.employeePhoneExists,
              type: MessageType.warning);
          return;
        }
      } catch (ex) {
        // If not found, continue
      }
      try {
        String? imageUrlToSave;
        if (selectedImageBytes != null) {
          // Lấy extension hợp lệ, nếu không thì mặc định là .png
          String ext = pickedImage?.path != null
              ? path.extension(pickedImage!.path).toLowerCase()
              : '.png';
          const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
          if (!allowed.contains(ext)) ext = '.png';
          final fileName =
              'employee_${DateTime.now().millisecondsSinceEpoch}$ext';
          try {
            imageUrlToSave = await widget.api
                .uploadEmployeeImage(selectedImageBytes!, fileName);
          } catch (e) {
            AppWidgets.showFlushbar(
                context, l10n.errorUploadingImageToServer(e.toString()),
                type: MessageType.error);
            return;
          }
        }
        await widget.api.createEmployee(name,
            phone: phone,
            password: passwordCtrl.text.trim(),
            image: imageUrlToSave);
        await _reload();
        AppWidgets.showFlushbar(context, l10n.employeeAddedSuccessfully,
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(context, l10n.errorAddingEmployee,
            type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Employee e) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: e.name);
    final phoneCtrl = TextEditingController(text: e.phone ?? '');
    final passwordCtrl = TextEditingController();
    String? imageUrl = e.image;
    XFile? pickedImage;
    Uint8List? selectedImageBytes;

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.editEmployee,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              l10n.updateEmployeeInfo,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildImageSelector(
                            imageUrl,
                            selectedImageBytes,
                            () => _pickImage((image, bytes) {
                                  setState(() {
                                    pickedImage = image;
                                    selectedImageBytes = bytes;
                                    imageUrl = '';
                                  });
                                })),
                        const SizedBox(height: 20),
                        Form(
                          key: _editFormKey,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.fullName,
                                    prefixIcon: Icon(Icons.person,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterFullName;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: phoneCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.phone,
                                    prefixIcon: Icon(Icons.phone,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterPhoneNumber;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: passwordCtrl,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.newPasswordOptional,
                                    prefixIcon: Icon(Icons.lock,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null &&
                                        value.isNotEmpty &&
                                        value.length < 6) {
                                      return l10n.passwordTooShort;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryStart
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_editFormKey.currentState!.validate()) {
                                Navigator.pop(context, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.save,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      final name = nameCtrl.text.trim();
      final phone = phoneCtrl.text.trim();

      try {
        final existing = await widget.api.findEmployeeByPhone(phone);
        if (existing != null && existing.id != e.id) {
          AppWidgets.showFlushbar(
              context, AppLocalizations.of(context)!.employeePhoneExists,
              type: MessageType.warning);
          return;
        }
      } catch (ex) {
        // If not found, continue
      }

      try {
        String? imageUrlToSave = imageUrl;
        if (selectedImageBytes != null) {
          // Lấy extension hợp lệ, nếu không thì mặc định là .png
          String ext = pickedImage?.path != null
              ? path.extension(pickedImage!.path).toLowerCase()
              : '.png';
          const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
          if (!allowed.contains(ext)) ext = '.png';
          final fileName =
              'employee_${DateTime.now().millisecondsSinceEpoch}$ext';
          try {
            imageUrlToSave = await widget.api
                .uploadEmployeeImage(selectedImageBytes!, fileName);
          } catch (e) {
            AppWidgets.showFlushbar(
                context, l10n.errorUploadingImageToServer(e.toString()),
                type: MessageType.error);
            return;
          }
        }
        final password = passwordCtrl.text.trim();
        await widget.api.updateEmployee(Employee(
          id: e.id,
          name: name,
          phone: phone.isEmpty ? null : phone,
          password: password.isEmpty ? null : password,
          image: imageUrlToSave,
        ));
        await _reload();
        AppWidgets.showFlushbar(context, l10n.employeeInfoUpdatedSuccessfully,
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.errorUpdatingEmployee,
            type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Employee e) async {
    try {
      await widget.api.deleteEmployee(e.id);
      await _reload();
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.employeeDeletedSuccessfully,
          type: MessageType.success);
    } catch (e) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.errorDeletingEmployee,
          type: MessageType.error);
    }
  }

  Future<void> _showActionDialog(Employee e) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          e.name.isEmpty ? (e.phone ?? '') : e.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!
            .chooseAction(AppLocalizations.of(context)!.employee)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(e);
            },
            icon: const Icon(Icons.edit, color: Colors.green),
            label: Text(AppLocalizations.of(context)!.edit),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _delete(e);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.controlHeight / 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryStart.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppWidgets.gradientHeader(
                  icon: Icons.work,
                  title: l10n.employees,
                  subtitle: l10n.manageSalonEmployees,
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: AppTheme.controlHeight,
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: AppTheme.inputDecoration(
                      label: l10n.searchEmployees,
                      prefixIcon: Icons.search,
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height -
                      300, // Đảm bảo có chiều cao cố định
                  child: FutureBuilder<List<Employee>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        AppWidgets.showFlushbar(
                            context, l10n.errorLoadingEmployeeList,
                            type: MessageType.error);
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(
                            children: [
                              const SizedBox(height: 200),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.cannotLoadEmployeeList,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.checkNetworkOrTryAgain,
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _reload,
                                      child: Text(AppLocalizations.of(context)!
                                          .tryAgain),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final data = snapshot.data ?? [];
                      final filtered = data
                          .where((e) =>
                              e.name
                                  .toLowerCase()
                                  .contains(_search.toLowerCase()) ||
                              (e.phone ?? '')
                                  .toLowerCase()
                                  .contains(_search.toLowerCase()))
                          .toList();

                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView(children: [
                            const SizedBox(height: 200),
                            Center(
                                child: Text(AppLocalizations.of(context)!
                                    .noItemsFound(AppLocalizations.of(context)!
                                        .employee)))
                          ]),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final e = filtered[i];
                            return AppWidgets.animatedItem(
                              index: i,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showActionDialog(e),
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: AppTheme.primaryStart
                                      .withValues(alpha: 0.2),
                                  highlightColor: AppTheme.primaryEnd
                                      .withValues(alpha: 0.1),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          AppTheme.primaryStart
                                              .withValues(alpha: 0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.primaryStart
                                            .withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryStart
                                              .withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.primaryStart
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child: e.image != null &&
                                                      e.image!.isNotEmpty
                                                  ? _buildImageWidget(e.image!)
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        gradient: AppTheme
                                                            .primaryGradient,
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 24,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppTheme.primaryStart
                                                            .withValues(
                                                                alpha: 0.1),
                                                        AppTheme.primaryEnd
                                                            .withValues(
                                                                alpha: 0.1),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: AppTheme
                                                            .primaryStart
                                                            .withValues(
                                                                alpha: 0.2)),
                                                  ),
                                                  child: Text(
                                                    e.name.isEmpty
                                                        ? (e.phone ?? '')
                                                        : e.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.primaryStart,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppTheme.primaryStart
                                                            .withValues(
                                                                alpha: 0.05),
                                                        AppTheme.primaryEnd
                                                            .withValues(
                                                                alpha: 0.05),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.phone,
                                                        size: 12,
                                                        color:
                                                            AppTheme.primaryEnd,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        e.phone ?? '',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme
                                                              .primaryEnd,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
