// Igual que en los otros modelos, importamos 'dart:convert' para poder
// usar json.decode(), que transforma un String JSON en un Map de Dart.
import 'dart:convert';
 
// Esta clase representa la respuesta del endpoint
// /generation/{id} de la PokeAPI: el detalle de UNA generación
// (por ejemplo, la generación 1), incluyendo la lista de especies
// de Pokémon que pertenecen a ella.
class GenerationDetailResponse {
  // Ojo: aquí 'id' no tiene tipo declarado (no dice "int id" ni
  // "String id"), así que Dart lo trata como tipo "dynamic",
  // es decir, puede guardar cualquier tipo de valor. Funciona,
  // pero no es lo más recomendable: sería más seguro declararlo
  // como "final int id;" para que el compilador nos avise si
  // en algún lado lo usamos mal (por ejemplo si esperamos un int
  // y por error llega un String).
  final id;
 
  // Nombre de la generación, ej: "generation-i".
  final String name;
 
  // Lista de todas las especies de Pokémon que pertenecen
  // a esta generación (cada una con nombre y url, ver la clase
  // PokemonSpeciesItem más abajo).
  final List<PokemonSpeciesItem> pokemonSpecies;
 
  // Constructor: los tres campos son obligatorios ('required')
  // al momento de crear un GenerationDetailResponse.
  GenerationDetailResponse({
    required this.id,
    required this.name,
    required this.pokemonSpecies
  });
 
  // Factory que recibe el String "crudo" (tal cual lo manda la API,
  // como texto) y lo decodifica antes de pasarlo al fromJson de abajo.
  factory GenerationDetailResponse.fromRawJson(String str) => GenerationDetailResponse.fromJson(json.decode(str));
 
  // Factory que arma el objeto a partir del Map ya decodificado.
  factory GenerationDetailResponse.fromJson(Map<String, dynamic> json) {
    // Sacamos la lista cruda que viene en la clave "pokemon_species".
    // Si no viniera (fuera null), usamos una lista vacía [] con el ??
    // para que el resto del código no truene.
    var list = json['pokemon_species'] as List? ?? [];
 
    // Recorremos esa lista cruda (de Maps) y convertimos cada elemento
    // en un objeto PokemonSpeciesItem usando su propio fromJson.
    // .map() transforma cada elemento, y .toList() junta el resultado
    // en una lista de verdad (map por sí solo da un Iterable, no una List).
    List<PokemonSpeciesItem> speciesList = list.map((i) => PokemonSpeciesItem.fromJson(i)).toList();
    
    // Devolvemos el objeto final ya armado.
    return GenerationDetailResponse(
      // Si "id" no viene en el JSON, usamos 0 como valor por defecto.
      id: json["id"] ?? 0, 
      // Si "name" no viene, usamos '' (string vacío) como valor por defecto.
      name: json['name'] ?? '', 
      pokemonSpecies: speciesList
    );
  }
 
  // Método inverso a fromJson: convierte este objeto Dart de vuelta
  // a un Map (que luego se podría volver a codificar a JSON con
  // json.encode() si quisiéramos, por ejemplo, guardarlo en un archivo
  // o mandarlo en el body de otra petición).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    // Igual que arriba pero al revés: convertimos cada PokemonSpeciesItem
    // otra vez a Map usando su propio toJson().
    'pokemon_species': pokemonSpecies.map((x) => x.toJson()).toList()
  };
}
 
// Esta clase representa UN elemento dentro de la lista "pokemon_species":
// solo trae el nombre y la url de esa especie (la API no manda aquí
// todos los detalles, para eso hay que ir a esa url por separado,
// que es justo lo que hace PokemonSpeciesResponse).
class PokemonSpeciesItem {
  final String name;
  final String url;
 
  // Constructor normal, ambos campos obligatorios.
  PokemonSpeciesItem({
    required this.name,
    required this.url
  });
 
  // Igual que en la otra clase: recibe el string crudo y lo decodifica.
  factory PokemonSpeciesItem.fromRawJson(String str) => PokemonSpeciesItem.fromJson(json.decode(str));
 
  // Arma el objeto a partir del Map ya decodificado.
  // Nota: aquí NO se usa "??" como valor por defecto (a diferencia de
  // GenerationDetailResponse.fromJson). Eso significa que si "name" o
  // "url" vinieran null, esto lanzaría un error en tiempo de ejecución.
  // Como la PokeAPI siempre manda estos dos campos, en la práctica
  // no debería pasar, pero es menos "a prueba de fallos" que el resto.
  factory PokemonSpeciesItem.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesItem(
      name: json['name'], 
      url: json['url']
    );
  }
 
  // Convierte de vuelta a Map, por si se necesita re-serializar.
  Map<String, dynamic> toJson() => {
    "name": name,
    "url": url
  };
 
  // Getter: se usa como una propiedad (item.id) pero calcula el valor
  // "al vuelo" cada vez, en vez de guardarlo ya calculado.
  // Extraer el ID del pokemon desde la url
  int get id {
    // Convertimos el String de la url en un objeto Uri para poder
    // acceder fácilmente a sus distintas partes (dominio, path, etc).
    final uri = Uri.parse(url);
 
    // pathSegments parte la url en pedazos separados por "/".
    // Ej: ".../pokemon-species/25/" -> ["pokemon-species", "25"].
    // El .where(...) descarta los segmentos vacíos (por si la url
    // termina en "/", lo cual generaría un elemento "" extra al final).
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
 
    // El id siempre queda como el último segmento de la url,
    // así que lo tomamos con .last y lo convertimos de String a int.
    return int.parse(segments.last);
  }
}
