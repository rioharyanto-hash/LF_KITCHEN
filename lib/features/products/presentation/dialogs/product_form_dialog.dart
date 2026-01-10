import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../categories/data/providers/category_providers.dart';
import '../../data/models/product.dart';
import '../../data/providers/product_providers.dart';

/// Product Form Dialog for Create/Edit
class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _specialPriceController;
  late TextEditingController _costController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;

  String? _selectedCategory;
  String? _selectedProductType;
  String? _selectedUnit;
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  // Predefined options
  static const List<String> _productTypes = [
    'Cake',
    'Pastry',
    'Bread',
    'Cookies',
    'Snack',
    'Minuman',
    'Lainnya',
  ];

  static const List<String> _units = [
    'pcs',
    'box',
    'slice',
    'loyang',
    'pack',
    'botol',
    'cup',
  ];

  static const List<String> _sizes = [
    '16 cm',
    '18 cm',
    '20 cm',
    '22 cm',
    '24 cm',
    'Small',
    'Medium',
    'Large',
    'Regular',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _sizeController = TextEditingController(text: widget.product?.size ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.unitPrice.toStringAsFixed(0) ?? '',
    );
    _specialPriceController = TextEditingController(
      text: widget.product?.specialPrice.toStringAsFixed(0) ?? '0',
    );
    _costController = TextEditingController(
      text: widget.product?.costPrice?.toStringAsFixed(0) ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQty.toString() ?? '0',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );
    _selectedCategory = widget.product?.category;
    _selectedProductType = widget.product?.productType;
    _selectedUnit = widget.product?.unit ?? 'pcs';

    // Load categories
    Future.microtask(() {
      ref.read(categoryListProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _specialPriceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      child: Container(
        width: isDesktop ? 550 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          hintText: 'Contoh: Nastar Premium',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Jenis & Ukuran Row
                      Row(
                        children: [
                          // Jenis (Product Type)
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedProductType,
                              decoration: const InputDecoration(
                                labelText: 'Jenis',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              hint: const Text('Pilih Jenis'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('-- Pilih Jenis --'),
                                ),
                                ..._productTypes.map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedProductType = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Ukuran (Size)
                          Expanded(
                            child: Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: _sizeController.text,
                              ),
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _sizes;
                                }
                                return _sizes.where(
                                  (size) => size.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    // Sync controller
                                    controller.text = _sizeController.text;
                                    controller.addListener(() {
                                      _sizeController.text = controller.text;
                                    });
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Ukuran',
                                        hintText: '22 cm',
                                        prefixIcon: Icon(Icons.straighten),
                                      ),
                                    );
                                  },
                              onSelected: (selection) {
                                _sizeController.text = selection;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category & Unit Row
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final categoriesState = ref.watch(
                                  categoryListProvider,
                                );
                                return categoriesState.when(
                                  initial: () =>
                                      const LinearProgressIndicator(),
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  success: (categories) {
                                    final categoryNames = categories
                                        .map((c) => c.name)
                                        .toList();
                                    final validValue =
                                        _selectedCategory != null &&
                                            categoryNames.contains(
                                              _selectedCategory,
                                            )
                                        ? _selectedCategory
                                        : null;

                                    return DropdownButtonFormField<String>(
                                      value: validValue,
                                      decoration: const InputDecoration(
                                        labelText: 'Kategori',
                                        prefixIcon: Icon(
                                          Icons.category_outlined,
                                        ),
                                      ),
                                      hint: const Text('Pilih Kategori'),
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text('-- Tanpa Kategori --'),
                                        ),
                                        ...categories.map(
                                          (c) => DropdownMenuItem(
                                            value: c.name,
                                            child: Text(c.name),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(
                                          () => _selectedCategory = value,
                                        );
                                      },
                                    );
                                  },
                                  error: (msg, _) => TextFormField(
                                    initialValue: _selectedCategory,
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori',
                                      hintText: 'Ketik kategori',
                                    ),
                                    onChanged: (v) => _selectedCategory = v,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Satuan (Unit)
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Satuan',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              isExpanded: true,
                              items: _units
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedUnit = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image URL
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Gambar',
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Deskripsi produk (opsional)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Price & Special Price Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Harga Satuan *',
                                helperText: 'Untuk ala carte',
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harga wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _specialPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Harga Spesial',
                                helperText: 'Untuk pelanggan khusus',
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cost & Stock Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costController,
                              decoration: const InputDecoration(
                                labelText: 'Harga Modal',
                                prefixText: 'Rp ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: InputDecoration(
                                labelText: 'Stok Awal',
                                suffixText: _selectedUnit ?? 'pcs',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Simpan' : 'Tambah'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      size: _sizeController.text.trim().isEmpty
          ? null
          : _sizeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      unitPrice: double.parse(_priceController.text),
      specialPrice: _specialPriceController.text.isEmpty
          ? 0
          : double.parse(_specialPriceController.text),
      costPrice: _costController.text.isEmpty
          ? null
          : double.parse(_costController.text),
      stockQty: int.tryParse(_stockController.text) ?? 0,
      category: _selectedCategory,
      unit: _selectedUnit,
      productType: _selectedProductType,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(productFormProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateProduct(product);
    } else {
      success = await notifier.createProduct(product);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Produk berhasil diupdate'
                : 'Produk berhasil ditambahkan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan produk'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
