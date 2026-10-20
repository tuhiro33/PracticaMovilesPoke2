import 'dart:convert';
 
import '../utils/name_helpers.dart';
import 'region_response.dart';
 
// Respuesta de /item-pocket: la lista de bolsillos de la mochila.
class NamedResourceList {
  final List<NamedResource> results;
 
  NamedResourceList({required this.results});
 
  factory NamedResourceList.fromRawJson(String str) =>
      NamedResourceList.fromJson(json.decode(str));
 
  factory NamedResourceList.fromJson(Map<String, dynamic> json) {
    return NamedResourceList(
      results: (json['results'] as List? ?? [])
          .map((r) => NamedResource.fromJson(r))
          .toList(),
    );
  }
}
 
// Respuesta de /item-pocket/{id}: un bolsillo con sus categorías.
class ItemPocketResponse {
  final int id;
  final String name;
  final List<NamedResource> categories;
 
  ItemPocketResponse({
    required this.id,
    required this.name,
    required this.categories,
  });
 
  factory ItemPocketResponse.fromRawJson(String str) =>
      ItemPocketResponse.fromJson(json.decode(str));
 
  factory ItemPocketResponse.fromJson(Map<String, dynamic> json) {
    return ItemPocketResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categories: (json['categories'] as List? ?? [])
          .map((c) => NamedResource.fromJson(c))
          .toList(),
    );
  }
}
 
// Respuesta de /item-category/{id}: una categoría con sus objetos
// (solo nombre y url de cada uno; el detalle se pide aparte).
class ItemCategoryResponse {
  final int id;
  final String name;
  final List<NamedResource> items;
 
  ItemCategoryResponse({
    required this.id,
    required this.name,
    required this.items,
  });
 
  factory ItemCategoryResponse.fromRawJson(String str) =>
      ItemCategoryResponse.fromJson(json.decode(str));
 
  factory ItemCategoryResponse.fromJson(Map<String, dynamic> json) {
    return ItemCategoryResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => NamedResource.fromJson(i))
          .toList(),
    );
  }
}
 
// Respuesta de /item/{id}: el detalle de un objeto.
//
// Ojo: los objetos más nuevos (de Paldea, por ejemplo) vienen casi vacíos
// en la API: sin sprite, sin descripción y sin nombre en español. Por eso
// casi todo es opcional o tiene un valor de respaldo.
class ItemResponse {
  final int id;
  final String name; // nombre técnico, ej. "super-potion"
  final String displayName; // español si existe, si no inglés
  final int cost; // 0 = no se vende
  final int? flingPower; // poder al lanzarlo con "Lanzamiento"
  final String categoryName;
  final String? spriteUrl; // puede ser null
  final String description; // vacío si la API no trae
  final String effect; // efecto corto (la API solo lo tiene en inglés)
  final List<String> attributes;
  final List<NamedResource> heldBy; // Pokémon salvajes que lo llevan
 
  ItemResponse({
    required this.id,
    required this.name,
    required this.displayName,
    required this.cost,
    required this.flingPower,
    required this.categoryName,
    required this.spriteUrl,
    required this.description,
    required this.effect,
    required this.attributes,
    required this.heldBy,
  });
 
  factory ItemResponse.fromRawJson(String str) =>
      ItemResponse.fromJson(json.decode(str));
 
  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final sprites = json['sprites'] as Map<String, dynamic>? ?? {};
 
    // En los objetos, el texto de la descripción viene en la clave "text".
    // También probamos "flavor_text" por si el formato cambiara.
    const textKeys = ['text', 'flavor_text'];
    final flavors = json['flavor_text_entries'];
    final description = cleanText(
      lastTextInLanguage(flavors, 'es', textKeys) ??
          lastTextInLanguage(flavors, 'en', textKeys) ??
          '',
    );
 
    final effect = cleanText(
      lastTextInLanguage(
            json['effect_entries'],
            'en',
            const ['short_effect', 'effect'],
          ) ??
          '',
    );
 
    return ItemResponse(
      id: json['id'] ?? 0,
      name: name,
      displayName: pickLocalizedName(json['names'], name),
      cost: (json['cost'] as int?) ?? 0,
      flingPower: json['fling_power'] as int?,
      categoryName: json['category']?['name'] as String? ?? '',
      spriteUrl: sprites['default'] as String?,
      description: description,
      effect: effect,
      attributes: (json['attributes'] as List? ?? [])
          .map((a) => a['name'] as String)
          .toList(),
      heldBy: (json['held_by_pokemon'] as List? ?? [])
          .map((h) => NamedResource.fromJson(h['pokemon']))
          .toList(),
    );
  }
}