import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/state_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Indonesian
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase jika sudah dikonfigurasi
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: LFKitchenApp()));
}

class LFKitchenApp extends ConsumerWidget {
  const LFKitchenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LF Kitchen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        // Menampilkan warning banner jika Supabase belum dikonfigurasi
        if (!SupabaseConfig.isConfigured) {
          return Column(
            children: [
              const ConfigWarningBanner(
                message:
                    '⚠️ Supabase belum dikonfigurasi! Buka Settings untuk info.',
              ),
              Expanded(child: child ?? const SizedBox()),
            ],
          );
        }
        return child ?? const SizedBox();
      },
    );
  }
}
