import 'package:flutter/material.dart';
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
import '../../../orders/data/models/order.dart';
import '../../../orders/data/providers/order_providers.dart';
import '../../../orders/presentation/widgets/mobile_product_paginated_grid.dart';

/// Paketan Page - Seperti Snack Box, pilih produk untuk paket, harga bisa diedit
class PaketanPage extends ConsumerStatefulWidget {
  const PaketanPage({super.key});

  @override
  ConsumerState<PaketanPage> createState() => _PaketanPageState();
}

class _PaketanPageState extends ConsumerState<PaketanPage> {
  final List<_SelectedProduct> _selectedProducts = [];
  Customer? _selectedCustomer;
  DateTime? _deliveryDate;
  final _packageNameController = TextEditingController(text: 'Paket');
  final _packagingPriceController = TextEditingController(text: '0');
  final _finalPriceController = TextEditingController();
  final _packageQtyController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productListProvider.notifier).loadProducts();
      ref.read(customerListProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _packagingPriceController.dispose();
    _finalPriceController.dispose();
    _packageQtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Total harga produk (harga produk × qty)
  double get _totalProductPrice =>
      _selectedProducts.fold(0, (sum, p) => sum + (p.price * p.qty));

  // Harga kemasan
  double get _packagingPrice =>
      double.tryParse(_packagingPriceController.text) ?? 0;

  // Harga dasar (produk + kemasan)
  double get _basePrice => _totalProductPrice + _packagingPrice;

  // Harga akhir per paket (bisa diedit, default = harga dasar)
  double get _finalPrice =>
      double.tryParse(_finalPriceController.text) ?? _basePrice;

  // Jumlah paket (minimal 1)
  int get _packageQty =>
      (int.tryParse(_packageQtyController.text) ?? 1).clamp(1, 9999);

  // Total harga pesanan
  double get _totalPrice => _finalPrice * _packageQty;

  // Validasi
  bool get _canOrder =>
      _selectedCustomer != null &&
      _selectedProducts.isNotEmpty &&
      _packageQty >= 1 &&
      !_isProcessing;

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Paketan'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/orders?view=list'),
              icon: const Icon(Icons.list_alt, size: 18),
              label: Text(isMobile ? 'Daftar' : 'Lihat Daftar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
            ),
          ),
          if (_selectedProducts.isNotEmpty && !isMobile)
            TextButton.icon(
              onPressed: () => setState(() => _selectedProducts.clear()),
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset'),
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
        Expanded(flex: 1, child: _buildPackagePreview()),
      ],
    );
  }

  Widget _buildMobileLayout(AsyncState<List<Product>> productState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBar(),
          productState.when(
            initial: () => const SizedBox(),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            success: (products) => _buildMobileProductList(products),
            error: (msg, code) => Center(child: Text('Error: $msg')),
          ),
          const Divider(),
          _buildMobilePackagePreview(),
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
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Pilih produk untuk isi paket, lalu atur harga paket'),
          ),
          if (_selectedProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_selectedProducts.length} item dipilih',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    // Kelompokkan berdasarkan productType
    final grouped = <String, List<Product>>{};
    for (final p in products) {
      final type = p.productType ?? 'Lainnya';
      grouped.putIfAbsent(type, () => []).add(p);
    }
    final sortedTypes = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sortedTypes.map((type) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: grouped[type]!.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(grouped[type]![index]),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileProductList(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilih Isi Paket:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          MobileProductPaginatedGrid(
            products: products,
            // Use productType as filter because 'Paketan' usually involves 'Nasi', 'Lauk', 'Minuman' types
            useProductTypeAsFilter: true,
            isSelected: (p) => _selectedProducts.any((sp) => sp.id == p.id),
            onProductTap: (product) {
              setState(() {
                final index = _selectedProducts.indexWhere(
                  (p) => p.id == product.id,
                );
                if (index >= 0) {
                  _selectedProducts.removeAt(index);
                } else {
                  _selectedProducts.add(
                    _SelectedProduct(
                      id: product.id,
                      name: product.name,
                      price: product.unitPrice,
                      qty: 1,
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final existingIndex = _selectedProducts.indexWhere(
      (p) => p.id == product.id,
    );
    final isSelected = existingIndex >= 0;
    final qty = isSelected ? _selectedProducts[existingIndex].qty : 0;

    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            setState(() {
              _selectedProducts.add(
                _SelectedProduct(
                  id: product.id,
                  name: product.name,
                  price: product.unitPrice,
                  qty: 1,
                ),
              );
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Center(
                                child: Icon(
                                  Icons.cake,
                                  size: 32,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.cake,
                              size: 32,
                              color: Colors.grey.shade300,
                            ),
                          ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
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
                      _currencyFormat.format(product.unitPrice),
                      style: TextStyle(fontSize: 10, color: AppColors.primary),
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

  Widget _buildPackagePreview() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: const Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Detail Paket',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer
                  _buildSectionLabel('NAMA PEMESAN *'),
                  const SizedBox(height: 6),
                  _buildCustomerDropdown(),
                  const SizedBox(height: 16),

                  // Date
                  _buildSectionLabel('TANGGAL AMBIL'),
                  const SizedBox(height: 6),
                  _buildDatePicker(),
                  const SizedBox(height: 16),

                  // Package Name
                  _buildSectionLabel('NAMA PAKET'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _packageNameController,
                    decoration: InputDecoration(
                      hintText: 'cth: Paket Nasi Tumpeng',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Isi paket
                  _buildSectionLabel(
                    'ISI PAKET (${_selectedProducts.length} item)',
                  ),
                  const SizedBox(height: 8),
                  if (_selectedProducts.isEmpty)
                    Text(
                      'Pilih produk di sebelah kiri',
                      style: TextStyle(color: Colors.grey.shade500),
                    )
                  else
                    ...List.generate(
                      _selectedProducts.length,
                      (i) => _buildSelectedProductTile(_selectedProducts[i], i),
                    ),
                  const SizedBox(height: 16),

                  // Notes
                  _buildSectionLabel('CATATAN'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Catatan tambahan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildPriceSummary(),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildMobilePackagePreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('NAMA PEMESAN *'),
          const SizedBox(height: 6),
          _buildCustomerDropdown(),
          const SizedBox(height: 16),

          _buildSectionLabel('TANGGAL AMBIL'),
          const SizedBox(height: 6),
          _buildDatePicker(),
          const SizedBox(height: 16),

          _buildSectionLabel('NAMA PAKET'),
          const SizedBox(height: 6),
          TextField(
            controller: _packageNameController,
            decoration: InputDecoration(
              hintText: 'cth: Paket Nasi Tumpeng',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionLabel('CATATAN'),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Catatan tambahan...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 24),

          _buildPriceSummary(),
          const SizedBox(height: 16),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 11,
        color: Colors.grey.shade600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    final customerState = ref.watch(customerListProvider);
    return customerState.when(
      initial: () => const SizedBox(),
      loading: () => const LinearProgressIndicator(),
      success: (customers) => DropdownButtonFormField<Customer>(
        initialValue: _selectedCustomer,
        decoration: InputDecoration(
          hintText: 'Pilih Pelanggan',
          prefixIcon: Icon(Icons.person, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
        menuMaxHeight: 250,
        isExpanded: true,
        items: customers
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(
                  '${c.name} (${c.phone})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedCustomer = value),
      ),
      error: (msg, code) => Text('Error: $msg'),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              _deliveryDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _deliveryDate = date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Pilih tanggal',
          prefixIcon: Icon(Icons.event, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
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

  Widget _buildSelectedProductTile(_SelectedProduct product, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(product.name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '${product.qty}x',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => setState(() => _selectedProducts.removeAt(index)),
          color: Colors.red,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total produk (readonly)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Produk:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                _currencyFormat.format(_totalProductPrice),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Harga kemasan (editable)
          Row(
            children: [
              const Text('Harga Kemasan:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _packagingPriceController,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Harga dasar (readonly)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harga Dasar (Produk + Kemasan):',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                _currencyFormat.format(_basePrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Harga akhir per paket (editable)
          TextField(
            controller: _finalPriceController,
            decoration: InputDecoration(
              labelText: 'HARGA AKHIR PER PAKET',
              hintText: _basePrice.toStringAsFixed(0),
              prefixText: 'Rp ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.primary.withAlpha(15),
              helperText: 'Kosongkan untuk harga = harga dasar',
              helperStyle: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Jumlah paket
          Row(
            children: [
              const Text(
                'Jumlah Paket:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _packageQtyController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Spacer(),
              Text(
                'Min: 1',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL BAYAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(_totalPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _canOrder ? _createOrder : null,
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
          label: Text(_isProcessing ? 'Memproses...' : 'Buat Pesanan'),
        ),
      ),
    );
  }

  Future<void> _createOrder() async {
    if (!_canOrder) return;

    setState(() => _isProcessing = true);

    try {
      // Build notes dengan isi paket (TANPA harga per item)
      final packageNotes = StringBuffer();
      packageNotes.writeln(
        '=== ${_packageNameController.text.toUpperCase()} ===',
      );
      packageNotes.writeln('Isi:');
      for (final item in _selectedProducts) {
        packageNotes.writeln(
          '  - ${item.name}${item.qty > 1 ? " x${item.qty}" : ""}',
        );
      }
      if (_notesController.text.isNotEmpty) {
        packageNotes.writeln('\nCatatan: ${_notesController.text}');
      }

      // Add item ke form
      final orderFormNotifier = ref.read(orderFormProvider.notifier);
      orderFormNotifier.clearItems();
      orderFormNotifier.addItem(
        OrderItem(
          id: '',
          orderId: '',
          productId: null, // Paket bukan produk
          productName: _packageNameController.text,
          quantity: _packageQty,
          unitPrice: _finalPrice,
          subtotal: _totalPrice,
        ),
      );

      final result = await orderFormNotifier.createOrder(
        customerId: _selectedCustomer!.id,
        orderType: OrderType.po,
        deliveryDate: _deliveryDate,
        dpAmount: 0,
        notes: packageNotes.toString(),
      );

      result.when(
        success: (_) {
          if (mounted) {
            CustomToast.showSuccess(
              context: context,
              title: 'Pesanan paketan berhasil dibuat!',
            );

            // Reset form
            setState(() {
              _selectedProducts.clear();
              _selectedCustomer = null;
              _deliveryDate = null;
              _packageNameController.text = 'Paket';
              _packagingPriceController.text = '0';
              _finalPriceController.clear();
              _packageQtyController.text = '1';
              _notesController.clear();
            });

            context.go('/orders?view=list');
          }
        },
        failure: (message, _) {
          if (mounted) {
            CustomToast.showError(
              context: context,
              title: 'Gagal membuat pesanan: $message',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          context: context,
          title: 'Gagal membuat pesanan: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// Helper class for selected products
class _SelectedProduct {
  final String id;
  final String name;
  final double price;
  int qty;

  _SelectedProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
  });
}
