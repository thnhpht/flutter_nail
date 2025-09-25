import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import 'dart:convert';
import '../generated/l10n/app_localizations.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = widget.api.getCategories();
  String _search = '';
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

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
        final l10n = AppLocalizations.of(context)!;
        AppWidgets.showFlushbar(context, l10n.cannotSelectImage,
            type: MessageType.error);
      }
    }
  }

  Widget _buildCategoryImagePlaceholder() {
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: selectedImageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  selectedImageBytes,
                  fit: BoxFit.cover,
                ),
              )
            : (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildCategoryImagePlaceholder();
                            },
                          )
                        : _buildImageWidget(imageUrl),
                  )
                : _buildCategoryImagePlaceholder(),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
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
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.only(
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
                        child: const Icon(Icons.category,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.addCategory,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.addCategory,
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
                                    labelText: AppLocalizations.of(context)!
                                        .categoryName,
                                    prefixIcon: Icon(Icons.category,
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
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterName;
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
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(
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
                              AppLocalizations.of(context)!.save,
                              style: const TextStyle(
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
      if (name.isEmpty) {
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.categoryNameRequired,
            type: MessageType.warning);
        return;
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
              'category_${DateTime.now().millisecondsSinceEpoch}$ext';
          try {
            imageUrlToSave = await widget.api
                .uploadCategoryImage(selectedImageBytes!, fileName);
          } catch (e) {
            AppWidgets.showFlushbar(
                context,
                AppLocalizations.of(context)!
                    .errorUploadingImageToServer(e.toString()),
                type: MessageType.error);
            return;
          }
        }
        await widget.api.createCategory(
          name,
          image: imageUrlToSave,
        );
        await _reload();
        AppWidgets.showFlushbar(context, l10n.categoryAddedSuccessfully,
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(context, l10n.errorAddingCategory,
            type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Category c) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: c.name);

    String? imageUrl = c.image;
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
                              l10n.editCategory,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.updateCategoryInfo,
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
                                    labelText: AppLocalizations.of(context)!
                                        .categoryName,
                                    prefixIcon: Icon(Icons.category,
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
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterName;
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
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(
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
                              AppLocalizations.of(context)!.save,
                              style: const TextStyle(
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
      if (name.isEmpty) {
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.categoryNameRequired,
            type: MessageType.warning);
        return;
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
              'category_${DateTime.now().millisecondsSinceEpoch}$ext';
          try {
            imageUrlToSave = await widget.api
                .uploadCategoryImage(selectedImageBytes!, fileName);
          } catch (e) {
            AppWidgets.showFlushbar(
                context,
                AppLocalizations.of(context)!
                    .errorUploadingImageToServer(e.toString()),
                type: MessageType.error);
            return;
          }
        }
        await widget.api.updateCategory(Category(
          id: c.id,
          name: name,
          items: c.items,
          image: imageUrlToSave,
        ));
        await _reload();
        AppWidgets.showFlushbar(context,
            AppLocalizations.of(context)!.categoryInfoUpdatedSuccessfully,
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.errorUpdatingCategory,
            type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Category c) async {
    try {
      await widget.api.deleteCategory(c.id);
      await _reload();
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.categoryDeletedSuccessfully,
          type: MessageType.success);
    } catch (e) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.errorDeletingCategory,
          type: MessageType.error);
    }
  }

  Future<void> _showActionDialog(Category c) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          c.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!
            .chooseAction(AppLocalizations.of(context)!.category)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(c);
            },
            icon: const Icon(Icons.edit, color: Colors.green),
            label: Text(AppLocalizations.of(context)!.edit),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _delete(c);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
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
          body: RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              slivers: [
                // Header Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppWidgets.gradientHeader(
                          icon: Icons.category,
                          title: AppLocalizations.of(context)!.categoriesTitle,
                          subtitle: AppLocalizations.of(context)!
                              .categoriesListDescription,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: AppTheme.controlHeight,
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            decoration: AppTheme.inputDecoration(
                              label: AppLocalizations.of(context)!
                                  .searchCategories,
                              prefixIcon: Icons.search,
                            ),
                            onChanged: (v) =>
                                setState(() => _search = v.trim()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories Grid
                FutureBuilder<List<Category>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      AppWidgets.showFlushbar(
                          context,
                          AppLocalizations.of(context)!
                              .errorLoadingCategoriesList,
                          type: MessageType.error);
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const SizedBox(height: 200),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .cannotLoadCategoriesList,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .checkNetworkOrTryAgainCategories,
                                      style: const TextStyle(
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
                        ),
                      );
                    }

                    final data = snapshot.data ?? [];
                    final filtered = data
                        .where((c) => c.name
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                        .toList();

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const SizedBox(height: 200),
                              Center(
                                  child: Text(AppLocalizations.of(context)!
                                      .noItemsFound(
                                          AppLocalizations.of(context)!
                                              .category))),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final c = filtered[i];
                            return AppWidgets.animatedItem(
                              index: i,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showActionDialog(c),
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: AppTheme.primaryStart
                                      .withValues(alpha: 0.2),
                                  highlightColor: AppTheme.primaryEnd
                                      .withValues(alpha: 0.1),
                                  child: Container(
                                    decoration: BoxDecoration(
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
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Background Image or Gradient
                                          c.image != null && c.image!.isNotEmpty
                                              ? _buildImageWidget(c.image!)
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    gradient: AppTheme
                                                        .primaryGradient,
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.category,
                                                      size: 60,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          // Content
                                          Positioned(
                                            left: 12,
                                            right: 12,
                                            bottom: 12,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Category Name
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
                                                                alpha: 0.9),
                                                        AppTheme.primaryEnd
                                                            .withValues(
                                                                alpha: 0.9),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme
                                                            .primaryStart
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    c.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                          childCount: filtered.length,
                        ),
                      ),
                    );
                  },
                ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
