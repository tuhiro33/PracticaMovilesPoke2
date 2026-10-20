import 'package:flutter/material.dart';
 
import '../models/region_response.dart';
import '../providers/poke_api_provider.dart';
import '../utils/name_helpers.dart';
import '../utils/region_info.dart';
import '../widgets/future_view.dart';
import 'location_detail_screen.dart';
 
// Muestra todas las ubicaciones de una región (rutas, ciudades, cuevas...)
// con un buscador para filtrarlas, porque algunas regiones tienen cientos.
class RegionDetailScreen extends StatefulWidget {
  final int regionId;
  final String regionName; // nombre técnico de la API, ej. "unova"
 
  const RegionDetailScreen({
    super.key,
    required this.regionId,
    required this.regionName,
  });
 
  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}
 
class _RegionDetailScreenState extends State<RegionDetailScreen> {
  final PokeApiProvider _api = PokeApiProvider();
  final TextEditingController _searchController = TextEditingController();
  late Future<RegionDetailResponse> _future;
  String _query = '';
 
  @override
  void initState() {
    super.initState();
    _future = _load();
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
 
  Future<RegionDetailResponse> _load() async {
    final response = await _api.getRegionDetail(widget.regionId);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return RegionDetailResponse.fromRawJson(response.body);
  }
 
  // Elige un ícono según el nombre de la ubicación (rutas, ciudades,
  // cuevas, etc.). Es una aproximación: se basa en palabras del nombre.
  IconData _iconFor(String name) {
    if (name.contains('route')) return Icons.alt_route;
    if (name.contains('city') ||
        name.contains('town') ||
        name.contains('village')) {
      return Icons.location_city;
    }
    if (name.contains('cave') ||
        name.contains('mt-') ||
        name.contains('mountain') ||
        name.contains('tunnel')) {
      return Icons.terrain;
    }
    if (name.contains('forest') ||
        name.contains('woods') ||
        name.contains('park') ||
        name.contains('garden')) {
      return Icons.park;
    }
    if (name.contains('lake') ||
        name.contains('sea') ||
        name.contains('ocean') ||
        name.contains('bay') ||
        name.contains('river') ||
        name.contains('beach') ||
        name.contains('island')) {
      return Icons.water;
    }
    if (name.contains('tower') ||
        name.contains('building') ||
        name.contains('lab')) {
      return Icons.apartment;
    }
    return Icons.place;
  }
 
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final info = regionInfoFor(widget.regionName, primary);
 
    return Scaffold(
      appBar: AppBar(title: Text(info.name)),
      body: FutureView<RegionDetailResponse>(
        future: _future,
        onRetry: () => setState(() {
          _future = _load();
        }),
        builder: (context, region) => _buildContent(region, info),
      ),
    );
  }
 
  Widget _buildContent(RegionDetailResponse region, RegionInfo info) {
    // Filtramos por lo que se escribió en el buscador.
    final q = _query.trim().toLowerCase();
    final locations = q.isEmpty
        ? region.locations
        : region.locations
            .where((l) => prettifyName(l.name).toLowerCase().contains(q))
            .toList();
 
    return Column(
      children: [
        // --- Encabezado con degradado ---
        Container(
          height: 88,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: info.colors,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.subtitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${region.locations.length} ubicaciones',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              ...info.starters.map(
                (id) => SizedBox(
                  width: 52,
                  child: Image.network(
                    pokemonArtworkUrl(id),
                    height: 64,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // --- Buscador (solo si hay suficientes ubicaciones para necesitarlo) ---
        if (region.locations.length > 8)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              // Colores explícitos para que se lea bien con cualquier tema.
              style: const TextStyle(color: Colors.black87),
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Buscar ubicación',
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        // --- Lista ---
        Expanded(
          child: region.locations.isEmpty
              ? const InfoMessage(
                  icon: Icons.map_outlined,
                  text: 'Esta región no tiene ubicaciones registradas en la API.',
                )
              : locations.isEmpty
                  ? InfoMessage(
                      icon: Icons.search_off,
                      text: 'Ninguna ubicación coincide con "$_query".',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: locations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: info.colors.first,
                              child: Icon(
                                _iconFor(location.name),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(prettifyName(location.name)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationDetailScreen(
                                    locationId: location.id,
                                    locationName: location.name,
                                    region: info,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
 