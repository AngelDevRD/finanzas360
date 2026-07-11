import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/app_updater.dart';
import 'core/storage_mode.dart';
import 'core/supabase_config.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';

bool _updateCheckStarted = false;

void _scheduleUpdateCheck(BuildContext context) {
  if (_updateCheckStarted) return;
  _updateCheckStarted = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      AppUpdater.checkForUpdate(context, slug: 'finanzas360');
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final storageMode = ref.watch(storageModeProvider);
    // El watch de currentUserProvider (toca Supabase.instance) solo ocurre
    // si ya estamos en modo nube -- en modo local nunca se evalua.
    final needsLogin =
        storageMode == StorageMode.cloud &&
        ref.watch(currentUserProvider) == null;

    if (needsLogin) {
      return MaterialApp(
        title: 'Finanzas 360',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        home: const LoginScreen(),
        builder: (context, child) {
          _scheduleUpdateCheck(context);
          return child!;
        },
      );
    }

    return MaterialApp.router(
      title: 'Finanzas 360',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: appRouter,
      builder: (context, child) {
        _scheduleUpdateCheck(context);
        return child!;
      },
    );
  }
}
