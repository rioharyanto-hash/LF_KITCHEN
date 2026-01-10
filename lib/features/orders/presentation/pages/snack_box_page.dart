import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../customers/data/models/customer.dart';
import '../../../customers/data/providers/customer_providers.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_providers.dart';

/// Snack Box Page - Pesanan Snack Box dengan isi pilihan (2-4 macam kue)
class SnackBoxPage extends ConsumerStatefulWidget {
  const SnackBoxPage({super.key});

  @override
  ConsumerState<SnackBoxPage> createState() => _SnackBoxPageState();
}

class _SnackBoxPageState extends ConsumerState<SnackBoxPage> {
  final List<Product> _selectedCakes = [];
  Product? _selectedWater;
  Customer? _selectedCustomer;
  DateTime? _deliveryDate;
  final _boxPriceController = TextEditingController(text: '2500');
  final _boxCountController = TextEditingController(text: '30');
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
    _boxPriceController.dispose();
    _boxCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Harga per kue berdasarkan tipe pelanggan
  double _getCakePrice(Product cake) {
    if (_selectedCustomer?.isSpecialPrice == true) {
      return cake.specialPrice > 0 ? cake.specialPrice : cake.unitPrice;
    }
    return cake.unitPrice;
  }

  // Harga isi per box (kue + air)
  double get _contentsPrice {
    double total = _selectedCakes.fold(
      0,
      (sum, cake) => sum + _getCakePrice(cake),
    );
    if (_selectedWater != null) total += _selectedWater!.unitPrice;
    return total;
  }

  // Harga kemasan/box
  double get _boxPrice => double.tryParse(_boxPriceController.text) ?? 0;

  // Harga per box (isi + kemasan)
  double get _pricePerBox => _contentsPrice + _boxPrice;

  // Jumlah box
  int get _boxCount => int.tryParse(_boxCountController.text) ?? 0;

  // Total harga pesanan
  double get _totalPrice => _pricePerBox * _boxCount;

  // Apakah jumlah box di bawah minimum
  bool get _isBelowMinimum => _boxCount > 0 && _boxCount < 30;

