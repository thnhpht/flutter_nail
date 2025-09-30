import 'package:flutter/material.dart';
import 'design_system.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/language_service.dart';
import '../generated/l10n/app_localizations.dart';
import '../config/salon_config.dart';

class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final String userRole; // 'shop_owner' or 'employee'
  final LanguageService languageService;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userRole,
    required this.languageService,
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
                children: _buildNavigationItems(context),
              ),
            ),

            // Language selector, Version info and Logout button
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
                  _buildLanguageSelector(),
                  SizedBox(
                      height: AppTheme.getResponsiveSpacing(context,
                          mobile: AppTheme.spacingS,
                          tablet: AppTheme.spacingM)),
                  _buildAdminContactInfo(),
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

  List<Widget> _buildNavigationItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (userRole == 'employee') {
      // Employee navigation - limited features
      return [
        // Menu section
        _buildSectionHeader(l10n.menu),
        _buildNavItem(
          icon: Icons.menu_book,
          title: l10n.menu,
          index: 0,
          isSelected: selectedIndex == 0,
        ),

        _buildSectionHeader(l10n.management),
        _buildNavItem(
          icon: Icons.shopping_cart,
          title: l10n.services,
          index: 1,
          isSelected: selectedIndex == 1,
        ),

        // Create order section
        _buildSectionHeader(l10n.createOrder),
        _buildNavItem(
          icon: Icons.add_shopping_cart,
          title: l10n.createOrder,
          index: 2,
          isSelected: selectedIndex == 2,
        ),

        // Bills section
        _buildSectionHeader(l10n.bills),
        _buildNavItem(
          icon: Icons.receipt,
          title: l10n.bills,
          index: 3,
          isSelected: selectedIndex == 3,
        ),
      ];
    } else {
      // Shop owner navigation - full features
      return [
        // Information section
        _buildSectionHeader(l10n.information),
        _buildNavItem(
          icon: Icons.business,
          title: l10n.salonInfo,
          index: 8,
          isSelected: selectedIndex == 8,
        ),

        // Menu section
        _buildSectionHeader(l10n.menu),
        _buildNavItem(
          icon: Icons.menu_book,
          title: l10n.menu,
          index: 9,
          isSelected: selectedIndex == 9,
        ),

        // Management section
        _buildSectionHeader(l10n.management),
        _buildNavItem(
          icon: Icons.people,
          title: l10n.customers,
          index: 1,
          isSelected: selectedIndex == 1,
        ),
        _buildNavItem(
          icon: Icons.work,
          title: l10n.employees,
          index: 2,
          isSelected: selectedIndex == 2,
        ),
        _buildNavItem(
          icon: Icons.category,
          title: l10n.categories,
          index: 3,
          isSelected: selectedIndex == 3,
        ),
        _buildNavItem(
          icon: Icons.shopping_cart,
          title: l10n.services,
          index: 4,
          isSelected: selectedIndex == 4,
        ),

        // Create order section
        _buildSectionHeader(l10n.createOrder),
        _buildNavItem(
          icon: Icons.add_shopping_cart,
          title: l10n.createOrder,
          index: 5,
          isSelected: selectedIndex == 5,
        ),

        // Bills & Reports section
        _buildSectionHeader(l10n.billsReports),
        _buildNavItem(
          icon: Icons.receipt,
          title: l10n.bills,
          index: 6,
          isSelected: selectedIndex == 6,
        ),
        _buildNavItem(
          icon: Icons.analytics,
          title: l10n.reports,
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

  Widget _buildLanguageSelector() {
    return Builder(
      builder: (context) {
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: LanguageService.supportedLocales.map((locale) {
            final isSelected =
                languageService.isCurrentLanguage(locale.languageCode);
            return GestureDetector(
              onTap: () => languageService.setLanguage(locale.languageCode),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingS, tablet: AppTheme.spacingM),
                  vertical: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue[600]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  languageService.getLanguageName(locale.languageCode),
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 10,
                      tablet: 11,
                      desktop: 12,
                    ),
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.blue[600],
                  ),
                ),
              ),
            );
          }).toList(),
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
                      mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS),
                ),
                child: Text(
                  'v${packageInfo.version}',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 11,
                      tablet: 12,
                      desktop: 13,
                    ),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingM, tablet: AppTheme.spacingL),
                  vertical: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS),
                ),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 11,
                      tablet: 12,
                      desktop: 13,
                    ),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAdminContactInfo() {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingM, tablet: AppTheme.spacingL),
            vertical: AppTheme.getResponsiveSpacing(context,
                mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: AppTheme.getResponsiveSpacing(context,
                      mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS)),
              _buildSimpleContactItem(
                context,
                Icons.location_on,
                SalonConfig.adminAddress,
                () {},
              ),
              _buildSimpleContactItem(
                context,
                Icons.phone,
                SalonConfig.adminPhone,
                () async {
                  final Uri phoneUri =
                      Uri(scheme: 'tel', path: SalonConfig.adminPhone);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                },
              ),
              _buildSimpleContactItem(
                context,
                Icons.web,
                SalonConfig.adminWebsite,
                () async {
                  final Uri websiteUri = Uri.parse(SalonConfig.adminWebsite);
                  if (await canLaunchUrl(websiteUri)) {
                    await launchUrl(websiteUri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleContactItem(
      BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.getResponsiveSpacing(context,
              mobile: 2, tablet: 3, desktop: 4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
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
                    mobile: AppTheme.spacingXS, tablet: AppTheme.spacingS)),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: AppTheme.getResponsiveFontSize(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 14,
                  ),
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
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
                    color: Colors.red.withValues(alpha: 0.1),
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
                  l10n.logout,
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
  final LanguageService languageService;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userRole,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: _buildRailDestinations(context),
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
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return Text(
                            l10n.logout,
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
                          );
                        },
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
            _buildAdminContactInfoRail(),
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

  List<NavigationRailDestination> _buildRailDestinations(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (userRole == 'employee') {
      // Employee navigation - limited features
      return [
        _buildRailDestination(Icons.menu_book, l10n.menu),
        _buildRailDestination(Icons.shopping_cart, l10n.services),
        _buildRailDestination(Icons.add_shopping_cart, l10n.createOrder),
        _buildRailDestination(Icons.receipt, l10n.bills),
      ];
    } else {
      // Shop owner navigation - full features
      return [
        _buildRailDestination(Icons.people, l10n.customers),
        _buildRailDestination(Icons.work, l10n.employees),
        _buildRailDestination(Icons.category, l10n.categories),
        _buildRailDestination(Icons.shopping_cart, l10n.services),
        _buildRailDestination(Icons.menu_book, l10n.menu),
        _buildRailDestination(Icons.add_shopping_cart, l10n.createOrder),
        _buildRailDestination(Icons.receipt, l10n.bills),
        _buildRailDestination(Icons.analytics, l10n.reports),
        _buildRailDestination(Icons.business, l10n.salonInfo),
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
                      tablet: 2, desktop: 3),
                ),
                child: Text(
                  'v${packageInfo.version}',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 9,
                      desktop: 10,
                    ),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
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
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.getResponsiveSpacing(context,
                      tablet: 6, desktop: 8),
                  vertical: AppTheme.getResponsiveSpacing(context,
                      tablet: 2, desktop: 3),
                ),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 9,
                      desktop: 10,
                    ),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAdminContactInfoRail() {
    return Builder(
      builder: (context) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal:
                AppTheme.getResponsiveSpacing(context, tablet: 4, desktop: 6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal:
                AppTheme.getResponsiveSpacing(context, tablet: 6, desktop: 8),
            vertical:
                AppTheme.getResponsiveSpacing(context, tablet: 2, desktop: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.grey[600],
                    size: AppTheme.getResponsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 9,
                      desktop: 10,
                    ),
                  ),
                  SizedBox(
                      width: AppTheme.getResponsiveSpacing(context,
                          mobile: 2, tablet: 3, desktop: 4)),
                  Expanded(
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: AppTheme.getResponsiveFontSize(
                          context,
                          mobile: 6,
                          tablet: 7,
                          desktop: 8,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height: AppTheme.getResponsiveSpacing(context,
                      mobile: 1, tablet: 2, desktop: 3)),
              _buildSimpleContactItemRail(
                context,
                Icons.location_on,
                () {},
              ),
              _buildSimpleContactItemRail(
                context,
                Icons.phone,
                () async {
                  final Uri phoneUri =
                      Uri(scheme: 'tel', path: SalonConfig.adminPhone);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                },
              ),
              _buildSimpleContactItemRail(
                context,
                Icons.web,
                () async {
                  final Uri websiteUri = Uri.parse(SalonConfig.adminWebsite);
                  if (await canLaunchUrl(websiteUri)) {
                    await launchUrl(websiteUri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleContactItemRail(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.getResponsiveSpacing(context,
              mobile: 1, tablet: 1, desktop: 2),
        ),
        child: Icon(
          icon,
          color: Colors.grey[600],
          size: AppTheme.getResponsiveFontSize(
            context,
            mobile: 8,
            tablet: 9,
            desktop: 10,
          ),
        ),
      ),
    );
  }
}
