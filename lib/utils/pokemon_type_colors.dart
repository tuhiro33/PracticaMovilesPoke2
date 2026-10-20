// Necesitamos material.dart aquí solo por la clase 'Color',
// que es la que usamos para representar los colores de cada tipo.
import 'package:flutter/material.dart';
 
/// Color representativo de cada tipo de Pokémon, usado para el fondo
/// dinámico de la pantalla de detalle.
//
// Este comentario con '///' (tres barras) es un "doc comment":
// un tipo especial de comentario que herramientas como el editor
// o "dart doc" pueden mostrar como documentación oficial de esta
// variable, a diferencia de un comentario normal con '//'.
//
// 'const' significa que este Map se crea UNA sola vez, en tiempo de
// compilación, y nunca cambia ni se vuelve a crear en memoria
// (a diferencia de 'final', que se calcula una vez en tiempo de
// ejecución pero podría depender de algo que varíe). Como aquí
// todos los valores son fijos y conocidos de antemano, 'const' es
// la opción más eficiente.
//
// Es un Map<String, Color>: la "llave" es el nombre del tipo tal
// como lo manda la PokeAPI en inglés y en minúsculas (ej: "fire"),
// y el "valor" es el Color que le corresponde.
const Map<String, Color> pokemonTypeColors = {
  // Cada Color se crea con Color(0xFF......): el "0xFF" son los
  // primeros dos dígitos hexadecimales, que representan la opacidad
  // (FF = 100% opaco), y los 6 dígitos que siguen son el color en
  // formato RRGGBB (rojo, verde, azul), igual que en CSS/diseño web.
  'normal': Color(0xFFA8A878),
  'fire': Color(0xFFF08030),
  'water': Color(0xFF6890F0),
  'electric': Color(0xFFF8D030),
  'grass': Color(0xFF78C850),
  'ice': Color(0xFF98D8D8),
  'fighting': Color(0xFFC03028),
  'poison': Color(0xFFA040A0),
  'ground': Color(0xFFE0C068),
  'flying': Color(0xFFA890F0),
  'psychic': Color(0xFFF85888),
  'bug': Color(0xFFA8B820),
  'rock': Color(0xFFB8A038),
  'ghost': Color(0xFF705898),
  'dragon': Color(0xFF7038F8),
  'dark': Color(0xFF705848),
  'steel': Color(0xFFB8B8D0),
  'fairy': Color(0xFFEE99AC),
};
 
// Esta es una FUNCIÓN "de nivel superior" (top-level function): no
// está dentro de ninguna clase, así que se puede llamar directamente
// desde cualquier archivo que importe este, solo con colorForType(...),
// sin necesidad de instanciar nada ni escribir NombreDeClase.colorForType(...).
//
// Es una función "flecha" (=>): una forma corta de escribir una función
// que solo tiene una expresión como cuerpo, equivalente a escribir:
// Color colorForType(String type) {
//   return pokemonTypeColors[type] ?? const Color(0xFF5345AB);
// }
//
// pokemonTypeColors[type] busca ese tipo en el Map de arriba. Si el
// tipo no existiera ahí (por ejemplo, si la API agregara un tipo nuevo
// que no está en nuestra lista), el resultado sería 'null', y ahí
// entra el '??' para devolver un morado genérico como valor de respaldo
// en vez de dejar que la app truene al intentar usar un color 'null'.
Color colorForType(String type) =>
    pokemonTypeColors[type] ?? const Color(0xFF5345AB);
 
// El guion bajo '_' al inicio del nombre hace que este Map sea
// PRIVADO a este archivo: ningún otro archivo del proyecto puede
// acceder directamente a '_pokemonTypeNamesEs', solo a través de la
// función pública typeNameEs(...) de aquí abajo. Esto es intencional:
// afuera de este archivo no debería importar CÓMO se traduce cada
// tipo, solo que existe una forma de pedir la traducción.
const Map<String, String> _pokemonTypeNamesEs = {
  // Aquí la llave sigue siendo el nombre en inglés que manda la API,
  // pero ahora el valor es el nombre en español que queremos mostrar
  // en la interfaz (en los chips de tipo, por ejemplo).
  'normal': 'Normal',
  'fire': 'Fuego',
  'water': 'Agua',
  'electric': 'Eléctrico',
  'grass': 'Planta',
  'ice': 'Hielo',
  'fighting': 'Lucha',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'flying': 'Volador',
  'psychic': 'Psíquico',
  'bug': 'Bicho',
  'rock': 'Roca',
  'ghost': 'Fantasma',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'steel': 'Acero',
  'fairy': 'Hada',
};
 
// Función pública que "envuelve" el acceso al Map privado de arriba.
// Si el tipo no estuviera en nuestra lista de traducciones, el '??'
// hace que se devuelva el nombre en inglés tal cual (mejor mostrar
// "fire" que no mostrar nada o hacer que la app truene).
String typeNameEs(String type) => _pokemonTypeNamesEs[type] ?? type;
 
// Mismo patrón que con los tipos, pero ahora para traducir los
// nombres técnicos de los stats base (los que vienen en
// PokemonStat.name) a nombres cortos en español para mostrarlos
// en las barras de estadísticas.
const Map<String, String> _pokemonStatNamesEs = {
  'hp': 'PS', // "Puntos de Salud", el nombre clásico en los juegos en español
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'At. Especial',
  'special-defense': 'Def. Especial',
  'speed': 'Velocidad',
};
 
// Igual que typeNameEs: si el stat no estuviera en el Map (no debería
// pasar, ya que la API siempre manda estos 6 stats), devolvemos el
// nombre técnico original en vez de tronar.
String statNameEs(String stat) => _pokemonStatNamesEs[stat] ?? stat;
