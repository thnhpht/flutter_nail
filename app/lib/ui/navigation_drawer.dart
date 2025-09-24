import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final String userRole; // 'shop_owner' or 'employee'

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Add extra spacing at the top
            // SizedBox(
            //   height: AppTheme.getResponsiveSpacing(
            //     context,
            //     mobile: AppTheme.spacingXXS,
            //     tablet: AppTheme.spacingXXS,
            //     desktop: AppTheme.spacingXXS,
            //   ),
            // ),

            // Navigation items
            Expanded(
              child: ListView(
                padding: AppTheme.getResponsivePadding(
                  context,
                  mobile:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  tablet:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                  desktop:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
                ),
                children: _buildNavigationItems(),
              ),
            ),

            // Version info and Logout button
            Container(
              padding: AppTheme.getResponsivePadding(
                context,
                mobile: const EdgeInsets.all(AppTheme.spacingM),
                tablet: const EdgeInsets.all(AppTheme.spacingL),
                desktop: const EdgeInsets.all(AppTheme.spacingXL),
              ),
              child: Column(
                children: [
                  const Divider(),
                  SizedBox(
                      height: AppTheme.getResponsiveSpacing(context,
                          mobile: AppTheme.spacingS,
                          tablet: AppTheme.spacingM)),
                  _buildVersionInfo(),
                  SizedBox(
                      height: AppTheme.getResponsiveSpacing(context,
                          mobile: AppTheme.spacingS,
                          tablet: AppTheme.spacingM)),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems() {
    if (userRole == 'employee') {
      // Employee navigation - limited features
      return [
        // Dịch vụ section
        _buildSectionHeader('Menu'),
        _buildNavItem(
          icon: Icons.menu_book,
          title: 'Menu',
          index: 0,
          isSelected: selectedIndex == 0,
        ),

        _buildSectionHeader('Quản lý'),
        _buildNavItem(
          icon: Icons.spa,
          title: 'Dịch vụ',
          index: 1,
          isSelected: selectedIndex == 1,
        ),

        // Tạo đơn section
        _buildSectionHeader('Tạo đơn'),
        _buildNavItem(
          icon: Icons.add_shopping_cart,
          title: 'Tạo đơn',
          index: 2,
          isSelected: selectedIndex == 2,
        ),

        // Hóa đơn section
        _buildSectionHeader('Hóa đơn'),
        _buildNavItem(
          icon: Icons.receipt,
          title: 'Hóa đơn',
          index: 3,
          isSelected: selectedIndex == 3,
        ),
      ];
    } else {
      // Shop owner navigation - full features
      return [
        // Thông tin section
        _buildSectionHeader('Thông tin'),
        _buildNavItem(
          icon: Icons.business,
          title: 'Thông tin Salon',
          index: 8,
          isSelected: selectedIndex == 8,
        ),

        // Menu section
        _buildSectionHeader('Menu'),
        _buildNavItem(
          icon: Icons.menu_book,
          title: 'Menu',
          index: 9,
          isSelected: selectedIndex == 9,
        ),

        // Quản lý section
        _buildSectionHeader('Quản lý'),
        _buildNavItem(
          icon: Icons.people,
          title: 'Khách hàng',
          index: 1,
          isSelected: selectedIndex == 1,
        ),
        _buildNavItem(
          icon: Icons.work,
          title: 'Nhân viên',
          index: 2,
          isSelected: selectedIndex == 2,
        ),
        _buildNavItem(
          icon: Icons.category,
          title: 'Danh mục',
          index: 3,
          isSelected: selectedIndex == 3,
        ),
        _buildNavItem(
          icon: Icons.spa,
          title: 'Dịch vụ',
          index: 4,
          isSelected: selectedIndex == 4,
        ),

        // Tạo đơn section
        _buildSectionHeader('Tạo đơn'),
        _buildNavItem(
          icon: Icons.add_shopping_cart,
          title: 'Tạo đơn',
          index: 5,
          isSelected: selectedIndex == 5,
        ),

        // Hóa đơn & Báo cáo section
        _buildSectionHeader('Hóa đơn & Báo cáo'),
        _buildNavItem(
          icon: Icons.receipt,
          title: 'Hóa đơn',
          index: 6,
          isSelected: selectedIndex == 6,
        ),
        _buildNavItem(
          icon: Icons.analytics,
          title: 'Báo cáo',
          index: 7,
          isSelected: selectedIndex == 7,
        ),
      ];
    }
  }

  Widget _buildSectionHeader(String title) {
    return Builder(
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(
            left: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingM, tablet: AppTheme.spacingL),
            right: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingM, tablet: AppTheme.spacingL),
            top: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingL, tablet: AppTheme.spacingXL),
            bottom: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingS, tablet: AppTheme.spacingM),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.getResponsiveFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Builder(
      builder: (context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(
            horizontal: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingS, tablet: AppTheme.spacingM),
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryStart.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => onItemSelected(index),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingS, tablet: AppTheme.spacingM),
                  vertical: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        icon,
                        key: ValueKey('$icon-$isSelected'),
                        color: isSelected
                            ? AppTheme.primaryStart
                            : Colors.grey[600],
                        size: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                    SizedBox(
                        width: AppTheme.getResponsiveSpacing(context,
                            mobile: AppTheme.spacingS,
                            tablet: AppTheme.spacingM)),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryStart
                              : Colors.grey[800],
                          letterSpacing: 0.2,
                        ),
                        child: Text(title),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return Builder(
      builder: (context) {
        return FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final packageInfo = snapshot.data!;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingM, tablet: AppTheme.spacingL),
                  vertical: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingS, tablet: AppTheme.spacingM),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                        SizedBox(
                            width: AppTheme.getResponsiveSpacing(context,
                                mobile: AppTheme.spacingXS,
                                tablet: AppTheme.spacingS)),
                        Text(
                          'Phiên bản',
                          style: TextStyle(
                            fontSize: AppTheme.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: AppTheme.getResponsiveSpacing(context,
                            mobile: AppTheme.spacingXS,
                            tablet: AppTheme.spacingS)),
                    Text(
                      'v${packageInfo.version}',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryStart,
                      ),
                    ),
                    if (packageInfo.buildNumber.isNotEmpty)
                      Text(
                        'Build ${packageInfo.buildNumber}',
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 12,
                            desktop: 14,
                          ),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppTheme.getResponsiveSpacing(context,
                    mobile: AppTheme.spacingM, tablet: AppTheme.spacingL)),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red[200]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Không thể tải thông tin phiên bản',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppTheme.getResponsiveSpacing(context,
                    mobile: AppTheme.spacingM, tablet: AppTheme.spacingL)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: AppTheme.getResponsiveFontSize(context,
                          mobile: 12, tablet: 14, desktop: 16),
                      height: AppTheme.getResponsiveFontSize(context,
                          mobile: 12, tablet: 14, desktop: 16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryStart,
                        ),
                      ),
                    ),
                    SizedBox(
                        width: AppTheme.getResponsiveSpacing(context,
                            mobile: AppTheme.spacingS,
                            tablet: AppTheme.spacingM)),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onLogout,
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(AppTheme.getResponsiveSpacing(context,
                      mobile: 6, tablet: 8, desktop: 10)),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                  ),
                ),
                title: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Navigation Rail for tablet/desktop
