import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/theme/app_theme.dart';
import '../../data/models/order.dart';

/// Dialog untuk print kwitansi/receipt
class ReceiptPrintDialog extends StatefulWidget {
  final Order order;

  const ReceiptPrintDialog({super.key, required this.order});

  @override
  State<ReceiptPrintDialog> createState() => _ReceiptPrintDialogState();

  static Future<void> show(BuildContext context, Order order) {
    return showDialog(
      context: context,
      builder: (context) => ReceiptPrintDialog(order: order),
    );
  }
}

class _ReceiptPrintDialogState extends State<ReceiptPrintDialog> {
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
    _notesController.text = widget.order.notes ?? '';
    _invoiceNumberController.text = _generateInvoiceNumber();
  }

  @override
  void dispose() {
    _shippingController.dispose();
    _notesController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final sequence = now.day.toString().padLeft(4, '0');
    final month = _romanMonth(now.month);
    return '$sequence/$month/${now.year}';
  }

  String _romanMonth(int month) {
    const romans = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];
    return romans[month - 1];
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
        ElevatedButton.icon(
          onPressed: _printReceipt,
          icon: const Icon(Icons.print),
          label: const Text('Cetak'),
        ),
      ],
    );
  }

  Future<void> _printReceipt() async {
    final shipping = double.tryParse(_shippingController.text) ?? 0;

    final pdf = await _generatePdf(shipping);

    await Printing.layoutPdf(
      onLayout: (format) async => pdf,
      name: 'Kwitansi_${_invoiceNumberController.text.replaceAll('/', '-')}',
    );

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

    final signatureImage = await rootBundle.load('assets/images/signature.png');
    final signatureBytes = signatureImage.buffer.asUint8List();

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
                      // Main item (not starting with " -")
                      if (!order.items![i].productName!.startsWith('  -'))
                        pw.TableRow(
                          children: [
                            _tableCell(
                              '${order.items!.where((e) => !e.productName!.startsWith('  -')).toList().indexOf(order.items![i]) + 1}',
                            ),
                            _tableCell(order.items![i].productName ?? '-'),
                            _tableCell(
                              '${order.items![i].quantity}',
                              align: pw.TextAlign.center,
                            ),
                            _tableCell(
                              _formatNumber(order.items![i].unitPrice),
                            ),
                            _tableCell(
                              _formatCurrency(order.items![i].subtotal),
                            ),
                          ],
                        ),
                      // Sub-item (ISI) - starting with "  -"
                      if (order.items![i].productName!.startsWith('  -'))
                        pw.TableRow(
                          children: [
                            _tableCell(
                              i == 1 ? 'ISI' : '-',
                              align: pw.TextAlign.center,
                            ), // Show ISI for first sub-item
                            _tableCell(
                              order.items![i].productName!.substring(2),
                            ), // Remove "  " prefix
                            _tableCell(''), // No qty for sub-items
                            _tableCell(
                              'Rp ${_formatNumber(order.items![i].unitPrice)}',
                            ),
                            _tableCell(''), // No subtotal for sub-items
                          ],
                        ),
                    ],
                ],
              ),
              pw.SizedBox(height: 10),

              // Shipping & Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (shipping > 0)
                        pw.Row(
                          children: [
                            pw.Text('Ongkos Kirim'),
                            pw.SizedBox(width: 40),
                            pw.Text(_formatCurrency(shipping)),
                          ],
                        ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.brown800,
                            width: 2,
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'TOTAL',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Text(': Rp.'),
                            pw.SizedBox(width: 20),
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

              // Notes - moved below Terbilang with box
              if (_notesController.text.isNotEmpty)
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
                          _notesController.text,
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
                  // Signature area
                  pw.Column(
                    children: [
                      pw.Text('Jakarta, ${dateFormat.format(_receiptDate)}'),
                      pw.Text('Yang Menerima'),
                      pw.SizedBox(height: 15),
                      pw.Container(
                        width: 120,
                        height: 60,
                        child: pw.Image(pw.MemoryImage(signatureBytes)),
                      ),
                      pw.SizedBox(height: 8),
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

  String _formatCurrency(double value) {
    return 'Rp ${_formatNumber(value)}';
  }

  String _formatNumber(double value) {
    return NumberFormat('#,###', 'id_ID').format(value);
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
    if (number < 100)
      return '${units[number ~/ 10]} Puluh${number % 10 > 0 ? ' ${units[number % 10]}' : ''}';
    if (number < 200)
      return 'Seratus${number % 100 > 0 ? ' ${_numberToWords(number % 100)}' : ''}';
    if (number < 1000)
      return '${units[number ~/ 100]} Ratus${number % 100 > 0 ? ' ${_numberToWords(number % 100)}' : ''}';
    if (number < 2000)
      return 'Seribu${number % 1000 > 0 ? ' ${_numberToWords(number % 1000)}' : ''}';
    if (number < 1000000)
      return '${_numberToWords(number ~/ 1000)} Ribu${number % 1000 > 0 ? ' ${_numberToWords(number % 1000)}' : ''}';
    if (number < 1000000000)
      return '${_numberToWords(number ~/ 1000000)} Juta${number % 1000000 > 0 ? ' ${_numberToWords(number % 1000000)}' : ''}';

    return number.toString();
  }
}
