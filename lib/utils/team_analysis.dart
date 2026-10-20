import '../models/team_member.dart';
import 'pokemon_type_colors.dart';
 
// Qué tan peligroso es un tipo atacante para el equipo.
enum TypeRisk { danger, good, neutral }
 
// Cómo le va al equipo completo contra UN tipo atacante.
class TypeCoverage {
  final String type;
 
  // Multiplicador de daño de cada integrante, en el orden del equipo.
  final List<double> multipliers;
 
  TypeCoverage({required this.type, required this.multipliers});
 
  // Cuántos integrantes reciben más daño de lo normal (x2 o x4).
  int get weak => multipliers.where((m) => m > 1).length;
 
  // Cuántos reciben menos daño (x1/2 o x1/4).
  int get resist => multipliers.where((m) => m > 0 && m < 1).length;
 
  // Cuántos no reciben ningún daño (x0).
  int get immune => multipliers.where((m) => m == 0).length;
 
  // Cuántos están "a salvo": resisten o son inmunes.
  int get protected => resist + immune;
 
  // Regla simple: si hay al menos 2 integrantes más débiles que
  // protegidos, ese tipo es un punto débil del equipo; si hay al menos 2
  // más protegidos que débiles, el equipo lo tiene bien cubierto.
  TypeRisk get risk {
    final balance = weak - protected;
    if (balance >= 2) return TypeRisk.danger;
    if (balance <= -2) return TypeRisk.good;
    return TypeRisk.neutral;
  }
}
 
// Analiza los 18 tipos contra el equipo. El resultado viene ordenado del
// tipo más peligroso al menos peligroso, para que lo importante quede arriba.
List<TypeCoverage> analyzeTeam(List<TeamMember> team) {
  final result = pokemonTypeColors.keys
      .map(
        (type) => TypeCoverage(
          type: type,
          multipliers: team.map((m) => m.effectiveness[type] ?? 1.0).toList(),
        ),
      )
      .toList();
 
  result.sort((a, b) {
    final byBalance = (b.weak - b.protected).compareTo(a.weak - a.protected);
    if (byBalance != 0) return byBalance;
    final byWeak = b.weak.compareTo(a.weak);
    return byWeak != 0 ? byWeak : a.type.compareTo(b.type);
  });
  return result;
}
 
// Nombres técnicos de las 6 estadísticas, en el orden en que se muestran.
const List<String> teamStatKeys = [
  'hp',
  'attack',
  'defense',
  'special-attack',
  'special-defense',
  'speed',
];
 
// Promedio de cada estadística base entre los integrantes del equipo.
Map<String, double> averageStats(List<TeamMember> team) {
  final result = <String, double>{};
  if (team.isEmpty) return result;
 
  for (final key in teamStatKeys) {
    var sum = 0;
    for (final member in team) {
      for (final stat in member.stats) {
        if (stat.name == key) sum += stat.baseStat;
      }
    }
    result[key] = sum / team.length;
  }
  return result;
}