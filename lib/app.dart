import 'package:flutter/material.dart';
import 'package:postboy/features/auth_screen.dart';
import 'package:postboy/features/environment_screen.dart';
import 'package:postboy/features/request/request_detail.dart';
import 'package:postboy/features/request/request_list_screen.dart';
import 'package:postboy/features/upgrade_screen.dart';
import 'package:provider/provider.dart';
import 'core/models/api_request.dart';
import 'features/home/home_screen.dart';
import 'features/request/analytics_screen.dart';
import 'features/request/request_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/themes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Postboy",
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/environments': (context) => const EnvironmentsScreen(),
        '/auth': (context) => const AuthScreen(),
        '/upgrade': (context) => const UpgradeScreen(),
        '/requests': (context) => const AllRequestsScreen(title: "My Requests",),
        '/create-request': (context) => const RequestScreen(),
        '/settings': (context) => const SettingsScreen(),

      },
    );
  }
}
