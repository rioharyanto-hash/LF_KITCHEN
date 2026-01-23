import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../categories/data/providers/category_providers.dart';
import '../../../settings/data/providers/product_settings_provider.dart';
import '../../data/models/product.dart';
import '../../data/providers/product_providers.dart';

/// Product Form Dialog for Create/Edit - Premium Design
class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _specialPriceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  String? _selectedProductType;
  String? _selectedUnit;
  String? _selectedSize;
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  // Image handling
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _selectedSize = widget.product!.size;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.unitPrice.toStringAsFixed(0);
      _specialPriceController.text = widget.product!.specialPrice
          .toStringAsFixed(0);
      _costController.text =
          widget.product!.costPrice?.toStringAsFixed(0) ?? '';
      _stockController.text = widget.product!.stockQty.toString();
      _imageUrl = widget.product!.imageUrl;
      _selectedCategory = widget.product!.category;
      _selectedProductType = widget.product!.productType;
      _selectedUnit = widget.product!.unit ?? 'pcs';
    } else {
      _selectedUnit = 'pcs';
      _stockController.text = '0';
    }

    Future.microtask(() {
      ref.read(categoryListProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _specialPriceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isDesktop ? 800 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
              ),
            ),
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.add_box_outlined,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Image Upload
            SizedBox(width: 280, child: _buildImageSection()),
            const SizedBox(width: 32),
            // Right: Form Fields
            Expanded(child: _buildFormFields()),
          ],
        ),
        const SizedBox(height: 24),
        // Price Row
        _buildPriceRow(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildImageSection(),
        const SizedBox(height: 24),
        _buildFormFields(),
        const SizedBox(height: 24),
        _buildPriceRow(),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GAMBAR PRODUK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        // Upload Area
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _imageUrl != null || _selectedImageBytes != null
                ? _buildImagePreview()
                : _buildUploadPlaceholder(),
          ),
        ),
        // Selected File Info
        if (_selectedFileName != null || _imageUrl != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image),
                          ),
                        )
                      : const Icon(Icons.image),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ?? 'product-image.jpg',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isUploadingImage)
                        const LinearProgressIndicator()
                      else
                        Text(
                          _selectedImageBytes != null
                              ? 'Siap upload'
                              : 'Tersimpan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () {
                    setState(() {
                      _selectedImageBytes = null;
                      _selectedFileName = null;
                      _imageUrl = null;
                    });
                  },
                  tooltip: 'Hapus gambar',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_selectedImageBytes != null)
            Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
          else if (_imageUrl != null)
            Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildUploadPlaceholder(),
            ),
          // Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Text(
                'Klik untuk ganti gambar',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Seret dan lepas gambar di sini',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Format: JPG, PNG, atau WEBP.\nMaksimal 2MB.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'atau klik untuk memilih file',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Nama Produk
        _buildFloatingLabelField(
          label: 'Nama Produk *',
          child: TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama produk wajib diisi';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        // Kategori
        _buildFloatingLabelField(
          label: 'Kategori',
          child: Consumer(
            builder: (context, ref, child) {
              final categoryState = ref.watch(categoryListProvider);
              return categoryState.when(
                initial: () => _buildCategoryDropdown([]),
                loading: () => _buildCategoryDropdown([]),
                success: (categories) => _buildCategoryDropdown(
                  categories.map((c) => c.name).toList(),
                ),
                error: (message, code) => _buildCategoryDropdown([]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Jenis (Product Type)
        _buildFloatingLabelField(
          label: 'Jenis',
          child: Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(productSettingsProvider);
              // Remove duplicates using toSet()
              final uniqueTypes = settings.productTypes.toSet().toList();
              // Validate selected value exists in list
              final validValue =
                  _selectedProductType != null &&
                      uniqueTypes.contains(_selectedProductType)
                  ? _selectedProductType
                  : null;
              return DropdownButtonFormField<String>(
                initialValue: validValue,
                decoration: _inputDecoration(prefixIcon: Icons.style_outlined),
                isExpanded: true,
                hint: const Text('Pilih jenis produk'),
                items: uniqueTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedProductType = value),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Satuan & Ukuran Row
        Row(
          children: [
            Expanded(
              child: _buildFloatingLabelField(
                label: 'Satuan',
                child: Consumer(
                  builder: (context, ref, child) {
                    final settings = ref.watch(productSettingsProvider);
                    // Remove duplicates
                    final uniqueUnits = settings.units.toSet().toList();
                    // Validate selected value exists
                    final validUnit =
                        _selectedUnit != null &&
                            uniqueUnits.contains(_selectedUnit)
                        ? _selectedUnit
                        : (uniqueUnits.isNotEmpty ? uniqueUnits.first : null);
                    return DropdownButtonFormField<String>(
                      initialValue: validUnit,
                      decoration: _inputDecoration(
                        prefixIcon: Icons.straighten,
                      ),
                      isExpanded: true,
                      items: uniqueUnits
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedUnit = value),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFloatingLabelField(
                label: 'Ukuran',
                child: Consumer(
                  builder: (context, ref, child) {
                    final settings = ref.watch(productSettingsProvider);
                    // Remove duplicates
                    final uniqueSizes = settings.sizes.toSet().toList();
                    // Validate selected value exists
                    final validSize =
                        _selectedSize != null &&
                            uniqueSizes.contains(_selectedSize)
                        ? _selectedSize
                        : null;
                    return DropdownButtonFormField<String>(
                      initialValue: validSize,
                      decoration: _inputDecoration(
                        prefixIcon: Icons.aspect_ratio,
                      ),
                      isExpanded: true,
                      hint: const Text('Pilih ukuran'),
                      items: uniqueSizes
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSize = value),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Deskripsi
        _buildFloatingLabelField(
          label: 'Deskripsi',
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: _inputDecoration(hintText: 'Deskripsi produk...'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    // Remove duplicates
    final uniqueCategories = categories.toSet().toList();
    // Validate selected value exists in list
    final validCategory =
        _selectedCategory != null &&
            uniqueCategories.contains(_selectedCategory)
        ? _selectedCategory
        : null;
    return DropdownButtonFormField<String>(
      initialValue: validCategory,
      decoration: _inputDecoration(prefixIcon: Icons.category_outlined),
      isExpanded: true,
      hint: const Text('Pilih kategori'),
      items: uniqueCategories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildPriceRow() {
    // Use Column with two rows for better mobile visibility
    return Column(
      children: [
        // First row: Harga Satuan + Harga Spesial
        Row(
          children: [
            Expanded(
              child: _buildPriceField(
                label: 'HARGA SATUAN *',
                controller: _priceController,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPriceField(
                label: 'HARGA SPESIAL',
                controller: _specialPriceController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Harga Modal + Stok
        Row(
          children: [
            Expanded(
              child: _buildPriceField(
                label: 'HARGA MODAL',
                controller: _costController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStockField()),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STOK AWAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _selectedUnit ?? 'pcs',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingLabelField({
    required String label,
    required Widget child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: 12,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: Theme.of(context).colorScheme.surface,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({IconData? prefixIcon, String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey.shade400, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveProduct,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(
              _isLoading
                  ? 'Menyimpan...'
                  : (_isEditing ? 'Simpan Perubahan' : 'Simpan'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for Web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (max 2MB)
        if (file.size > 2 * 1024 * 1024) {
          if (mounted) {
            CustomToast.showError(
              context: context,
              title: 'File Terlalu Besar',
              subtitle: 'Ukuran file maksimal 2MB.',
            );
          }
          return;
        }

        // Get bytes
        Uint8List? bytes = file.bytes;

        // If bytes is null (sometimes on Desktop without withData, but we set it true),
        // try reading from path if not web
        if (bytes == null && file.path != null && !kIsWeb) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _selectedImageBytes = bytes;
            _selectedFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          context: context,
          title: 'Gagal Memilih Gambar',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null) return _imageUrl;

    setState(() => _isUploadingImage = true);

    try {
      final supabase = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = _selectedFileName!.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      ); // Sanitize
      final fileName = 'products/${timestamp}_$cleanFileName';

      // Upload using bytes with explicit content type based on extension
      final ext = _selectedFileName?.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      await supabase.storage
          .from('images')
          .uploadBinary(
            fileName,
            _selectedImageBytes!,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);
      setState(() => _isUploadingImage = false);
      return publicUrl;
    } catch (e) {
      setState(() => _isUploadingImage = false);

      String errorMessage = 'Gagal upload gambar.';
      if (e.toString().contains('Bucket not found') ||
          e.toString().contains('404')) {
        errorMessage =
            "Bucket 'images' tidak ditemukan. Silakan buat bucket 'images' (Public) di Supabase Dashboard.";
      } else {
        errorMessage = 'Error: $e';
      }

      if (mounted) {
        CustomToast.showError(
          context: context,
          title: 'Gagal Upload Gambar',
          subtitle: errorMessage,
        );
      }
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Upload image if new file selected
    String? finalImageUrl = _imageUrl;
    if (_selectedImageBytes != null) {
      final uploadedUrl = await _uploadImage();
      if (uploadedUrl == null) {
        // Upload failed - abort save
        setState(() => _isLoading = false);
        return;
      }
      finalImageUrl = uploadedUrl;
    }

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      size: _selectedSize,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      unitPrice: double.parse(
        _priceController.text.isEmpty ? '0' : _priceController.text,
      ),
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
      imageUrl: finalImageUrl,
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
      // Use CustomToast instead of SnackBar
      CustomToast.showSuccess(
        context: context,
        title: _isEditing
            ? 'Produk Berhasil Diperbarui'
            : 'Produk Berhasil Ditambahkan',
        subtitle: 'Perubahan telah disimpan ke sistem.',
      );
    } else if (mounted) {
      CustomToast.showError(
        context: context,
        title: 'Gagal Menyimpan Produk',
        subtitle: 'Silakan coba lagi atau hubungi admin.',
      );
    }
  }
}
