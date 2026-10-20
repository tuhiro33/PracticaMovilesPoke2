import 'package:flutter/material.dart';
 
import '../models/item_response.dart';
import '../models/region_response.dart';
import '../utils/item_cache.dart';
import '../utils/item_info.dart';
import '../utils/name_helpers.dart';
import '../widgets/future_view.dart';
import 'pokemon_detail_screen.dart';
 
// Detalle de un objeto: sprite grande, precio, descripción, características
// y qué Pokémon salvajes lo llevan equipado.
class ItemDetailScreen extends StatefulWidget {
  final int itemId;
  final String itemName; // nombre técnico, se usa mientras carga
  final PocketInfo pocket; // colores del bolsillo al que pertenece
 
  const ItemDetailScreen({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.pocket,
  });
 
  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}
 
class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Future<ItemResponse> _future;
 
  @override
  void initState() {
    super.initState();
    // Normalmente el objeto ya está en la caché porque la casilla de la
    // cuadrícula lo pidió, así que esto suele ser instantáneo.
    _future = ItemCache.get(widget.itemId);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(prettifyName(widget.itemName))),
      body: FutureView<ItemResponse>(
        future: _future,
        onRetry: () => setState(() {
          _future = ItemCache.get(widget.itemId);
        }),
        builder: (context, item) => _buildContent(item),
      ),
    );
  }
 
  Widget _buildContent(ItemResponse item) {
    final colors = widget.pocket.colors;
 
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          // --- Encabezado con sprite grande ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: item.spriteUrl != null
                        ? Image.network(
                            item.spriteUrl!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (context, error, stack) => const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: 56,
                            ),
                          )
                        // Muchos objetos nuevos no tienen sprite en la API.
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 56,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.categoryName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      categoryNameEs(item.categoryName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // --- Precio y poder al lanzar ---
          _SectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoItem(
                  icon: Icons.sell,
                  label: 'Precio',
                  value: item.cost > 0 ? '₽ ${item.cost}' : 'No se vende',
                  color: colors.first,
                ),
                if (item.flingPower != null)
                  _InfoItem(
                    icon: Icons.sports_baseball,
                    label: 'Poder al lanzar',
                    value: '${item.flingPower}',
                    color: colors.first,
                  ),
              ],
            ),
          ),
          // --- Descripción ---
          _SectionCard(
            title: 'Descripción',
            child: Text(
              item.description.isNotEmpty
                  ? item.description
                  : 'La API no tiene descripción para este objeto.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: item.description.isNotEmpty
                    ? Colors.black87
                    : Colors.black45,
              ),
            ),
          ),
          // --- Efecto (solo existe en inglés en la API) ---
          if (item.effect.isNotEmpty)
            _SectionCard(
              title: 'Efecto (en inglés)',
              child: Text(
                item.effect,
                style: const TextStyle(
                    fontSize: 14, height: 1.4, color: Colors.black87),
              ),
            ),
          // --- Características ---
          if (item.attributes.isNotEmpty)
            _SectionCard(
              title: 'Características',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.attributes
                    .map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.first.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            attributeNameEs(a),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.first,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          // --- Pokémon que lo llevan ---
          if (item.heldBy.isNotEmpty)
            _SectionCard(
              title: 'Pokémon salvajes que lo llevan',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.heldBy.take(24).map(_holderChip).toList(),
              ),
            ),
          if (item.heldBy.length > 24)
            Text(
              'y ${item.heldBy.length - 24} más',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
 
  // Chip de un Pokémon que lleva el objeto; al tocarlo abre su detalle
  // (solo si es un Pokémon "normal": las formas especiales tienen ids altos
  // y no existen como especie).
  Widget _holderChip(NamedResource holder) {
    final canOpen = holder.id > 0 && holder.id <= 1025;
    return ActionChip(
      label: Text(
        prettifyName(holder.name),
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
      backgroundColor: Colors.grey.shade200,
      onPressed: canOpen
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PokemonDetailScreen(
                    pokemonId: holder.id,
                    pokemonName: holder.name,
                  ),
                ),
              );
            }
          : null,
    );
  }
}
 
// Tarjeta blanca con título opcional. Usa colores explícitos para
// verse bien con cualquier tema.
class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
 
  const _SectionCard({this.title, required this.child});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}
 
// Ícono + valor + etiqueta, para precio y poder de lanzamiento.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
 
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}