class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final String userRole; // 'shop_owner' or 'employee'

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: _buildRailDestinations(),
      leading: Column(
        children: [
          SizedBox(
              height: AppTheme.getResponsiveSpacing(context,
                  tablet: 16, desktop: 20)),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal:
                  AppTheme.getResponsiveSpacing(context, tablet: 6, desktop: 8),
              vertical: 4,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onLogout,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppTheme.getResponsiveSpacing(context,
                        tablet: 10, desktop: 12),
                    horizontal: AppTheme.getResponsiveSpacing(context,
                        tablet: 6, desktop: 8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red[400],
                        size: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 24,
                        ),
                      ),
                      SizedBox(
                          height: AppTheme.getResponsiveSpacing(context,
                              mobile: 2, tablet: 2, desktop: 4)),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 8,
                            tablet: 9,
                            desktop: 10,
                          ),
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/icon/logo.png',
              width: AppTheme.getResponsiveFontSize(context,
                  mobile: 32, tablet: 36, desktop: 40),
              height: AppTheme.getResponsiveFontSize(context,
                  mobile: 32, tablet: 36, desktop: 40),
              fit: BoxFit.contain,
            ),
            SizedBox(
                height: AppTheme.getResponsiveSpacing(context,
                    mobile: 4, tablet: 6, desktop: 8)),
            Text(
              'AeRI',
              style: TextStyle(
                fontSize: AppTheme.getResponsiveFontSize(
                  context,
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryStart,
              ),
            ),
            SizedBox(
                height: AppTheme.getResponsiveSpacing(context,
                    mobile: 8, tablet: 10, desktop: 12)),
            _buildVersionInfoRail(),
            SizedBox(
                height: AppTheme.getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
          ],
        ),
      ),
    );
  }

  List<NavigationRailDestination> _buildRailDestinations() {
    if (userRole == 'employee') {
      // Employee navigation - limited features
      return [
        _buildRailDestination(Icons.menu_book, 'Menu'),
        _buildRailDestination(Icons.spa, 'Dịch vụ'),
        _buildRailDestination(Icons.add_shopping_cart, 'Tạo đơn'),
        _buildRailDestination(Icons.receipt, 'Hóa đơn'),
      ];
    } else {
      // Shop owner navigation - full features
      return [
        _buildRailDestination(Icons.people, 'Khách hàng'),
        _buildRailDestination(Icons.work, 'Nhân viên'),
        _buildRailDestination(Icons.category, 'Danh mục'),
        _buildRailDestination(Icons.spa, 'Dịch vụ'),
        _buildRailDestination(Icons.menu_book, 'Menu'),
        _buildRailDestination(Icons.add_shopping_cart, 'Tạo đơn'),
        _buildRailDestination(Icons.receipt, 'Hóa đơn'),
        _buildRailDestination(Icons.analytics, 'Báo cáo'),
        _buildRailDestination(Icons.business, 'Thông tin Salon'),
      ];
    }
  }

  NavigationRailDestination _buildRailDestination(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(
        icon,
        color: Colors.grey[600],
        size: 20,
      ),
      selectedIcon: Icon(
        icon,
        color: AppTheme.primaryStart,
        size: 20,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildVersionInfoRail() {
    return Builder(
      builder: (context) {
        return FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final packageInfo = snapshot.data!;
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      tablet: 4, desktop: 6),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      tablet: 6, desktop: 8),
                  vertical: AppTheme.getResponsiveSpacing(context,
                      tablet: 4, desktop: 6),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v${packageInfo.version}',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 8,
                          tablet: 9,
                          desktop: 10,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryStart,
                      ),
                    ),
                    if (packageInfo.buildNumber.isNotEmpty)
                      Text(
                        'Build ${packageInfo.buildNumber}',
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            context,
                            mobile: 6,
                            tablet: 7,
                            desktop: 8,
                          ),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      tablet: 4, desktop: 6),
                ),
                padding: EdgeInsets.all(AppTheme.getResponsiveSpacing(context,
                    tablet: 4, desktop: 6)),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red[200]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Error',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 6,
                      tablet: 7,
                      desktop: 8,
                    ),
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      tablet: 4, desktop: 6),
                ),
                padding: EdgeInsets.all(AppTheme.getResponsiveSpacing(context,
                    tablet: 4, desktop: 6)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: SizedBox(
                  width: AppTheme.getResponsiveFontSize(context,
                      mobile: 8, tablet: 9, desktop: 10),
                  height: AppTheme.getResponsiveFontSize(context,
                      mobile: 8, tablet: 9, desktop: 10),
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryStart,
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