  // Validasi untuk enable tombol pesan
  bool get _canOrder =>
      _selectedCustomer != null &&
      _selectedCakes.length >= 2 &&
      _selectedCakes.length <= 4 &&
      _boxCount > 0 &&
      !_isProcessing;

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Snack Box'),
        actions: [
          if (_selectedCakes.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedCakes.clear();
                _selectedWater = null;
              }),
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset'),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left: Product Selection
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Info Bar
                _buildInfoBar(),
                const Divider(height: 1),
                // Product Grid
                Expanded(
                  child: productState.when(
                    initial: () =>
                        const Center(child: Text('Memuat produk...')),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    success: (products) => _buildProductGrid(products),
                    error: (msg, _) => Center(child: Text('Error: $msg')),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right: Box Configuration & Preview
          Expanded(flex: 1, child: _buildBoxPreview()),
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
          const Text('Pilih 2-4 macam kue untuk isi Snack Box'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedCakes.length >= 2 && _selectedCakes.length <= 4
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedCakes.length}/4 kue dipilih',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedCakes.length >= 2 && _selectedCakes.length <= 4
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    // Filter untuk kategori Snack Box dan Minuman
    final cakes = products
        .where((p) => p.category?.toLowerCase() == 'snack box')
        .toList();
    final waters = products
        .where((p) => p.category?.toLowerCase() == 'minuman')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Water Selection (moved to top)
        const Text(
          'Tambah Air Mineral (opsional):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (waters.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Belum ada produk minuman. Tambahkan produk dengan kategori "Minuman" di halaman Produk.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // No water option
              ChoiceChip(
                label: const Text('Tanpa Air'),
                selected: _selectedWater == null,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedWater = null);
                },
              ),
              // Water options
              ...waters.map(
                (water) => ChoiceChip(
                  avatar: const Icon(Icons.water_drop, size: 16),
                  label: Text(
                    '${water.name} (${_currencyFormat.format(water.unitPrice)})',
                  ),
                  selected: _selectedWater?.id == water.id,
                  onSelected: (selected) {
                    setState(() => _selectedWater = selected ? water : null);
                  },
                  selectedColor: Colors.blue.shade100,
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Cake Selection
        const Text(
          'Pilih Kue (2-4 macam):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: cakes.length,
          itemBuilder: (context, index) =>
              _buildProductCard(cakes[index], isCake: true),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, {required bool isCake}) {
    final isSelected = _selectedCakes.any((c) => c.id == product.id);
    final canSelect = _selectedCakes.length < 4 || isSelected;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: canSelect ? () => _toggleCake(product) : null,
        child: Opacity(
          opacity: canSelect ? 1.0 : 0.5,
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
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
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
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _currencyFormat.format(_getCakePrice(product)),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.cake_outlined, size: 32, color: Colors.grey.shade400),
    );
  }

  void _toggleCake(Product product) {
    setState(() {
      final index = _selectedCakes.indexWhere((c) => c.id == product.id);
      if (index >= 0) {
        _selectedCakes.removeAt(index);
      } else if (_selectedCakes.length < 4) {
        _selectedCakes.add(product);
      }
    });
  }

  Widget _buildBoxPreview() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(Icons.inventory_2, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Snack Box',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Box Contents & Config
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer Dropdown with Label
              const Text(
                'Nama Pemesan *',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ref
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
                        : DropdownButtonFormField<Customer>(
                            value: _selectedCustomer,
                            hint: const Text('Pilih pelanggan'),
                            isExpanded: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.person,
                                size: 20,
                                color: _selectedCustomer?.isSpecialPrice == true
                                    ? Colors.amber
                                    : null,
                              ),
                              suffixIcon:
                                  _selectedCustomer?.isSpecialPrice == true
                                  ? const Tooltip(
                                      message: 'Pelanggan Harga Spesial',
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    )
                                  : null,
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
                          ),
                    error: (msg, _) => Text('Error: $msg'),
                  ),
              const SizedBox(height: 16),

              // Delivery Date Label
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
              // Delivery Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _deliveryDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _deliveryDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: 'Pilih tanggal',
                    prefixIcon: const Icon(
                      Icons.event,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIcon: _deliveryDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _deliveryDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _deliveryDate != null
                        ? DateFormat(
                            'EEEE, dd MMM yyyy',
                            'id_ID',
                          ).format(_deliveryDate!)
                        : 'Pilih tanggal pengambilan',
                    style: TextStyle(
                      color: _deliveryDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selected Cakes Section - redesigned
              Row(
                children: [
                  const Text(
                    'ISI BOX',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '(${_selectedCakes.length}/4)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _selectedCakes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Belum ada kue dipilih\n(Pilih 2-4 macam kue dari panel kiri)',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: _selectedCakes.map((cake) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      cake.imageUrl != null &&
                                          cake.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            cake.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cake.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '1× ${_currencyFormat.format(_getCakePrice(cake))}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete Button
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _selectedCakes.remove(cake);
                                  }),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              if (_selectedWater != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.water_drop,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    _selectedWater!.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Text(
                    _currencyFormat.format(_selectedWater!.unitPrice),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],

              const Divider(height: 24),

              // Box Price Labels
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'HARGA BOX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'JUMLAH BOX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Box Price Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _boxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '2500',
                        prefixText: 'Rp ',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _boxCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '30',
                        suffixText: 'box',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        helperText: _isBelowMinimum ? '⚠️ Min 30 box' : null,
                        helperStyle: TextStyle(color: Colors.orange.shade700),
                      ),
                      onChanged: (_) => setState(() {}),
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

              // Price Breakdown
              _buildPriceRow('Subtotal Isi', _contentsPrice),
              _buildPriceRow('Harga Kemasan', _boxPrice),
              const Divider(),
              _buildPriceRow('Harga per Box', _pricePerBox, isBold: true),
              const SizedBox(height: 8),
              _buildPriceRow(
                '× $_boxCount box',
                _totalPrice,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currencyFormat.format(_totalPrice),
                    style: TextStyle(
                      fontSize: 24,
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
                      : const Icon(Icons.shopping_bag),
                  label: Text(
                    _isProcessing ? 'Memproses...' : 'Pesan Snack Box',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_selectedCakes.length < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Pilih minimal 2 macam kue',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_selectedCustomer == null && _selectedCakes.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Pilih pelanggan',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    double value, {
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
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
          ),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: isTotal ? 18 : null,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrder() async {
    setState(() => _isProcessing = true);

    try {
      // Build structured order items for snack box
      final items = <OrderItem>[];

      // 1. Main SNACK BOX item (header)
      items.add(
        OrderItem(
          id: '',
          orderId: '',
          productId: null,
          productName: 'SNACK BOX',
          quantity: _boxCount,
          unitPrice: _pricePerBox,
          subtotal: _totalPrice,
        ),
      );

      // 2. Individual cake items (ISI)
      for (final cake in _selectedCakes) {
        items.add(
          OrderItem(
            id: '',
            orderId: '',
            productId: cake.id,
            productName: '  - ${cake.name}',
            quantity: _boxCount, // Same qty as box count
            unitPrice: _getCakePrice(cake),
            subtotal: 0, // Component detail, not adding to total
          ),
        );
      }

      // 3. Water if selected
      if (_selectedWater != null) {
        items.add(
          OrderItem(
            id: '',
            orderId: '',
            productId: _selectedWater!.id,
            productName: '  - ${_selectedWater!.name}',
            quantity: _boxCount,
            unitPrice: _selectedWater!.unitPrice,
            subtotal: 0, // Component detail
          ),
        );
      }

      // 4. Box/Packaging
      items.add(
        OrderItem(
          id: '',
          orderId: '',
          productId: null,
          productName: '  - Dus',
          quantity: _boxCount,
          unitPrice: _boxPrice,
          subtotal: 0, // Component detail
        ),
      );

      final userNotes = _notesController.text.isNotEmpty
          ? _notesController.text
          : null;

      final order = Order(
        id: '',
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        orderDate: DateTime.now(),
        deliveryDate: _deliveryDate,
        orderType: OrderType.po,
        status: OrderStatus.draft,
        totalAmount: _totalPrice,
        dpAmount: 0,
        paymentStatus: PaymentStatus.unpaid,
        notes: userNotes,
        createdAt: DateTime.now(),
      );

      final result = await ref
          .read(orderRepositoryProvider)
          .create(order, items);

      result.when(
        success: (order) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Snack Box $_boxCount box berhasil dipesan!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Reset form
            setState(() {
              _selectedCakes.clear();
              _selectedWater = null;
              _selectedCustomer = null;
              _deliveryDate = null;
              _boxCountController.text = '30';
              _notesController.clear();
            });
          }
        },
        failure: (message, code) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal membuat pesanan: $message'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
