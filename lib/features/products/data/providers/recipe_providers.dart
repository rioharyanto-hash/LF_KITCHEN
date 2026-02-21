import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/async_state.dart';
import '../../../../core/utils/result.dart';
import '../repositories/recipe_repository.dart';
import '../../domain/repositories/i_recipe_repository.dart';
import '../../domain/entities/recipe.dart';

/// Provider for Recipe Repository
final recipeRepositoryProvider = Provider<IRecipeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RecipeRepository(client);
});

/// Provider for fetching recipe for a specific product
final recipeProvider =
    StateNotifierProvider.family<
      RecipeNotifier,
      AsyncState<ProductRecipe>,
      String
    >((ref, productId) {
      final repository = ref.watch(recipeRepositoryProvider);
      return RecipeNotifier(repository, productId);
    });

class RecipeNotifier extends StateNotifier<AsyncState<ProductRecipe>> {
  final IRecipeRepository _repository;
  final String _productId;

  RecipeNotifier(this._repository, this._productId)
    : super(const AsyncState.initial()) {
    loadRecipe();
  }

  Future<void> loadRecipe() async {
    state = const AsyncState.loading();
    final result = await _repository.getByProductId(_productId);
    if (result is Success<ProductRecipe>) {
      state = AsyncState.success(result.data);
    } else if (result is Failure<ProductRecipe>) {
      state = AsyncState.error(result.message);
    }
  }

  Future<bool> updateRecipe(List<RecipeItem> items) async {
    final result = await _repository.updateRecipe(_productId, items);
    if (result is Success<void>) {
      await loadRecipe();
      return true;
    }
    return false;
  }
}
