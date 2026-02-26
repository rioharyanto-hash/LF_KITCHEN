import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shell/presentation/app_shell.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/products/presentation/pages/product_list_page.dart';
import '../../features/customers/presentation/pages/customer_list_page.dart';
import '../../features/orders/presentation/pages/order_list_page.dart';
import '../../features/orders/presentation/pages/order_form_page.dart';
import '../../features/orders/presentation/pages/pos_page.dart';
import '../../features/orders/presentation/pages/snack_box_page.dart';
import '../../features/orders/data/models/order.dart';
import '../../features/purchasing/presentation/pages/purchase_list_page.dart';
import '../../features/purchasing/presentation/pages/raw_materials_page.dart';
import '../../features/purchasing/presentation/pages/supplier_list_page.dart';
import '../../features/purchasing/presentation/pages/receipt_scan_page.dart';
import '../../features/production/presentation/pages/production_dashboard_page.dart';
import '../../features/invoices/presentation/pages/invoice_list_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/packages/presentation/pages/paketan_page.dart';

/// Router Configuration menggunakan GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Shell Route untuk Navigation (Bottom Nav / Sidebar)
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          // Penjualan Routes
          GoRoute(
            path: '/orders',
            name: 'orders',
            pageBuilder: (context, state) {
              // Check if we want to show list or form
              final view = state.uri.queryParameters['view'];
              final highlightOrderId = state.uri.queryParameters['highlight'];
              final initialStatus = state.uri.queryParameters['status'];

              if (view == 'list') {
                return NoTransitionPage(
                  child: OrderListPage(
                    highlightOrderId: highlightOrderId,
                    initialStatus: initialStatus,
                  ),
                );
              }
              // Default: show order form page
              final order = state.extra as Order?;
              return NoTransitionPage(child: OrderFormPage(order: order));
            },
          ),
          GoRoute(
            path: '/pos',
            name: 'pos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PosPage()),
          ),
          GoRoute(
            path: '/snack-box',
            name: 'snack-box',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SnackBoxPage()),
          ),
          // Paketan Route
          GoRoute(
            path: '/paketan',
            name: 'paketan',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PaketanPage()),
          ),
          // Produksi Route
          GoRoute(
            path: '/production',
            name: 'production',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProductionDashboardPage()),
          ),
          // Tagihan Route
          GoRoute(
            path: '/invoices',
            name: 'invoices',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InvoiceListPage()),
          ),
          // Pembelian Route
          GoRoute(
            path: '/purchasing',
            name: 'purchasing',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PurchaseListPage()),
          ),
          // Receipt Scan Route
          GoRoute(
            path: '/receipt-scan',
            name: 'receipt-scan',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReceiptScanPage()),
          ),
          // Supplier Route
          GoRoute(
            path: '/suppliers',
            name: 'suppliers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SupplierListPage()),
          ),
          // Bahan Baku Route
          GoRoute(
            path: '/raw-materials',
            name: 'raw-materials',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RawMaterialsPage()),
          ),
          // Master Data - Products
          GoRoute(
            path: '/products',
            name: 'products',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProductListPage()),
          ),
          // Master Data - Customers
          GoRoute(
            path: '/customers',
            name: 'customers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CustomerListPage()),
          ),
          // Laporan Route
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsPage()),
          ),
          // Pengaturan Route
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Halaman tidak ditemukan: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Kembali ke Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
