import 'dart:convert';
 
// Respuesta del endpoint /type/{name}. Solo nos interesa
// "damage_relations", que dice contra qué tipos es débil o resistente
// el tipo consultado cuando ES EL QUE DEFIENDE (los campos "_from").
class TypeRelationsResponse {
  final String name;
  // Tipos que le hacen el DOBLE de daño (x2)
  final List<String> doubleDamageFrom;
  // Tipos que le hacen la MITAD de daño (x0.5)
  final List<String> halfDamageFrom;
  // Tipos que NO le hacen daño (x0)
  final List<String> noDamageFrom;
 
  TypeRelationsResponse({
    required this.name,
    required this.doubleDamageFrom,
    required this.halfDamageFrom,
    required this.noDamageFrom,
  });
 
  factory TypeRelationsResponse.fromRawJson(String str) =>
      TypeRelationsResponse.fromJson(json.decode(str));
 
  factory TypeRelationsResponse.fromJson(Map<String, dynamic> json) {
    final relations = json['damage_relations'] as Map<String, dynamic>? ?? {};
 
    // Cada lista viene como [{ "name": "fire", "url": "..." }, ...]
    // y solo necesitamos los nombres.
    List<String> namesOf(String key) => (relations[key] as List? ?? [])
        .map((t) => t['name'] as String)
        .toList();
 
    return TypeRelationsResponse(
      name: json['name'] ?? '',
      doubleDamageFrom: namesOf('double_damage_from'),
      halfDamageFrom: namesOf('half_damage_from'),
      noDamageFrom: namesOf('no_damage_from'),
    );
  }
}
 