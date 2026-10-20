import 'pokemon_detail_response.dart';
 
// Uno de los dos Pokémon que se comparan, con todo lo que necesita la
// pantalla ya calculado (así no se vuelve a pedir nada a la API al redibujar).
class ComparisonSide {
  final PokemonDetailResponse pokemon;
 
  // Tipo atacante -> multiplicador de daño que recibe este Pokémon
  // (4 = muy débil, 2 = débil, 1 = normal, 0.5 = resiste, 0 = inmune).
  final Map<String, double> effectiveness;
 
  // Habilidades ya con su nombre en español y marcadas si son ocultas.
  final List<String> abilityLabels;
 
  ComparisonSide({
    required this.pokemon,
    required this.effectiveness,
    required this.abilityLabels,
  });
 
  // Valor de una estadística por su nombre técnico ("attack", "speed"...).
  int statValue(String key) {
    for (final stat in pokemon.stats) {
      if (stat.name == key) return stat.baseStat;
    }
    return 0;
  }
 
  // Suma de las 6 estadísticas base.
  int get totalStats =>
      pokemon.stats.fold<int>(0, (sum, stat) => sum + stat.baseStat);
}
 