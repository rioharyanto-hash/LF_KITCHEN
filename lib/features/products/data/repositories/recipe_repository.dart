import 'package:flutter/foundation.dart';

import '../../../../core/data/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/i_recipe_repository.dart';

class RecipeRepository extends BaseRepository implements IRecipeRepository {
  RecipeRepository(super.client);

  static const String _tableName = 'product_recipes';

  @override
  Future<Result<ProductRecipe>> getByProductId(String productId) async {
    return safeCall(() async {
      debugPrint('[RecipeRepo] getByProductId: $productId');
      final response = await client
          .from(_tableName)
          .select(
            '*, products(recipe_yield), raw_materials(name, unit, last_purchase_price, base_unit, unit_conversion)',
          )
          .eq('product_id', productId);

      debugPrint(
        '[RecipeRepo] Raw response: ${(response as List).length} rows',
      );

      int recipeYield = 1;
      final items = (response).map((json) {
        final material = json['raw_materials'] as Map<String, dynamic>?;
        final product = json['products'] as Map<String, dynamic>?;
        if (product != null) {
          recipeYield = product['recipe_yield'] as int? ?? 1;
        }

        return RecipeItem(
          id: json['id'] as String,
          productId: json['product_id'] as String,
          rawMaterialId: json['raw_material_id'] as String,
          rawMaterialName: material != null
              ? material['name'] as String?
              : null,
          quantity: (json['quantity'] as num).toDouble(),
          unit: json['unit'] as String,
          unitCost: material != null
              ? (material['last_purchase_price'] as num?)?.toDouble()
              : null,
          unitConversion: material != null
              ? (json['unit'] == material['unit']
                    ? 1.0
                    : (material['unit_conversion'] as num?)?.toDouble() ?? 1.0)
              : 1.0,
        );
      }).toList();

      debugPrint(
        '[RecipeRepo] Parsed ${items.length} items for product $productId',
      );

      return ProductRecipe(
        productId: productId,
        items: items,
        recipeYield: recipeYield,
      );
    });
  }

  @override
  Future<Result<void>> updateRecipe(
    String productId,
    List<RecipeItem> items,
  ) async {
    return safeCall(() async {
      debugPrint(
        '[RecipeRepo] updateRecipe: productId=$productId, items=${items.length}',
      );

      // Delete existing
      await client.from(_tableName).delete().eq('product_id', productId);
      debugPrint('[RecipeRepo] Deleted existing items for $productId');

      if (items.isNotEmpty) {
        final itemsJson = items
            .map(
              (item) => {
                'product_id': productId,
                'raw_material_id': item.rawMaterialId,
                'quantity': item.quantity,
                'unit': item.unit,
              },
            )
            .toList();

        debugPrint(
          '[RecipeRepo] Inserting ${itemsJson.length} items: $itemsJson',
        );
        await client.from(_tableName).insert(itemsJson);
        debugPrint('[RecipeRepo] Insert completed successfully');
      } else {
        debugPrint('[RecipeRepo] No items to insert (list was empty)');
      }
    });
  }

  @override
  Future<Result<double>> calculateHpp(String productId) async {
    final recipeResult = await getByProductId(productId);
    if (recipeResult is Failure<ProductRecipe>) {
      return Failure(recipeResult.message);
    }
    return Success((recipeResult as Success<ProductRecipe>).data.totalHpp);
  }

  @override
  Future<Result<List<ProductRecipe>>> getAllRecipes() async {
    return safeCall(() async {
      final response = await client
          .from(_tableName)
          .select(
            '*, products(recipe_yield), raw_materials(name, unit, last_purchase_price, base_unit, unit_conversion)',
          );

      final Map<String, _GroupedRecipe> grouped = {};

      for (final json in (response as List)) {
        final pid = json['product_id'] as String;
        final material = json['raw_materials'] as Map<String, dynamic>?;
        final recipeYield =
            (json['products'] as Map<String, dynamic>?)?['recipe_yield']
                as int? ??
            1;

        final item = RecipeItem(
          id: json['id'] as String,
          productId: pid,
          rawMaterialId: json['raw_material_id'] as String,
          rawMaterialName: material != null
              ? material['name'] as String?
              : null,
          quantity: (json['quantity'] as num).toDouble(),
          unit: json['unit'] as String,
          unitCost: material != null
              ? (material['last_purchase_price'] as num?)?.toDouble()
              : null,
          unitConversion: material != null
              ? (json['unit'] == material['unit']
                    ? 1.0
                    : (material['unit_conversion'] as num?)?.toDouble() ?? 1.0)
              : 1.0,
        );

        if (!grouped.containsKey(pid)) {
          grouped[pid] = _GroupedRecipe(recipeYield: recipeYield, items: []);
        }
        grouped[pid]!.items.add(item);
      }

      return grouped.entries.map((e) {
        return ProductRecipe(
          productId: e.key,
          items: e.value.items,
          recipeYield: e.value.recipeYield,
        );
      }).toList();
    });
  }

  @override
  Future<Result<void>> syncAllProductCosts() async {
    return safeCall(() async {
      final recipesResult = await getAllRecipes();
      if (recipesResult is Failure<List<ProductRecipe>>) {
        throw Exception(recipesResult.message);
      }

      final recipes = (recipesResult as Success<List<ProductRecipe>>).data;

      for (final recipe in recipes) {
        final hpp = recipe.totalHpp;
        await client
            .from('products')
            .update({'cost_price': hpp})
            .eq('id', recipe.productId);
      }
    });
  }
}

class _GroupedRecipe {
  final int recipeYield;
  final List<RecipeItem> items;
  _GroupedRecipe({required this.recipeYield, required this.items});
}
