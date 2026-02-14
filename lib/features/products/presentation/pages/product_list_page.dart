import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/providers/product_providers.dart';
import '../widgets/product_card.dart';
import '../dialogs/product_form_dialog.dart';

/// Product List Page - Daftar Produk Kue
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products on init
    Future.microtask(() {
      ref.read(productListProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Kue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              scrollInfo.metrics.axis == Axis.vertical) {
            ref.read(productListProvider.notifier).loadMore();
          }
          return false;
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(productListProvider.notifier)
                                .loadProducts();
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref.read(productListProvider.notifier).searchProducts(value);
                },
              ),
            ),
            // Product List/Grid
            Expanded(
              child: productState.whenWithData(
                initial: () => const Center(child: Text('Memuat data...')),
                loading: (data) {
                  if (data != null && data.isNotEmpty) {
                    // Show previous data while loading
                    return isDesktop
                        ? _ProductGrid(
                            products: data,
                            onDelete: _deleteProduct,
                            onEdit: (p) => _showEditProductDialog(context, p),
                          )
                        : _ProductList(
                            products: data,
                            onDelete: _deleteProduct,
                            onEdit: (p) => _showEditProductDialog(context, p),
                          );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                success: (products) {
                  if (products.isEmpty) {
                    return _EmptyState(
                      onAddProduct: () => _showAddProductDialog(context),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(productListProvider.notifier).refresh(),
                    child: isDesktop
                        ? _ProductGrid(
                            products: products,
                            onDelete: _deleteProduct,
                            onEdit: (p) => _showEditProductDialog(context, p),
                          )
                        : _ProductList(
                            products: products,
                            onDelete: _deleteProduct,
                            onEdit: (p) => _showEditProductDialog(context, p),
                          ),
                  );
                },
                error: (message, code) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $message'),
                      if (code != null) Text('Code: $code'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(productListProvider.notifier)
                            .loadProducts(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading More Indicator
            if (productState.isLoading &&
                productState.hasData &&
                productState.data!.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProductFormDialog(),
    ).then((result) {
      if (result == true) {
        ref.read(productListProvider.notifier).loadProducts();
      }
    });
  }

  void _showEditProductDialog(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    ).then((result) {
      if (result == true) {
        ref.read(productListProvider.notifier).loadProducts();
      }
    });
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
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
      await ref.read(productListProvider.notifier).deleteProduct(id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddProduct;

  const _EmptyState({required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cake_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Tambahkan produk pertama Anda'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Produk'),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List products;
  final Future<void> Function(String) onDelete;
  final void Function(dynamic) onEdit;

  const _ProductGrid({
    required this.products,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onEdit: () => onEdit(products[index]),
        onDelete: () => onDelete(products[index].id),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List products;
  final Future<void> Function(String) onDelete;
  final void Function(dynamic) onEdit;

  const _ProductList({
    required this.products,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onEdit: () => onEdit(products[index]),
        onDelete: () => onDelete(products[index].id),
        isListMode: true,
      ),
    );
  }
}
