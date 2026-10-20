import 'package:flutter/material.dart';
 
import 'comparator_screen.dart';
import 'generation_list_screen.dart';
import 'item_pocket_list_screen.dart';
import 'region_list_screen.dart';
import 'team_builder_screen.dart';
 
// Pantalla principal: una barra de navegación inferior para moverse entre
// las secciones de la app. Cada sección tiene su propio Scaffold y AppBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene vivas las dos pantallas y solo muestra la
      // elegida. Así, al cambiar de pestaña no se pierde el scroll ni se
      // vuelven a pedir los datos a internet.
      body: IndexedStack(
        index: _index,
        children: const [
          GenerationListScreen(),
          RegionListScreen(),
          ItemPocketListScreen(),
          TeamBuilderScreen(),
          ComparatorScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.catching_pokemon),
            label: 'Pokédex',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Regiones',
          ),
          NavigationDestination(
            icon: Icon(Icons.backpack_outlined),
            selectedIcon: Icon(Icons.backpack),
            label: 'Objetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Equipo',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Comparar',
          ),
        ],
      ),
    );
  }
}
 