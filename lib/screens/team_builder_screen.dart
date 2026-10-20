import 'package:flutter/material.dart';
 
import '../models/pokemon_detail_response.dart';
import '../models/region_response.dart';
import '../models/team_member.dart';
import '../providers/poke_api_provider.dart';
import '../utils/name_helpers.dart';
import '../utils/pokemon_type_colors.dart';
import '../utils/type_cache.dart';
import '../utils/type_effectiveness.dart';
import '../widgets/team_analysis_view.dart';
import 'pokemon_detail_screen.dart';
import 'pokemon_picker_screen.dart';
 
// Armador de equipos: se eligen hasta 6 Pokémon y la pantalla analiza qué
// tipos castigan al equipo, a cuáles resiste y cuáles son sus estadísticas
// promedio.
class TeamBuilderScreen extends StatefulWidget {
  const TeamBuilderScreen({super.key});
 
  @override
  State<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}
 
class _TeamBuilderScreenState extends State<TeamBuilderScreen> {
  static const int _maxTeam = 6;
 
  final PokeApiProvider _api = PokeApiProvider();
  final List<TeamMember> _team = [];
 
  // true mientras se descarga el Pokémon que se acaba de elegir.
  bool _adding = false;
 
  // Abre el selector y, si se eligió un Pokémon, lo descarga y lo agrega.
  Future<void> _addMember() async {
    if (_adding || _team.length >= _maxTeam) return;
 
    final picked = await Navigator.push<NamedResource>(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonPickerScreen(
          excludedIds: _team.map((m) => m.id).toSet(),
        ),
      ),
    );
 
    // Si cerró el selector sin elegir, o salió de esta pantalla, no hacemos nada.
    if (picked == null || !mounted) return;
 
    setState(() => _adding = true);
    try {
      final member = await _loadMember(picked);
      if (!mounted) return;
      setState(() {
        _team.add(member);
        _adding = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo agregar a ${prettifyName(picked.name)}'),
        ),
      );
    }
  }
 
  // Pide el Pokémon y las relaciones de daño de sus tipos, y calcula cuánto
  // daño recibe de cada tipo.
  Future<TeamMember> _loadMember(NamedResource picked) async {
    final response = await _api.getPokemonDetail(picked.id);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    final pokemon = PokemonDetailResponse.fromRawJson(response.body);
 
    // Los tipos se piden en paralelo, y TypeCache evita repetir los que
    // ya se descargaron para otro integrante.
    final relations = await Future.wait(pokemon.types.map(TypeCache.get));
 
    return TeamMember(
      id: pokemon.id,
      name: pokemon.name,
      spriteUrl: pokemon.spriteUrl,
      types: pokemon.types,
      stats: pokemon.stats,
      effectiveness: calculateTypeEffectiveness(relations),
    );
  }
 
  void _removeMember(int index) {
    setState(() {
      _team.removeAt(index);
    });
  }
 
  Future<void> _clearTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Vaciar el equipo?'),
        content: const Text('Se quitarán todos los Pokémon de tu equipo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _team.clear();
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi equipo'),
        actions: [
          // El botón de vaciar solo aparece si hay algo que vaciar.
          if (_team.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Vaciar equipo',
              onPressed: _clearTeam,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Arma tu equipo',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige hasta $_maxTeam Pokémon y descubre los puntos débiles y fuertes de tu equipo',
            style: textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_team.length}/$_maxTeam Pokémon',
            style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
          ),
          const SizedBox(height: 8),
          // Cuadrícula de 6 espacios. shrinkWrap y NeverScrollable hacen que
          // use solo el alto que necesita y deje que scrollee la lista de
          // afuera (no se pueden anidar dos scrolls verticales).
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: List.generate(_maxTeam, _buildSlot),
          ),
          if (_team.isNotEmpty) TeamAnalysisView(team: _team),
        ],
      ),
    );
  }
 
  // Un espacio del equipo: lleno, cargando o vacío según su posición.
  Widget _buildSlot(int index) {
    if (index < _team.length) {
      final member = _team[index];
      return _FilledSlot(
        member: member,
        onRemove: () => _removeMember(index),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(
                pokemonId: member.id,
                pokemonName: member.name,
              ),
            ),
          );
        },
      );
    }
    // El primer espacio libre muestra el círculo de carga mientras se
    // descarga el Pokémon recién elegido.
    if (_adding && index == _team.length) return const _LoadingSlot();
    return _EmptySlot(onTap: _addMember);
  }
}
 
// Espacio ocupado: artwork, nombre, tipos y una "x" para quitarlo.
class _FilledSlot extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onRemove;
  final VoidCallback onTap;
 
  const _FilledSlot({
    required this.member,
    required this.onRemove,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: member.spriteUrl != null
                          ? Image.network(
                              member.spriteUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) =>
                                  const Icon(
                                Icons.catching_pokemon,
                                color: Colors.black38,
                                size: 40,
                              ),
                            )
                          : const Icon(
                              Icons.catching_pokemon,
                              color: Colors.black38,
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prettifyName(member.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 3,
                    runSpacing: 3,
                    children: member.types
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
            // Botón para quitar al Pokémon del equipo.
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// Espacio vacío con borde: al tocarlo se abre el selector.
class _EmptySlot extends StatelessWidget {
  final VoidCallback onTap;
 
  const _EmptySlot({required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
 
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: onSurface.withValues(alpha: 0.35),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 34,
              color: onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// Espacio que muestra un círculo de carga mientras se descarga un Pokémon.
class _LoadingSlot extends StatelessWidget {
  const _LoadingSlot();
 
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
 
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: onSurface.withValues(alpha: 0.35),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}
