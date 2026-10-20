import 'package:flutter/material.dart';
 
import 'name_helpers.dart';
 
// Datos "de adorno" de cada bolsillo de la mochila. La API solo da el
// nombre técnico ("pokeballs"), así que el nombre en español, el ícono y
// los colores los definimos nosotros usando ese nombre como llave.
class PocketInfo {
  final String name;
  final IconData icon;
  final List<Color> colors;
 
  const PocketInfo({
    required this.name,
    required this.icon,
    required this.colors,
  });
}
 
const Map<String, PocketInfo> _pockets = {
  'misc': PocketInfo(
    name: 'Varios',
    icon: Icons.inventory_2,
    colors: [Color(0xFF546E7A), Color(0xFF90A4AE)],
  ),
  'medicine': PocketInfo(
    name: 'Medicinas',
    icon: Icons.medical_services,
    colors: [Color(0xFFD81B60), Color(0xFFF06292)],
  ),
  'pokeballs': PocketInfo(
    name: 'Poké Balls',
    icon: Icons.catching_pokemon,
    colors: [Color(0xFFD32F2F), Color(0xFFFF7043)],
  ),
  'machines': PocketInfo(
    name: 'MT y MO',
    icon: Icons.album,
    colors: [Color(0xFF3949AB), Color(0xFF7E57C2)],
  ),
  'berries': PocketInfo(
    name: 'Bayas',
    icon: Icons.eco,
    colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
  ),
  'mail': PocketInfo(
    name: 'Cartas',
    icon: Icons.mail,
    colors: [Color(0xFFE08A00), Color(0xFFFFB300)],
  ),
  'battle': PocketInfo(
    name: 'Combate',
    icon: Icons.flash_on,
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
  ),
  'key': PocketInfo(
    name: 'Objetos clave',
    icon: Icons.vpn_key,
    colors: [Color(0xFF6D4C41), Color(0xFFA1887F)],
  ),
};
 
// Devuelve los datos de un bolsillo; si la API trae uno que no conocemos,
// arma un estilo genérico con el color que le pasemos.
PocketInfo pocketInfoFor(String apiName, Color fallbackColor) {
  return _pockets[apiName] ??
      PocketInfo(
        name: prettifyName(apiName),
        icon: Icons.inventory_2,
        colors: [fallbackColor, fallbackColor.withValues(alpha: 0.6)],
      );
}
 
// Categorías de objetos (nombre técnico -> español). Las que no estén aquí
// se muestran con prettifyName, así que nada queda sin nombre.
const Map<String, String> _categoryNamesEs = {
  'stat-boosts': 'Mejoras de estadísticas',
  'effort-drop': 'Reducción de EV',
  'medicine': 'Medicina',
  'other': 'Otros',
  'in-a-pinch': 'En apuros',
  'picky-healing': 'Curación selectiva',
  'type-protection': 'Protección de tipo',
  'baking-only': 'Solo para hornear',
  'collectibles': 'Coleccionables',
  'evolution': 'Evolución',
  'spelunking': 'Espeleología',
  'held-items': 'Objetos equipables',
  'choice': 'Objetos de elección',
  'effort-training': 'Entrenamiento de EV',
  'bad-held-items': 'Equipables negativos',
  'training': 'Entrenamiento',
  'plates': 'Tablas',
  'species-specific': 'De una especie',
  'type-enhancement': 'Mejora de tipo',
  'event-items': 'Objetos de evento',
  'gameplay': 'Jugabilidad',
  'plot-advancement': 'Avance de trama',
  'unused': 'Sin usar',
  'loot': 'Botín',
  'all-mail': 'Cartas',
  'vitamins': 'Vitaminas',
  'healing': 'Curación',
  'pp-recovery': 'Recuperación de PP',
  'revival': 'Revivir',
  'status-cures': 'Curar estados',
  'mulch': 'Abono',
  'special-balls': 'Balls especiales',
  'standard-balls': 'Balls estándar',
  'dex-completion': 'Completar Pokédex',
  'scarves': 'Bufandas',
  'all-machines': 'Máquinas',
  'flutes': 'Flautas',
  'jewels': 'Gemas',
  'mega-stones': 'Megapiedras',
  'z-crystals': 'Cristales Z',
  'picnic': 'Picnic',
};
 
String categoryNameEs(String apiName) =>
    _categoryNamesEs[apiName] ?? prettifyName(apiName);
 
// Características de un objeto (nombre técnico -> español).
const Map<String, String> _attributeNamesEs = {
  'countable': 'Se puede apilar',
  'consumable': 'Consumible',
  'usable-overworld': 'Usable fuera de combate',
  'usable-in-battle': 'Usable en combate',
  'holdable': 'Equipable',
  'holdable-passive': 'Equipable (pasivo)',
  'holdable-active': 'Equipable (activo)',
  'underground': 'Se encuentra bajo tierra',
};
 
String attributeNameEs(String apiName) =>
    _attributeNamesEs[apiName] ?? prettifyName(apiName);