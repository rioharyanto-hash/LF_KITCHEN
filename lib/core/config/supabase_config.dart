/// Konstanta untuk environment Supabase
class SupabaseConfig {
  static const String supabaseUrl = 'https://srbsiligtgvftjhggatw.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_RNqhJ0iz_WGeuRZFYFfR2A_nzVbJNGd';

  /// Cek apakah config sudah diisi
  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
