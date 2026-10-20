import 'dart:convert';
import 'dart:math';
 
import '../utils/name_helpers.dart';
import 'region_response.dart';
 
// Respuesta de /location/{id}: una ubicación (ej. "Ruta 1") con
// la lista de sus áreas. Las áreas son las que tienen los encuentros.
class LocationResponse {
  final int id;
  final String name;
  final String displayName;
  final List<NamedResource> areas;
 
  LocationResponse({
    required this.id,
    required this.name,
    required this.displayName,
    required this.areas,
  });
 
  factory LocationResponse.fromRawJson(String str) =>
      LocationResponse.fromJson(json.decode(str));
 
  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return LocationResponse(
      id: json['id'] ?? 0,
      name: name,
      displayName: pickLocalizedName(json['names'], name),
      areas: (json['areas'] as List? ?? [])
          .map((a) => NamedResource.fromJson(a))
          .toList(),
    );
  }
}
 
// Respuesta de /location-area/{id}: los Pokémon que aparecen en esa área.
class LocationAreaResponse {
  final int id;
  final String name;
  final List<AreaEncounter> encounters;
 
  LocationAreaResponse({
    required this.id,
    required this.name,
    required this.encounters,
  });
 
  factory LocationAreaResponse.fromRawJson(String str) =>
      LocationAreaResponse.fromJson(json.decode(str));
 
  factory LocationAreaResponse.fromJson(Map<String, dynamic> json) {
    final encounters = (json['pokemon_encounters'] as List? ?? [])
        .map((e) => AreaEncounter.fromJson(e))
        .toList()
      // Primero los más probables; a igualdad de probabilidad, por nombre.
      ..sort((a, b) {
        final byChance = b.chance.compareTo(a.chance);
        return byChance != 0 ? byChance : a.pokemonName.compareTo(b.pokemonName);
      });
 
    return LocationAreaResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      encounters: encounters,
    );
  }
}
 
// Un Pokémon que aparece en un área, ya resumido.
//
// En la API cada Pokémon trae un detalle POR JUEGO y, dentro de cada juego,
// varios "encounter_details" (uno por método, nivel, condición...). Para
// mostrarlo en una sola fila juntamos todo: rango de niveles, métodos,
// juegos y una probabilidad aproximada.
class AreaEncounter {
  final String pokemonName;
  final int pokemonId;
  final int minLevel; // 0 si la API no trae niveles
  final int maxLevel;
  final int chance; // probabilidad aproximada, de 0 a 100
  final List<String> methods;
  final List<String> versions;
 
  AreaEncounter({
    required this.pokemonName,
    required this.pokemonId,
    required this.minLevel,
    required this.maxLevel,
    required this.chance,
    required this.methods,
    required this.versions,
  });
 
  factory AreaEncounter.fromJson(Map<String, dynamic> json) {
    final pokemon = json['pokemon'] as Map<String, dynamic>? ?? {};
    final resource = NamedResource.fromJson(pokemon);
 
    int? minLevel;
    int? maxLevel;
    int bestChance = 0;
    // Un Set no repite elementos y conserva el orden en que se agregan.
    final methods = <String>{};
    final versions = <String>{};
 
    for (final versionDetail in (json['version_details'] as List? ?? [])) {
      final versionName = versionDetail['version']?['name'];
      if (versionName is String) versions.add(versionName);
 
      // Probabilidad por método dentro de este juego: sumamos los "slots"
      // de ese método. NO usamos el campo max_chance de la API porque suma
      // todos los métodos juntos y puede pasar de 100%.
      final chanceByMethod = <String, int>{};
 
      for (final detail in (versionDetail['encounter_details'] as List? ?? [])) {
        final lo = detail['min_level'];
        final hi = detail['max_level'];
        if (lo is int && (minLevel == null || lo < minLevel)) minLevel = lo;
        if (hi is int && (maxLevel == null || hi > maxLevel)) maxLevel = hi;
 
        final method = detail['method']?['name'];
        if (method is String) {
          methods.add(method);
          final chance = detail['chance'];
          if (chance is int) {
            chanceByMethod[method] = (chanceByMethod[method] ?? 0) + chance;
          }
        }
      }
 
      for (final total in chanceByMethod.values) {
        // Limitamos a 100: con condiciones como "de día / de noche" los
        // slots se repiten y la suma podría pasarse.
        bestChance = max(bestChance, min(total, 100));
      }
    }
 
    return AreaEncounter(
      pokemonName: resource.name,
      pokemonId: resource.id,
      minLevel: minLevel ?? 0,
      maxLevel: maxLevel ?? 0,
      chance: bestChance,
      methods: methods.toList(),
      versions: versions.toList(),
    );
  }
}