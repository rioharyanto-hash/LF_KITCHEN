import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';

import '../../../../core/services/invoice_number_service.dart';
import '../../data/models/order.dart';
import '../../data/providers/order_providers.dart';

/// Dialog untuk print kwitansi/receipt
class ReceiptPrintDialog extends ConsumerStatefulWidget {
  final Order order;

  const ReceiptPrintDialog({super.key, required this.order});

  @override
  ConsumerState<ReceiptPrintDialog> createState() => _ReceiptPrintDialogState();

  static Future<void> show(BuildContext context, Order order) {
    return showDialog(
      context: context,
      builder: (context) => ReceiptPrintDialog(order: order),
    );
  }
}

class _ReceiptPrintDialogState extends ConsumerState<ReceiptPrintDialog> {
  final _shippingController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  // Editable fields
  late DateTime _receiptDate;
  String _bankName = 'BCA';
  String _accountName = 'Lusi Febrianti';
  String _accountNumber = '0650199537';

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _receiptDate = DateTime.now();

    // Use saved shipping cost from order (or fallback to notes for legacy)
    if (widget.order.shippingCost > 0) {
      _shippingController.text = widget.order.shippingCost.toStringAsFixed(0);
    } else {
      // Fallback: parse shipping from notes (format: SHIPPING:25000)
      final existingShipping = _parseShippingFromNotes(widget.order.notes);
      _shippingController.text = existingShipping.toStringAsFixed(0);
    }

    // Remove shipping info from displayed notes
    final cleanNotes = (widget.order.notes ?? '')
        .replaceAll(RegExp(r'SHIPPING:\d+'), '')
        .trim();
    _notesController.text = cleanNotes;

