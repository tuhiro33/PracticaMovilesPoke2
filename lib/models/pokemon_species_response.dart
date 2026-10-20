// Importamos 'dart:convert' para usar json.decode(), que convierte
// el texto JSON en un Map de Dart que ya podemos leer.
import 'dart:convert';
 
// Esta clase representa la respuesta del endpoint
// /pokemon-species/{id} de la PokeAPI. De todo lo que trae ese
// endpoint, a nosotros solo nos interesan dos cosas:
// 1) la descripción (el texto tipo "Pokédex") y
// 2) la url de la cadena evolutiva de esa especie.
class PokemonSpeciesResponse {
  // Descripción ya "limpia" y lista para mostrar en pantalla.
  final String description;
 
  // Url completa para pedir después la cadena evolutiva
  // (se la pasamos tal cual a getEvolutionChain en el provider).
  final String evolutionChainUrl;
 
  // Constructor normal, ambos campos obligatorios.
  PokemonSpeciesResponse({
    required this.description,
    required this.evolutionChainUrl,
  });
 
  // Factory que recibe el String crudo y lo decodifica antes de
  // pasarlo al fromJson de abajo.
  factory PokemonSpeciesResponse.fromRawJson(String str) =>
      PokemonSpeciesResponse.fromJson(json.decode(str));
 
  // Factory que arma el objeto a partir del Map ya decodificado.
  factory PokemonSpeciesResponse.fromJson(Map<String, dynamic> json) {
    // "flavor_text_entries" es una LISTA larga con la MISMA descripción
    // repetida en distintos idiomas y distintas versiones del juego.
    // Cada elemento se ve más o menos así:
    // {
    //   "flavor_text": "Un extraño bulbo...",
    //   "language": { "name": "es" },
    //   "version": { "name": "red" }
    // }
    // Si la clave no viniera, usamos [] para no romper el resto del código.
    final entries = json['flavor_text_entries'] as List? ?? [];
 
    // Aquí iremos guardando la descripción final ya elegida y limpia.
    // Empieza vacía por si no encontramos ninguna coincidencia.
    String description = '';
 
    // Buscamos primero una descripción en español, si no existe usamos inglés.
    // Recorremos la lista ['es', 'en'] EN ESE ORDEN: primero intentamos
    // español, y solo si no encontramos nada útil, probamos inglés.
    for (final lang in ['es', 'en']) {
      // .cast<Map<String, dynamic>?>() le dice a Dart que trate cada
      // elemento de la lista como un Map (o null), para poder usar
      // firstWhere de forma segura sobre ellos.
      //
      // firstWhere busca el PRIMER elemento que cumpla la condición
      // que le pasamos: que el idioma de esa entrada (e?['language']?['name'])
      // sea igual al idioma que estamos probando en esta vuelta del for.
      //
      // Los '?.' son por seguridad: si 'e' fuera null, o si 'language'
      // no existiera dentro de 'e', esto da null en vez de tronar.
      //
      // 'orElse: () => null' le dice qué hacer si NO encuentra ninguna
      // coincidencia: en vez de lanzar un error (que es lo que haría
      // firstWhere por defecto), simplemente devuelve null.
      final match = entries.cast<Map<String, dynamic>?>().firstWhere(
            (e) => e?['language']?['name'] == lang,
            orElse: () => null,
          );
 
      // Si sí encontramos una entrada en este idioma...
      if (match != null) {
        // ...sacamos su texto y lo vamos "limpiando" encadenando
        // varios .replaceAll() uno tras otro:
        description = (match['flavor_text'] as String? ?? '')
            // La PokeAPI mete saltos de línea (\n) en medio del texto
            // para que se vea bien en la pantalla de un Game Boy,
            // pero en nuestra app eso se ve raro, así que los
            // cambiamos por espacios normales.
            .replaceAll('\n', ' ')
            // '\f' es un salto de página (form feed), otro carácter
            // "de videojuego viejo" que tampoco queremos que se vea.
            .replaceAll('\f', ' ')
            // '\u00ad' es el carácter de "guión suave" (soft hyphen),
            // uno invisible que a veces se cuela en textos y solo
            // causaría confusión, así que lo eliminamos por completo
            // (lo reemplazamos por '' en vez de por un espacio).
            .replaceAll('\u00ad', '')
            // .trim() quita espacios en blanco sobrantes al principio
            // y al final del texto (por ejemplo si quedó un espacio
            // extra después de reemplazar los \n).
            .trim();
 
        // Si después de limpiar el texto SÍ quedó algo (no está vacío),
        // ya no seguimos buscando en el siguiente idioma: cortamos
        // el for con 'break'. Si hubiera quedado vacío (raro, pero
        // por si acaso), seguimos probando con el siguiente idioma.
        if (description.isNotEmpty) break;
      }
    }
 
    // "evolution_chain" viene como un objeto pequeño: { "url": "..." }.
    // Lo sacamos como Map (o null si no viniera).
    final evolutionChain = json['evolution_chain'] as Map<String, dynamic>?;
 
    // Armamos el objeto final.
    return PokemonSpeciesResponse(
      description: description,
      // Si 'evolutionChain' fuera null, o si no tuviera 'url',
      // usamos '' (string vacío) como valor de respaldo con el '??'.
      evolutionChainUrl: evolutionChain?['url'] as String? ?? '',
    );
  }
}
