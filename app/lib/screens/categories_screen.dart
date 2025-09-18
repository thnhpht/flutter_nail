import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import 'dart:convert';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = widget.api.getCategories();
  String _search = '';
  final _searchController = TextEditingController();

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getCategories();
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
        AppWidgets.showFlushbar(
          context,
          'Không thể chọn hình ảnh. Vui lòng kiểm tra quyền truy cập.',
          type: MessageType.error,
        );
      }
    }
  }

  Widget _buildCategoryImagePlaceholder() {
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
                              _buildCategoryImagePlaceholder(),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCategoryImagePlaceholder(),
                        ))
                  : _buildCategoryImagePlaceholder(),
        ),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Uint8List? selectedImageBytes;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                          Icons.category,
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
                              'Thêm danh mục',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textOnPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tạo danh mục dịch vụ mới',
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
                                    'Hình ảnh danh mục',
                                    style: AppTheme.labelLarge,
                                  ),
                                  const SizedBox(height: AppTheme.spacingXS),
                                  Text(
                                    'Nhấn để chọn hình ảnh cho danh mục',
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Category Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: AppTheme.inputDecoration(
                            label: 'Tên danh mục',
                            prefixIcon: Icons.category,
                          ),
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập tên danh mục'
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

      try {
        String? imageBase64;
        if (selectedImageBytes != null) {
          imageBase64 =
              'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}';
        }

        await widget.api.createCategory(name, image: imageBase64);
        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Thêm danh mục thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi thêm danh mục',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _showEditDialog(Category category) async {
    final nameCtrl = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();
    Uint8List? selectedImageBytes;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                              'Sửa danh mục',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textOnPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Cập nhật thông tin danh mục',
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
                              category.image,
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
                                    'Hình ảnh danh mục',
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

                        // Category Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: AppTheme.inputDecoration(
                            label: 'Tên danh mục',
                            prefixIcon: Icons.category,
                          ),
                          validator: (v) => v?.trim().isEmpty == true
                              ? 'Vui lòng nhập tên danh mục'
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

      try {
        String? imageBase64 = category.image;
        if (selectedImageBytes != null) {
          imageBase64 =
              'data:image/jpeg;base64,${base64Encode(selectedImageBytes!)}';
        }

        await widget.api.updateCategory(Category(
          id: category.id,
          name: name,
          items: category.items,
          image: imageBase64,
        ));

        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Cập nhật danh mục thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi cập nhật danh mục',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _delete(Category category) async {
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
          'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?\nTất cả dịch vụ trong danh mục này cũng sẽ bị xóa.',
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
        await widget.api.deleteCategory(category.id);
        await _reload();
        AppWidgets.showFlushbar(
          context,
          'Xóa danh mục thành công',
          type: MessageType.success,
        );
      } catch (e) {
        AppWidgets.showFlushbar(
          context,
          'Lỗi khi xóa danh mục',
          type: MessageType.error,
        );
      }
    }
  }

  List<Category> _filterCategories(List<Category> categories) {
    if (_search.isEmpty) return categories;

    return categories.where((category) {
      final searchLower = _search.toLowerCase();
      return category.name.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Danh mục',
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
          // Search Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý danh mục dịch vụ',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppWidgets.searchField(
                  hintText: 'Tìm kiếm danh mục...',
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: FutureBuilder<List<Category>>(
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
                          'Không thể tải danh sách danh mục',
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

                final categories = _filterCategories(snapshot.data ?? []);

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _search.isEmpty
                              ? Icons.category_outlined
                              : Icons.search_off,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'Chưa có danh mục nào'
                              : 'Không tìm thấy kết quả',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isEmpty
                              ? 'Hãy thêm danh mục đầu tiên cho salon'
                              : 'Thử tìm kiếm với từ khóa khác',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_search.isEmpty) ...[
                          const SizedBox(height: 24),
                          AppWidgets.primaryButton(
                            label: 'Thêm danh mục',
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
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryCard(category);
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

  Widget _buildCategoryCard(Category category) {
    return Container(
      decoration: AppTheme.cardDecoration(elevated: true),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => _showEditDialog(category),
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
                    child: category.image != null && category.image!.isNotEmpty
                        ? (category.image!.startsWith('data:image/')
                            ? Image.memory(
                                base64Decode(category.image!.split(',')[1]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCategoryImagePlaceholder(),
                              )
                            : Image.network(
                                category.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCategoryImagePlaceholder(),
                              ))
                        : _buildCategoryImagePlaceholder(),
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
                      // Category Name
                      Text(
                        category.name,
                        style: AppTheme.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),

                      // Services Count
                      Text(
                        '${category.items.length} dịch vụ',
                        style: AppTheme.bodySmall,
                      ),
                      const Spacer(),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppWidgets.iconButton(
                            icon: Icons.edit,
                            onPressed: () => _showEditDialog(category),
                            backgroundColor: AppTheme.info.withOpacity(0.1),
                            iconColor: AppTheme.info,
                            size: 32,
                          ),
                          const SizedBox(width: 4),
                          AppWidgets.iconButton(
                            icon: Icons.delete,
                            onPressed: () => _delete(category),
                            backgroundColor: AppTheme.error.withOpacity(0.1),
                            iconColor: AppTheme.error,
                            size: 32,
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
