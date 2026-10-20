import 'package:flutter/material.dart';
 
import 'name_helpers.dart';
 
// Datos "de adorno" de cada región. La API solo da el nombre técnico
// ("unova"), así que el nombre en español, los iniciales y los colores
// los definimos nosotros usando ese nombre técnico como llave.
class RegionInfo {
  final String name; // nombre en español
  final String subtitle; // generación o juego asociado
  final List<int> starters; // ids de los 3 iniciales
  final List<Color> colors; // degradado
 
  const RegionInfo({
    required this.name,
    required this.subtitle,
    required this.starters,
    required this.colors,
  });
}
 
const Map<String, RegionInfo> _regions = {
  'kanto': RegionInfo(
    name: 'Kanto',
    subtitle: 'Generación I',
    starters: [1, 4, 7],
    colors: [Color(0xFFD32F2F), Color(0xFFFF7043)],
  ),
  'johto': RegionInfo(
    name: 'Johto',
    subtitle: 'Generación II',
    starters: [152, 155, 158],
    colors: [Color(0xFFE08A00), Color(0xFFFFB300)],
  ),
  'hoenn': RegionInfo(
    name: 'Hoenn',
    subtitle: 'Generación III',
    starters: [252, 255, 258],
    colors: [Color(0xFF00897B), Color(0xFF26C6DA)],
  ),
  'sinnoh': RegionInfo(
    name: 'Sinnoh',
    subtitle: 'Generación IV',
    starters: [387, 390, 393],
    colors: [Color(0xFF3949AB), Color(0xFF7E57C2)],
  ),
  'unova': RegionInfo(
    name: 'Teselia',
    subtitle: 'Generación V',
    starters: [495, 498, 501],
    colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
  ),
  'kalos': RegionInfo(
    name: 'Kalos',
    subtitle: 'Generación VI',
    starters: [650, 653, 656],
    colors: [Color(0xFFEC407A), Color(0xFF5C6BC0)],
  ),
  'alola': RegionInfo(
    name: 'Alola',
    subtitle: 'Generación VII',
    starters: [722, 725, 728],
    colors: [Color(0xFFF57C00), Color(0xFF26A69A)],
  ),
  'galar': RegionInfo(
    name: 'Galar',
    subtitle: 'Generación VIII',
    starters: [810, 813, 816],
    colors: [Color(0xFF1565C0), Color(0xFFD81B60)],
  ),
  'hisui': RegionInfo(
    name: 'Hisui',
    subtitle: 'Leyendas Arceus',
    starters: [722, 155, 501],
    colors: [Color(0xFF37474F), Color(0xFF8D6E63)],
  ),
  'paldea': RegionInfo(
    name: 'Paldea',
    subtitle: 'Generación IX',
    starters: [906, 909, 912],
    colors: [Color(0xFFC62828), Color(0xFF7B1FA2)],
  ),
};
 
// Devuelve los datos de una región; si la API trae una que no conocemos,
// arma un estilo genérico con el color que le pasemos.
RegionInfo regionInfoFor(String apiName, Color fallbackColor) {
  return _regions[apiName] ??
      RegionInfo(
        name: prettifyName(apiName),
        subtitle: 'Región',
        starters: const [],
        colors: [fallbackColor, fallbackColor.withValues(alpha: 0.6)],
      );
}
 
String pokemonArtworkUrl(int id) =>
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
 