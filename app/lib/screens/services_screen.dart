import '../generated/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
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
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  // Filter state
  List<Category> _selectedCategories = [];
  List<Category> _appliedCategories = [];
  bool _showCategoryFilter = false;

  // Sorting state
  String? _selectedSortOption;
  String? _appliedSortOption;

  // Sorting options will be created dynamically with localization
  Map<String, String> _getSortOptions(BuildContext context) {
    return {
      'alphabetical_az': AppLocalizations.of(context)!.sortAlphabeticalAZ,
      'alphabetical_za': AppLocalizations.of(context)!.sortAlphabeticalZA,
      'newest_first': AppLocalizations.of(context)!.sortNewestFirst,
      'oldest_first': AppLocalizations.of(context)!.sortOldestFirst,
      'price_high_to_low': AppLocalizations.of(context)!.sortPriceHighToLow,
      'price_low_to_high': AppLocalizations.of(context)!.sortPriceLowToHigh,
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Thêm method _pickImage cải tiến
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
            context, AppLocalizations.of(context)!.cannotSelectImage,
            type: MessageType.error);
      }
    }
  }

  // Thêm method tạo placeholder image
  Widget _buildServiceImagePlaceholder() {
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
          AppLocalizations.of(context)!.addImage,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryStart,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Cải tiến image display widget
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
                              return _buildServiceImagePlaceholder();
                            },
                          )
                        : _buildImageWidget(imageUrl),
                  )
                : _buildServiceImagePlaceholder(),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  Future<void> _load() async {
    final cats = await widget.api.getCategories();
    setState(() {
      _categories = cats;
      _future = widget.api.getServices();
    });
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.getServices();
    });
  }

  // Filter methods
  void _toggleCategoryFilter() {
    setState(() {
      _showCategoryFilter = !_showCategoryFilter;
    });
  }

  void _onCategoryToggled(Category category) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _appliedCategories.clear();
      _search = '';
      _selectedSortOption = null;
      _appliedSortOption = null;
    });
  }

  void _applyFilters() {
    setState(() {
      _appliedCategories = List.from(_selectedCategories);
      _appliedSortOption = _selectedSortOption;
      _showCategoryFilter = false;
    });
  }

  List<Service> _filterServices(List<Service> services) {
    List<Service> filtered = services;

    // Filter by search
    if (_search.isNotEmpty) {
      filtered = filtered
          .where((s) => s.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    // Filter by applied categories
    if (_appliedCategories.isNotEmpty) {
      filtered = filtered
          .where((s) => _appliedCategories.any((cat) => cat.id == s.categoryId))
          .toList();
    }

    // Apply sorting
    return _sortServices(filtered);
  }

  List<Service> _sortServices(List<Service> services) {
    if (_appliedSortOption == null) return services;

    List<Service> sorted = List.from(services);

    switch (_appliedSortOption) {
      case 'alphabetical_az':
        sorted.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'alphabetical_za':
        sorted.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'newest_first':
        // Assuming code represents creation order - higher code = newer
        sorted.sort((a, b) => (b.code ?? 0).compareTo(a.code ?? 0));
        break;
      case 'oldest_first':
        // Assuming code represents creation order - lower code = higher
        sorted.sort((a, b) => (a.code ?? 0).compareTo(b.code ?? 0));
        break;
      case 'price_high_to_low':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'price_low_to_high':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      default:
        break;
    }

    return sorted;
  }

  Widget _buildCompactCategoryFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.categoryFilter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.selectCategoriesToFilter,
                        style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Selected Categories Chips
                if (_selectedCategories.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCategories.map((category) {
                      return _buildChip(
                        label: category.name,
                        onDeleted: () => _onCategoryToggled(category),
                        color: const Color(0xFF7386dd),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Category Dropdown Button
                _buildDropdownButton(
                  onTap: _toggleCategoryFilter,
                  label: _appliedCategories.isEmpty
                      ? AppLocalizations.of(context)!.selectCategory
                      : AppLocalizations.of(context)!
                          .categoriesSelected(_appliedCategories.length),
                  isExpanded: _showCategoryFilter,
                  selectText: AppLocalizations.of(context)!.select,
                ),

                // Category Dropdown Menu
                if (_showCategoryFilter) ...[
                  const SizedBox(height: 8),
                  _buildDropdownMenu(
                    maxHeight: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected =
                            _selectedCategories.contains(category);
                        return _buildDropdownCategoryItem(
                          title: category.name,
                          isSelected: isSelected,
                          onTap: () => _onCategoryToggled(category),
                          image: category.image,
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Sorting Section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.sortBy,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 12),

                // Sort Options
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getSortOptions(context).entries.map((entry) {
                    final isSelected = _selectedSortOption == entry.key;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedSortOption = _selectedSortOption == entry.key
                              ? null
                              : entry.key;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: [
                                  Color(0xFF7386dd),
                                  Color(0xFF5a6fd8)
                                ])
                              : LinearGradient(colors: [
                                  Colors.grey[100]!,
                                  Colors.grey[200]!,
                                ]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF7386dd)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSecondaryButton(
                        onPressed: _clearAllFilters,
                        label: AppLocalizations.of(context)!.clearFilter,
                        icon: Icons.clear,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPrimaryButton(
                        onPressed: _applyFilters,
                        isLoading: false,
                        label: AppLocalizations.of(context)!.apply,
                        icon: Icons.check,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    String? selectedCatId =
        _categories.isNotEmpty ? _categories.first.id : null;
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
              maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        child: const Icon(Icons.shopping_cart,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.addService,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.createNewService,
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
                              imageUrl =
                                  ''; // Clear old URL when new image is selected
                            });
                          }),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCatId,
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                    value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) => selectedCatId = v,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.categories,
                              prefixIcon: const Icon(Icons.category,
                                  color: AppTheme.primaryStart),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                        .serviceName,
                                    prefixIcon: const Icon(Icons.shopping_cart,
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
                                          .pleaseEnterServiceName;
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
                                  controller: priceCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${AppLocalizations.of(context)!.price} (${AppLocalizations.of(context)!.vnd})',
                                    prefixIcon: const Icon(Icons.attach_money,
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
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterPrice;
                                    }
                                    if (double.tryParse(value.trim()) == null) {
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterValidPrice;
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
                                  controller: unitCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${AppLocalizations.of(context)!.unit}',
                                    prefixIcon: const Icon(Icons.straighten,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
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

    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      final unit = unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim();

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
              'service_${DateTime.now().millisecondsSinceEpoch}$ext';
          try {
            imageUrlToSave = await widget.api
                .uploadServiceImage(selectedImageBytes!, fileName);
          } catch (e) {
            AppWidgets.showFlushbar(
                context, AppLocalizations.of(context)!.errorUploadingImage,
                type: MessageType.error);
            return;
          }
        }
        await widget.api.createService(selectedCatId!, name, price,
            image: imageUrlToSave, unit: unit);
        await _reload();
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.serviceAddedSuccessfully,
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.errorAddingService,
            type: MessageType.error);
      }
    }
  }

  Future<void> _showEditDialog(Service s) async {
    final nameCtrl = TextEditingController(text: s.name);
    final priceCtrl = TextEditingController(text: s.price.toStringAsFixed(0));
    final unitCtrl = TextEditingController(text: s.unit ?? '');
    String? selectedCatId = s.categoryId;
    String? imageUrl = s.image;
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
              maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.editService,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.updateServiceInfo,
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
                              imageUrl =
                                  ''; // Clear old URL when new image is selected
                            });
                          }),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCatId,
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                    value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) => selectedCatId = v,
                            decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.categories,
                              prefixIcon: const Icon(Icons.category,
                                  color: AppTheme.primaryStart),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                        .serviceName,
                                    prefixIcon: const Icon(Icons.shopping_cart,
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
                                          .pleaseEnterServiceName;
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
                                  controller: priceCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${AppLocalizations.of(context)!.price} (${AppLocalizations.of(context)!.vnd})',
                                    prefixIcon: const Icon(Icons.attach_money,
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
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterPrice;
                                    }
                                    if (double.tryParse(value.trim()) == null) {
                                      return AppLocalizations.of(context)!
                                          .pleaseEnterValidPrice;
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
                                  controller: unitCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${AppLocalizations.of(context)!.unit}',
                                    prefixIcon: const Icon(Icons.straighten,
                                        color: AppTheme.primaryStart),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
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

    if (ok == true && selectedCatId != null) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? s.price;
      final unit = unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim();

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
              'service_${DateTime.now().millisecondsSinceEpoch}$ext';
          try {
            imageUrlToSave = await widget.api
                .uploadServiceImage(selectedImageBytes!, fileName);
          } catch (e) {
            AppWidgets.showFlushbar(
                context, AppLocalizations.of(context)!.errorUploadingImage,
                type: MessageType.error);
            return;
          }
        }
        await widget.api.updateService(Service(
          id: s.id,
          categoryId: selectedCatId!,
          name: name,
          price: price,
          image: imageUrlToSave,
          unit: unit,
          code: s.code, // Giữ nguyên code từ service gốc
        ));
        await _reload();
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.serviceUpdatedSuccessfully,
            type: MessageType.success);
      } catch (e) {
        AppWidgets.showFlushbar(
            context, AppLocalizations.of(context)!.errorUpdatingService,
            type: MessageType.error);
      }
    }
  }

  Future<void> _delete(Service s) async {
    try {
      await widget.api.deleteService(s.categoryId, s.id);
      await _reload();
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.serviceDeletedSuccessfully,
          type: MessageType.success);
    } catch (e) {
      AppWidgets.showFlushbar(
          context, AppLocalizations.of(context)!.errorDeletingService,
          type: MessageType.error);
    }
  }

  Future<void> _showActionDialog(Service s) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!
            .chooseAction(AppLocalizations.of(context)!.item)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(s);
            },
            icon: const Icon(Icons.edit, color: Colors.green),
            label: Text(AppLocalizations.of(context)!.edit),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _delete(s);
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

  Widget _buildChip({
    required String label,
    required VoidCallback onDeleted,
    required Color color,
  }) {
    return Chip(
      label: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
      onDeleted: onDeleted,
      backgroundColor: color,
      side: BorderSide.none,
    );
  }

  Widget _buildDropdownButton({
    required VoidCallback onTap,
    required String label,
    required bool isExpanded,
    required String selectText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppTheme.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: label.contains(selectText)
                      ? Colors.grey[600]
                      : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownMenu({
    required double maxHeight,
    required Widget child,
  }) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDropdownCategoryItem({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    String? image,
  }) {
    return ListTile(
      leading: image != null && image.isNotEmpty
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(image),
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Icon(
                Icons.category,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      tileColor:
          isSelected ? const Color(0xFF667eea).withValues(alpha: 0.1) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
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
          body: Stack(
            children: [
              RefreshIndicator(
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
                              icon: Icons.shopping_cart,
                              title:
                                  AppLocalizations.of(context)!.servicesTitle,
                              subtitle: AppLocalizations.of(context)!
                                  .servicesSubtitle,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 24),
                            // Search bar with filter button
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: AppTheme.controlHeight,
                                    child: TextField(
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: AppTheme.inputDecoration(
                                        label: AppLocalizations.of(context)!
                                            .searchServices,
                                        prefixIcon: Icons.search,
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _search = v.trim()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Filter button
                                Container(
                                  height: AppTheme.controlHeight,
                                  width: AppTheme.controlHeight,
                                  decoration: BoxDecoration(
                                    gradient: (_appliedCategories.isNotEmpty ||
                                            _appliedSortOption != null)
                                        ? AppTheme.primaryGradient
                                        : LinearGradient(
                                            colors: [
                                              AppTheme.primaryStart
                                                  .withValues(alpha: 0.1),
                                              AppTheme.primaryEnd
                                                  .withValues(alpha: 0.1)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (_appliedCategories.isNotEmpty ||
                                              _appliedSortOption != null)
                                          ? AppTheme.primaryStart
                                              .withValues(alpha: 0.3)
                                          : AppTheme.primaryStart
                                              .withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ((_appliedCategories
                                                        .isNotEmpty ||
                                                    _appliedSortOption != null)
                                                ? AppTheme.primaryStart
                                                : AppTheme.primaryStart
                                                    .withValues(alpha: 0.3))
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _toggleCategoryFilter,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Icon(
                                              Icons.filter_list,
                                              color: (_appliedCategories
                                                          .isNotEmpty ||
                                                      _appliedSortOption !=
                                                          null)
                                                  ? Colors.white
                                                  : AppTheme.primaryStart
                                                      .withValues(alpha: 0.7),
                                              size: 20,
                                            ),
                                          ),
                                          if (_appliedCategories.isNotEmpty ||
                                              _appliedSortOption != null)
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.1),
                                                      blurRadius: 2,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Text(
                                                  '${_appliedCategories.length + (_appliedSortOption != null ? 1 : 0)}',
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.primaryStart,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Services Grid
                    FutureBuilder<List<Service>>(
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
                                  .errorLoadingServicesList,
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
                                              .cannotLoadServicesList,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .checkNetworkOrTryAgainServices,
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _reload,
                                          child: Text(
                                              AppLocalizations.of(context)!
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
                        final filtered = _filterServices(data);

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
                                                  .item)))
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
                                final s = filtered[i];
                                return AppWidgets.animatedItem(
                                  index: i,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showActionDialog(s),
                                      borderRadius: BorderRadius.circular(16),
                                      splashColor: AppTheme.primaryStart
                                          .withValues(alpha: 0.2),
                                      highlightColor: AppTheme.primaryEnd
                                          .withValues(alpha: 0.1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Background Image or Gradient
                                              s.image != null &&
                                                      s.image!.isNotEmpty
                                                  ? _buildImageWidget(s.image!)
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        gradient: AppTheme
                                                            .primaryGradient,
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.shopping_cart,
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Service Name
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            AppTheme
                                                                .primaryStart
                                                                .withValues(
                                                                    alpha: 0.9),
                                                            AppTheme.primaryEnd
                                                                .withValues(
                                                                    alpha: 0.9),
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppTheme
                                                                .primaryStart
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        s.name,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Price
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            AppTheme
                                                                .primaryStart
                                                                .withValues(
                                                                    alpha: 0.9),
                                                            AppTheme.primaryEnd
                                                                .withValues(
                                                                    alpha: 0.9),
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppTheme
                                                                .primaryStart
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.attach_money,
                                                            size: 12,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${_formatPrice(s.price)} ${AppLocalizations.of(context)!.vnd}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Unit
                                                    if (s.unit != null) ...[
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              AppTheme
                                                                  .primaryStart
                                                                  .withValues(
                                                                      alpha:
                                                                          0.9),
                                                              AppTheme
                                                                  .primaryEnd
                                                                  .withValues(
                                                                      alpha:
                                                                          0.9),
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      100),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppTheme
                                                                  .primaryStart
                                                                  .withValues(
                                                                      alpha:
                                                                          0.3),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.straighten,
                                                              size: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              '${AppLocalizations.of(context)!.unit}: ${s.unit}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
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
              // Floating filter overlay with backdrop
              if (_showCategoryFilter)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleCategoryFilter,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: GestureDetector(
                          onTap:
                              () {}, // Prevent closing when tapping on filter
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.7,
                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                            ),
                            child: Material(
                              elevation: 20,
                              borderRadius: BorderRadius.circular(20),
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              child: _buildCompactCategoryFilter(),
                            ),
                          ),
                        ),
                      ),
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
