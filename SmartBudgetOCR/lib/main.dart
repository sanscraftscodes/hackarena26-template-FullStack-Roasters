import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Start connectivity listener after Firebase is initialized
    ServiceLocator.sync.startConnectivityListener();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error initializing Firebase: $e');
    }
    // Continue anyway, some features might still work
  }

  runApp(const SnapBudgetApp());
}

class SnapBudgetApp extends StatelessWidget {
  const SnapBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'SnapBudget',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: AppRouter.create(),
      ),
    );
  }
}
