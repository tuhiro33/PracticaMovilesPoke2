import 'package:flutter/material.dart';
 
import '../models/team_member.dart';
import '../utils/pokemon_type_colors.dart';
import '../utils/team_analysis.dart';
 
// Todo el análisis del equipo: resumen de puntos débiles y fuertes,
// tabla de los 18 tipos contra cada integrante y estadísticas promedio.
// Usa tarjetas blancas con colores explícitos para verse bien con cualquier tema.
class TeamAnalysisView extends StatelessWidget {
  final List<TeamMember> team;
 
  const TeamAnalysisView({super.key, required this.team});
 
  @override
  Widget build(BuildContext context) {
    final coverage = analyzeTeam(team);
    final danger = coverage.where((c) => c.risk == TypeRisk.danger).toList();
    final good = coverage.where((c) => c.risk == TypeRisk.good).toList();
 
    return Column(
      children: [
        _AnalysisCard(
          title: 'Resumen',
          child: team.length < 2
              ? const Text(
                  'Agrega al menos 2 Pokémon para ver los puntos débiles y fuertes de tu equipo.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeGroup(
                      title: 'Puntos débiles',
                      subtitle: 'Tipos que castigan a varios de tus Pokémon',
                      emptyText: 'Ningún tipo es una amenaza grave.',
                      items: danger,
                      count: (c) => c.weak,
                    ),
                    const SizedBox(height: 14),
                    _TypeGroup(
                      title: 'Bien cubierto contra',
                      subtitle: 'Tipos a los que varios resisten o ignoran',
                      emptyText: 'Ningún tipo está especialmente cubierto.',
                      items: good,
                      count: (c) => c.protected,
                    ),
                  ],
                ),
        ),
        _AnalysisCard(
          title: 'Tabla de tipos',
          subtitle: 'Ordenada del tipo más peligroso al menos peligroso',
          child: _TypeTable(team: team, coverage: coverage),
        ),
        _AnalysisCard(
          title: 'Estadísticas promedio',
          child: _AverageStats(stats: averageStats(team)),
        ),
      ],
    );
  }
}
 
// Tarjeta blanca con título y subtítulo opcional.
class _AnalysisCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
 
  const _AnalysisCard({required this.title, this.subtitle, required this.child});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
 
// Grupo de tipos con un título (puntos débiles / bien cubierto).
class _TypeGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyText;
  final List<TypeCoverage> items;
  // Qué número se muestra junto a cada tipo (cuántos son débiles / cuántos
  // están a salvo).
  final int Function(TypeCoverage) count;
 
  const _TypeGroup({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.items,
    required this.count,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((c) => _TypePill(type: c.type, suffix: ' · ${count(c)}'))
                .toList(),
          ),
      ],
    );
  }
}
 
// Etiqueta con el nombre de un tipo, pintada con su color.
// Con compact: true es más pequeña, para caber en la tabla.
class _TypePill extends StatelessWidget {
  final String type;
  final String suffix;
  final bool compact;
 
  const _TypePill({required this.type, this.suffix = '', this.compact = false});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: colorForType(type),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Text(
        '${typeNameEs(type)}$suffix',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
 
// Color de una celda según el multiplicador de daño.
Color _cellColor(double m) {
  if (m == 0) return const Color(0xFF37474F); // inmune
  if (m >= 4) return const Color(0xFFB71C1C); // muy débil
  if (m >= 2) return const Color(0xFFEF5350); // débil
  if (m <= 0.25) return const Color(0xFF388E3C); // muy resistente
  if (m <= 0.5) return const Color(0xFF81C784); // resistente
  return Colors.grey.shade200; // daño normal
}
 
// Texto corto dentro de la celda (vacío si el daño es normal).
String _cellLabel(double m) {
  if (m == 0) return '0';
  if (m == 4) return '4';
  if (m == 2) return '2';
  if (m == 0.5) return '½';
  if (m == 0.25) return '¼';
  return '';
}
 
// Tabla: una fila por tipo atacante y una columna por integrante.
// Cada celda se pinta según cuánto daño recibe ese Pokémon de ese tipo.
class _TypeTable extends StatelessWidget {
  final List<TeamMember> team;
  final List<TypeCoverage> coverage;
 
  // Anchos fijos de la columna del tipo y de la columna de totales;
  // las celdas de los Pokémon se reparten el espacio que sobra.
  static const double _typeWidth = 72;
  static const double _totalsWidth = 52;
 
  const _TypeTable({required this.team, required this.coverage});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 4),
        ...coverage.map(_buildRow),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }
 
  // Fila de arriba: el sprite de cada integrante sobre su columna.
  Widget _buildHeader() {
    return Row(
      children: [
        const SizedBox(width: _typeWidth),
        Expanded(
          child: Row(
            children: team
                .map(
                  (m) => Expanded(
                    child: Center(
                      child: m.spriteUrl != null
                          ? Image.network(
                              m.spriteUrl!,
                              height: 28,
                              errorBuilder: (context, error, stack) =>
                                  const Icon(Icons.catching_pokemon, size: 20),
                            )
                          : const Icon(Icons.catching_pokemon, size: 20),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(
          width: _totalsWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Déb.',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF5350))),
              Text('Res.',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C))),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildRow(TypeCoverage c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: _typeWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypePill(type: c.type, compact: true),
            ),
          ),
          Expanded(
            child: Row(
              children: c.multipliers
                  .map(
                    (m) => Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cellColor(m),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _cellLabel(m),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(
            width: _totalsWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CountBadge(value: c.weak, color: const Color(0xFFEF5350)),
                _CountBadge(
                    value: c.protected, color: const Color(0xFF388E3C)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildLegend() {
    const items = <(Color, String)>[
      (Color(0xFFB71C1C), '4 = muy débil (x4)'),
      (Color(0xFFEF5350), '2 = débil (x2)'),
      (Color(0xFF81C784), '½ = resiste'),
      (Color(0xFF388E3C), '¼ = muy resistente'),
      (Color(0xFF37474F), '0 = inmune'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.$1,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.$2,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
 
// Número en un círculo de color; si es 0 se ve apagado.
class _CountBadge extends StatelessWidget {
  final int value;
  final Color color;
 
  const _CountBadge({required this.value, required this.color});
 
  @override
  Widget build(BuildContext context) {
    final active = value > 0;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : Colors.black26,
        ),
      ),
    );
  }
}
 
// Barras con el promedio de cada estadística y el total.
class _AverageStats extends StatelessWidget {
  final Map<String, double> stats;
 
  const _AverageStats({required this.stats});
 
  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold<double>(0, (a, b) => a + b);
 
    return Column(
      children: [
        ...teamStatKeys.map((key) {
          final value = stats[key] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    statNameEs(key),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${value.round()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      // 200 es aprox. el máximo teórico de un stat base.
                      value: (value / 200).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF5C6BC0),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total promedio por Pokémon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              '${total.round()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
 