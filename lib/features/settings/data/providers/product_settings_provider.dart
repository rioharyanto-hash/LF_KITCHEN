import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product Settings Provider - mengelola Jenis, Ukuran, dan Satuan produk
class ProductSettingsNotifier extends StateNotifier<ProductSettings> {
  ProductSettingsNotifier() : super(ProductSettings.defaults()) {
    _loadSettings();
  }

  static const String _keyProductTypes = 'product_types';
  static const String _keySizes = 'product_sizes';
  static const String _keyUnits = 'product_units';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final types = prefs.getStringList(_keyProductTypes);
    final sizes = prefs.getStringList(_keySizes);
    final units = prefs.getStringList(_keyUnits);

    state = ProductSettings(
      productTypes: types ?? ProductSettings.defaultProductTypes,
      sizes: sizes ?? ProductSettings.defaultSizes,
      units: units ?? ProductSettings.defaultUnits,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyProductTypes, state.productTypes);
    await prefs.setStringList(_keySizes, state.sizes);
    await prefs.setStringList(_keyUnits, state.units);
  }

  // Product Types
  Future<void> addProductType(String type) async {
    if (!state.productTypes.contains(type)) {
      state = state.copyWith(productTypes: [...state.productTypes, type]);
      await _saveSettings();
    }
  }

  Future<void> removeProductType(String type) async {
    state = state.copyWith(
      productTypes: state.productTypes.where((t) => t != type).toList(),
    );
    await _saveSettings();
  }

  Future<void> updateProductType(String oldType, String newType) async {
    final types = state.productTypes
        .map((t) => t == oldType ? newType : t)
        .toList();
    state = state.copyWith(productTypes: types);
    await _saveSettings();
  }

  // Sizes
  Future<void> addSize(String size) async {
    if (!state.sizes.contains(size)) {
      state = state.copyWith(sizes: [...state.sizes, size]);
      await _saveSettings();
    }
  }

  Future<void> removeSize(String size) async {
    state = state.copyWith(sizes: state.sizes.where((s) => s != size).toList());
    await _saveSettings();
  }

  Future<void> updateSize(String oldSize, String newSize) async {
    final sizes = state.sizes.map((s) => s == oldSize ? newSize : s).toList();
    state = state.copyWith(sizes: sizes);
    await _saveSettings();
  }

  // Units
  Future<void> addUnit(String unit) async {
    if (!state.units.contains(unit)) {
      state = state.copyWith(units: [...state.units, unit]);
      await _saveSettings();
    }
  }

  Future<void> removeUnit(String unit) async {
    state = state.copyWith(units: state.units.where((u) => u != unit).toList());
    await _saveSettings();
  }

  Future<void> updateUnit(String oldUnit, String newUnit) async {
    final units = state.units.map((u) => u == oldUnit ? newUnit : u).toList();
    state = state.copyWith(units: units);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = ProductSettings.defaults();
    await _saveSettings();
  }
}

/// Product Settings State
class ProductSettings {
  final List<String> productTypes;
  final List<String> sizes;
  final List<String> units;

  const ProductSettings({
    required this.productTypes,
    required this.sizes,
    required this.units,
  });

  static const List<String> defaultProductTypes = [
    'Cake',
    'Pastry',
    'Bread',
    'Cookies',
    'Snack',
    'Minuman',
    'Lainnya',
  ];

  static const List<String> defaultSizes = [
    '16 cm',
    '18 cm',
    '20 cm',
    '22 cm',
    '24 cm',
    'Small',
    'Medium',
    'Large',
    'Regular',
  ];

  static const List<String> defaultUnits = [
    'pcs',
    'box',
    'slice',
    'loyang',
    'pack',
    'botol',
    'cup',
  ];

  factory ProductSettings.defaults() => const ProductSettings(
    productTypes: defaultProductTypes,
    sizes: defaultSizes,
    units: defaultUnits,
  );

  ProductSettings copyWith({
    List<String>? productTypes,
    List<String>? sizes,
    List<String>? units,
  }) {
    return ProductSettings(
      productTypes: productTypes ?? this.productTypes,
      sizes: sizes ?? this.sizes,
      units: units ?? this.units,
    );
  }
}

/// Provider
final productSettingsProvider =
    StateNotifierProvider<ProductSettingsNotifier, ProductSettings>((ref) {
      return ProductSettingsNotifier();
    });