    // Load invoice number async
    _loadInvoiceNumber();
  }

  Future<void> _loadInvoiceNumber() async {
    // Use stored receipt_number if already generated (persisted on confirmation)
    if (widget.order.receiptNumber != null &&
        widget.order.receiptNumber!.isNotEmpty) {
      if (mounted) {
        setState(
          () => _invoiceNumberController.text = widget.order.receiptNumber!,
        );
      }
      return;
    }

    // Fallback for legacy orders: preview next number (without incrementing)
    final invoiceType = _getInvoiceType();
    final number = await InvoiceNumberService.previewNextNumber(invoiceType);
    if (mounted) {
      setState(() => _invoiceNumberController.text = number);
    }
  }

  /// Determine invoice type based on order
  String _getInvoiceType() {
    // Check if it's a POS/Direct order (type = direct)
    if (widget.order.orderType == OrderType.direct) {
      return InvoiceNumberService.kasir;
    }

    // Check if it's Paketan (notes contain === ===)
    if (_isPaketanOrder(widget.order.notes)) {
      return InvoiceNumberService.paketan;
    }

    // Check if it's Snack Box (check item names and notes)
    final hasSnackBoxInNotes =
        widget.order.notes?.toUpperCase().contains('SNACK BOX') == true ||
        widget.order.notes?.toUpperCase().contains('SNACKBOX') == true;
    final hasSnackBoxInItems =
        widget.order.items?.any(
          (item) =>
              item.productName?.toUpperCase().contains('SNACK BOX') == true ||
              item.productName?.toUpperCase().contains('SNACKBOX') == true,
        ) ??
        false;

    if (hasSnackBoxInNotes || hasSnackBoxInItems) {
      return InvoiceNumberService.snackBox;
    }

    // Default to PO
    return InvoiceNumberService.po;
  }

  double _parseShippingFromNotes(String? notes) {
    if (notes == null) return 0;
    final match = RegExp(r'SHIPPING:(\d+)').firstMatch(notes);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  /// Parse isi paket dari notes (format: Isi:\n  - item1\n  - item2)
  List<String> _parsePackageContents(String? notes) {
    if (notes == null) return [];
    final contents = <String>[];
    final match = RegExp(
      r'Isi:\n([\s\S]*?)(?:\n\nCatatan:|$)',
    ).firstMatch(notes);
    if (match != null) {
      final itemsText = match.group(1) ?? '';
      for (final line in itemsText.split('\n')) {
        if (line.trim().startsWith('-')) {
          contents.add(line.trim().substring(1).trim());
        }
      }
    }
    return contents;
  }

  /// Get catatan tambahan dari notes (Catatan: xxx)
  String _getExtraNotesFromNotes(String? notes) {
    if (notes == null) return '';
    final match = RegExp(
      r'Catatan:\s*(.+)$',
      multiLine: true,
    ).firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  /// Check if order is paketan (notes contain "=== PAKET")
  bool _isPaketanOrder(String? notes) {
    return notes != null && notes.contains('=== ') && notes.contains(' ===');
  }

  @override
  void dispose() {
    _shippingController.dispose();
    _notesController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cetak Kwitansi'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Info
              Text(
                'Pesanan: ${widget.order.customerName ?? "Guest"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Total: ${_currencyFormat.format(widget.order.totalAmount)}',
              ),
              const Divider(height: 24),

              // Receipt Date
              Row(
                children: [
                  const Text('Tanggal Kwitansi:'),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _receiptDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _receiptDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(_receiptDate),
                    ),
                  ),
                ],
              ),

              // Invoice Number
              TextField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kwitansi',
                  hintText: '0001/I/2026',
                ),
              ),
              const SizedBox(height: 12),

              // Shipping
              TextField(
                controller: _shippingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ongkos Kirim',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Snack Box (3 pcs): ...',
                ),
              ),
              const SizedBox(height: 16),

              // Payment Info Section
              const Text(
                'Info Pembayaran:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Bank',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: _bankName),
                      onChanged: (v) => _bankName = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: _accountName),
                      onChanged: (v) => _accountName = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'No. Rekening',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: _accountNumber),
                      onChanged: (v) => _accountNumber = v,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        OutlinedButton.icon(
          onPressed: _savePdfToFile,
          icon: const Icon(Icons.save),
          label: const Text('Simpan PDF'),
        ),
        ElevatedButton.icon(
          onPressed: _printReceipt,
          icon: const Icon(Icons.print),
          label: const Text('Cetak'),
        ),
      ],
    );
  }

  Future<void> _savePdfToFile() async {
    final shipping = double.tryParse(_shippingController.text) ?? 0;

    // Save shipping cost to order
    if (shipping != widget.order.shippingCost) {
      await ref
          .read(orderRepositoryProvider)
          .updateShipping(widget.order.id, shipping);
      // Refresh order list
      ref.invalidate(orderListProvider);
    }

    // Increment invoice number when actually saving
    final invoiceType = _getInvoiceType();
    final finalNumber = await InvoiceNumberService.getNextNumber(invoiceType);
    _invoiceNumberController.text = finalNumber;

    final pdf = await _generatePdf(shipping);

    // Generate descriptive filename
    final customerName =
        widget.order.customerName?.replaceAll(RegExp(r'[^\w\s]'), '') ??
        'Guest';
    final invoiceNum = _invoiceNumberController.text.replaceAll('/', '-');
    final fileName = 'Kwitansi_${customerName}_$invoiceNum.pdf';

    if (kIsWeb) {
      // For web: use sharePdf which triggers download
      await Printing.sharePdf(bytes: pdf, filename: fileName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF diunduh: $fileName')));
        Navigator.of(context).pop();
      }
    } else {
      // For desktop: let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Kwitansi PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(pdf);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF disimpan: $fileName')));
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _printReceipt() async {
    final shipping = double.tryParse(_shippingController.text) ?? 0;

    // Save shipping cost to order
    if (shipping != widget.order.shippingCost) {
      await ref
          .read(orderRepositoryProvider)
          .updateShipping(widget.order.id, shipping);
      // Refresh order list
      ref.invalidate(orderListProvider);
    }

    // Increment invoice number when actually printing
    final invoiceType = _getInvoiceType();
    final finalNumber = await InvoiceNumberService.getNextNumber(invoiceType);
    _invoiceNumberController.text = finalNumber;

    final pdf = await _generatePdf(shipping);

    // Generate descriptive filename
    final customerName =
        widget.order.customerName?.replaceAll(RegExp(r'[^\w\s]'), '') ??
        'Guest';
    final invoiceNum = _invoiceNumberController.text.replaceAll('/', '-');
    final fileName = 'Kwitansi_${customerName}_$invoiceNum';

    await Printing.layoutPdf(onLayout: (format) async => pdf, name: fileName);

    // Auto close dialog after printing
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<Uint8List> _generatePdf(double shipping) async {
    final pdf = pw.Document();
    final order = widget.order;
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    final grandTotal = order.totalAmount + shipping;

    // Load images
    final logoImage = await rootBundle.load(
      'assets/images/logo_lf_kitchen.png',
    );
    final logoBytes = logoImage.buffer.asUint8List();

    final qrCodeImage = await rootBundle.load('assets/images/qr_code.png');
    final qrCodeBytes = qrCodeImage.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(pw.MemoryImage(logoBytes)),
                  ),
                  pw.SizedBox(width: 40),
                  // Title
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'KWITANSI',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.brown800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Company Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LF Kitchen',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Jl. Nanas No.10'),
                      pw.Text('RT.007/RW.010'),
                      pw.Text('Utan Kayu Utara'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Customer & Order Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Sudah terima dari', ''),
                        _buildInfoRow('Nama', order.customerName ?? '-'),
                        // Alamat with expanded width for long addresses
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(width: 100, child: pw.Text('Alamat')),
                              pw.Text(': '),
                              pw.Expanded(
                                child: pw.Text(
                                  order.customerAddress ?? '-',
                                  style: const pw.TextStyle(
                                    color: PdfColors.brown800,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildInfoRow(
                          'Tgl Pengiriman',
                          order.deliveryDate != null
                              ? dateFormat.format(order.deliveryDate!)
                              : '-',
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Tanggal', dateFormat.format(_receiptDate)),
                      _buildInfoRow('Nomor', _invoiceNumberController.text),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder(
                  // Only top and bottom lines for the whole table
                  top: pw.BorderSide(color: PdfColors.brown800),
                  bottom: pw.BorderSide(color: PdfColors.brown800),
                  // Vertical lines only for header (will be added per row)
                  horizontalInside: pw.BorderSide.none,
                  verticalInside: pw.BorderSide.none,
                  left: pw.BorderSide.none,
                  right: pw.BorderSide.none,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FixedColumnWidth(90),
                  4: const pw.FixedColumnWidth(100),
                },
                children: [
                  // Header with border
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.brown100,
                      border: pw.Border.all(color: PdfColors.brown800),
                    ),
                    children: [
                      _tableHeader('NO.'),
                      _tableHeader('KETERANGAN'),
                      _tableHeader('Jumlah'),
                      _tableHeader('Harga'),
                      _tableHeader('JUMLAH'),
                    ],
                  ),
                  // Items
                  if (order.items != null)
                    for (var i = 0; i < order.items!.length; i++) ...[
                      // Main item row
                      if (!order.items![i].productName!.startsWith('  -'))
                        pw.TableRow(
                          children: [
                            _tableCell(
                              '${order.items!.where((e) => !e.productName!.startsWith('  -')).toList().indexOf(order.items![i]) + 1}',
                            ),
                            // For paketan: show name + contents below
                            _isPaketanOrder(order.notes) &&
                                    order.items![i].productId == null
                                ? _tableCellWithContents(
                                    _sanitizeText(
                                      order.items![i].productName ?? '-',
                                    ),
                                    _parsePackageContents(order.notes),
                                  )
                                : _tableCell(
                                    _sanitizeText(
                                      order.items![i].productName ?? '-',
                                    ),
                                  ),
                            _tableCell(
                              '${order.items![i].quantity}',
                              align: pw.TextAlign.center,
                            ),
                            _tableCell(
                              _formatNumber(order.items![i].unitPrice),
                              align: pw.TextAlign.right,
                            ),
                            _tableCurrencyCell(order.items![i].subtotal),
                          ],
                        ),
                      // Sub-item (ISI) - starting with "  -" for snackbox
                      if (order.items![i].productName!.startsWith('  -'))
                        pw.TableRow(
                          children: [
                            _tableCell(
                              i == 1 ? 'ISI' : '',
                              align: pw.TextAlign.center,
                            ),
                            _tableCell(
                              order.items![i].productName!.substring(4),
                            ),
                            _tableCell(''),
                            _tableCell(
                              'Rp ${_formatNumber(order.items![i].unitPrice)}',
                            ),
                            _tableCell(''),
                          ],
                        ),
                    ],
                ],
              ),
              pw.SizedBox(height: 10),

              // Shipping & Total - using same table structure for alignment
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FixedColumnWidth(90),
                  4: const pw.FixedColumnWidth(100),
                },
                children: [
                  if (shipping > 0)
                    pw.TableRow(
                      children: [
                        pw.SizedBox(),
                        pw.SizedBox(),
                        pw.SizedBox(),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Ongkos Kirim',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        _tableCurrencyCell(shipping),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 5),
              // TOTAL box aligned to the right
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.brown800,
                        width: 2,
                      ),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(' : '),
                        pw.Container(
                          width: 100,
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'Rp.',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                _formatNumber(grandTotal),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Terbilang
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.brown800),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Terbilang',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(':'),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        '# ${_numberToWords(grandTotal.toInt())} Rupiah #',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes - show only extra notes for paketan, full notes for others
              if (_getDisplayNotes().isNotEmpty)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.brown800),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Catatan: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          _getDisplayNotes(),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Payment Info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Payment Info',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Bank     : $_bankName'),
                        pw.Text('Name    : $_accountName'),
                        pw.Text('Acct      : $_accountNumber'),
                      ],
                    ),
                  ),
                  // QR Code area
                  pw.Column(
                    children: [
                      pw.Text('Jakarta, ${dateFormat.format(_receiptDate)}'),
                      pw.SizedBox(height: 5),
                      pw.Text('Yang Menerima,'),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        width: 100,
                        height: 100,
                        child: pw.Image(pw.MemoryImage(qrCodeBytes)),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '( Lusi Febrianti )',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  String _formatNumber(double value) {
    return NumberFormat('#,###', 'id_ID').format(value);
  }

  /// Replace special Unicode hyphens/dashes with standard ASCII hyphen
  String _sanitizeText(String text) {
    return text
        .replaceAll('\u2010', '-') // hyphen
        .replaceAll('\u2011', '-') // non-breaking hyphen
        .replaceAll('\u2012', '-') // figure dash
        .replaceAll('\u2013', '-') // en-dash
        .replaceAll('\u2014', '-') // em-dash
        .replaceAll('\u2015', '-') // horizontal bar
        .replaceAll('\u2212', '-') // minus sign
        .replaceAll('\u00AD', '-'); // soft hyphen
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label)),
          pw.Text(': '),
          pw.Text(value, style: const pw.TextStyle(color: PdfColors.brown800)),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, textAlign: align),
    );
  }

  pw.Widget _tableCurrencyCell(double value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Row(
        children: [pw.Text('Rp'), pw.Spacer(), pw.Text(_formatNumber(value))],
      ),
    );
  }

  /// Table cell with package contents listed below
  pw.Widget _tableCellWithContents(String title, List<String> contents) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title),
          if (contents.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Isi:',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
            ),
            for (final item in contents)
              pw.Text('  - $item', style: const pw.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    );
  }

  /// Get notes to display - for paketan shows extra notes only
  String _getDisplayNotes() {
    if (_isPaketanOrder(widget.order.notes)) {
      return _getExtraNotesFromNotes(_notesController.text);
    }
    return _notesController.text;
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Nol';

    const units = [
      '',
      'Satu',
      'Dua',
      'Tiga',
      'Empat',
      'Lima',
      'Enam',
      'Tujuh',
      'Delapan',
      'Sembilan',
      'Sepuluh',
      'Sebelas',
    ];

    if (number < 12) return units[number];
    if (number < 20) return '${units[number - 10]} Belas';
    if (number < 100) {
      return '${units[number ~/ 10]} Puluh${number % 10 > 0 ? ' ${units[number % 10]}' : ''}';
    }
    if (number < 200) {
      return 'Seratus${number % 100 > 0 ? ' ${_numberToWords(number % 100)}' : ''}';
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} Ratus${number % 100 > 0 ? ' ${_numberToWords(number % 100)}' : ''}';
    }
    if (number < 2000) {
      return 'Seribu${number % 1000 > 0 ? ' ${_numberToWords(number % 1000)}' : ''}';
    }
    if (number < 1000000) {
      return '${_numberToWords(number ~/ 1000)} Ribu${number % 1000 > 0 ? ' ${_numberToWords(number % 1000)}' : ''}';
    }
    if (number < 1000000000) {
      return '${_numberToWords(number ~/ 1000000)} Juta${number % 1000000 > 0 ? ' ${_numberToWords(number % 1000000)}' : ''}';
    }

    return number.toString();
  }
}
