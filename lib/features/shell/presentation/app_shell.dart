import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';

/// Responsive App Shell dengan Sidebar Terstruktur
/// - Mobile: Bottom Navigation Bar
/// - Desktop: Custom Sidebar dengan Group Navigation
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                _DesktopSidebar(),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: isDesktop ? null : _MobileBottomNav(),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Pesanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.cake_outlined),
          selectedIcon: Icon(Icons.cake),
          label: 'Snackbox',
        ),
        NavigationDestination(
          icon: Icon(Icons.card_giftcard_outlined),
          selectedIcon: Icon(Icons.card_giftcard),
          label: 'Paketan',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'Lainnya',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/snack-box')) return 2;
    if (location.startsWith('/paketan')) return 3;
    if (location.startsWith('/pos') ||
        location.startsWith('/customers') ||
        location.startsWith('/production') ||
        location.startsWith('/purchasing') ||
        location.startsWith('/products') ||
        location.startsWith('/invoices') ||
        location.startsWith('/reports') ||
        location.startsWith('/settings')) {
      return 4;
    }
    return 0; // dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/snack-box');
        break;
      case 3:
        context.go('/paketan');
        break;
      case 4:
        _showMoreOptions(context);
        break;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.point_of_sale_outlined, size: 22),
                title: const Text('Kasir'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/pos');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.factory_outlined, size: 22),
                title: const Text('Produksi'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/production');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_outlined, size: 22),
                title: const Text('Tagihan'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/invoices');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.shopping_bag_outlined, size: 22),
                title: const Text('Pembelian Bahan'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/purchasing');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.inventory, size: 22),
                title: const Text('Bahan Baku'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/raw-materials');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.people_outlined, size: 22),
                title: const Text('Pelanggan'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/customers');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.inventory_2_outlined, size: 22),
                title: const Text('Master Produk'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/products');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.assessment_outlined, size: 22),
                title: const Text('Laporan'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/reports');
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.settings_outlined, size: 22),
                title: const Text('Pengaturan'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
              const Divider(),
              // Dark Mode Toggle
              _MobileThemeToggleTile(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Desktop Sidebar dengan Grouped Navigation
class _DesktopSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isExtended = MediaQuery.of(context).size.width >= 1100;

    return Container(
      width: isExtended ? 240 : 72,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Header
          _buildHeader(context, isExtended),
          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UTAMA
                  _buildSectionHeader('UTAMA', isExtended),
                  _NavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    path: '/',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.point_of_sale,
                    label: 'Kasir / POS',
                    path: '/pos',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),

                  const SizedBox(height: 24),

                  // OPERASIONAL
                  _buildSectionHeader('OPERASIONAL', isExtended),
                  _NavItem(
                    icon: Icons.shopping_cart,
                    label: 'Pesanan',
                    path: '/orders',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.inventory_2,
                    label: 'Snack Box',
                    path: '/snack-box',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.card_giftcard,
                    label: 'Paketan',
                    path: '/paketan',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.precision_manufacturing,
                    label: 'Produksi',
                    path: '/production',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),

                  const SizedBox(height: 24),

                  // INVENTARIS & PRODUK
                  _buildSectionHeader('INVENTARIS & PRODUK', isExtended),
                  _NavItem(
                    icon: Icons.restaurant_menu,
                    label: 'Produk',
                    path: '/products',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.local_shipping,
                    label: 'Pembelian',
                    path: '/purchasing',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.inventory,
                    label: 'Bahan Baku',
                    path: '/raw-materials',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),

                  const SizedBox(height: 24),

                  // ADMINISTRASI
                  _buildSectionHeader('ADMINISTRASI', isExtended),
                  _NavItem(
                    icon: Icons.receipt_long,
                    label: 'Tagihan',
                    path: '/invoices',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.group,
                    label: 'Pelanggan',
                    path: '/customers',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'Laporan',
                    path: '/reports',
                    currentPath: currentPath,
                    isExtended: isExtended,
                  ),
                ],
              ),
            ),
          ),

          // Settings and Theme Toggle at Bottom
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.settings,
                  label: 'Pengaturan',
                  path: '/settings',
                  currentPath: currentPath,
                  isExtended: isExtended,
                ),
                const SizedBox(height: 8),
                _ThemeToggleButton(isExtended: isExtended),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isExtended) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to text logo if image fails
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'LF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isExtended) ...[
            const SizedBox(width: 12),
            Text(
              'LF Kitchen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isExtended) {
    if (!isExtended) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

/// Navigation Item Widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool isExtended;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.isExtended,
  });

  bool get isActive {
    if (path == '/') return currentPath == '/';
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExtended ? 12 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isExtended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                ),
                if (isExtended) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme Toggle Button using Riverpod
class _ThemeToggleButton extends ConsumerWidget {
  final bool isExtended;

  const _ThemeToggleButton({required this.isExtended});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? Colors.amber : Colors.grey.shade600,
                size: 22,
              ),
              if (isExtended) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isDark ? 'Mode Gelap' : 'Mode Terang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                  activeTrackColor: AppColors.primaryLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile Theme Toggle Tile for Bottom Sheet
class _MobileThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return ListTile(
      dense: true,
      leading: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: isDark ? Colors.amber : Colors.grey.shade600,
        size: 22,
      ),
      title: Text(isDark ? 'Mode Gelap' : 'Mode Terang'),
      trailing: Switch(
        value: isDark,
        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
        activeTrackColor: AppColors.primaryLight,
      ),
      onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
    );
  }
}
