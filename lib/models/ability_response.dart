import 'dart:convert';
 
// Respuesta del endpoint /ability/{name}: de todo lo que trae, solo
// necesitamos el nombre (en español si existe) y una descripción.
class AbilityResponse {
  final String name;
  final String description;
 
  AbilityResponse({required this.name, required this.description});
 
  factory AbilityResponse.fromRawJson(String str) =>
      AbilityResponse.fromJson(json.decode(str));
 
  factory AbilityResponse.fromJson(Map<String, dynamic> json) {
    // Busca en una lista de entradas la que esté en el idioma pedido.
    // Devuelve la ÚLTIMA coincidencia, porque en flavor_text_entries las
    // entradas van de las versiones de juego más viejas a las más nuevas.
    Map<String, dynamic>? lastInLanguage(List entries, String lang) {
      Map<String, dynamic>? found;
      for (final e in entries) {
        if (e is Map<String, dynamic> && e['language']?['name'] == lang) {
          found = e;
        }
      }
      return found;
    }
 
    String clean(String text) =>
        text.replaceAll('\n', ' ').replaceAll('\f', ' ').trim();
 
    // --- Nombre: español si existe, si no el nombre técnico ---
    final names = json['names'] as List? ?? [];
    final nameEs = lastInLanguage(names, 'es')?['name'] as String?;
    final fallbackName = (json['name'] as String? ?? '').replaceAll('-', ' ');
 
    // --- Descripción: flavor text en español, luego en inglés,
    // y como último recurso el efecto corto en inglés ---
    final flavors = json['flavor_text_entries'] as List? ?? [];
    final effects = json['effect_entries'] as List? ?? [];
 
    String description =
        clean(lastInLanguage(flavors, 'es')?['flavor_text'] as String? ?? '');
    if (description.isEmpty) {
      description = clean(
          lastInLanguage(flavors, 'en')?['flavor_text'] as String? ?? '');
    }
    if (description.isEmpty) {
      description = clean(
          lastInLanguage(effects, 'en')?['short_effect'] as String? ?? '');
    }
 
    return AbilityResponse(
      name: nameEs ?? fallbackName,
      description: description,
    );
  }
}
 