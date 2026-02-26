import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Entity for a single scanned receipt item
class ScannedReceiptItem {
  String name;
  double quantity;
  String unit;
  double unitPrice;
  double total;
  String? matchedMaterialId;
  String? matchedMaterialName;

  ScannedReceiptItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
    this.matchedMaterialId,
    this.matchedMaterialName,
  });

  factory ScannedReceiptItem.fromJson(Map<String, dynamic> json) {
    return ScannedReceiptItem(
      name: json['name'] as String? ?? 'Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? 'pcs',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Entity for a scanned receipt
class ScannedReceipt {
  String? storeName;
  DateTime? date;
  List<ScannedReceiptItem> items;
  double totalAmount;

  ScannedReceipt({
    this.storeName,
    this.date,
    required this.items,
    required this.totalAmount,
  });

  factory ScannedReceipt.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List<dynamic>?)
            ?.map(
              (item) =>
                  ScannedReceiptItem.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return ScannedReceipt(
      storeName: json['store_name'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      items: items,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Service for interacting with Google Gemini API
class GeminiService {
  GenerativeModel? _model;

  GenerativeModel get model {
    if (_model == null) {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env');
      }
      // Use gemini-1.5-flash as it has more stable free-tier quotas (15 RPM)
      // gemini-2.0-flash can sometimes show 'limit 0' on certain free keys
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
    }
    return _model!;
  }

  /// Analyze a receipt image and extract structured data
  Future<ScannedReceipt> analyzeReceipt(Uint8List imageBytes) async {
    final prompt = TextPart('''
Kamu adalah AI pembaca struk belanja. Analisis foto struk/nota belanja ini dan extract semua item yang dibeli.

INSTRUKSI:
1. Extract nama toko (jika terlihat)
2. Extract tanggal pembelian (format YYYY-MM-DD, jika terlihat)
3. Untuk SETIAP item yang dibeli, extract:
   - name: nama item (bahasa asli dari struk)
   - quantity: jumlah beli (default 1 jika tidak terlihat)
   - unit: satuan (pcs, kg, liter, pack, dll. Default "pcs")
   - unit_price: harga per unit
   - total: total harga item tersebut
4. Extract total keseluruhan

PENTING:
- Abaikan item diskon/potongan terpisah, masukkan ke harga item
- Jika item terpotong/tidak terbaca, skip item tersebut
- Harga dalam Rupiah (angka saja, tanpa Rp, tanpa titik pemisah ribuan)
- Jawab HANYA dengan JSON valid, TANPA markdown, TANPA penjelasan

FORMAT JSON:
{
  "store_name": "Nama Toko",
  "date": "2026-02-21",
  "items": [
    {"name": "Gula Pasir 1kg", "quantity": 1, "unit": "pcs", "unit_price": 15000, "total": 15000},
    {"name": "Telur Ayam", "quantity": 1, "unit": "kg", "unit_price": 28000, "total": 28000}
  ],
  "total_amount": 43000
}
''');

    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      debugPrint('[Gemini] Sending receipt image for analysis...');
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text?.trim() ?? '';
      debugPrint('[Gemini] Raw response: $text');

      // Clean response - remove markdown code fences if present
      String cleanJson = text;
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson
            .replaceFirst(RegExp(r'^```json?\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }

      final json = jsonDecode(cleanJson) as Map<String, dynamic>;
      final receipt = ScannedReceipt.fromJson(json);
      debugPrint(
        '[Gemini] Parsed ${receipt.items.length} items, total: ${receipt.totalAmount}',
      );
      return receipt;
    } catch (e) {
      debugPrint('[Gemini] Error: $e');
      rethrow;
    }
  }
}
