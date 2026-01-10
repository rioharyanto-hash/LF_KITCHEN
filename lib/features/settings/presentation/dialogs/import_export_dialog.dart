import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../products/data/models/product.dart';
import '../../../products/data/providers/product_providers.dart';

/// Import/Export Products Dialog
class ImportExportDialog extends ConsumerStatefulWidget {
  const ImportExportDialog({super.key});

  @override
  ConsumerState<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends ConsumerState<ImportExportDialog> {
  bool _isLoading = false;
  String _status = '';
  List<Product> _importedProducts = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.import_export, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Import / Export Produk',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.upload_file,
                    title: 'Import Excel',
                    subtitle: 'Import produk dari file .xlsx',
                    onTap: _isLoading ? null : _importFromExcel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download,
                    title: 'Export Excel',
                    subtitle: 'Download semua produk',
                    onTap: _isLoading ? null : _exportToExcel,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Template Download
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _downloadTemplate,
              icon: const Icon(Icons.file_download),
              label: const Text('Download Template Excel'),
            ),

            // Status
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _status.contains('Error')
                            ? Icons.error
                            : Icons.check_circle,
                        color: _status.contains('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_status)),
                  ],
                ),
              ),
            ],

            // Preview imported products
            if (_importedProducts.isNotEmpty && !_isLoading) ...[
              const SizedBox(height: 16),
              Text(
                'Preview: ${_importedProducts.length} produk ditemukan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _importedProducts.take(10).length,
                  itemBuilder: (context, index) {
                    final p = _importedProducts[index];
                    return ListTile(
                      dense: true,
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.category ?? "-"} | Rp ${p.unitPrice.toStringAsFixed(0)}',
                      ),
                      trailing: Text(p.productType ?? '-'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _saveImportedProducts,
                icon: const Icon(Icons.save),
                label: Text('Simpan ${_importedProducts.length} Produk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Memilih file...';
        _importedProducts = [];
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _status = '';
        });
        return;
      }

      setState(() => _status = 'Membaca file...');

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      // Try to decode Excel with error handling for format issues
      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (excelError) {
        setState(() {
          _isLoading = false;
          _status =
              'Error: Format Excel tidak didukung.\n\nCoba simpan ulang file sebagai "Excel Workbook (.xlsx)" dari Microsoft Excel atau Google Sheets.';
        });
        return;
      }

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.length < 2) {
        setState(() {
          _isLoading = false;
          _status = 'Error: File kosong atau tidak valid';
        });
        return;
      }

      // Parse header (first row)
      final headers = rows[0]
          .map((cell) => cell?.value?.toString().toLowerCase() ?? '')
          .toList();

      // Find column indices
      final nameIdx = _findColumn(headers, [
        'nama',
        'name',
        'nama_produk',
        'product_name',
      ]);
      final categoryIdx = _findColumn(headers, ['kategori', 'category']);
      final typeIdx = _findColumn(headers, [
        'jenis',
        'type',
        'product_type',
        'jenis_produk',
      ]);
      final sizeIdx = _findColumn(headers, ['ukuran', 'size']);
      final unitIdx = _findColumn(headers, ['satuan', 'unit']);
      final priceIdx = _findColumn(headers, [
        'harga',
        'price',
        'harga_satuan',
        'unit_price',
      ]);
      final specialPriceIdx = _findColumn(headers, [
        'harga_spesial',
        'special_price',
      ]);
      final costIdx = _findColumn(headers, [
        'modal',
        'cost',
        'harga_modal',
        'cost_price',
      ]);
      final stockIdx = _findColumn(headers, ['stok', 'stock', 'stock_qty']);
      final descIdx = _findColumn(headers, [
        'deskripsi',
        'description',
        'desc',
      ]);

      if (nameIdx == -1 || priceIdx == -1) {
        setState(() {
          _isLoading = false;
          _status = 'Error: Kolom "Nama" dan "Harga" wajib ada';
        });
        return;
      }

      setState(() => _status = 'Memproses data...');

      final products = <Product>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final name = _getCellValue(row, nameIdx);
        if (name.isEmpty) continue;

        products.add(
          Product(
            id: '',
            name: name,
            category: _getCellValueOrNull(row, categoryIdx),
            productType: _getCellValueOrNull(row, typeIdx),
            size: _getCellValueOrNull(row, sizeIdx),
            unit: _getCellValueOrNull(row, unitIdx),
            unitPrice: _parseDouble(_getCellValue(row, priceIdx)),
            specialPrice: _parseDouble(_getCellValue(row, specialPriceIdx)),
            costPrice: _parseDoubleOrNull(_getCellValue(row, costIdx)),
            stockQty: int.tryParse(_getCellValue(row, stockIdx)) ?? 0,
            description: _getCellValueOrNull(row, descIdx),
            createdAt: DateTime.now(),
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _importedProducts = products;
        _status = 'Berhasil membaca ${products.length} produk';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }

  int _findColumn(List<String> headers, List<String> possibleNames) {
    for (var i = 0; i < headers.length; i++) {
      if (possibleNames.any((name) => headers[i].contains(name))) {
        return i;
      }
    }
    return -1;
  }

  String _getCellValue(List<Data?> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index]?.value?.toString().trim() ?? '';
  }

  String? _getCellValueOrNull(List<Data?> row, int? index) {
    final val = _getCellValue(row, index);
    return val.isEmpty ? null : val;
  }

  double _parseDouble(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double? _parseDoubleOrNull(String value) {
    if (value.isEmpty) return null;
    return _parseDouble(value);
  }

  Future<void> _saveImportedProducts() async {
    setState(() {
      _isLoading = true;
      _status = 'Menyimpan produk...';
    });

    int success = 0;
    int failed = 0;

    for (final product in _importedProducts) {
      final result = await ref
          .read(productFormProvider.notifier)
          .createProduct(product);
      if (result) {
        success++;
      } else {
        failed++;
      }
    }

    await ref.read(productListProvider.notifier).loadProducts();

    setState(() {
      _isLoading = false;
      _importedProducts = [];
      _status =
          'Berhasil menyimpan $success produk${failed > 0 ? ', gagal: $failed' : ''}';
    });
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Mengambil data produk...';
      });

      await ref.read(productListProvider.notifier).loadProducts();
      final products = ref.read(productListProvider).data ?? [];

      if (products.isEmpty) {
        setState(() {
          _isLoading = false;
          _status = 'Tidak ada produk untuk diexport';
        });
        return;
      }

      setState(() => _status = 'Membuat file Excel...');

      final excel = Excel.createExcel();
      final sheet = excel['Produk'];

      // Headers
      sheet.appendRow([
        TextCellValue('Nama'),
        TextCellValue('Kategori'),
        TextCellValue('Jenis'),
        TextCellValue('Ukuran'),
        TextCellValue('Satuan'),
        TextCellValue('Harga'),
        TextCellValue('Harga Spesial'),
        TextCellValue('Modal'),
        TextCellValue('Stok'),
        TextCellValue('Deskripsi'),
      ]);

      // Data
      for (final p in products) {
        sheet.appendRow([
          TextCellValue(p.name),
          TextCellValue(p.category ?? ''),
          TextCellValue(p.productType ?? ''),
          TextCellValue(p.size ?? ''),
          TextCellValue(p.unit ?? 'pcs'),
          DoubleCellValue(p.unitPrice),
          DoubleCellValue(p.specialPrice),
          DoubleCellValue(p.costPrice ?? 0),
          IntCellValue(p.stockQty),
          TextCellValue(p.description ?? ''),
        ]);
      }

      // Remove default Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'LF_Kitchen_Produk_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
      }

      setState(() {
        _isLoading = false;
        _status = 'File tersimpan: $fileName';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Membuat template...';
      });

      final excel = Excel.createExcel();
      final sheet = excel['Template'];

      // Headers
      sheet.appendRow([
        TextCellValue('Nama'),
        TextCellValue('Kategori'),
        TextCellValue('Jenis'),
        TextCellValue('Ukuran'),
        TextCellValue('Satuan'),
        TextCellValue('Harga'),
        TextCellValue('Harga Spesial'),
        TextCellValue('Modal'),
        TextCellValue('Stok'),
        TextCellValue('Deskripsi'),
      ]);

      // Example row
      sheet.appendRow([
        TextCellValue('Brownies Keju'),
        TextCellValue('Snack Box'),
        TextCellValue('Cake'),
        TextCellValue('22 cm'),
        TextCellValue('pcs'),
        IntCellValue(150000),
        IntCellValue(140000),
        IntCellValue(80000),
        IntCellValue(10),
        TextCellValue('Brownies dengan topping keju'),
      ]);

      // Remove default Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Template_Import_Produk.xlsx';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
      }

      setState(() {
        _isLoading = false;
        _status = 'Template tersimpan di Documents';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
