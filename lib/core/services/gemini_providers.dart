import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gemini_service.dart';

/// Provider for GeminiService (singleton)
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
