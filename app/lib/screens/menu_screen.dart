import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_client.dart';
import '../models.dart';
import '../ui/design_system.dart';
import '../generated/l10n/app_localizations.dart';

class MenuScreen extends StatefulWidget {
  final ApiClient api;

  const MenuScreen({super.key, required this.api});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  List<Category> _categories = [];
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await widget.api.getCategories();
      final services = await widget.api.getServices();

      setState(() {
        // Sort categories alphabetically by name
        categories.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _categories = categories;

        // Sort services by price from low to high
        services.sort((a, b) => a.price.compareTo(b.price));
        _services = services;
        _filteredServices = services;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorLoadingData(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterServices();
    });
  }

  void _filterServices() {
    List<Service> filtered = _services;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((service) =>
              service.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by selected category
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((service) => service.categoryId == _selectedCategoryId)
          .toList();
    }

    // Sort services: first by category name, then by price from low to high
    filtered.sort((a, b) {
      // First sort by category name
      final categoryA = _categories.firstWhere(
        (cat) => cat.id == a.categoryId,
        orElse: () => Category(id: '', name: ''),
      );
      final categoryB = _categories.firstWhere(
        (cat) => cat.id == b.categoryId,
        orElse: () => Category(id: '', name: ''),
      );

      final categoryComparison = categoryA.name.compareTo(categoryB.name);
      if (categoryComparison != 0) {
        return categoryComparison;
      }

      // If same category, sort by price from low to high
      return a.price.compareTo(b.price);
    });

    setState(() {
      _filteredServices = filtered;
    });
  }

