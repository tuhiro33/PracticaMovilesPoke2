import 'package:flutter/material.dart';
import 'package:practicasmovilespoke2/providers/poke_api_provider.dart';
import 'package:practicasmovilespoke2/screens/home_screen.dart';

import 'package:provider/provider.dart';

void main() => runApp(const Appstate());

class Appstate extends StatelessWidget {
  const Appstate({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(
      create: (_) => PokeApiProvider(),
      lazy: false, 
      )
    ],
    child: MyApp(),
    );
  }
}

const _KPrimary = Color(0xFF5345AB);
const _KSecondary = Color(0xFFE5D36D);
const _KSurfaceVariant = Color(0xFFB8BDD5);
const _KDark = Color(0xFF1E2240);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Poke Clase',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _KSurfaceVariant,
        colorScheme: const ColorScheme.dark(
          primary: _KPrimary,
          onPrimary: Colors.white,
          secondary: _KSecondary,
          onSecondary: _KDark,
          surface: _KSurfaceVariant,
          onSurface: _KDark
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _KPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.white,
          textColor: _KDark,
          iconColor: _KPrimary
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _KSecondary,
          foregroundColor: _KDark
        )
      ),
      home: const HomeScreen(),
    );
  }
}