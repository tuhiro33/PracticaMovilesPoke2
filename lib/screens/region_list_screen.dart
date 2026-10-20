import 'package:flutter/material.dart';
 
import '../models/region_response.dart';
import '../providers/poke_api_provider.dart';
import '../utils/region_info.dart';
import '../widgets/future_view.dart';
import 'region_detail_screen.dart';
 
// Lista de regiones del mundo Pokémon (Kanto, Johto, Hoenn...).
// Al tocar una se abre la lista de sus ubicaciones.
class RegionListScreen extends StatefulWidget {
  const RegionListScreen({super.key});
 
  @override
  State<RegionListScreen> createState() => _RegionListScreenState();
}
 
class _RegionListScreenState extends State<RegionListScreen> {
  final PokeApiProvider _api = PokeApiProvider();
  late Future<RegionListResponse> _future;
 
  @override
  void initState() {
    super.initState();
    _future = _load();
  }
 
  Future<RegionListResponse> _load() async {
    final response = await _api.getRegions();
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return RegionListResponse.fromRawJson(response.body);
  }
 
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;
 
    return Scaffold(
      appBar: AppBar(title: const Text('Regiones')),
      body: FutureView<RegionListResponse>(
        future: _future,
        onRetry: () => setState(() {
          _future = _load();
        }),
        builder: (context, data) {
          final regions = data.results;
          // El elemento 0 es el encabezado; las regiones empiezan en el 1.
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: regions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explora el mundo Pokémon',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige una región para ver sus rutas, ciudades y qué Pokémon aparecen en cada lugar',
                        style: textTheme.bodyMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }
 
              final region = regions[index - 1];
              final info = regionInfoFor(region.name, primary);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RegionCard(
                  info: info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegionDetailScreen(
                          regionId: region.id,
                          regionName: region.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
 
// Tarjeta ancha de una región: degradado, nombre a la izquierda
// y los tres iniciales a la derecha.
class _RegionCard extends StatelessWidget {
  final RegionInfo info;
  final VoidCallback onTap;
 
  const _RegionCard({required this.info, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Material(
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.subtitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Text(
                              'Ver ubicaciones',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.white, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...info.starters.map(
                    (id) => SizedBox(
                      width: 60,
                      child: Image.network(
                        pokemonArtworkUrl(id),
                        height: 84,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 