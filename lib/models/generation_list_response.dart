// Importamos 'dart:convert' para poder usar json.decode(), que
// convierte un String en formato JSON a un Map de Dart que ya
// podemos leer con json['clave'].
import 'dart:convert';
 
// Esta clase representa la respuesta del endpoint
// /generation de la PokeAPI: la LISTA de todas las generaciones
// que existen (generación 1, 2, 3, etc.), sin sus detalles.
class GenerationListResponse {
  // Cuántas generaciones hay en total (dato que manda la propia API,
  // típico de los endpoints "de lista" de PokeAPI).
  final int count;
 
  // Url de la "siguiente página" de resultados, si es que hay paginación.
  // Es "String?" (con el signo de interrogación) porque puede ser null:
  // si ya estamos en la última página, la API manda next: null.
  final String? next;
 
  // Lo mismo pero para la página anterior: puede ser null si ya
  // estamos en la primera página.
  final String? previous;
 
  // La lista de generaciones en sí, cada una como un GenerationItem
  // (ver la clase de abajo).
  final List<GenerationItem> results;
 
  // Constructor: 'count' y 'results' son obligatorios (required),
  // mientras que 'next' y 'previous' son opcionales porque ya
  // aceptan null (no llevan 'required').
  GenerationListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
 
  //Metodo para recibir directamente el response.body (String)
  // Este factory recibe el texto crudo (tal como llega de http.get)
  // y primero lo decodifica con json.decode() antes de armar el objeto.
  factory GenerationListResponse.fromRawJson(String str) =>
  GenerationListResponse.fromJson(json.decode(str));
 
  //Metodo para recibir el Map ya decodificado
  // Este factory ya recibe un Map (no un String), y arma el objeto
  // leyendo cada clave del JSON.
  factory GenerationListResponse.fromJson(Map<String, dynamic> json) {
    // Sacamos la lista cruda de la clave "results". Si no viniera,
    // usamos una lista vacía [] gracias al operador ??.
    var list = json['results'] as List? ?? [];
 
    // Convertimos cada elemento de esa lista cruda (Maps) en un
    // objeto GenerationItem real, usando su propio fromJson.
    // .map() transforma uno por uno, y .toList() junta todo en una List.
    List<GenerationItem> resultsList = list.map((item) =>
    GenerationItem.fromJson(item)).toList();
 
    // Devolvemos el objeto final ya armado.
    return GenerationListResponse(
      // Si "count" no viene, usamos 0 como valor por defecto.
      count: json['count'] ?? 0,
      // 'next' y 'previous' no necesitan '??' porque ya son String?
      // (nullable): si vienen null en el JSON, simplemente quedan null.
      next: json['next'],
      previous: json['previous'],
      results: resultsList,
    );
  }
}
 
// Esta clase representa UNA generación dentro de la lista
// (solo trae nombre y url; para ver los Pokémon que contiene
// hay que ir a esa url, que es justo lo que hace
// GenerationDetailResponse).
class GenerationItem {
  // Nombre de la generación, ej: "generation-i".
  final String name;
  // Url completa para pedir el detalle de esta generación.
  final String url;
 
  // Constructor normal: ambos campos son obligatorios.
  GenerationItem({
    required this.name,
    required this.url,
  });
 
  // Igual que en la otra clase: recibe el String crudo y lo decodifica
  // antes de pasarlo al fromJson de abajo.
  factory GenerationItem.fromRawJson(String str) =>
  GenerationItem.fromJson(json.decode(str));
 
  // Arma el objeto a partir del Map ya decodificado, con valores
  // por defecto ('' string vacío) por si alguna clave faltara.
  factory GenerationItem.fromJson(Map<String, dynamic> json) {
    return GenerationItem(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }
 
  //En caso de querer mandarlo a nuestro backend, podemos convertirlo a json
  // Método inverso a fromJson: convierte este objeto Dart de vuelta
  // a un Map (por ejemplo, si quisiéramos mandarlo nosotros mismos
  // en el body de otra petición, o guardarlo en un archivo local).
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
 
  //Extraer el Id de la generacion directamente desde la URL
  // Getter: se usa como una propiedad (item.id, sin paréntesis),
  // pero en realidad calcula el valor cada vez que se pide,
  // en vez de guardarlo ya calculado desde el inicio.
  int get id {
    // Convertimos el String de la url en un objeto Uri, que nos
    // deja acceder fácilmente a sus distintas partes.
    final uri = Uri.parse(url);
 
    // pathSegments parte la url en pedazos separados por "/".
    // Ej: ".../generation/3/" -> ["generation", "3"].
    // El .where(...) quita los segmentos vacíos (por ejemplo el que
    // se genera si la url termina en "/").
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
 
    // El id siempre es el último segmento, lo tomamos con .last
    // y lo convertimos de String a int con int.parse().
    return int.parse(segments.last);
  }
 
}
