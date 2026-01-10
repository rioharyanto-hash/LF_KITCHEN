import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/purchase.dart';
import '../../data/providers/purchase_providers.dart';
import '../dialogs/purchase_form_dialog.dart';

/// Purchase List Page - Daftar Pembelian Bahan Baku
class PurchaseListPage extends ConsumerStatefulWidget {
  const PurchaseListPage({super.key});

  @override
  ConsumerState<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends ConsumerState<PurchaseListPage> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(purchaseListProvider.notifier).loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian Bahan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(purchaseListProvider.notifier).loadPurchases(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          _SummaryCards(),
          // Purchase List
          Expanded(
            child: purchaseState.when(
              initial: () => const Center(child: Text('Memuat data...')),
              loading: () => const Center(child: CircularProgressIndicator()),
              success: (purchases) => purchases.isEmpty
                  ? _EmptyState(onAdd: () => _showAddPurchaseDialog(context))
                  : _PurchaseList(
                      purchases: purchases,
                      dateFormat: _dateFormat,
                      currencyFormat: _currencyFormat,
                      onDelete: _deletePurchase,
                    ),
              error: (message, code) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error: $message'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(purchaseListProvider.notifier)
                          .loadPurchases(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPurchaseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Catat Pembelian'),
      ),
    );
  }

  void _showAddPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PurchaseFormDialog(),
    ).then((result) {
      if (result == true) {
        ref.read(purchaseListProvider.notifier).loadPurchases();
        ref.read(materialListProvider.notifier).loadMaterials();
      }
    });
  }

  Future<void> _deletePurchase(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pembelian'),
        content: const Text(
          'Apakah Anda yakin? Stok bahan akan dikurangi sesuai pembelian ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(purchaseListProvider.notifier).deletePurchase(id);
      ref.read(materialListProvider.notifier).loadMaterials();
    }
  }
}

class _SummaryCards extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseListProvider);
    final purchases = purchaseState.when(
      initial: () => <Purchase>[],
      loading: () => <Purchase>[],
      success: (data) => data,
      error: (msg, code) => <Purchase>[],
    );

    final totalPurchases = purchases.length;
    final totalSpent = purchases.fold<double>(0, (sum, p) => sum + p.totalCost);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Pembelian',
              value: totalPurchases.toString(),
              subtitle: 'Transaksi',
              icon: Icons.shopping_bag_outlined,
              iconColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Total Pengeluaran',
              value: NumberFormat.compactCurrency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(totalSpent),
              subtitle: 'Bulan ini',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pembelian',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Catat pembelian bahan baku Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Catat Pembelian'),
          ),
        ],
      ),
    );
  }
}

class _PurchaseList extends StatelessWidget {
  final List<Purchase> purchases;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final Future<void> Function(String) onDelete;

  const _PurchaseList({
    required this.purchases,
    required this.dateFormat,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    purchase.supplierName ?? 'Supplier tidak diketahui',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  currencyFormat.format(purchase.totalCost),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(purchase.purchaseDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (purchase.invoiceNumber != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.tag, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    purchase.invoiceNumber!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
            children: [
              if (purchase.items != null && purchase.items!.isNotEmpty)
                ...purchase.items!.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.materialName ?? 'Bahan'} (${item.quantity} ${item.materialUnit ?? 'pcs'})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          currencyFormat.format(item.subtotal),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => onDelete(purchase.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    label: Text(
                      'Hapus',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
