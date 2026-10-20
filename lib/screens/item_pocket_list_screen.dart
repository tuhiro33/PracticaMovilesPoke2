import 'package:flutter/material.dart';
 
import '../models/item_response.dart';
import '../providers/poke_api_provider.dart';
import '../utils/item_info.dart';
import '../widgets/future_view.dart';
import 'item_pocket_screen.dart';
 
// Entrada a la sección de objetos: los bolsillos de la mochila
// (Medicinas, Poké Balls, Bayas, MT y MO...). Al tocar uno se abre la
// lista de sus categorías y objetos.
class ItemPocketListScreen extends StatefulWidget {
  const ItemPocketListScreen({super.key});
 
  @override
  State<ItemPocketListScreen> createState() => _ItemPocketListScreenState();
}
 
class _ItemPocketListScreenState extends State<ItemPocketListScreen> {
  final PokeApiProvider _api = PokeApiProvider();
  late Future<NamedResourceList> _future;
 
  @override
  void initState() {
    super.initState();
    _future = _load();
  }
 
  Future<NamedResourceList> _load() async {
    final response = await _api.getItemPockets();
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return NamedResourceList.fromRawJson(response.body);
  }
 
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;
 
    return Scaffold(
      appBar: AppBar(title: const Text('Objetos')),
      body: FutureView<NamedResourceList>(
        future: _future,
        onRetry: () => setState(() {
          _future = _load();
        }),
        builder: (context, data) {
          final pockets = data.results;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu mochila',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige un bolsillo para ver sus objetos',
                        style: textTheme.bodyMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pocket = pockets[index];
                      final info = pocketInfoFor(pocket.name, primary);
                      return _PocketCard(
                        info: info,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemPocketScreen(
                                pocketId: pocket.id,
                                pocketName: pocket.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: pockets.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
 
// Tarjeta de un bolsillo: degradado, ícono grande translúcido de fondo,
// y el nombre abajo a la izquierda.
class _PocketCard extends StatelessWidget {
  final PocketInfo info;
  final VoidCallback onTap;
 
  const _PocketCard({required this.info, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      color: info.colors.first,
      shadowColor: info.colors.last.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: info.colors,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ícono enorme y translúcido como marca de agua.
              Positioned(
                right: -14,
                top: -14,
                child: Icon(
                  info.icon,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(info.icon, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      info.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}