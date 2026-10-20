import 'package:flutter/material.dart';
 
import '../models/comparison_side.dart';
import '../utils/name_helpers.dart';
import '../utils/pokemon_type_colors.dart';
import '../utils/team_analysis.dart';
 
// Colores fijos de cada lado: azul para el primero, naranja para el
// segundo. Se usan también en los selectores de la pantalla para que
// quede claro quién es quién.
const Color comparisonColorA = Color(0xFF5C6BC0);
const Color comparisonColorB = Color(0xFFFF7043);
 
// Valor máximo de una estadística base, usado como 100% de las barras.
const double _maxStat = 255;
 
String _name(ComparisonSide side) => prettifyName(side.pokemon.name);
 
// "x2", "x½"... para mostrar un multiplicador de daño.
String _multiplier(double m) {
  if (m == 0) return '×0';
  if (m == 0.5) return '×½';
  if (m == 0.25) return '×¼';
  return '×${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)}';
}
 
// Toda la comparación entre dos Pokémon. Usa tarjetas blancas con colores
// explícitos para verse bien con cualquier tema.
class ComparisonView extends StatelessWidget {
  final ComparisonSide a;
  final ComparisonSide b;
 
  const ComparisonView({super.key, required this.a, required this.b});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryCard(a: a, b: b),
        _StatsCard(a: a, b: b),
        _BasicDataCard(a: a, b: b),
        _MatchupCard(a: a, b: b),
        _AbilitiesCard(a: a, b: b),
      ],
    );
  }
}
 
// Tarjeta blanca con título y subtítulo opcional.
class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
 
  const _Card({required this.title, this.subtitle, required this.child});
 
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
 
// --- Resumen: quién gana en más estadísticas ---
class _SummaryCard extends StatelessWidget {
  final ComparisonSide a;
  final ComparisonSide b;
 
  const _SummaryCard({required this.a, required this.b});
 
