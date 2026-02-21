import '../../../../core/data/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../models/supplier.dart';
import '../models/raw_material.dart';
import '../models/purchase.dart';

/// Repository untuk operasi CRUD Purchasing
class PurchaseRepository extends BaseRepository {
  PurchaseRepository(super.client);

  static const String _purchasesTable = 'material_purchases';
  static const String _purchaseItemsTable = 'purchase_items';
  static const String _suppliersTable = 'suppliers';
  static const String _materialsTable = 'raw_materials';

  // ==================== SUPPLIERS ====================

  /// Get all suppliers
  Future<Result<List<Supplier>>> getAllSuppliers() async {
    return safeCall(() async {
      final response = await client
          .from(_suppliersTable)
          .select()
          .order('name', ascending: true);

      return (response as List).map((json) => Supplier.fromJson(json)).toList();
    });
  }

  /// Get supplier by ID
  Future<Result<Supplier>> getSupplierById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_suppliersTable)
          .select()
          .eq('id', id)
          .single();

      return Supplier.fromJson(response);
    });
  }

  /// Create supplier
  Future<Result<Supplier>> createSupplier(Supplier supplier) async {
    return safeCall(() async {
      final response = await client
          .from(_suppliersTable)
          .insert(supplier.toInsertJson())
          .select()
          .single();

      return Supplier.fromJson(response);
    });
  }

  /// Update supplier
  Future<Result<Supplier>> updateSupplier(Supplier supplier) async {
    return safeCall(() async {
      final response = await client
          .from(_suppliersTable)
          .update(supplier.toInsertJson())
          .eq('id', supplier.id)
          .select()
          .single();

      return Supplier.fromJson(response);
    });
  }

  /// Delete supplier
  Future<Result<void>> deleteSupplier(String id) async {
    return safeCall(() async {
      await client.from(_suppliersTable).delete().eq('id', id);
    });
  }

  // ==================== RAW MATERIALS ====================

  /// Get all raw materials
  Future<Result<List<RawMaterial>>> getAllMaterials() async {
    return safeCall(() async {
      final response = await client
          .from(_materialsTable)
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => RawMaterial.fromJson(json))
          .toList();
    });
  }

  /// Get materials with low stock
  Future<Result<List<RawMaterial>>> getLowStockMaterials() async {
    return safeCall(() async {
      final response = await client
          .from(_materialsTable)
          .select()
          .order('stock_qty', ascending: true);

      final materials = (response as List)
          .map((json) => RawMaterial.fromJson(json))
          .where((m) => m.isLowStock)
          .toList();

      return materials;
    });
  }

  /// Get material by ID
  Future<Result<RawMaterial>> getMaterialById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_materialsTable)
          .select()
          .eq('id', id)
          .single();

      return RawMaterial.fromJson(response);
    });
  }

  /// Create material
  Future<Result<RawMaterial>> createMaterial(RawMaterial material) async {
    return safeCall(() async {
      final response = await client
          .from(_materialsTable)
          .insert(material.toInsertJson())
          .select()
          .single();

      return RawMaterial.fromJson(response);
    });
  }

  /// Update material
  Future<Result<RawMaterial>> updateMaterial(RawMaterial material) async {
    return safeCall(() async {
      final response = await client
          .from(_materialsTable)
          .update(material.toInsertJson())
          .eq('id', material.id)
          .select()
          .single();

      return RawMaterial.fromJson(response);
    });
  }

  /// Update material stock
  Future<Result<void>> updateMaterialStock(
    String id,
    double newStockQty,
    double? lastPurchasePrice,
  ) async {
    return safeCall(() async {
      final updates = <String, dynamic>{'stock_qty': newStockQty};
      if (lastPurchasePrice != null) {
        updates['last_purchase_price'] = lastPurchasePrice;
      }
      await client.from(_materialsTable).update(updates).eq('id', id);
    });
  }

  /// Delete material
  Future<Result<void>> deleteMaterial(String id) async {
    return safeCall(() async {
      await client.from(_materialsTable).delete().eq('id', id);
    });
  }

  /// Get price history for a specific material
  Future<Result<List<Map<String, dynamic>>>> getMaterialPriceHistory(
    String materialId, {
    int limit = 5,
  }) async {
    return safeCall(() async {
      final response = await client
          .from(_purchaseItemsTable)
          .select('unit_cost, material_purchases(purchase_date)')
          .eq('material_id', materialId)
          .order('material_purchases(purchase_date)', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    });
  }

  // ==================== PURCHASES ====================

  /// Get all purchases with supplier info
  Future<Result<List<Purchase>>> getAllPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    String? supplierId,
  }) async {
    return safeCall(() async {
      var query = client
          .from(_purchasesTable)
          .select(
            '*, suppliers(name), purchase_items(*, raw_materials(name, unit))',
          );

      if (supplierId != null) {
        query = query.eq('supplier_id', supplierId);
      }
      if (fromDate != null) {
        query = query.gte('purchase_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('purchase_date', toDate.toIso8601String());
      }

      final response = await query.order('purchase_date', ascending: false);

      return (response as List).map((json) => Purchase.fromJson(json)).toList();
    });
  }

  /// Get purchase by ID with items
  Future<Result<Purchase>> getPurchaseById(String id) async {
    return safeCall(() async {
      final response = await client
          .from(_purchasesTable)
          .select(
            '*, suppliers(name), purchase_items(*, raw_materials(name, unit))',
          )
          .eq('id', id)
          .single();

      return Purchase.fromJson(response);
    });
  }

  /// Create purchase with items
  Future<Result<Purchase>> createPurchase(
    Purchase purchase,
    List<PurchaseItem> items,
  ) async {
    return safeCall(() async {
      // Insert purchase header
      final purchaseResponse = await client
          .from(_purchasesTable)
          .insert(purchase.toInsertJson())
          .select()
          .single();

      final purchaseId = purchaseResponse['id'];

      // Insert purchase items
      if (items.isNotEmpty) {
        final itemsJson = items.map((item) {
          final json = item.toInsertJson();
          json['purchase_id'] = purchaseId;
          return json;
        }).toList();

        await client.from(_purchaseItemsTable).insert(itemsJson);

        // Update material stocks
        for (final item in items) {
          final materialResult = await getMaterialById(item.materialId);
          if (materialResult.isSuccess) {
            final material = materialResult.dataOrNull!;
            await updateMaterialStock(
              item.materialId,
              material.stockQty + item.quantity,
              item.unitCost,
            );
          }
        }
      }

      // Fetch complete purchase with relations
      return await getPurchaseById(purchaseId).then((r) => r.dataOrNull!);
    });
  }

  /// Delete purchase (will also rollback stock)
  Future<Result<void>> deletePurchase(String id) async {
    return safeCall(() async {
      // First get the purchase items to rollback stock
      final purchaseResult = await getPurchaseById(id);
      if (purchaseResult.isSuccess &&
          purchaseResult.dataOrNull?.items != null) {
        for (final item in purchaseResult.dataOrNull!.items!) {
          final materialResult = await getMaterialById(item.materialId);
          if (materialResult.isSuccess) {
            final material = materialResult.dataOrNull!;
            await updateMaterialStock(
              item.materialId,
              (material.stockQty - item.quantity).clamp(0, double.infinity),
              null,
            );
          }
        }
      }

      // Delete purchase (cascade will delete items)
      await client.from(_purchasesTable).delete().eq('id', id);
    });
  }

  /// Get total purchases for a date range
  Future<Result<double>> getTotalPurchases({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return safeCall(() async {
      var query = client.from(_purchasesTable).select('total_cost');

      if (fromDate != null) {
        query = query.gte('purchase_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('purchase_date', toDate.toIso8601String());
      }

      final response = await query;
      double total = 0;
      for (final row in response as List) {
        total += (row['total_cost'] as num).toDouble();
      }
      return total;
    });
  }
}
