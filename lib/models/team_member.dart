import 'pokemon_detail_response.dart';
 
// Un Pokémon del equipo, con todo lo que necesita el análisis ya calculado
// (así no hay que volver a pedir nada a la API al redibujar la pantalla).
class TeamMember {
  final int id;
  final String name; // nombre técnico, ej. "mr-mime"
  final String? spriteUrl;
  final List<String> types;
  final List<PokemonStat> stats;
 
  // Tipo atacante -> multiplicador de daño que recibe este Pokémon
  // (4 = muy débil, 2 = débil, 1 = normal, 0.5 = resiste, 0 = inmune).
  final Map<String, double> effectiveness;
 
  TeamMember({
    required this.id,
    required this.name,
    required this.spriteUrl,
    required this.types,
    required this.stats,
    required this.effectiveness,
  });
}