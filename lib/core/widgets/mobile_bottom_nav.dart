import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Mobile Bottom Navigation Bar
/// Shows only on mobile screens (width < 768)
class MobileBottomNav extends StatelessWidget {
  final int currentIndex;

  const MobileBottomNav({super.key, required this.currentIndex});

  static const items = [
    _NavItem(icon: Icons.home, label: 'Home', route: '/dashboard'),
    _NavItem(icon: Icons.receipt_long, label: 'Pesanan', route: '/orders'),
    _NavItem(icon: Icons.cake, label: 'Snackbox', route: '/snackbox'),
    _NavItem(icon: Icons.inventory_2, label: 'Paketan', route: '/paketan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Main 4 items
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = currentIndex == index;
                return _buildNavItem(
                  context,
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => context.go(item.route),
                );
              }),
              // More menu (3 dots)
              _buildNavItem(
                context,
                icon: Icons.more_horiz,
                label: 'Lainnya',
                isSelected: currentIndex == 4,
                onTap: () => _showMoreMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Kasir'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/pos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Pelanggan'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Produk'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.factory),
              title: const Text('Produksi'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/production');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Tagihan'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/invoices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Laporan'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/settings');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