  @override
  Widget build(BuildContext context) {
    var winsA = 0;
    var winsB = 0;
    var ties = 0;
    for (final key in teamStatKeys) {
      final va = a.statValue(key);
      final vb = b.statValue(key);
      if (va > vb) {
        winsA++;
      } else if (vb > va) {
        winsB++;
      } else {
        ties++;
      }
    }
 
    final totalA = a.totalStats;
    final totalB = b.totalStats;
    final String verdict;
    if (totalA == totalB) {
      verdict = 'Tienen el mismo total de estadísticas base ($totalA).';
    } else {
      final winner = totalA > totalB ? a : b;
      final diff = (totalA - totalB).abs();
      verdict =
          '${_name(winner)} suma $diff puntos más en total ($totalA contra $totalB).';
    }
 
    return _Card(
      title: 'Resumen',
      subtitle: 'Estadísticas ganadas, de un total de 6',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _WinsColumn(name: _name(a), wins: winsA, color: comparisonColorA)),
              Column(
                children: [
                  const Text(
                    'vs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  ),
                  if (ties > 0)
                    Text(
                      '$ties ${ties == 1 ? 'empate' : 'empates'}',
                      style: const TextStyle(fontSize: 10, color: Colors.black45),
                    ),
                ],
              ),
              Expanded(child: _WinsColumn(name: _name(b), wins: winsB, color: comparisonColorB)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            verdict,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
 
class _WinsColumn extends StatelessWidget {
  final String name;
  final int wins;
  final Color color;
 
  const _WinsColumn({
    required this.name,
    required this.wins,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$wins',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
 
// --- Estadísticas enfrentadas ---
class _StatsCard extends StatelessWidget {
  final ComparisonSide a;
  final ComparisonSide b;
 
  const _StatsCard({required this.a, required this.b});
 
  @override
  Widget build(BuildContext context) {
    final totalA = a.totalStats;
    final totalB = b.totalStats;
    // La barra del total se escala contra el mayor de los dos totales.
    final totalMax = (totalA > totalB ? totalA : totalB).toDouble();
 
    return _Card(
      title: 'Estadísticas base',
      child: Column(
        children: [
          ...teamStatKeys.map(
            (key) => _StatRow(
              label: statNameEs(key),
              valueA: a.statValue(key),
              valueB: b.statValue(key),
              max: _maxStat,
            ),
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Total',
            valueA: totalA,
            valueB: totalB,
            max: totalMax <= 0 ? 1 : totalMax,
          ),
        ],
      ),
    );
  }
}
 
// Una fila: valor de A, dos barras que crecen desde el centro y valor de B.
// El lado que gana se resalta en negrita y con su color.
class _StatRow extends StatelessWidget {
  final String label;
  final int valueA;
  final int valueB;
  final double max;
 
  const _StatRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.max,
  });
 
  @override
  Widget build(BuildContext context) {
    final aWins = valueA > valueB;
    final bWins = valueB > valueA;
 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$valueA',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: aWins ? FontWeight.w800 : FontWeight.normal,
                color: aWins ? comparisonColorA : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: _HalfBar(
                        fraction: valueA / max,
                        color: comparisonColorA,
                        fromRight: true,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _HalfBar(
                        fraction: valueB / max,
                        color: comparisonColorB,
                        fromRight: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$valueB',
              style: TextStyle(
                fontSize: 13,
                fontWeight: bWins ? FontWeight.w800 : FontWeight.normal,
                color: bWins ? comparisonColorB : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// Mitad de una barra: la de A crece hacia la izquierda y la de B hacia la
// derecha, así se ven enfrentadas en el centro.
class _HalfBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final bool fromRight;
 
  const _HalfBar({
    required this.fraction,
    required this.color,
    required this.fromRight,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: fromRight ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}
 
// --- Altura, peso y experiencia base ---
class _BasicDataCard extends StatelessWidget {
  final ComparisonSide a;
  final ComparisonSide b;
 
  const _BasicDataCard({required this.a, required this.b});
 
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Datos físicos',
      child: Column(
        children: [
          _VersusRow(
            label: 'Altura',
            textA: '${a.pokemon.heightInMeters.toStringAsFixed(1)} m',
            textB: '${b.pokemon.heightInMeters.toStringAsFixed(1)} m',
            valueA: a.pokemon.height.toDouble(),
            valueB: b.pokemon.height.toDouble(),
          ),
          _VersusRow(
            label: 'Peso',
            textA: '${a.pokemon.weightInKg.toStringAsFixed(1)} kg',
            textB: '${b.pokemon.weightInKg.toStringAsFixed(1)} kg',
            valueA: a.pokemon.weight.toDouble(),
            valueB: b.pokemon.weight.toDouble(),
          ),
          _VersusRow(
            label: 'Exp. base',
            textA: '${a.pokemon.baseExperience}',
            textB: '${b.pokemon.baseExperience}',
            valueA: a.pokemon.baseExperience.toDouble(),
            valueB: b.pokemon.baseExperience.toDouble(),
          ),
        ],
      ),
    );
  }
}
 
// Fila simple "valor A | etiqueta | valor B"; resalta el valor mayor.
class _VersusRow extends StatelessWidget {
  final String label;
  final String textA;
  final String textB;
  final double valueA;
  final double valueB;
 
  const _VersusRow({
    required this.label,
    required this.textA,
    required this.textB,
    required this.valueA,
    required this.valueB,
  });
 
  @override
  Widget build(BuildContext context) {
    final aWins = valueA > valueB;
    final bWins = valueB > valueA;
 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              textA,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: aWins ? FontWeight.w800 : FontWeight.normal,
                color: aWins ? comparisonColorA : Colors.black54,
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              textB,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bWins ? FontWeight.w800 : FontWeight.normal,
                color: bWins ? comparisonColorB : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// --- Ventaja de tipos: cómo le pega cada uno al otro ---
class _MatchupCard extends StatelessWidget {
  final ComparisonSide a;
  final ComparisonSide b;
 
  const _MatchupCard({required this.a, required this.b});
 
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Ventaja de tipos',
      subtitle: 'Qué tan efectivos son los tipos de cada uno contra el otro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MatchupBlock(attacker: a, defender: b, color: comparisonColorA),
          const SizedBox(height: 14),
          _MatchupBlock(attacker: b, defender: a, color: comparisonColorB),
        ],
      ),
    );
  }
}
 
class _MatchupBlock extends StatelessWidget {
  final ComparisonSide attacker;
  final ComparisonSide defender;
  final Color color;
 
  const _MatchupBlock({
    required this.attacker,
    required this.defender,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    // Por cada tipo del atacante, cuánto daño le hace al defensor.
    // defender.effectiveness ya guarda cuánto daño recibe de cada tipo.
    final entries = attacker.pokemon.types
        .map((type) => (type, defender.effectiveness[type] ?? 1.0))
        .toList();
    final best = entries.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
 
    final String caption;
    if (best >= 2) {
      caption = 'Tiene ventaja de tipo: su mejor tipo hace ${_multiplier(best)}.';
    } else if (best == 1) {
      caption = 'Sus tipos hacen daño normal.';
    } else if (best > 0) {
      caption = 'Sus tipos son poco efectivos (mejor: ${_multiplier(best)}).';
    } else {
      caption = 'Sus tipos no le hacen daño.';
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_name(attacker)} atacando a ${_name(defender)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: entries
              .map(
                (e) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorForType(e.$1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${typeNameEs(e.$1)} ${_multiplier(e.$2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
 
// --- Habilidades de cada uno, en dos columnas ---
class _AbilitiesCard extends StatelessWidget {
  final ComparisonSide a;
  final ComparisonSide b;
 
  const _AbilitiesCard({required this.a, required this.b});
 
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Habilidades',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _AbilityColumn(side: a, color: comparisonColorA)),
          const SizedBox(width: 12),
          Expanded(child: _AbilityColumn(side: b, color: comparisonColorB)),
        ],
      ),
    );
  }
}
 
class _AbilityColumn extends StatelessWidget {
  final ComparisonSide side;
  final Color color;
 
  const _AbilityColumn({required this.side, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _name(side),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...side.abilityLabels.map(
          (label) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}