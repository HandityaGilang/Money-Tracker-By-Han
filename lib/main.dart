import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/supabase/supabase_manager.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/joint_saving/providers/joint_saving_provider.dart';
import 'features/personal_finance/providers/personal_finance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JointSavingProvider()),
        ChangeNotifierProvider(create: (_) => PersonalFinanceProvider()),
      ],
      child: const OurFinanceApp(),
    ),
  );
}

class OurFinanceApp extends StatelessWidget {
  const OurFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'OurFinance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.white(),
      darkTheme: themeProvider.currentThemeMode == AppThemeMode.white
          ? AppTheme.white()
          : themeProvider.currentThemeMode == AppThemeMode.black
              ? AppTheme.black()
              : AppTheme.navy(),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeProvider.themeModeName,
        orElse: () => ThemeMode.light,
      ),
      home: const AuthGate(),
    );
  }
}
