import 'dart:convert';
 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
 
// Imports relativos (sin el nombre del paquete) para que funcionen
// sin importar cómo se llame tu proyecto.
import '../models/generation_list_response.dart';
import '../providers/poke_api_provider.dart';
import 'generation_detail_screen.dart';
import 'who_is_that_pokemon_screen.dart';
 
// Información "de adorno" de cada generación. La API solo da el nombre
// técnico ("generation-i"), así que la región, los iniciales y los colores
// los definimos nosotros, usando el id de la generación como llave.
class _GenerationInfo {
  final String region;
  final String roman; // numeral romano de la generación
  final int pokemonCount;
  final List<int> starters; // ids de los 3 iniciales (planta, fuego, agua)
  final List<Color> colors; // degradado de la tarjeta
 
  const _GenerationInfo({
    required this.region,
    required this.roman,
    required this.pokemonCount,
    required this.starters,
    required this.colors,
  });
}
 
const Map<int, _GenerationInfo> _generationInfo = {
  1: _GenerationInfo(
    region: 'Kanto',
    roman: 'I',
    pokemonCount: 151,
    starters: [1, 4, 7],
    colors: [Color(0xFFD32F2F), Color(0xFFFF7043)],
  ),
  2: _GenerationInfo(
    region: 'Johto',
    roman: 'II',
    pokemonCount: 100,
    starters: [152, 155, 158],
    colors: [Color(0xFFE08A00), Color(0xFFFFB300)],
  ),
  3: _GenerationInfo(
    region: 'Hoenn',
    roman: 'III',
    pokemonCount: 135,
    starters: [252, 255, 258],
    colors: [Color(0xFF00897B), Color(0xFF26C6DA)],
  ),
  4: _GenerationInfo(
    region: 'Sinnoh',
    roman: 'IV',
    pokemonCount: 107,
    starters: [387, 390, 393],
    colors: [Color(0xFF3949AB), Color(0xFF7E57C2)],
  ),
  5: _GenerationInfo(
    region: 'Teselia',
    roman: 'V',
    pokemonCount: 156,
    starters: [495, 498, 501],
    colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
  ),
  6: _GenerationInfo(
    region: 'Kalos',
    roman: 'VI',
    pokemonCount: 72,
    starters: [650, 653, 656],
    colors: [Color(0xFFEC407A), Color(0xFF5C6BC0)],
  ),
  7: _GenerationInfo(
    region: 'Alola',
    roman: 'VII',
    pokemonCount: 88,
    starters: [722, 725, 728],
    colors: [Color(0xFFF57C00), Color(0xFF26A69A)],
  ),
  8: _GenerationInfo(
    region: 'Galar',
    roman: 'VIII',
    pokemonCount: 96,
    starters: [810, 813, 816],
    colors: [Color(0xFF1565C0), Color(0xFFD81B60)],
  ),
  9: _GenerationInfo(
    region: 'Paldea',
    roman: 'IX',
    pokemonCount: 120,
    starters: [906, 909, 912],
    colors: [Color(0xFFC62828), Color(0xFF7B1FA2)],
  ),
};
 
String _artworkUrl(int id) =>
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
 
// Ahora es StatefulWidget para guardar el Future (así no se vuelve a pedir
// a internet cada vez que la pantalla se redibuja) y poder reintentar
// cuando falla la conexión.
class GenerationListScreen extends StatefulWidget {
  const GenerationListScreen({super.key});
 
  @override
  State<GenerationListScreen> createState() => _GenerationListScreenState();
}
 
class _GenerationListScreenState extends State<GenerationListScreen> {
  late Future<http.Response> _future;
 
  @override
  void initState() {
    super.initState();
    _future = _load();
  }
 
  Future<http.Response> _load() =>
      Provider.of<PokeApiProvider>(context, listen: false).getGenerations();
 
  void _retry() {
    setState(() {
      _future = _load();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: FutureBuilder<http.Response>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: 'No se pudo conectar.\n${snapshot.error}',
              onRetry: _retry,
            );
          }
          if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return _ErrorView(
              message: 'No se encontraron generaciones de Pokémon.',
              onRetry: _retry,
            );
          }
 
          final generations = GenerationListResponse.fromJson(
            json.decode(snapshot.data!.body),
          ).results;
 
          // CustomScrollView permite combinar un encabezado normal con una
          // cuadrícula en un solo scroll (los "slivers").
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final generation = generations[index];
                      return _GenerationCard(
                        index: index,
                        generationId: generation.id,
                        // Si aparece una generación que no conocemos,
                        // _GenerationCard usa un estilo genérico.
                        info: _generationInfo[generation.id],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenerationDetailScreen(
                                generationId: generation.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: generations.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
 
  // Título + banner que abre el juego.
  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;
 
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige una generación',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explora los Pokémon de cada región',
            style: textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          _GameBanner(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WhoIsThatPokemonScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
 
// Tarjeta de una generación: degradado, numeral romano de fondo,
// región, cantidad de Pokémon y los 3 iniciales abajo.
class _GenerationCard extends StatelessWidget {
  final int index;
  final int generationId;
  final _GenerationInfo? info;
  final VoidCallback onTap;
 
  const _GenerationCard({
    required this.index,
    required this.generationId,
    required this.info,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    // Estilo de respaldo para generaciones que no están en el mapa.
    final primary = Theme.of(context).colorScheme.primary;
    final data = info ??
        _GenerationInfo(
          region: 'Generación $generationId',
          roman: '$generationId',
          pokemonCount: 0,
          starters: const [],
          colors: [primary, primary.withValues(alpha: 0.6)],
        );
 
    return _FadeSlideIn(
      index: index,
      child: Material(
        elevation: 6,
        color: data.colors.first,
        shadowColor: data.colors.last.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        // Recorta lo que se salga de la tarjeta (el numeral gigante).
        clipBehavior: Clip.antiAlias,
        // Ink pinta el degradado "debajo" del efecto de toque de InkWell.
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.colors,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Numeral romano enorme y translúcido como marca de agua.
                Positioned(
                  right: -4,
                  top: -14,
                  child: Text(
                    data.roman,
                    style: TextStyle(
                      fontSize: 88,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GENERACIÓN ${data.roman}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.region,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (data.pokemonCount > 0)
                        Text(
                          '${data.pokemonCount} Pokémon',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      const Spacer(),
                      // Los 3 iniciales, repartidos en partes iguales.
                      if (data.starters.isNotEmpty)
                        SizedBox(
                          height: 64,
                          child: Row(
                            children: data.starters
                                .map(
                                  (id) => Expanded(
                                    child: Image.network(
                                      _artworkUrl(id),
                                      fit: BoxFit.contain,
                                      alignment: Alignment.bottomCenter,
                                      errorBuilder:
                                          (context, error, stack) =>
                                              const SizedBox.shrink(),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
// Banner que invita a jugar "¿Quién es ese Pokémon?".
class _GameBanner extends StatelessWidget {
  final VoidCallback onTap;
 
  const _GameBanner({required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: const Color(0xFF1D3B8B),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D3B8B), Color(0xFF3F6FD8)],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_mark_rounded,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Quién es ese Pokémon?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Adivina la silueta en 10 rondas',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
// Hace que su hijo aparezca con un fundido y un pequeño deslizamiento hacia
// arriba. Cada tarjeta tarda un poco más según su posición (index), lo que
// crea el efecto de aparecer una tras otra.
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
 
  const _FadeSlideIn({required this.index, required this.child});
 
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index.clamp(0, 8) * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
 
// Mensaje de error con botón para reintentar.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
 
  const _ErrorView({required this.message, required this.onRetry});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}