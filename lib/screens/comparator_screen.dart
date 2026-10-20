import 'package:flutter/material.dart';
 
import '../models/comparison_side.dart';
import '../models/pokemon_detail_response.dart';
import '../models/region_response.dart';
import '../providers/poke_api_provider.dart';
import '../utils/ability_cache.dart';
import '../utils/name_helpers.dart';
import '../utils/pokemon_type_colors.dart';
import '../utils/type_cache.dart';
import '../utils/type_effectiveness.dart';
import '../widgets/comparison_view.dart';
import 'pokemon_picker_screen.dart';
 
// Comparador: se eligen dos Pokémon y la pantalla los enfrenta en
// estadísticas, datos físicos, ventaja de tipos y habilidades.
class ComparatorScreen extends StatefulWidget {
  const ComparatorScreen({super.key});
 
  @override
  State<ComparatorScreen> createState() => _ComparatorScreenState();
}
 
class _ComparatorScreenState extends State<ComparatorScreen> {
  final PokeApiProvider _api = PokeApiProvider();
 
  // Los dos lados de la comparación (null = todavía sin elegir).
  ComparisonSide? _a;
  ComparisonSide? _b;
 
  // true mientras se descarga el Pokémon recién elegido de ese lado.
  bool _loadingA = false;
  bool _loadingB = false;
 
  bool get _busy => _loadingA || _loadingB;
 
  // Abre el selector para un lado. Si se elige un Pokémon, lo descarga
  // y lo coloca en ese lado.
  Future<void> _pick({required bool isA}) async {
    if (_busy) return;
 
    // El Pokémon del otro lado no se puede elegir: comparar a alguien
    // consigo mismo no tiene sentido.
    final other = isA ? _b : _a;
    final picked = await Navigator.push<NamedResource>(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonPickerScreen(
          excludedIds: other == null ? const {} : {other.pokemon.id},
        ),
      ),
    );
 
    // Si cerró el selector sin elegir, o salió de esta pantalla, no hacemos nada.
    if (picked == null || !mounted) return;
 
    setState(() {
      if (isA) {
        _loadingA = true;
      } else {
        _loadingB = true;
      }
    });
 
    try {
      final side = await _loadSide(picked);
      if (!mounted) return;
      setState(() {
        if (isA) {
          _a = side;
          _loadingA = false;
        } else {
          _b = side;
          _loadingB = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingA = false;
        _loadingB = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar a ${prettifyName(picked.name)}'),
        ),
      );
    }
  }
 
  // Descarga el Pokémon, calcula cuánto daño recibe de cada tipo y busca
  // el nombre en español de sus habilidades.
  Future<ComparisonSide> _loadSide(NamedResource picked) async {
    final response = await _api.getPokemonDetail(picked.id);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    final pokemon = PokemonDetailResponse.fromRawJson(response.body);
 
    // Tipos y habilidades se piden en paralelo; las cachés evitan repetir
    // lo que ya se descargó para otro Pokémon.
    final relations = await Future.wait(pokemon.types.map(TypeCache.get));
    final abilityLabels = await Future.wait(
      pokemon.abilities.map((ability) async {
        String name;
        try {
          name = capitalizeFirst((await AbilityCache.get(ability.name)).name);
        } catch (_) {
          // Si la habilidad falla usamos el nombre técnico arreglado.
          name = prettifyName(ability.name);
        }
        return ability.isHidden ? '$name (oculta)' : name;
      }),
    );
 
    return ComparisonSide(
      pokemon: pokemon,
      effectiveness: calculateTypeEffectiveness(relations),
      abilityLabels: abilityLabels,
    );
  }
 
  // Intercambia los lados: A pasa a B y B pasa a A.
  void _swap() {
    setState(() {
      final temp = _a;
      _a = _b;
      _b = temp;
    });
  }
 
  void _reset() {
    setState(() {
      _a = null;
      _b = null;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;
    final a = _a;
    final b = _b;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar'),
        actions: [
          // El botón de reiniciar solo aparece si hay algo elegido.
          if (a != null || b != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reiniciar',
              onPressed: _busy ? null : _reset,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Compara dos Pokémon',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige uno a cada lado y mira quién gana en estadísticas, tipos y más',
            style: textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // --- Los dos selectores, con el botón de intercambiar en medio ---
          SizedBox(
            height: 196,
            child: Row(
              children: [
                Expanded(
                  child: _Selector(
                    side: a,
                    loading: _loadingA,
                    color: comparisonColorA,
                    onTap: () => _pick(isA: true),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Intercambiar',
                    color: onSurface.withValues(alpha: 0.7),
                    padding: EdgeInsets.zero,
                    onPressed: (a != null || b != null) && !_busy ? _swap : null,
                  ),
                ),
                Expanded(
                  child: _Selector(
                    side: b,
                    loading: _loadingB,
                    color: comparisonColorB,
                    onTap: () => _pick(isA: false),
                  ),
                ),
              ],
            ),
          ),
          // --- La comparación, solo cuando ya hay dos Pokémon ---
          if (a != null && b != null)
            ComparisonView(a: a, b: b)
          else
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'Elige los dos Pokémon para ver la comparación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}
 
// Selector de un lado: muestra el Pokémon elegido (artwork, nombre y tipos),
// o un espacio vacío con "Elegir Pokémon". Al tocarlo se abre el selector.
class _Selector extends StatelessWidget {
  final ComparisonSide? side;
  final bool loading;
  final Color color;
  final VoidCallback onTap;
 
  const _Selector({
    required this.side,
    required this.loading,
    required this.color,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final current = side;
 
    return Material(
      color: current != null ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // El borde lleva el color del lado (azul / naranja).
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : current == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 36, color: color),
                        const SizedBox(height: 6),
                        Text(
                          'Elegir Pokémon',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: current.pokemon.spriteUrl != null
                              ? Image.network(
                                  current.pokemon.spriteUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                    Icons.catching_pokemon,
                                    color: Colors.black38,
                                    size: 48,
                                  ),
                                )
                              : const Icon(
                                  Icons.catching_pokemon,
                                  color: Colors.black38,
                                  size: 48,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prettifyName(current.pokemon.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 3,
                          runSpacing: 3,
                          children: current.pokemon.types
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorForType(t),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    typeNameEs(t),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}