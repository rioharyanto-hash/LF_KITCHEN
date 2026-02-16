import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../../../customers/data/models/customer.dart';
import '../../../customers/data/providers/customer_providers.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_providers.dart';
import '../widgets/mobile_product_paginated_grid.dart';

/// Order Form Page - Halaman Buat Pesanan (seperti Snack Box)
class OrderFormPage extends ConsumerStatefulWidget {
  final Order? order;

  const OrderFormPage({super.key, this.order});

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  // Selected items with quantities
  final Map<Product, int> _selectedProducts = {};
  // Composite items (for Paketan/SnackBox with null productId)
  final List<OrderItem> _compositeItems = [];
  Customer? _selectedCustomer;
  DateTime? _orderDate;
  DateTime? _deliveryDate;
  final _dpController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  bool get isEditMode => widget.order != null;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Load customers
      ref.read(customerListProvider.notifier).loadCustomers();

      // Load products and wait
      await ref.read(productListProvider.notifier).loadProducts();
      // Ensure products are loaded before populating
      final productState = ref.read(productListProvider);
      final products = productState.data ?? [];

      if (widget.order != null) {
        var order = widget.order!;

        // If items are missing, fetch full order
        if (order.items == null || order.items!.isEmpty) {
          try {
            final result = await ref
                .read(orderRepositoryProvider)
                .getById(order.id);
            if (result.isSuccess && result.dataOrNull != null) {
              order = result.dataOrNull!;
            }
          } catch (e) {
            debugPrint('Error fetching full order: $e');
          }
        }

        if (mounted) {
          setState(() {
            _orderDate = order.orderDate;
            _deliveryDate = order.deliveryDate;
            _dpController.text = order.dpAmount.toStringAsFixed(0);
            _notesController.text = order.notes ?? '';
          });
        }

        // Load customer
        if (order.customerId != null) {
          ref
              .read(customerListProvider)
              .when(
                initial: () {},
                loading: () {},
                success: (customers) {
                  final customer = customers.firstWhere(
                    (c) => c.id == order.customerId,
                    orElse: () => customers.first,
                  );
                  if (mounted) setState(() => _selectedCustomer = customer);
                },
                error: (message, code) {},
              );
        }

        // Load items
        if (order.items != null && products.isNotEmpty) {
          final Map<Product, int> items = {};
          final List<OrderItem> composites = [];
          for (final item in order.items!) {
            if (item.productId == null || item.productId!.isEmpty) {
              // Composite item (Paketan/SnackBox)
              composites.add(item);
            } else {
              try {
                final product = products.firstWhere(
                  (p) => p.id == item.productId,
                );
                items[product] = item.quantity;
              } catch (_) {
                // Product not found, treat as composite
                composites.add(item);
              }
            }
          }
          if (mounted) {
            setState(() {
              _selectedProducts.addAll(items);
              _compositeItems.addAll(composites);
            });
          }
        }
      } else {
        // New order
        if (mounted) {
          setState(() => _orderDate = DateTime.now());
        }
      }
    });
  }

  @override
  void dispose() {
    _dpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getPrice(Product product) {
    if (_selectedCustomer?.isSpecialPrice == true) {
      return product.specialPrice > 0
          ? product.specialPrice
          : product.unitPrice;
    }
    return product.unitPrice;
  }

  double get _totalAmount {
    double total = 0;
    _selectedProducts.forEach((product, qty) {
      total += _getPrice(product) * qty;
    });
    // Add composite items (Paketan/SnackBox)
    for (final item in _compositeItems) {
      total += item.subtotal;
    }
    return total;
  }

  double get _dpAmount =>
      double.tryParse(_dpController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  double get _remainingAmount => _totalAmount - _dpAmount;

  bool get _canOrder =>
      _selectedCustomer != null &&
      (_selectedProducts.isNotEmpty || _compositeItems.isNotEmpty) &&
      _deliveryDate != null &&
      !_isProcessing;

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(isEditMode ? 'Edit Pesanan' : 'Buat Pesanan Baru'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/orders?view=list'),
              icon: Icon(Icons.list_alt, size: 18, color: AppColors.primary),
              label: Text(
                isMobile ? 'Daftar' : 'Daftar Pesanan',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          if (_selectedProducts.isNotEmpty && !isMobile)
            TextButton.icon(
              onPressed: () => setState(() => _selectedProducts.clear()),
              icon: const Icon(Icons.clear_all, color: Colors.white),
              label: const Text('Reset', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: isMobile
          ? _buildMobileLayout(productState)
          : _buildDesktopLayout(productState),
    );
  }

  Widget _buildDesktopLayout(AsyncState<List<Product>> productState) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildInfoBar(),
              const Divider(height: 1),
              Expanded(
                child: productState.when(
                  initial: () => const Center(child: Text('Memuat produk...')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  success: (products) => _buildProductGrid(products),
                  error: (msg, code) => Center(child: Text('Error: $msg')),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(flex: 1, child: _buildOrderPanel()),
      ],
    );
  }

  Widget _buildMobileLayout(AsyncState<List<Product>> productState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pilih produk untuk ditambahkan ke pesanan',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedProducts.isNotEmpty
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedProducts.length} item',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedProducts.isNotEmpty
                          ? Colors.green.shade800
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products section
          productState.when(
            initial: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Memuat produk...'),
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            success: (products) => _buildMobileProductSection(products),
            error: (msg, code) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $msg'),
              ),
            ),
          ),

          const Divider(),

          // Order details form
          _buildMobileOrderPanel(),
        ],
      ),
    );
  }

  Widget _buildMobileProductSection(List<Product> products) {
    // Deduplicate products by ID
    final Map<String, Product> uniqueProducts = {};
    for (final p in products) {
      uniqueProducts[p.id] = p;
    }
    final dedupedProducts = uniqueProducts.values.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Pilih Produk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (_selectedProducts.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedProducts.clear()),
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MobileProductPaginatedGrid(
            products: dedupedProducts,
            useProductTypeAsFilter: true,
            isSelected: (p) => _selectedProducts.containsKey(p),
            getQuantity: (p) => _selectedProducts[p] ?? 0,
            onProductTap: _addProduct,
            onDecrement: _decreaseProduct,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOrderPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Pesanan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Customer dropdown
          const Text(
            'NAMA PEMESAN *',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          _buildCustomerDropdown(),
          const SizedBox(height: 16),

          // Date pickers
          const Text(
            'TANGGAL PESANAN *',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          _buildOrderDatePicker(),
          const SizedBox(height: 16),

          const Text(
            'TANGGAL AMBIL *',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          _buildDatePicker(),
          const SizedBox(height: 16),

          // DP Amount
          const Text(
            'DP (UANG MUKA)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _dpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Total section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL'),
                    Text(
                      _currencyFormat.format(_totalAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (_dpAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sisa', style: TextStyle(fontSize: 13)),
                      Text(
                        _currencyFormat.format(_remainingAmount),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          Row(
            children: [
              if (isEditMode) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canOrder ? _submitOrder : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_cart),
                  label: Text(
                    _isProcessing
                        ? 'Memproses...'
                        : isEditMode
                        ? 'Simpan Perubahan'
                        : 'Buat Pesanan',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (!_canOrder && _selectedProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Pilih minimal 1 produk',
                style: TextStyle(fontSize: 12, color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Pilih produk untuk ditambahkan ke pesanan'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedProducts.isNotEmpty
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedProducts.length} produk dipilih',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedProducts.isNotEmpty
                    ? Colors.green.shade800
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    // Show all categories for Pesanan page, grouped by Jenis (productType)

    // Group by productType (Jenis)
    final Map<String, List<Product>> grouped = {};
    for (final p in products) {
      final jenis = p.productType ?? 'Lainnya';
      grouped.putIfAbsent(jenis, () => []);
      grouped[jenis]!.add(p);
    }

    // Sort groups alphabetically and sort products within each group
    final sortedKeys = grouped.keys.toList()..sort();
    for (final key in sortedKeys) {
      grouped[key]!.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final jenis = sortedKeys[index];
        final jenisProducts = grouped[jenis]!;

        final isMobile = MediaQuery.of(context).size.width < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                jenis.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 3 : 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 0.65 : 0.85,
              ),
              itemCount: jenisProducts.length,
              itemBuilder: (context, i) => _buildProductCard(jenisProducts[i]),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProducts.containsKey(product);
    final qty = _selectedProducts[product] ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _addProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.size != null && product.size!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.size!,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(_getPrice(product)),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.cake_outlined, size: 32, color: Colors.grey.shade400),
    );
  }

  void _addProduct(Product product) {
    setState(() {
      if (_selectedProducts.containsKey(product)) {
        _selectedProducts[product] = _selectedProducts[product]! + 1;
      } else {
        _selectedProducts[product] = 1;
      }
    });
  }

  void _decreaseProduct(Product product) {
    setState(() {
      if (_selectedProducts.containsKey(product)) {
        if (_selectedProducts[product]! > 1) {
          _selectedProducts[product] = _selectedProducts[product]! - 1;
        } else {
          _selectedProducts.remove(product);
        }
      }
    });
  }

  Widget _buildOrderPanel() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Config Panel
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer Dropdown
              const Text(
                'NAMA PEMESAN *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildCustomerDropdown(),
              const SizedBox(height: 16),

              // Date Pickers
              const Text(
                'TANGGAL PESANAN *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildOrderDatePicker(),
              const SizedBox(height: 16),

              const Text(
                'TANGGAL AMBIL *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 20),

              // Selected Items
              Row(
                children: [
                  const Text(
                    'ITEM PESANAN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '(${_selectedProducts.length} item)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildItemsList(),

              const Divider(height: 24),

              // DP Input
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DP (Uang Muka)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _dpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            prefixText: 'Rp ',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Catatan tambahan...',
                  isDense: true,
                ),
              ),

              const Divider(height: 24),

              // Price Summary
              _buildPriceRow('Total', _totalAmount, isBold: true),
              _buildPriceRow('DP', _dpAmount),
              const Divider(),
              _buildPriceRow(
                'Sisa Bayar',
                _remainingAmount,
                isBold: true,
                isTotal: true,
              ),
            ],
          ),
        ),

        // Order Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
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
              if (!_canOrder && _selectedProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pilih minimal 1 produk',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                children: [
                  if (isEditMode) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/orders?view=list'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _canOrder ? _submitOrder : null,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isProcessing
                            ? 'Memproses...'
                            : isEditMode
                            ? 'Update Pesanan'
                            : 'Buat Pesanan',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    if (isEditMode) {
      return TextFormField(
        key: ValueKey(_selectedCustomer?.id ?? widget.order?.customerId),
        initialValue: _selectedCustomer?.name ?? widget.order?.customerName,
        decoration: InputDecoration(
          labelText: 'Pelanggan',
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: const Icon(Icons.person, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        enabled: false, // Read-only
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return ref
        .watch(customerListProvider)
        .when(
          initial: () => const LinearProgressIndicator(),
          loading: () => const LinearProgressIndicator(),
          success: (customers) => customers.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Belum ada pelanggan. Tambahkan di menu Pelanggan.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Builder(
                  builder: (context) {
                    // Validate selected customer exists in the list
                    final validCustomer =
                        _selectedCustomer != null &&
                            customers.any((c) => c.id == _selectedCustomer!.id)
                        ? customers.firstWhere(
                            (c) => c.id == _selectedCustomer!.id,
                          )
                        : null;
                    return DropdownButtonFormField<Customer>(
                      initialValue: validCustomer,
                      hint: const Text('Pilih pelanggan'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person,
                          size: 20,
                          color: validCustomer?.isSpecialPrice == true
                              ? Colors.amber
                              : null,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('${c.name} (${c.phone})'),
                                  ),
                                  if (c.isSpecialPrice)
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCustomer = value),
                    );
                  },
                ),
          error: (msg, code) => Text('Error: $msg'),
        );
  }

  Widget _buildOrderDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _orderDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _orderDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Pilih tanggal pesanan',
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Text(
          _orderDate != null
              ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_orderDate!)
              : 'Pilih tanggal pesanan',
          style: TextStyle(
            color: _orderDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              _deliveryDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime(2020), // Remove restriction
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _deliveryDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Pilih tanggal',
          prefixIcon: Icon(Icons.event, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: _deliveryDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _deliveryDate = null),
                )
              : null,
        ),
        child: Text(
          _deliveryDate != null
              ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_deliveryDate!)
              : 'Pilih tanggal pengambilan',
          style: TextStyle(
            color: _deliveryDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    final hasItems = _selectedProducts.isNotEmpty || _compositeItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: !hasItems
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada item dipilih\n(Pilih produk dari panel kiri)',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                // Product-based items
                ..._selectedProducts.entries.map((entry) {
                  final product = entry.key;
                  final qty = entry.value;
                  final subtotal = _getPrice(product) * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Thumbnail
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.cake,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                  ),
                                )
                              : Icon(
                                  Icons.cake,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(_getPrice(product)),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quantity Controls
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              onPressed: () => setState(() {
                                if (qty > 1) {
                                  _selectedProducts[product] = qty - 1;
                                } else {
                                  _selectedProducts.remove(product);
                                }
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(
                              width: 40,
                              height: 28,
                              child: TextField(
                                controller: TextEditingController(text: '$qty'),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 4,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (value) {
                                  final newQty = int.tryParse(value) ?? 1;
                                  setState(() {
                                    if (newQty > 0) {
                                      _selectedProducts[product] = newQty;
                                    } else {
                                      _selectedProducts.remove(product);
                                    }
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              onPressed: () => setState(() {
                                _selectedProducts[product] = qty + 1;
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Subtotal
                        Text(
                          _currencyFormat.format(subtotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Composite items (read-only)
                ..._compositeItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Thumbnail placeholder
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.dinner_dining,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Paket Custom',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(item.unitPrice),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quantity (read-only)
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Subtotal
                        Text(
                          _currencyFormat.format(item.subtotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_canOrder) return;

    setState(() => _isProcessing = true);

    try {
      // Build order items from selected products
      final items = _selectedProducts.entries.map((entry) {
        final product = entry.key;
        final qty = entry.value;
        return OrderItem(
          id: '',
          orderId: '',
          productId: product.id,
          productName: product.name,
          quantity: qty,
          unitPrice: _getPrice(product),
          subtotal: _getPrice(product) * qty,
        );
      }).toList();

      // Add composite items (Paketan/SnackBox) - preserve as-is
      items.addAll(_compositeItems);

      // Build order
      final order = Order(
        id: widget.order?.id ?? '',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        orderDate: _orderDate ?? DateTime.now(),
        deliveryDate: _deliveryDate,
        orderType: OrderType.po,
        status: OrderStatus.draft,
        totalAmount: _totalAmount,
        dpAmount: _dpAmount,
        paymentStatus: _dpAmount >= _totalAmount
            ? PaymentStatus.paid
            : PaymentStatus.partial,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.order?.createdAt ?? DateTime.now(),
      );

      Result<Order> result;
      if (isEditMode) {
        result = await ref.read(orderRepositoryProvider).update(order, items);
      } else {
        result = await ref.read(orderRepositoryProvider).create(order, items);
      }

      if (result.isSuccess && mounted) {
        CustomToast.showSuccess(
          context: context,
          title: isEditMode
              ? 'Pesanan Berhasil Diupdate'
              : 'Pesanan Berhasil Dibuat',
          subtitle: 'Pesanan untuk ${_selectedCustomer!.name} telah disimpan.',
        );
        // Navigate to order list
        context.go('/orders?view=list');
      } else if (mounted) {
        CustomToast.showError(
          context: context,
          title: 'Gagal Menyimpan Pesanan',
          subtitle: result.errorMessage ?? 'Terjadi kesalahan',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
