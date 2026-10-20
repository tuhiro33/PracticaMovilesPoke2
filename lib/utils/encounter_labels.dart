import 'name_helpers.dart';
 
// Cómo se encuentra un Pokémon (nombre técnico de la API -> español).
// Los métodos que no estén aquí se muestran con prettifyName.
const Map<String, String> _methodNamesEs = {
  'walk': 'Caminando',
  'old-rod': 'Caña vieja',
  'good-rod': 'Caña buena',
  'super-rod': 'Supercaña',
  'surf': 'Surf',
  'rock-smash': 'Golpe Roca',
  'headbutt': 'Cabezazo',
  'dark-grass': 'Hierba oscura',
  'grass-spots': 'Hierba agitada',
  'cave-spots': 'Polvo de cueva',
  'bridge-spots': 'Sombra en puente',
  'surf-spots': 'Surf (zona agitada)',
  'super-rod-spots': 'Pesca (zona agitada)',
  'yellow-flowers': 'Flores amarillas',
  'purple-flowers': 'Flores moradas',
  'red-flowers': 'Flores rojas',
  'rough-terrain': 'Terreno irregular',
  'gift': 'Regalo',
  'gift-egg': 'Huevo regalo',
  'only-one': 'Único',
  'pokeflute': 'Poké Flauta',
  'roaming-grass': 'Errante (hierba)',
  'roaming-water': 'Errante (agua)',
  'sos-encounter': 'Llamada SOS',
};
 
String methodNameEs(String method) =>
    _methodNamesEs[method] ?? prettifyName(method);
 
// Nombres de los juegos (versiones) en español.
const Map<String, String> _versionNamesEs = {
  'red': 'Rojo',
  'blue': 'Azul',
  'yellow': 'Amarillo',
  'gold': 'Oro',
  'silver': 'Plata',
  'crystal': 'Cristal',
  'ruby': 'Rubí',
  'sapphire': 'Zafiro',
  'emerald': 'Esmeralda',
  'firered': 'Rojo Fuego',
  'leafgreen': 'Verde Hoja',
  'diamond': 'Diamante',
  'pearl': 'Perla',
  'platinum': 'Platino',
  'heartgold': 'Oro HeartGold',
  'soulsilver': 'Plata SoulSilver',
  'black': 'Negro',
  'white': 'Blanco',
  'black-2': 'Negro 2',
  'white-2': 'Blanco 2',
  'x': 'X',
  'y': 'Y',
  'omega-ruby': 'Rubí Omega',
  'alpha-sapphire': 'Zafiro Alfa',
  'sun': 'Sol',
  'moon': 'Luna',
  'ultra-sun': 'Ultra Sol',
  'ultra-moon': 'Ultra Luna',
  'lets-go-pikachu': "Let's Go Pikachu",
  'lets-go-eevee': "Let's Go Eevee",
  'sword': 'Espada',
  'shield': 'Escudo',
  'brilliant-diamond': 'Diamante Brillante',
  'shining-pearl': 'Perla Reluciente',
  'legends-arceus': 'Leyendas Arceus',
  'scarlet': 'Escarlata',
  'violet': 'Púrpura',
};
 
String versionNameEs(String version) =>
    _versionNamesEs[version] ?? prettifyName(version);
 