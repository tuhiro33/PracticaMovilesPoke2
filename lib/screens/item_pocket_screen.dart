import 'package:flutter/material.dart';
 
import '../models/item_response.dart';
import '../models/region_response.dart';
import '../providers/poke_api_provider.dart';
import '../utils/item_cache.dart';
import '../utils/item_info.dart';
import '../utils/name_helpers.dart';
import '../widgets/future_view.dart';
import 'item_detail_screen.dart';
 
// Un bolsillo de la mochila: arriba las categorías (chips deslizables) y
// abajo una cuadrícula con los objetos de la categoría elegida.
class ItemPocketScreen extends StatefulWidget {
  final int pocketId;
  final String pocketName; // nombre técnico de la API, ej. "pokeballs"
 
  const ItemPocketScreen({
    super.key,
    required this.pocketId,
    required this.pocketName,
  });
 
  @override
  State<ItemPocketScreen> createState() => _ItemPocketScreenState();
}
 
class _ItemPocketScreenState extends State<ItemPocketScreen> {
  final PokeApiProvider _api = PokeApiProvider();
  late Future<ItemPocketResponse> _pocketFuture;
 
  // Futures de las categorías ya pedidas, para no repetir la descarga
  // si el usuario va y viene entre chips.
  final Map<int, Future<ItemCategoryResponse>> _categoryCache = {};
  int? _selectedCategoryId;
 
  @override
  void initState() {
    super.initState();
    _pocketFuture = _loadPocket();
  }
 
  Future<ItemPocketResponse> _loadPocket() async {
    final response = await _api.getItemPocketDetail(widget.pocketId);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return ItemPocketResponse.fromRawJson(response.body);
  }
 
  Future<ItemCategoryResponse> _loadCategory(int id) async {
    final response = await _api.getItemCategoryDetail(id);
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return ItemCategoryResponse.fromRawJson(response.body);
  }
 
  Future<ItemCategoryResponse> _categoryFuture(int id) =>
      _categoryCache.putIfAbsent(id, () => _loadCategory(id));
 
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final info = pocketInfoFor(widget.pocketName, primary);
 
    return Scaffold(
      appBar: AppBar(title: Text(info.name)),
      body: FutureView<ItemPocketResponse>(
        future: _pocketFuture,
        onRetry: () => setState(() {
          _pocketFuture = _loadPocket();
        }),
        builder: (context, pocket) {
          if (pocket.categories.isEmpty) {
            return const InfoMessage(
              icon: Icons.inventory_2_outlined,
              text: 'Este bolsillo no tiene categorías registradas.',
            );
          }
 
          // Si todavía no se eligió categoría, usamos la primera.
          final selectedId = _selectedCategoryId ?? pocket.categories.first.id;
 
          return Column(
            children: [
              _buildCategoryChips(pocket, selectedId, info),
              Expanded(
                child: FutureView<ItemCategoryResponse>(
                  // La key hace que Flutter trate cada categoría como una
                  // vista nueva al cambiar de chip.
                  key: ValueKey(selectedId),
                  future: _categoryFuture(selectedId),
                  onRetry: () => setState(() {
                    _categoryCache.remove(selectedId);
                  }),
                  builder: (context, category) =>
                      _buildItems(category, info),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
 
  // Fila deslizable de chips, uno por categoría.
  Widget _buildCategoryChips(
      ItemPocketResponse pocket, int selectedId, PocketInfo info) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: pocket.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = pocket.categories[index];
          final selected = category.id == selectedId;
          return Center(
            child: ChoiceChip(
              label: Text(
                categoryNameEs(category.name),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              showCheckmark: false,
              selectedColor: info.colors.first,
              backgroundColor: Colors.white,
              onSelected: (_) =>
                  setState(() => _selectedCategoryId = category.id),
            ),
          );
        },
      ),
    );
  }
 
  Widget _buildItems(ItemCategoryResponse category, PocketInfo info) {
    if (category.items.isEmpty) {
      return const InfoMessage(
        icon: Icons.search_off,
        text: 'No hay objetos en esta categoría.',
      );
    }
 
    final onSurface = Theme.of(context).colorScheme.onSurface;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            '${category.items.length} objetos',
            style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
          ),
        ),
        // GridView.builder es "perezoso": solo construye las casillas que
        // se ven en pantalla, así que solo esas piden su detalle a la API.
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: category.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = category.items[index];
              return _ItemTile(
                item: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(
                        itemId: item.id,
                        itemName: item.name,
                        pocket: info,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
 
// Casilla de un objeto: sprite y nombre. Al aparecer en pantalla pide el
// detalle del objeto (a través de la caché) para mostrar su nombre en
// español y su sprite. Mientras carga, muestra el nombre técnico arreglado.
class _ItemTile extends StatelessWidget {
  final NamedResource item;
  final VoidCallback onTap;
 
  const _ItemTile({required this.item, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
 
    return Material(
      // Mismos colores que las tarjetas de la pantalla de generaciones,
      // así se respeta la paleta de tu tema.
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FutureBuilder<ItemResponse>(
            future: ItemCache.get(item.id),
            builder: (context, snapshot) {
              final data = snapshot.data;
              final title = data?.displayName ?? prettifyName(item.name);
              final sprite = data?.spriteUrl;
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
 
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: sprite != null
                          ? Image.network(
                              sprite,
                              width: 56,
                              height: 56,
                              fit: BoxFit.contain,
                              // Los sprites son pixel art pequeño: sin
                              // suavizado se ven nítidos al agrandarlos.
                              filterQuality: FilterQuality.none,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.inventory_2_outlined,
                                color: colorScheme.secondary,
                              ),
                            )
                          : loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.inventory_2_outlined,
                                  color: colorScheme.secondary,
                                ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}