  void _onCategorySelected(Category category) {
    HapticFeedback.lightImpact();
    setState(() {
      // Toggle category selection - nếu đã chọn thì bỏ chọn
      if (_selectedCategoryId == category.id) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = category.id;
      }
    });
    _filterServices();
  }

  void _clearCategoryFilter() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = null;
    });
    _filterServices();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
    _searchController.clear(); // Clear the text field
    _filterServices();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
        );
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty && _selectedCategoryId != null) {
      final category = _categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => Category(
            id: '', name: AppLocalizations.of(context)!.unknownCategory),
      );
      return AppLocalizations.of(context)!
          .noServicesFoundWithSearchAndCategory(_searchQuery, category.name);
    } else if (_searchQuery.isNotEmpty) {
      return AppLocalizations.of(context)!
          .noServicesFoundWithSearch(_searchQuery);
    } else if (_selectedCategoryId != null) {
      final category = _categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => Category(
            id: '', name: AppLocalizations.of(context)!.unknownCategory),
      );
      return AppLocalizations.of(context)!.noServicesInCategory(category.name);
    } else {
      return AppLocalizations.of(context)!.noServicesYet;
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
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header với search bar
                  Column(
                    children: [
                      _buildFullWidthHeader(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSearchBar(),
                      ),
                    ],
                  ),

                  // Categories carousel
                  _buildCategoriesSection(),

                  // Services grid
                  _buildServicesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, color: Colors.white, size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              AppLocalizations.of(context)!.menuTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.menuSubtitle,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: AppTheme.controlHeight,
      child: TextField(
        controller: _searchController,
        textAlignVertical: TextAlignVertical.center,
        onChanged: _onSearchChanged,
        decoration: AppTheme.inputDecoration(
          label: AppLocalizations.of(context)!.searchServicesPlaceholder,
          prefixIcon: Icons.search,
        ).copyWith(
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                  ),
                  onPressed: _clearSearch,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noCategoriesYet,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: AppTheme.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with navigation arrows
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.categoriesSection,
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 20,
                          tablet: 24,
                          desktop: 28,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (_selectedCategoryId != null)
                      Text(
                        AppLocalizations.of(context)!
                            .servicesCount(_filteredServices.length),
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: AppTheme.primaryStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedCategoryId != null)
                      TextButton(
                        onPressed: _clearCategoryFilter,
                        child: Text(
                          AppLocalizations.of(context)!.clearFilter,
                          style: TextStyle(
                            color: AppTheme.primaryStart,
                            fontSize: AppTheme.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: AppTheme.getResponsiveSpacing(
                        context,
                        mobile: 8,
                        tablet: 12,
                        desktop: 16,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!
                          .categoriesCount(_categories.length),
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: AppTheme.primaryStart,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(
            height: AppTheme.getResponsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),

          // Categories carousel
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryId == category.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildCategoryCard(category, isSelected),
                );
              },
            ),
          ),

          SizedBox(
            height: AppTheme.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 16,
              desktop: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Background image or gradient
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [
                            AppTheme.primaryStart,
                            AppTheme.primaryEnd,
                          ]
                        : [
                            Colors.grey[300]!,
                            Colors.grey[400]!,
                          ],
                  ),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? _buildImageWidget(category.image!)
                    : _buildCategoryImagePlaceholder(),
              ),

              // Overlay for better text readability
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),

              // Category name label
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF667eea),
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategoryId != null
                  ? Icons.category_outlined
                  : Icons.search_off,
              size: AppTheme.getResponsiveFontSize(
                context,
                mobile: 48,
                tablet: 56,
                desktop: 64,
              ),
              color: Colors.grey[400],
            ),
            SizedBox(
              height: AppTheme.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedCategoryId != null || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    _clearSearch();
                    _clearCategoryFilter();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.viewAllServices,
                    style: TextStyle(
                      color: AppTheme.primaryStart,
                      fontSize: AppTheme.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Services section title
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.servicesSection,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (_filteredServices.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .servicesCount(_filteredServices.length),
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            desktop: 16,
                          ),
                          color: AppTheme.primaryStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          SizedBox(
            height: AppTheme.getResponsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),

          // Services grouped by category
          _buildGroupedServices(),
        ],
      ),
    );
  }

  Widget _buildGroupedServices() {
    // Group services by category
    final Map<String, List<Service>> groupedServices = {};
    for (final service in _filteredServices) {
      final categoryId = service.categoryId;
      if (!groupedServices.containsKey(categoryId)) {
        groupedServices[categoryId] = [];
      }
      groupedServices[categoryId]!.add(service);
    }

    // Sort categories by name
    final sortedCategories = groupedServices.keys.toList()
      ..sort((a, b) {
        final categoryA = _categories.firstWhere(
          (cat) => cat.id == a,
          orElse: () => Category(id: '', name: ''),
        );
        final categoryB = _categories.firstWhere(
          (cat) => cat.id == b,
          orElse: () => Category(id: '', name: ''),
        );
        return categoryA.name.compareTo(categoryB.name);
      });

    return Column(
      children: sortedCategories.map((categoryId) {
        final services = groupedServices[categoryId]!
          ..sort((a, b) => a.price.compareTo(
              b.price)); // Sort services by price within each category
        final category = _categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => Category(
              id: '', name: AppLocalizations.of(context)!.unknownCategory),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
                vertical: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryStart,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    width: AppTheme.getResponsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(
                    width: AppTheme.getResponsiveSpacing(
                      context,
                      mobile: 8,
                      tablet: 12,
                      desktop: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${services.length}',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: AppTheme.primaryStart,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Services grid for this category
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppTheme.isMobile(context) ? 2 : 3,
                childAspectRatio: 0.75, // Slightly taller to accommodate text
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: services.length,
              itemBuilder: (context, serviceIndex) {
                final service = services[serviceIndex];
                return _buildServiceCard(service);
              },
            ),

            // Spacing between categories
            if (sortedCategories.indexOf(categoryId) <
                sortedCategories.length - 1)
              SizedBox(
                height: AppTheme.getResponsiveSpacing(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard(Service service) {
    final category = _categories.firstWhere(
      (cat) => cat.id == service.categoryId,
      orElse: () =>
          Category(id: '', name: AppLocalizations.of(context)!.unknownCategory),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: service.image != null && service.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: _buildImageWidget(service.image!),
                    )
                  : _buildServiceImagePlaceholder(),
            ),
          ),

          // Service info - Fixed height container to prevent overflow
          Container(
            height: 65, // Fixed height to prevent overflow
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Service name - Limited space
                Expanded(
                  flex: 2,
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Category name
                Expanded(
                  flex: 1,
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Price
                Expanded(
                  flex: 1,
                  child: Text(
                    '${_formatPrice(service.price)}₫',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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

  Widget _buildServiceImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 232,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Icon(
        Icons.shopping_cart,
        size: AppTheme.getResponsiveFontSize(
          context,
          mobile: 48,
          tablet: 56,
          desktop: 64,
        ),
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildCategoryImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryStart.withValues(alpha: 0.3),
            AppTheme.primaryEnd.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Icon(
        Icons.category,
        size: AppTheme.getResponsiveFontSize(
          context,
          mobile: 48,
          tablet: 56,
          desktop: 64,
        ),
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}
