import '../../../../core/utils/result.dart';
import '../entities/recipe.dart';

abstract class IRecipeRepository {
  /// Ambil resep untuk satu produk
  Future<Result<ProductRecipe>> getByProductId(String productId);

  /// Update resep untuk satu produk (hapus lama, pasang baru)
  Future<Result<void>> updateRecipe(String productId, List<RecipeItem> items);

  /// Hitung HPP berdasarkan resep dan harga bahan baku terakhir
  Future<Result<double>> calculateHpp(String productId);

  /// Ambil semua resep untuk perhitungan HPP massal (optional)
  Future<Result<List<ProductRecipe>>> getAllRecipes();

  /// Sinkronisasi semua harga pokok (HPP) produk berdasarkan resep
  Future<Result<void>> syncAllProductCosts();
}
