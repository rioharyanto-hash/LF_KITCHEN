import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_providers.dart';
import '../../data/providers/pos_providers.dart';

/// POS Page - Kasir / Penjualan Langsung
class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productListProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(productListProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: isDesktop ? const _DesktopPosLayout() : const _MobilePosLayout(),
    );
  }
}

class _DesktopPosLayout extends StatelessWidget {
  const _DesktopPosLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        // Product Grid (2/3)
        Expanded(flex: 2, child: _ProductGrid()),
        VerticalDivider(width: 1),
        // Cart (1/3)
        Expanded(flex: 1, child: _CartPanel()),
      ],
    );
  }
}

class _MobilePosLayout extends StatelessWidget {
  const _MobilePosLayout();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Produk', icon: Icon(Icons.grid_view)),
              Tab(text: 'Keranjang', icon: Icon(Icons.shopping_basket)),
            ],
          ),
          const Expanded(
            child: TabBarView(children: [_ProductGrid(), _CartPanel()]),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productListProvider);

    return productState.when(
      initial: () => const Center(child: Text('Memuat produk...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (products) {
        if (products.isEmpty) {
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
                const Text('Tambahkan produk terlebih dahulu'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              _ProductCard(product: products[index]),
        );
      },
      error: (message, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $message'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(productListProvider.notifier).loadProducts(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.read(posCartProvider.notifier).addProduct(product);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} ditambahkan'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey.shade100,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _currencyFormat.format(product.unitPrice),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.cake_outlined, size: 32, color: Colors.grey.shade400),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(posCartProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keranjang (${cartState.itemCount})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (!cartState.isEmpty)
                TextButton(
                  onPressed: () =>
                      ref.read(posCartProvider.notifier).clearCart(),
                  child: Text(
                    'Hapus Semua',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
        // Cart Items
        Expanded(
          child: cartState.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_basket_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keranjang kosong',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Klik produk untuk menambahkan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return _CartItemTile(item: item);
                  },
                ),
        ),
        // Total & Pay Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    _currencyFormat.format(cartState.total),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cartState.isEmpty || cartState.isProcessing
                      ? null
                      : () => _showPaymentDialog(context, ref, cartState),
                  icon: cartState.isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    cartState.isProcessing ? 'Memproses...' : 'Bayar',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PosPaymentDialog(
        total: cartState.total,
        onPay: (method) async {
          ref.read(posCartProvider.notifier).setProcessing(true);

          try {
            // Create order items
            final items = cartState.items
                .map(
                  (item) => OrderItem(
                    id: '',
                    orderId: '',
                    productId: item.product.id,
                    productName: item.product.name,
                    quantity: item.quantity,
                    unitPrice: item.product.unitPrice,
                    subtotal: item.subtotal,
                  ),
                )
                .toList();

            // Create order
            final order = Order(
              id: '',
              orderDate: DateTime.now(),
              orderType: OrderType.direct,
              status: OrderStatus.completed,
              totalAmount: cartState.total,
              dpAmount: cartState.total,
              paymentStatus: PaymentStatus.paid,
              createdAt: DateTime.now(),
            );

            final result = await ref
                .read(orderRepositoryProvider)
                .create(order, items);

            if (result.isSuccess) {
              ref.read(posCartProvider.notifier).clearCart();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaksi berhasil!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Gagal menyimpan transaksi'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } finally {
            ref.read(posCartProvider.notifier).setProcessing(false);
          }
        },
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _currencyFormat.format(item.product.unitPrice),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => ref
                    .read(posCartProvider.notifier)
                    .decrementQuantity(item.product.id),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => ref
                    .read(posCartProvider.notifier)
                    .incrementQuantity(item.product.id),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              _currencyFormat.format(item.subtotal),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosPaymentDialog extends StatefulWidget {
  final double total;
  final Future<void> Function(String method) onPay;

  const _PosPaymentDialog({required this.total, required this.onPay});

  @override
  State<_PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class _PosPaymentDialogState extends State<_PosPaymentDialog> {
  String _selectedMethod = 'Tunai';
  bool _isLoading = false;

  static const _paymentMethods = ['Tunai', 'Transfer', 'QRIS'];

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(widget.total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Method
          const Text('Metode Pembayaran:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedMethod == method;
              return ChoiceChip(
                label: Text(method),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedMethod = method);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                avatar: Icon(
                  _getMethodIcon(method),
                  size: 16,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handlePayment,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_isLoading ? 'Memproses...' : 'Konfirmasi'),
        ),
      ],
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'Transfer':
        return Icons.account_balance;
      case 'QRIS':
        return Icons.qr_code;
      default:
        return Icons.payments;
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    await widget.onPay(_selectedMethod);
    setState(() => _isLoading = false);
  }
}
