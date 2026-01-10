import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Responsive App Shell
/// - Mobile: Bottom Navigation Bar
/// - Desktop: Sidebar Navigation
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
                const VerticalDivider(width: 1),
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
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Pesanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: 'Kasir',
        ),
        NavigationDestination(
          icon: Icon(Icons.factory_outlined),
          selectedIcon: Icon(Icons.factory),
          label: 'Produksi',
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
    if (location.startsWith('/pos')) return 2;
    if (location.startsWith('/production')) return 3;
    if (location.startsWith('/purchasing') ||
        location.startsWith('/products') ||
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
        context.go('/pos');
        break;
      case 3:
        context.go('/production');
        break;
      case 4:
        // Show more options bottom sheet
        _showMoreOptions(context);
        break;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Snack Box'),
              onTap: () {
                Navigator.pop(context);
                context.go('/snack-box');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Tagihan'),
              onTap: () {
                Navigator.pop(context);
                context.go('/invoices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Pembelian Bahan'),
              onTap: () {
                Navigator.pop(context);
                context.go('/purchasing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Master Produk'),
              onTap: () {
                Navigator.pop(context);
                context.go('/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outlined),
              title: const Text('Pelanggan'),
              onTap: () {
                Navigator.pop(context);
                context.go('/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment_outlined),
              title: const Text('Laporan'),
              onTap: () {
                Navigator.pop(context);
                context.go('/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return NavigationRail(
      extended: MediaQuery.of(context).size.width >= 1200,
      minExtendedWidth: 200,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onItemTapped(index, context),
      leading: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LF Kitchen',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: Text('Pesanan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: Text('Kasir'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Snack Box'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.factory_outlined),
          selectedIcon: Icon(Icons.factory),
          label: Text('Produksi'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Tagihan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag),
          label: Text('Pembelian'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.cake_outlined),
          selectedIcon: Icon(Icons.cake),
          label: Text('Produk'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: Text('Pelanggan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(Icons.assessment),
          label: Text('Laporan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Pengaturan'),
        ),
      ],
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/pos')) return 2;
    if (location.startsWith('/snack-box')) return 3;
    if (location.startsWith('/production')) return 4;
    if (location.startsWith('/invoices')) return 5;
    if (location.startsWith('/purchasing')) return 6;
    if (location.startsWith('/products')) return 7;
    if (location.startsWith('/customers')) return 8;
    if (location.startsWith('/reports')) return 9;
    if (location.startsWith('/settings')) return 10;
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
        context.go('/pos');
        break;
      case 3:
        context.go('/snack-box');
        break;
      case 4:
        context.go('/production');
        break;
      case 5:
        context.go('/invoices');
        break;
      case 6:
        context.go('/purchasing');
        break;
      case 7:
        context.go('/products');
        break;
      case 8:
        context.go('/customers');
        break;
      case 9:
        context.go('/reports');
        break;
      case 10:
        context.go('/settings');
        break;
    }
  }
}
