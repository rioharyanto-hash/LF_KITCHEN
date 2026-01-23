import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/utils/async_state.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';
import '../../data/models/package.dart';
import '../../data/providers/package_providers.dart';

/// Halaman Kelola Paket - Buat paket dengan pilih produk, set harga
class PackageManagementPage extends ConsumerStatefulWidget {
  const PackageManagementPage({super.key});

  @override
  ConsumerState<PackageManagementPage> createState() =>
      _PackageManagementPageState();
}

class _PackageManagementPageState extends ConsumerState<PackageManagementPage> {
  final List<_SelectedItem> _selectedItems = [];
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isProcessing = false;
  Package? _editingPackage;

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
      ref.read(packageListProvider.notifier).loadPackages(activeOnly: false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _totalComponentPrice =>
      _selectedItems.fold(0, (sum, item) => sum + item.subtotal);

  bool get _canSave =>
      _nameController.text.isNotEmpty &&
      _selectedItems.isNotEmpty &&
      !_isProcessing;

  void _resetForm() {
    setState(() {
      _selectedItems.clear();
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _editingPackage = null;
    });
  }

  void _loadPackageForEdit(Package package) {
    setState(() {
      _editingPackage = package;
      _nameController.text = package.name;
      _descController.text = package.description ?? '';
      _priceController.text = package.price.toStringAsFixed(0);
      _selectedItems.clear();
      if (package.items != null) {
        for (final item in package.items!) {
          _selectedItems.add(
            _SelectedItem(
              name: item.itemName,
              qty: item.quantity,
              price: item.unitPrice,
              productId: item.productId,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productListProvider);
    final packageState = ref.watch(packageListProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editingPackage != null
              ? 'Edit: ${_editingPackage!.name}'
              : 'Buat Paket Baru',
        ),
        actions: [
          if (_editingPackage != null)
            TextButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.add),
              label: const Text('Buat Baru'),
            ),
        ],
      ),
      body: isMobile
          ? _buildMobileLayout(productState)
          : _buildDesktopLayout(productState, packageState),
    );
  }

  Widget _buildDesktopLayout(
    AsyncState<List<Product>> productState,
    AsyncState<List<Package>> packageState,
  ) {
    return Row(
      children: [
        // Daftar paket yang ada
        SizedBox(
          width: 280,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: const Row(
                  children: [
                    Icon(Icons.inventory_2, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Paket Tersedia',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: packageState.when(
                  initial: () => const SizedBox(),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  success: (packages) => packages.isEmpty
                      ? const Center(child: Text('Belum ada paket'))
                      : ListView.builder(
                          itemCount: packages.length,
                          itemBuilder: (context, index) =>
                              _buildPackageListItem(packages[index]),
                        ),
                  error: (msg, _) => Center(child: Text('Error: $msg')),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Form buat paket
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildFormHeader(),
              const Divider(height: 1),
              Expanded(
                child: productState.when(
                  initial: () => const Center(child: Text('Memuat...')),
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
        // Preview paket
        SizedBox(width: 320, child: _buildPackagePreview()),
      ],
    );
  }

  Widget _buildMobileLayout(AsyncState<List<Product>> productState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormHeader(),
          productState.when(
            initial: () => const SizedBox(),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            success: (products) => _buildMobileProductList(products),
            error: (msg, _) => Center(child: Text('Error: $msg')),
          ),
          const Divider(),
          _buildMobilePackagePreview(),
        ],
      ),
    );
  }

  Widget _buildPackageListItem(Package package) {
    final isEditing = _editingPackage?.id == package.id;
    return ListTile(
      dense: true,
      selected: isEditing,
      selectedTileColor: AppColors.primary.withAlpha(20),
      leading: Icon(
        Icons.inventory_2,
        color: package.isActive ? AppColors.primary : Colors.grey,
        size: 20,
      ),
      title: Text(
        package.name,
        style: TextStyle(
          fontWeight: isEditing ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        _currencyFormat.format(package.price),
        style: TextStyle(fontSize: 11, color: AppColors.primary),
      ),
      trailing: package.isActive
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('OFF', style: TextStyle(fontSize: 9)),
            ),
      onTap: () => _loadPackageForEdit(package),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Paket *',
                hintText: 'cth: Paket Nasi Tumpeng',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Deskripsi (opsional)',
                hintText: 'cth: Untuk 10 orang',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildMobileProductList(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Isi Paket:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: products.map((p) => _buildProductChip(p)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final existingIndex = _selectedItems.indexWhere(
      (item) => item.productId == product.id || item.name == product.name,
    );
    final isSelected = existingIndex >= 0;
    final qty = isSelected ? _selectedItems[existingIndex].qty : 0;

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
              _selectedItems.add(
                _SelectedItem(
                  name: product.name,
                  qty: 1,
                  price: product.unitPrice,
                  productId: product.id,
                ),
              );
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(product.unitPrice),
                style: TextStyle(fontSize: 11, color: AppColors.primary),
              ),
              const Spacer(),
              if (isSelected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (qty <= 1) {
                            _selectedItems.removeAt(existingIndex);
                          } else {
                            _selectedItems[existingIndex].qty--;
                          }
                        });
                      },
                      icon: const Icon(Icons.remove_circle, size: 22),
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          qty.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedItems[existingIndex].qty++;
                        });
                      },
                      icon: const Icon(Icons.add_circle, size: 22),
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    'Tap untuk pilih',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductChip(Product product) {
    final existingIndex = _selectedItems.indexWhere(
      (item) => item.productId == product.id || item.name == product.name,
    );
    final isSelected = existingIndex >= 0;

    return FilterChip(
      label: Text(product.name),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedItems.add(
              _SelectedItem(
                name: product.name,
                qty: 1,
                price: product.unitPrice,
                productId: product.id,
              ),
            );
          } else {
            _selectedItems.removeAt(existingIndex);
          }
        });
      },
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
                  'Isi Paket',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedItems.isEmpty
                ? const Center(child: Text('Pilih produk untuk isi paket'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _selectedItems.length,
                    itemBuilder: (context, index) =>
                        _buildSelectedItemTile(_selectedItems[index], index),
                  ),
          ),
          _buildPriceSummary(),
          _buildActionButtons(),
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
          const Text(
            'Isi Paket:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_selectedItems.isEmpty)
            const Text(
              'Belum ada isi paket',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...List.generate(
              _selectedItems.length,
              (i) => _buildSelectedItemTile(_selectedItems[i], i),
            ),
          const SizedBox(height: 16),
          _buildPriceSummary(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSelectedItemTile(_SelectedItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(item.name),
        subtitle: Text(
          '${item.qty} × ${_currencyFormat.format(item.price)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currencyFormat.format(item.subtotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _selectedItems.removeAt(index)),
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Komponen:'),
              Text(
                _currencyFormat.format(_totalComponentPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'HARGA JUAL PAKET',
              hintText: _totalComponentPrice.toStringAsFixed(0),
              prefixText: 'Rp ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.primary.withAlpha(10),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kosongkan untuk harga = total komponen',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isEditing = _editingPackage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSave ? _savePackage : null,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isEditing ? Icons.save : Icons.add),
              label: Text(isEditing ? 'Simpan Perubahan' : 'Simpan Paket'),
            ),
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleActive(),
                    icon: Icon(
                      _editingPackage!.isActive
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    label: Text(
                      _editingPackage!.isActive ? 'Nonaktifkan' : 'Aktifkan',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deletePackage(),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _savePackage() async {
    if (!_canSave) return;

    setState(() => _isProcessing = true);

    try {
      final price =
          double.tryParse(_priceController.text) ?? _totalComponentPrice;
      final isEditing = _editingPackage != null;

      // Create/update package
      final packageData = Package(
        id: _editingPackage?.id ?? '',
        name: _nameController.text,
        description: _descController.text.isEmpty ? null : _descController.text,
        price: price,
        isActive: _editingPackage?.isActive ?? true,
        createdAt: _editingPackage?.createdAt ?? DateTime.now(),
      );

      final formNotifier = ref.read(packageFormProvider.notifier);
      final success = isEditing
          ? await formNotifier.updatePackage(packageData)
          : await formNotifier.createPackage(packageData);

      if (success) {
        // Get created package ID
        final createdPackage = ref.read(packageFormProvider).data;
        if (createdPackage != null || isEditing) {
          final packageId = isEditing
              ? _editingPackage!.id
              : createdPackage!.id;

          // Delete old items if editing
          if (isEditing) {
            await ref.read(packageRepositoryProvider).deleteAllItems(packageId);
          }

          // Add items
          for (final item in _selectedItems) {
            await formNotifier.addItem(
              PackageItem(
                id: '',
                packageId: packageId,
                productId: item.productId,
                itemName: item.name,
                quantity: item.qty,
                unitPrice: item.price,
              ),
            );
          }
        }

        // Refresh list
        ref.read(packageListProvider.notifier).loadPackages(activeOnly: false);

        if (mounted) {
          CustomToast.showSuccess(
            context: context,
            title: isEditing
                ? 'Paket berhasil diupdate'
                : 'Paket berhasil disimpan',
          );
          _resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context: context, title: 'Gagal menyimpan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _toggleActive() async {
    if (_editingPackage == null) return;

    final success = await ref
        .read(packageListProvider.notifier)
        .toggleActive(_editingPackage!.id, !_editingPackage!.isActive);

    if (success && mounted) {
      CustomToast.showSuccess(
        context: context,
        title: _editingPackage!.isActive
            ? 'Paket dinonaktifkan'
            : 'Paket diaktifkan',
      );
      _resetForm();
    }
  }

  Future<void> _deletePackage() async {
    if (_editingPackage == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Paket?'),
        content: Text('Yakin ingin menghapus "${_editingPackage!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(packageListProvider.notifier)
          .deletePackage(_editingPackage!.id);
      if (success && mounted) {
        CustomToast.showSuccess(
          context: context,
          title: 'Paket berhasil dihapus',
        );
        _resetForm();
      }
    }
  }
}

/// Helper class for selected items
class _SelectedItem {
  final String name;
  int qty;
  final double price;
  final String? productId;

  _SelectedItem({
    required this.name,
    required this.qty,
    required this.price,
    this.productId,
  });

  double get subtotal => qty * price;
}
