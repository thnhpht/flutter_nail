import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import 'dart:convert';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<Service>> _future = Future.value([]);
  List<Category> _categories = [];
  String _search = '';
  final _searchController = TextEditingController();

  // Filter state
  List<Category> _selectedCategories = [];
  bool _showCategoryFilter = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _future = widget.api.getServices();
    });
    try {
      _categories = await widget.api.getCategories();
      setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _reload() async {
    await _load();
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
        AppWidgets.showFlushbar(
          context,
          'Không thể chọn hình ảnh. Vui lòng kiểm tra quyền truy cập.',
          type: MessageType.error,
        );
      }
    }
  }

  Widget _buildServiceImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32,
          color: AppTheme.primaryPink,
        ),
        const SizedBox(height: 4),
        Text(
          'Thêm ảnh',
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.primaryPink,
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
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.borderLight,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
          child: selectedImageBytes != null
              ? Image.memory(selectedImageBytes, fit: BoxFit.cover)
              : (imageUrl != null && imageUrl.isNotEmpty)
                  ? (imageUrl.startsWith('data:image/')
                      ? Image.memory(
                          base64Decode(imageUrl.split(',')[1]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildServiceImagePlaceholder(),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildServiceImagePlaceholder(),
                        ))
                  : _buildServiceImagePlaceholder(),
        ),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Category? selectedCategory;
    Uint8List? selectedImageBytes;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: AppTheme.floatingCardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusXL),
                      topRight: Radius.circular(AppTheme.radiusXL),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.textOnPrimary.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.spa,
                          color: AppTheme.textOnPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm dịch vụ',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textOnPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tạo dịch vụ mới cho salon',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textOnPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Image Section
                        Row(
                          children: [
                            _buildImageSelector(
                              null,
                              selectedImageBytes,
                              () => _pickImage((image, bytes) {
                                setDialogState(() {
                                  selectedImageBytes = bytes;
                                });
                              }),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hình ảnh dịch vụ',
                                    style: AppTheme.labelLarge,
                                  ),
                                  const SizedBox(height: AppTheme.spacingXS),
                                  Text(
                                    'Nhấn để chọn hình ảnh cho dịch vụ',
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Category Dropdown
                        DropdownButtonFormField<Category>(
                          decoration: AppTheme.inputDecoration(
                            label: 'Danh mục',
                            prefixIcon: Icons.category,
                          ),
                          value: selectedCategory,
                          items: _categories.map((category) {
                            return DropdownMenuItem<Category>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Vui lòng chọn danh mục' : null,
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Service Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: AppTheme.inputDecoration(
                            label: 'Tên dịch vụ',
                            prefixIcon: Icons.spa,
                          ),
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập tên dịch vụ'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Price
                        TextFormField(
                          controller: priceCtrl,
                          decoration: AppTheme.inputDecoration(
                            label: 'Giá dịch vụ (VNĐ)',
                            prefixIcon: Icons.attach_money,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập giá dịch vụ'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.spacingXL),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: AppWidgets.secondaryButton(
                                label: 'Hủy',
                                onPressed: () => Navigator.pop(context, false),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: AppWidgets.primaryButton(
                                label: 'Lưu',
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(context, true);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

      if (selectedCategory == null) return;

      try {
        String? imageBase64;
        if (selectedImageBytes != null) {
          imageBase64 =
              'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}';
        }

        await widget.api.createService(
          selectedCategory!.id,
          name,
          price,
          image: imageBase64,
        );

        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Thêm dịch vụ thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi thêm dịch vụ',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _showEditDialog(Service service) async {
    final nameCtrl = TextEditingController(text: service.name);
    final priceCtrl = TextEditingController(text: service.price.toString());
    final formKey = GlobalKey<FormState>();
    Category? selectedCategory = _categories.firstWhere(
      (cat) => cat.id == service.categoryId,
      orElse: () => _categories.first,
    );
    Uint8List? selectedImageBytes;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: AppTheme.floatingCardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusXL),
                      topRight: Radius.circular(AppTheme.radiusXL),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.textOnPrimary.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppTheme.textOnPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sửa dịch vụ',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textOnPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Cập nhật thông tin dịch vụ',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textOnPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Image Section
                        Row(
                          children: [
                            _buildImageSelector(
                              service.image,
                              selectedImageBytes,
                              () => _pickImage((image, bytes) {
                                setDialogState(() {
                                  selectedImageBytes = bytes;
                                });
                              }),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hình ảnh dịch vụ',
                                    style: AppTheme.labelLarge,
                                  ),
                                  const SizedBox(height: AppTheme.spacingXS),
                                  Text(
                                    'Nhấn để thay đổi hình ảnh',
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Category Dropdown
                        DropdownButtonFormField<Category>(
                          decoration: AppTheme.inputDecoration(
                            label: 'Danh mục',
                            prefixIcon: Icons.category,
                          ),
                          value: selectedCategory,
                          items: _categories.map((category) {
                            return DropdownMenuItem<Category>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Vui lòng chọn danh mục' : null,
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Service Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: AppTheme.inputDecoration(
                            label: 'Tên dịch vụ',
                            prefixIcon: Icons.spa,
                          ),
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập tên dịch vụ'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Price
                        TextFormField(
                          controller: priceCtrl,
                          decoration: AppTheme.inputDecoration(
                            label: 'Giá dịch vụ (VNĐ)',
                            prefixIcon: Icons.attach_money,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập giá dịch vụ'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.spacingXL),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: AppWidgets.secondaryButton(
                                label: 'Hủy',
                                onPressed: () => Navigator.pop(context, false),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: AppWidgets.primaryButton(
                                label: 'Lưu',
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(context, true);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

      if (selectedCategory == null) return;

      try {
        String? imageBase64 = service.image;
        if (selectedImageBytes != null) {
          imageBase64 =
              'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}';
        }

        await widget.api.updateService(Service(
          id: service.id,
          name: name,
          price: price,
          categoryId: selectedCategory!.id,
          image: imageBase64,
        ));

        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Cập nhật dịch vụ thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi cập nhật dịch vụ',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _delete(Service service) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Xác nhận xóa',
          style: AppTheme.headingSmall,
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa dịch vụ "${service.name}"?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          AppWidgets.secondaryButton(
            label: 'Hủy',
            onPressed: () => Navigator.pop(context, false),
            isSmall: true,
          ),
          AppWidgets.primaryButton(
            label: 'Xóa',
            onPressed: () => Navigator.pop(context, true),
            isSmall: true,
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await widget.api.deleteService(service.categoryId, service.id);
        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Xóa dịch vụ thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi xóa dịch vụ',
          type: MessageType.error,
        );
      }
    }
  }

  List<Service> _filterServices(List<Service> services) {
    List<Service> filtered = services;

    // Filter by search
    if (_search.isNotEmpty) {
      filtered = filtered.where((service) {
        final searchLower = _search.toLowerCase();
        return service.name.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Filter by categories
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((service) {
        return _selectedCategories.any((cat) => cat.id == service.categoryId);
      }).toList();
    }

    return filtered;
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lọc theo danh mục',
              style: AppTheme.labelLarge,
            ),
            AppWidgets.iconButton(
              icon: _showCategoryFilter ? Icons.expand_less : Icons.expand_more,
              onPressed: () {
                setState(() {
                  _showCategoryFilter = !_showCategoryFilter;
                });
              },
              size: 32,
            ),
          ],
        ),
        if (_showCategoryFilter) ...[
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: _categories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: AppTheme.primaryPink.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryPink,
                backgroundColor: AppTheme.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              );
            }).toList(),
          ),
          if (_selectedCategories.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            AppWidgets.secondaryButton(
              label: 'Xóa bộ lọc',
              onPressed: () {
                setState(() {
                  _selectedCategories.clear();
                });
              },
              isSmall: true,
            ),
          ],
        ],
      ],
    );
  }

  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return 'Không xác định';
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Dịch vụ',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          AppWidgets.iconButton(
            icon: Icons.add,
            onPressed: _showAddDialog,
            backgroundColor: AppTheme.primaryPink,
            iconColor: AppTheme.textOnPrimary,
            elevated: true,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý dịch vụ theo danh mục',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppWidgets.searchField(
                  hintText: 'Tìm kiếm dịch vụ...',
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
                const SizedBox(height: 16),
                _buildCategoryFilter(),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: FutureBuilder<List<Service>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPink,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể tải danh sách dịch vụ',
                          style: AppTheme.headingSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng kiểm tra kết nối mạng và thử lại',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppWidgets.primaryButton(
                          label: 'Thử lại',
                          onPressed: _reload,
                        ),
                      ],
                    ),
                  );
                }

                final services = _filterServices(snapshot.data ?? []);

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _search.isEmpty && _selectedCategories.isEmpty
                              ? Icons.spa_outlined
                              : Icons.search_off,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty && _selectedCategories.isEmpty
                              ? 'Chưa có dịch vụ nào'
                              : 'Không tìm thấy kết quả',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isEmpty && _selectedCategories.isEmpty
                              ? 'Hãy thêm dịch vụ đầu tiên cho salon'
                              : 'Thử tìm kiếm với từ khóa khác hoặc thay đổi bộ lọc',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_search.isEmpty && _selectedCategories.isEmpty) ...[
                          const SizedBox(height: 24),
                          AppWidgets.primaryButton(
                            label: 'Thêm dịch vụ',
                            onPressed: _showAddDialog,
                            icon: Icons.add,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  color: AppTheme.primaryPink,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppTheme.getResponsiveColumns(
                        context,
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                      ),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(service);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showEditDialog(service),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      topRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      topRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                    child: service.image != null && service.image!.isNotEmpty
                        ? (service.image!.startsWith('data:image/')
                            ? Image.memory(
                                base64Decode(service.image!.split(',')[1]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildServiceImagePlaceholder(),
                              )
                            : Image.network(
                                service.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildServiceImagePlaceholder(),
                              ))
                        : _buildServiceImagePlaceholder(),
                  ),
                ),
              ),

              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      AppWidgets.statusBadge(
                        text: _getCategoryName(service.categoryId),
                        color: AppTheme.primaryPinkLight,
                      ),
                      const SizedBox(height: AppTheme.spacingS),

                      // Service Name
                      Text(
                        service.name,
                        style: AppTheme.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // Price and Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatPrice(service.price),
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.primaryPink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppWidgets.iconButton(
                                icon: Icons.edit,
                                onPressed: () => _showEditDialog(service),
                                backgroundColor: AppTheme.info.withOpacity(0.1),
                                iconColor: AppTheme.info,
                                size: 32,
                              ),
                              const SizedBox(width: 4),
                              AppWidgets.iconButton(
                                icon: Icons.delete,
                                onPressed: () => _delete(service),
                                backgroundColor:
                                    AppTheme.error.withOpacity(0.1),
                                iconColor: AppTheme.error,
                                size: 32,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
