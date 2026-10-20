import 'package:flutter/material.dart';
 
import '../models/location_response.dart';
import '../providers/poke_api_provider.dart';
import '../utils/encounter_labels.dart';
import '../utils/name_helpers.dart';
import '../utils/region_info.dart';
import '../widgets/future_view.dart';
import 'pokemon_detail_screen.dart';
 
// Detalle de una ubicación (ej. "Ruta 1"): arriba se eligen sus áreas y
// abajo se ven los Pokémon que aparecen en el área elegida, con nivel,
// método de encuentro, probabilidad y juegos.
class LocationDetailScreen extends StatefulWidget {
  final int locationId;
  final String locationName; // nombre técnico, ej. "canalave-city"
  final RegionInfo region; // para pintar la pantalla con los colores de la región
 
  const LocationDetailScreen({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.region,
  });
 
  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}
 
class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final PokeApiProvider _api = PokeApiProvider();
  late Future<LocationResponse> _locationFuture;
 
  // Guardamos el Future de cada área ya pedida: si el usuario va y viene
  // entre áreas, no se vuelve a descargar lo mismo.
  final Map<int, Future<LocationAreaResponse>> _areaCache = {};
  int? _selectedAreaId;
 
  @override
  void initState() {
    super.initState();
    _locationFuture = _loadLocation();
  }
 
  Future<LocationResponse> _loadLocation() async {
    final response = await _api.getLocationDetail(widget.locationId);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return LocationResponse.fromRawJson(response.body);
  }
 
  Future<LocationAreaResponse> _loadArea(int id) async {
    final response = await _api.getLocationArea(id);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return LocationAreaResponse.fromRawJson(response.body);
  }
 
  // putIfAbsent: si ya hay un Future para ese id lo reutiliza,
  // si no, lo crea y lo guarda.
  Future<LocationAreaResponse> _areaFuture(int id) =>
      _areaCache.putIfAbsent(id, () => _loadArea(id));
 
  // Nombre corto del área para mostrarlo en los chips. Los nombres de la
  // API repiten el de la ubicación ("route-1-area"), así que se lo quitamos.
  String _areaLabel(String areaName) {
    final base = widget.locationName;
    if (areaName == '$base-area') return 'Área principal';
    if (areaName.startsWith('$base-')) {
      final rest = areaName.substring(base.length + 1);
      return rest == 'main' ? 'Principal' : prettifyName(rest);
    }
    return prettifyName(areaName);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(prettifyName(widget.locationName))),
      body: FutureView<LocationResponse>(
        future: _locationFuture,
        onRetry: () => setState(() {
          _locationFuture = _loadLocation();
        }),
        builder: (context, location) {
          if (location.areas.isEmpty) {
            return const InfoMessage(
              icon: Icons.explore_off,
              text: 'Esta ubicación no tiene áreas con encuentros registrados.',
            );
          }
 
          // Si todavía no se eligió un área, usamos la primera.
          final selectedId = _selectedAreaId ?? location.areas.first.id;
 
          return Column(
            children: [
              _buildHeader(location),
              if (location.areas.length > 1) _buildAreaChips(location, selectedId),
              Expanded(
                child: FutureView<LocationAreaResponse>(
                  // La key hace que Flutter trate cada área como una vista
                  // nueva al cambiar de chip.
                  key: ValueKey(selectedId),
                  future: _areaFuture(selectedId),
                  onRetry: () => setState(() {
                    _areaCache.remove(selectedId);
                  }),
                  builder: (context, area) => _EncounterList(
                    area: area,
                    color: widget.region.colors.first,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
 
  Widget _buildHeader(LocationResponse location) {
    final areas = location.areas.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.region.colors,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${widget.region.name} · $areas ${areas == 1 ? 'área' : 'áreas'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  // Fila deslizable de chips, uno por área.
  Widget _buildAreaChips(LocationResponse location, int selectedId) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: location.areas.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final area = location.areas[index];
          final selected = area.id == selectedId;
          return Center(
            child: ChoiceChip(
              label: Text(
                _areaLabel(area.name),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              showCheckmark: false,
              selectedColor: widget.region.colors.first,
              backgroundColor: Colors.white,
              onSelected: (_) => setState(() => _selectedAreaId = area.id),
            ),
          );
        },
      ),
    );
  }
}
 
// Lista de Pokémon que aparecen en un área.
class _EncounterList extends StatelessWidget {
  final LocationAreaResponse area;
  final Color color;
 
  const _EncounterList({required this.area, required this.color});
 
  @override
  Widget build(BuildContext context) {
    if (area.encounters.isEmpty) {
      return const InfoMessage(
        icon: Icons.search_off,
        text:
            'No hay Pokémon registrados en esta área.\nLa API tiene pocos datos de encuentros para los juegos más recientes.',
      );
    }
 
    final onSurface = Theme.of(context).colorScheme.onSurface;
 
    // El elemento 0 es el contador; los Pokémon empiezan en el 1.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: area.encounters.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${area.encounters.length} Pokémon en esta área',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _EncounterTile(
            encounter: area.encounters[index - 1],
            color: color,
          ),
        );
      },
    );
  }
}
 
class _EncounterTile extends StatelessWidget {
  final AreaEncounter encounter;
  final Color color;
 
  const _EncounterTile({required this.encounter, required this.color});
 
  // "Nv. 5" o "Nv. 5–8" (vacío si la API no trae niveles).
  String get _levelText {
    if (encounter.maxLevel == 0) return '';
    return encounter.minLevel == encounter.maxLevel
        ? 'Nv. ${encounter.minLevel}'
        : 'Nv. ${encounter.minLevel}–${encounter.maxLevel}';
  }
 
  // "Nv. 5–8 · hasta 40%"
  String get _infoText {
    final parts = <String>[
      if (_levelText.isNotEmpty) _levelText,
      if (encounter.chance > 0) 'hasta ${encounter.chance}%',
    ];
    return parts.join(' · ');
  }
 
  // Los primeros 4 juegos y, si hay más, un "+N".
  String get _versionsText {
    final shown = encounter.versions.take(4).map(versionNameEs).join(', ');
    final extra = encounter.versions.length - 4;
    return extra > 0 ? '$shown +$extra' : shown;
  }
 
  @override
  Widget build(BuildContext context) {
    // La pantalla de detalle solo funciona con Pokémon "normales" (ids
    // hasta 1025). Las formas especiales tienen ids más altos y no
    // existen como especie, así que esas filas no se pueden abrir.
    final canOpen = encounter.pokemonId > 0 && encounter.pokemonId <= 1025;
 
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Image.network(
            pokemonArtworkUrl(encounter.pokemonId),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const Icon(Icons.catching_pokemon),
          ),
        ),
        title: Text(
          prettifyName(encounter.pokemonName),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_infoText.isNotEmpty) Text(_infoText),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: encounter.methods
                  .map((m) => _Tag(text: methodNameEs(m), color: color))
                  .toList(),
            ),
            if (encounter.versions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_versionsText, style: const TextStyle(fontSize: 11)),
            ],
          ],
        ),
        trailing: canOpen ? const Icon(Icons.chevron_right) : null,
        onTap: canOpen
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PokemonDetailScreen(
                      pokemonId: encounter.pokemonId,
                      pokemonName: encounter.pokemonName,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
 
// Etiqueta pequeña de color (la usamos para el método de encuentro).
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
 
  const _Tag({required this.text, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}