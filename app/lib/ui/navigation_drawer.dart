import 'package:flutter/material.dart';
import 'design_system.dart';

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
      child: Column(
        children: [
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
              children: _buildNavigationItems(),
            ),
          ),
          
          // Logout button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: AppTheme.spacingS),
                _buildLogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavigationItems() {
    if (userRole == 'employee') {
      // Employee navigation - limited features
      return [
        // Dịch vụ section
        _buildSectionHeader('Dịch vụ'),
        _buildNavItem(
          icon: Icons.spa,
          title: 'Dịch vụ',
          index: 0,
          isSelected: selectedIndex == 0,
        ),
        
        // Tạo đơn section
        _buildSectionHeader('Tạo đơn'),
        _buildNavItem(
          icon: Icons.add_shopping_cart,
          title: 'Tạo đơn',
          index: 1,
          isSelected: selectedIndex == 1,
        ),
        
        // Hóa đơn section
        _buildSectionHeader('Hóa đơn'),
        _buildNavItem(
          icon: Icons.receipt,
          title: 'Hóa đơn',
          index: 2,
          isSelected: selectedIndex == 2,
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
    return Container(
      margin: const EdgeInsets.only(
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        top: AppTheme.spacingXL,
        bottom: AppTheme.spacingM,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey[700],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryStart.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => onItemSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey('$icon-$isSelected'),
                    color: isSelected ? AppTheme.primaryStart : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryStart : Colors.grey[800],
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
  }

  Widget _buildLogoutButton() {
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 20,
              ),
            ),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16,
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
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red[400],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 10,
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
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            const Text(
              'AeRI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryStart,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<NavigationRailDestination> _buildRailDestinations() {
    if (userRole == 'employee') {
      // Employee navigation - limited features
      return [
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
        _buildRailDestination(Icons.add_shopping_cart, 'Tạo đơn'),
        _buildRailDestination(Icons.receipt, 'Hóa đơn'),
        _buildRailDestination(Icons.analytics, 'Báo cáo'),
        _buildRailDestination(Icons.business, 'Thông tin Salon'),
      ];
    }
  }

  NavigationRailDestination _buildRailDestination(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon, color: Colors.grey[600]),
      selectedIcon: Icon(icon, color: AppTheme.primaryStart),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
