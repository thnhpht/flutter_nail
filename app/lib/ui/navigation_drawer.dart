import 'package:flutter/material.dart';
import 'design_system.dart';

class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header with logo and branding
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'icon/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    // App name
                    const Center(
                      child: Text(
                        'AeRI Nailroom',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Quản lý salon nail',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  title: 'Trang chủ',
                  index: 0,
                  isSelected: selectedIndex == 0,
                ),
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
                _buildNavItem(
                  icon: Icons.add_shopping_cart,
                  title: 'Tạo đơn',
                  index: 5,
                  isSelected: selectedIndex == 5,
                ),
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
              ],
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () => onItemSelected(index),
          child: ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryStart 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryStart.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('$icon-$isSelected'),
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryStart : Colors.grey[800],
              ),
              child: Text(title),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: onLogout,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        _buildRailDestination(Icons.home, 'Trang chủ'),
        _buildRailDestination(Icons.people, 'Khách hàng'),
        _buildRailDestination(Icons.work, 'Nhân viên'),
        _buildRailDestination(Icons.category, 'Danh mục'),
        _buildRailDestination(Icons.spa, 'Dịch vụ'),
        _buildRailDestination(Icons.add_shopping_cart, 'Tạo đơn'),
        _buildRailDestination(Icons.receipt, 'Hóa đơn'),
        _buildRailDestination(Icons.analytics, 'Báo cáo'),
      ],
      leading: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'icon/logo.png',
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
        ],
      ),
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
