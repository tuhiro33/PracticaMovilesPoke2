
import 'package:practicasmovilespoke2/models/type_relations_response.dart';
import 'package:practicasmovilespoke2/utils/pokemon_type_colors.dart';
 
// Calcula cuánto daño recibe un Pokémon de cada tipo atacante.
//
// Recibe las relaciones de daño de CADA tipo del Pokémon (1 o 2 tipos)
// y devuelve un Map: tipo atacante -> multiplicador.
//   4.0  = muy débil (x4)       2.0 = débil (x2)
//   1.0  = daño normal          0.5 = resistente (x1/2)
//   0.25 = muy resistente (x1/4)   0.0 = inmune
//
// Con dos tipos los multiplicadores SE MULTIPLICAN entre sí. Ejemplo:
// Bulbasaur (planta/veneno) recibe x2 de fuego (planta x2 * veneno x1)
// y solo x1/4 de planta (planta x0.5 * veneno x0.5).
Map<String, double> calculateTypeEffectiveness(
    List<TypeRelationsResponse> defendingTypes) {
  // Partimos con todos los tipos atacantes en x1 (daño normal).
  final result = <String, double>{
    for (final type in pokemonTypeColors.keys) type: 1.0,
  };
 
  for (final relations in defendingTypes) {
    for (final t in relations.doubleDamageFrom) {
      if (result.containsKey(t)) result[t] = result[t]! * 2;
    }
    for (final t in relations.halfDamageFrom) {
      if (result.containsKey(t)) result[t] = result[t]! * 0.5;
    }
    for (final t in relations.noDamageFrom) {
      if (result.containsKey(t)) result[t] = result[t]! * 0;
    }
  }
 
  return result;
}
 