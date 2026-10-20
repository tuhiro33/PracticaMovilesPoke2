// Necesitamos 'dart:convert' porque trae la función json.decode(),
// que convierte un String en formato JSON (texto) a un Map de Dart
// (algo así como un diccionario) que ya podemos leer con json['clave'].
import 'dart:convert';
 
// Esta clase representa la respuesta completa del endpoint
// /evolution-chain/{id} de la PokeAPI, pero ya "traducida" a un
// formato simple: una lista plana con cada etapa de evolución.
class EvolutionChainResponse {
  // Lista de nodos de evolución, en el orden en que van evolucionando.
  // 'final' significa que una vez creado el objeto, esta lista no cambia.
  final List<EvolutionNode> chain;
 
  // Constructor de la clase. 'required this.chain' obliga a que,
  // cada vez que creemos un EvolutionChainResponse, le pasemos la lista.
  EvolutionChainResponse({required this.chain});
 
  // Factory constructor: es un constructor especial que en vez de
  // simplemente asignar valores, hace un trabajo extra antes de
  // devolver el objeto. Este recibe el String "crudo" (raw) que
  // devuelve la API (todavía en formato texto JSON).
  factory EvolutionChainResponse.fromRawJson(String str) =>
      // Lo decodificamos con json.decode(), que nos da un Map,
      // y se lo pasamos al otro factory (fromJson) de abajo.
      EvolutionChainResponse.fromJson(json.decode(str));
 
  // Este factory recibe el JSON ya convertido en Map<String, dynamic>
  // (o sea, ya no es texto, ya es una estructura de datos de Dart)
  // y arma el objeto EvolutionChainResponse.
  factory EvolutionChainResponse.fromJson(Map<String, dynamic> json) {
    // Sacamos el objeto "chain" del JSON, que es el nodo raíz
    // del árbol de evoluciones (el Pokémon base, ej. Bulbasaur).
    // El "as Map<String, dynamic>?" le dice a Dart que esperamos
    // un Map, pero puede ser null si no viniera (por eso el '?').
    final rootChain = json['chain'] as Map<String, dynamic>?;
 
    // Esta es la lista donde vamos a ir guardando cada especie
    // (cada etapa de evolución) a medida que recorremos el árbol.
    // Empieza vacía.
    final List<EvolutionNode> flatList = [];
 
    // Función interna (definida aquí adentro, solo se usa en este método)
    // que recorre el árbol de evoluciones de forma recursiva.
    // "Recursiva" quiere decir que la función se llama a sí misma
    // para bajar un nivel más en el árbol cada vez.
    void traverse(Map<String, dynamic>? node) {
      // Caso base de la recursión: si no hay nodo (llegamos al final
      // de una rama, o el nodo raíz vino vacío), simplemente salimos.
      if (node == null) return;
 
      // Cada nodo del árbol tiene una clave "species" con el nombre
      // y la url de esa especie/Pokémon (ej. { name: "bulbasaur", url: ... }).
      final species = node['species'] as Map<String, dynamic>?;
 
      // Si sí trae species, creamos un EvolutionNode a partir de eso
      // y lo agregamos a nuestra lista plana.
      if (species != null) {
        flatList.add(EvolutionNode.fromJson(species));
      }
 
      // Cada nodo también tiene "evolves_to", que es una LISTA de
      // los siguientes nodos a los que puede evolucionar (puede tener
      // más de uno si es una evolución ramificada, como Eevee).
      // Si no viene, usamos una lista vacía [] para no romper el for.
      final evolvesTo = node['evolves_to'] as List? ?? [];
 
      // Recorremos cada uno de esos siguientes nodos...
      for (final next in evolvesTo) {
        // ...y llamamos de nuevo a traverse() con ese nodo,
        // para que siga bajando por el árbol (por eso es recursiva).
        traverse(next as Map<String, dynamic>);
      }
    }
 
    // Arrancamos el recorrido desde la raíz del árbol.
    traverse(rootChain);
 
    // Devolvemos el objeto final, ya con la lista plana llena.
    return EvolutionChainResponse(chain: flatList);
  }
}
 
// Esta clase representa UNA sola etapa/especie dentro de la cadena
// evolutiva (por ejemplo: solo "bulbasaur", con su nombre y su url).
class EvolutionNode {
  // Nombre de la especie, ej: "bulbasaur".
  final String name;
  // Url completa de esa especie en la API, ej:
  // "https://pokeapi.co/api/v2/pokemon-species/1/"
  final String url;
 
  // Constructor normal, pide nombre y url obligatorios.
  EvolutionNode({required this.name, required this.url});
 
  // Factory que arma un EvolutionNode a partir del Map de JSON
  // que viene dentro de "species" en cada nodo del árbol.
  factory EvolutionNode.fromJson(Map<String, dynamic> json) {
    return EvolutionNode(
      // Si json['name'] viniera null, usamos '' como valor por defecto
      // gracias al operador ?? (esto evita errores si algo falta).
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }
 
  // Esto es un "getter": se comporta como si fuera una propiedad
  // (se usa como nodo.id, sin paréntesis) pero en realidad calcula
  // el valor cada vez que lo pedimos, en vez de guardarlo fijo.
  int get id {
    // Convertimos el String de la url en un objeto Uri, que nos
    // permite acceder fácilmente a sus distintas partes.
    final uri = Uri.parse(url);
 
    // pathSegments nos da la url partida en pedazos separados por "/".
    // Ej: para ".../pokemon-species/1/" nos da ["pokemon-species", "1"].
    // El .where((s) => s.isNotEmpty) filtra los segmentos vacíos
    // (por ejemplo si la url termina en "/", eso generaría un "" extra).
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
 
    // El id siempre es el último segmento de la url, así que lo tomamos
    // y lo convertimos de String a int con int.parse().
    return int.parse(segments.last);
  }
}
