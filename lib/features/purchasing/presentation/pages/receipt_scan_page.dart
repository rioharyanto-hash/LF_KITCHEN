import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gemini_providers.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/purchase.dart';
import '../../data/models/raw_material.dart';
import '../../data/providers/purchase_providers.dart';

/// Receipt Scan Page — Scan struk belanja untuk catat pembelian otomatis
class ReceiptScanPage extends ConsumerStatefulWidget {
  const ReceiptScanPage({super.key});

  @override
  ConsumerState<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

enum _ScanState { capture, analyzing, preview, saving }

class _ReceiptScanPageState extends ConsumerState<ReceiptScanPage> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  _ScanState _state = _ScanState.capture;
  Uint8List? _imageBytes;
  ScannedReceipt? _receipt;
  String? _errorMessage;
  List<RawMaterial> _materials = [];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Load materials for matching
      await ref.read(materialListProvider.notifier).loadMaterials();
      final matState = ref.read(materialListProvider);
      if (matState.isSuccess && matState.data != null) {
        _materials = matState.data!;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _state = _ScanState.analyzing;
        _errorMessage = null;
      });

      await _analyzeReceipt(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil gambar: $e';
        _state = _ScanState.capture;
      });
    }
  }

  Future<void> _analyzeReceipt(Uint8List bytes) async {
    try {
      final gemini = ref.read(geminiServiceProvider);
      final receipt = await gemini.analyzeReceipt(bytes);

      // Auto-match items with existing raw materials
      for (final item in receipt.items) {
        _autoMatchMaterial(item);
      }

      setState(() {
        _receipt = receipt;
        _state = _ScanState.preview;
      });
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Quota exceeded')) {
        errorMsg =
            'Limit penggunaan AI gratis tercapai. Mohon tunggu sekitar 1 menit sebelum mencoba lagi.';
      } else if (errorMsg.contains('billing details')) {
        errorMsg =
            'API Key Gemini Anda memerlukan pengaturan billing atau limit kuota habis.';
      }

      setState(() {
        _errorMessage = errorMsg;
        _state = _ScanState.capture;
      });
    }
  }

  void _autoMatchMaterial(ScannedReceiptItem item) {
    final nameLower = item.name.toLowerCase();
    for (final mat in _materials) {
      final matLower = mat.name.toLowerCase();
      // Simple fuzzy match: check if either contains the other
      if (nameLower.contains(matLower) || matLower.contains(nameLower)) {
        item.matchedMaterialId = mat.id;
        item.matchedMaterialName = mat.name;
        break;
      }
    }
  }

  Future<void> _savePurchase() async {
    if (_receipt == null) return;

    // Filter items that have matched materials
    final matchedItems = _receipt!.items
        .where((i) => i.matchedMaterialId != null)
        .toList();

    if (matchedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada item yang terhubung ke bahan baku. '
            'Silakan hubungkan minimal 1 item.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _state = _ScanState.saving);

    final purchase = Purchase(
      id: '',
      purchaseDate: _receipt!.date ?? DateTime.now(),
      totalCost: matchedItems.fold(0.0, (sum, i) => sum + i.total),
      invoiceNumber:
          'SCAN-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
      notes:
          'Dari scan struk${_receipt!.storeName != null ? ' — ${_receipt!.storeName}' : ''}',
      createdAt: DateTime.now(),
    );

    final purchaseItems = matchedItems
        .map(
          (item) => PurchaseItem(
            id: '',
            purchaseId: '',
            materialId: item.matchedMaterialId!,
            quantity: item.quantity,
            unitCost: item.unitPrice,
            subtotal: item.total,
          ),
        )
        .toList();

    final success = await ref
        .read(purchaseListProvider.notifier)
        .createPurchase(purchase, purchaseItems);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menyimpan ${matchedItems.length} item pembelian!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _state = _ScanState.preview);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan pembelian'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _receipt!.items.removeAt(index);
      _receipt!.totalAmount = _receipt!.items.fold(
        0.0,
        (sum, i) => sum + i.total,
      );
    });
  }

  void _editItem(int index) {
    final item = _receipt!.items[index];
    _showEditDialog(item, index);
  }

  void _showEditDialog(ScannedReceiptItem item, int index) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final unitCtrl = TextEditingController(text: item.unit);
    final priceCtrl = TextEditingController(
      text: item.unitPrice.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Item'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Satuan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Harga Satuan'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text) ?? item.quantity;
              final price = double.tryParse(priceCtrl.text) ?? item.unitPrice;
              setState(() {
                item.name = nameCtrl.text;
                item.quantity = qty;
                item.unit = unitCtrl.text;
                item.unitPrice = price;
                item.total = qty * price;
                _receipt!.totalAmount = _receipt!.items.fold(
                  0.0,
                  (sum, i) => sum + i.total,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMatchDialog(int index) {
    final item = _receipt!.items[index];

    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = _materials
                .where(
                  (m) =>
                      m.name.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return AlertDialog(
              title: const Text('Hubungkan ke Bahan Baku'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari bahan baku...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('Tidak ada bahan baku ditemukan'),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final mat = filtered[i];
                                final isSelected =
                                    item.matchedMaterialId == mat.id;
                                return ListTile(
                                  title: Text(mat.name),
                                  subtitle: Text(mat.unit),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : null,
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      item.matchedMaterialId = mat.id;
                                      item.matchedMaterialName = mat.name;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (item.matchedMaterialId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        item.matchedMaterialId = null;
                        item.matchedMaterialName = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Lepas Hubungan'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Struk Belanja'),
        actions: [
          if (_state == _ScanState.preview) ...[
            TextButton.icon(
              onPressed: () => setState(() {
                _state = _ScanState.capture;
                _receipt = null;
                _imageBytes = null;
              }),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Ulang'),
            ),
          ],
        ],
      ),
      body: switch (_state) {
        _ScanState.capture => _buildCaptureView(),
        _ScanState.analyzing => _buildAnalyzingView(),
        _ScanState.preview => _buildPreviewView(),
        _ScanState.saving => _buildSavingView(),
      },
    );
  }

  Widget _buildCaptureView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Struk Belanja',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Foto atau pilih gambar struk belanja supermarket\n'
              'untuk otomatis mencatat pembelian bahan baku',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionCard(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageBytes != null)
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 24),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
            ),
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Menganalisis struk dengan AI...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    if (_receipt == null) return const SizedBox();

    final matchedCount = _receipt!.items
        .where((i) => i.matchedMaterialId != null)
        .length;

    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_receipt!.storeName != null)
                Text(
                  _receipt!.storeName!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (_receipt!.date != null)
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_receipt!.date!),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildChip(
                    '${_receipt!.items.length} item ditemukan',
                    Icons.list,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    '$matchedCount terhubung',
                    Icons.link,
                    color: matchedCount > 0 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _receipt!.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _buildItemCard(i),
          ),
        ),

        // Bottom bar with total and save
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.grey)),
                      Text(
                        _currencyFormat.format(_receipt!.totalAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: matchedCount > 0 ? _savePurchase : null,
                  icon: const Icon(Icons.save),
                  label: Text('Simpan ($matchedCount item)'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _receipt!.items[index];
    final isMatched = item.matchedMaterialId != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMatched ? Colors.green.shade200 : Colors.grey.shade300,
          width: isMatched ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Match indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isMatched
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMatched ? Icons.link : Icons.link_off,
                    size: 16,
                    color: isMatched ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${item.quantity} ${item.unit} × ${_currencyFormat.format(item.unitPrice)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (isMatched)
                        Text(
                          '→ ${item.matchedMaterialName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Total
                Text(
                  _currencyFormat.format(item.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSmallButton(
                  icon: Icons.link,
                  label: isMatched ? 'Ganti Bahan' : 'Hubungkan',
                  color: isMatched ? Colors.green : AppColors.primary,
                  onTap: () => _showMatchDialog(index),
                ),
                const SizedBox(width: 8),
                _buildSmallButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onTap: () => _editItem(index),
                ),
                const SizedBox(width: 8),
                _buildSmallButton(
                  icon: Icons.delete,
                  label: 'Hapus',
                  color: Colors.red,
                  onTap: () => _removeItem(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, {Color? color}) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }

  Widget _buildSavingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Menyimpan pembelian...'),
        ],
      ),
    );
  }
}
