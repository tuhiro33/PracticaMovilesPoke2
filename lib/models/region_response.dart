import 'dart:convert';
 
import '../utils/name_helpers.dart';
 
// Un recurso de la API que solo trae nombre y url, como
// { "name": "kanto", "url": "https://pokeapi.co/api/v2/region/1/" }.
// Se usa para regiones, ubicaciones y áreas.
class NamedResource {
  final String name;
  final String url;
 
  const NamedResource({required this.name, required this.url});
 
  factory NamedResource.fromJson(Map<String, dynamic> json) {
    return NamedResource(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }
 
  // Id sacado del último segmento de la url (igual que en los otros modelos).
  int get id {
    final segments =
        Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? 0 : int.tryParse(segments.last) ?? 0;
  }
}
 
// Respuesta de /region: la lista de regiones.
class RegionListResponse {
  final List<NamedResource> results;
 
  RegionListResponse({required this.results});
 
  factory RegionListResponse.fromRawJson(String str) =>
      RegionListResponse.fromJson(json.decode(str));
 
  factory RegionListResponse.fromJson(Map<String, dynamic> json) {
    return RegionListResponse(
      results: (json['results'] as List? ?? [])
          .map((r) => NamedResource.fromJson(r))
          .toList(),
    );
  }
}
 
// Respuesta de /region/{id}: de todo lo que trae solo usamos
// el nombre y la lista de ubicaciones (rutas, ciudades, cuevas...).
class RegionDetailResponse {
  final int id;
  final String name;
  final String displayName;
  final List<NamedResource> locations;
 
  RegionDetailResponse({
    required this.id,
    required this.name,
    required this.displayName,
    required this.locations,
  });
 
  factory RegionDetailResponse.fromRawJson(String str) =>
      RegionDetailResponse.fromJson(json.decode(str));
 
  factory RegionDetailResponse.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return RegionDetailResponse(
      id: json['id'] ?? 0,
      name: name,
      displayName: pickLocalizedName(json['names'], name),
      locations: (json['locations'] as List? ?? [])
          .map((l) => NamedResource.fromJson(l))
          .toList(),
    );
  }
}
 