import 'package:flutter/material.dart';
 
import '../models/region_response.dart';
import '../utils/name_helpers.dart';
import '../utils/pokemon_names_cache.dart';
import '../utils/region_info.dart';
import '../widgets/future_view.dart';
 
// Selector de Pokémon: una cuadrícula con buscador. Al tocar uno, la
// pantalla se cierra y devuelve ese Pokémon (NamedResource) a quien la abrió.
class PokemonPickerScreen extends StatefulWidget {
  // Ids que ya están en el equipo: se ven apagados y no se pueden elegir
  // otra vez (en un equipo no se repite el mismo Pokémon).
  final Set<int> excludedIds;
 
  const PokemonPickerScreen({super.key, this.excludedIds = const {}});
 
  @override
  State<PokemonPickerScreen> createState() => _PokemonPickerScreenState();
}
 
class _PokemonPickerScreenState extends State<PokemonPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<NamedResource>> _future;
  String _query = '';
 
  @override
  void initState() {
    super.initState();
    _future = PokemonNamesCache.get();
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige un Pokémon')),
      body: FutureView<List<NamedResource>>(
        future: _future,
        onRetry: () => setState(() {
          _future = PokemonNamesCache.get();
        }),
        builder: (context, all) {
          // Filtramos por nombre o por número de la Pokédex.
          final q = _query.trim().toLowerCase();
          final pokemon = q.isEmpty
              ? all
              : all
                  .where((p) =>
                      prettifyName(p.name).toLowerCase().contains(q) ||
                      p.id.toString() == q)
                  .toList();
 
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  // Colores explícitos para que se lea bien con cualquier tema.
                  style: const TextStyle(color: Colors.black87),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o número',
                    hintStyle: const TextStyle(color: Colors.black45),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: pokemon.isEmpty
                    ? InfoMessage(
                        icon: Icons.search_off,
                        text: 'Ningún Pokémon coincide con "$_query".',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: pokemon.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final p = pokemon[index];
                          final taken = widget.excludedIds.contains(p.id);
                          return _PickerTile(
                            pokemon: p,
                            taken: taken,
                            // Si ya está en el equipo, no hace nada al tocar.
                            onTap: taken
                                ? null
                                : () => Navigator.pop(context, p),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
 
// Casilla de un Pokémon: número, artwork y nombre. Mismos colores que las
// tarjetas de la pantalla de generaciones, para respetar tu tema.
class _PickerTile extends StatelessWidget {
  final NamedResource pokemon;
  final bool taken;
  final VoidCallback? onTap;
 
  const _PickerTile({
    required this.pokemon,
    required this.taken,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Opacity(
      opacity: taken ? 0.35 : 1,
      child: Material(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text(
                  taken
                      ? 'En el equipo'
                      : '#${pokemon.id.toString().padLeft(3, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Image.network(
                    pokemonArtworkUrl(pokemon.id),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.catching_pokemon,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
                Text(
                  prettifyName(pokemon.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
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