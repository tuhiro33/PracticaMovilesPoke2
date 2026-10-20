// Importamos 'dart:convert' para usar json.decode(), que convierte
// el texto JSON que manda la API en un Map de Dart que ya podemos leer.
import 'dart:convert';
 
// Esta clase representa la respuesta del endpoint /pokemon/{id}
// de la PokeAPI: todo el detalle de un Pokémon en específico
// (altura, peso, tipos, stats, movimientos, sprite y sonido).
class PokemonDetailResponse {
  final int id;
  final String name;
  final int height; // en decímetros (tal como lo entrega la API)
  final int weight; // en hectogramos (tal como lo entrega la API)
  final int baseExperience;
 
  // Estos dos son "String?" (con el signo de interrogación) porque
  // pueden ser null: no todos los Pokémon tienen artwork oficial
  // o sonido disponible, así que la app tiene que estar preparada
  // para ese caso (por eso en la pantalla se usa spriteUrl != null antes
  // de intentar mostrar la imagen).
  final String? spriteUrl;
  final String? cryUrl;
 
  // Lista simple con los nombres de los tipos, ej: ["grass", "poison"].
  final List<String> types;
 
  // Lista de stats base (PS, Ataque, Defensa, etc.), cada uno como
  // un objeto PokemonStat (ver la clase de abajo).
  final List<PokemonStat> stats;
 
  // Lista simple con los nombres de todos los movimientos que puede
  // aprender este Pokémon (en cualquier juego/versión).
  final List<String> moves;
 
  // Habilidades del Pokémon: solo el nombre y si es oculta o no.
  // La descripción de cada una se pide aparte (endpoint /ability/{name}).
  final List<PokemonAbilityRef> abilities;
 
  // Constructor: todos los campos son obligatorios ('required'),
  // incluso spriteUrl y cryUrl (que sí pueden valer null, pero
  // igual hay que pasarlos explícitamente al crear el objeto,
  // aunque sea pasando null).
  PokemonDetailResponse({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.spriteUrl,
    required this.cryUrl,
    required this.types,
    required this.stats,
    required this.moves,
    required this.abilities,
  });
 
  // Factory que recibe el String crudo (como llega de http.get)
  // y lo decodifica antes de pasarlo al fromJson de abajo.
  factory PokemonDetailResponse.fromRawJson(String str) =>
      PokemonDetailResponse.fromJson(json.decode(str));
 
  // Factory que arma el objeto a partir del Map ya decodificado.
  // Este es el método más largo de todo el proyecto porque el JSON
  // de /pokemon/{id} viene con varios niveles anidados (sprites
  // dentro de sprites, tipos dentro de listas, etc), así que hay
  // que ir "desenvolviendo" cada capa antes de sacar el dato final.
  factory PokemonDetailResponse.fromJson(Map<String, dynamic> json) {
    // --- SPRITES (imágenes) ---
    // La estructura real que manda la API es algo así:
    // "sprites": {
    //   "front_default": "url...",
    //   "other": {
    //     "official-artwork": { "front_default": "url..." }
    //   }
    // }
    // Por eso hay que ir bajando nivel por nivel con variables intermedias.
 
    // Sacamos "sprites"; si no viniera, usamos {} (Map vacío) para
    // que las siguientes líneas no truenen al intentar leer sub-claves.
    final sprites = json['sprites'] as Map<String, dynamic>? ?? {};
 
    // Dentro de sprites, sacamos "other" (ahí vive el artwork oficial).
    final other = sprites['other'] as Map<String, dynamic>? ?? {};
 
    // Dentro de "other", sacamos "official-artwork".
    final officialArtwork =
        other['official-artwork'] as Map<String, dynamic>? ?? {};
 
    // Y finalmente, dentro de eso, la url de la imagen en sí.
    // Puede ser null si ese Pokémon no tiene artwork oficial.
    final artworkUrl = officialArtwork['front_default'] as String?;
 
    // Como respaldo, también guardamos el sprite "normal" (más
    // pequeño/pixelado), por si el artwork oficial no existiera.
    final frontDefault = sprites['front_default'] as String?;
 
    // --- SONIDO (cries) ---
    // "cries": { "latest": "url...", "legacy": "url..." }
    // Aquí sí puede ser que ni siquiera exista la clave "cries",
    // por eso el "as Map<String, dynamic>?" (sin "?? {}"): dejamos
    // que 'cries' sea null si no viene, y usamos el operador '?.'
    // más abajo para leerlo con seguridad.
    final cries = json['cries'] as Map<String, dynamic>?;
 
    // --- TIPOS ---
    // "types" viene como una lista de objetos, cada uno con esta forma:
    // { "slot": 1, "type": { "name": "grass", "url": "..." } }
    // Necesitamos solo el nombre de cada tipo, así que:
    final typesList = (json['types'] as List? ?? [])
        // Por cada elemento 't' de la lista, entramos a t['type']
        // y de ahí sacamos ['name']. Lo forzamos a "String" con "as String"
        // porque sabemos que ahí siempre va a venir un texto.
        .map((t) => t['type']['name'] as String)
        .toList();
 
    // --- STATS ---
    // "stats" viene como una lista de objetos con esta forma:
    // { "base_stat": 45, "effort": 0, "stat": { "name": "hp", ... } }
    // Por cada uno, creamos un PokemonStat usando su propio fromJson
    // (así no repetimos la lógica de extracción aquí mismo).
    final statsList =
        (json['stats'] as List? ?? []).map((s) => PokemonStat.fromJson(s)).toList();
 
    // --- MOVIMIENTOS ---
    // "moves" viene como una lista de objetos con esta forma:
    // { "move": { "name": "tackle", "url": "..." }, "version_group_details": [...] }
    // Solo nos interesa el nombre del movimiento.
    final movesList = (json['moves'] as List? ?? [])
        .map((m) => m['move']['name'] as String)
        .toList();
 
    // --- HABILIDADES ---
    // "abilities" viene como una lista de objetos con esta forma:
    // { "ability": { "name": "overgrow", "url": "..." }, "is_hidden": false, "slot": 1 }
    final abilitiesList = (json['abilities'] as List? ?? [])
        .map((a) => PokemonAbilityRef(
              name: a['ability']['name'] as String,
              isHidden: a['is_hidden'] as bool? ?? false,
            ))
        .toList();
 
    // Ya con todo "desenvuelto" y limpio, armamos el objeto final.
    return PokemonDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      baseExperience: json['base_experience'] ?? 0,
      // Preferimos el artwork oficial; si no existe (fuera null),
      // usamos el sprite normal como respaldo con el operador ??.
      spriteUrl: artworkUrl ?? frontDefault,
      // Preferimos el sonido "latest"; si no existe, probamos "legacy".
      // El '?.' evita un error si 'cries' completo fuera null
      // (en ese caso, cries?['latest'] simplemente da null en vez
      // de tronar, y seguimos al siguiente intento con 'legacy').
      cryUrl: cries?['latest'] as String? ?? cries?['legacy'] as String?,
      types: typesList,
      stats: statsList,
      moves: movesList,
      abilities: abilitiesList,
    );
  }
 
  // La API entrega la altura en decímetros y el peso en hectogramos.
  // Estos dos getters hacen la conversión a las unidades normales
  // (metros y kilogramos) para mostrarlas más claras en la pantalla.
  // Al ser "getters" (no variables guardadas), el cálculo se hace
  // cada vez que se piden, pero es una división simple así que no
  // afecta el rendimiento.
  double get heightInMeters => height / 10;
  double get weightInKg => weight / 10;
}
 
// Clase pequeña que representa UN stat base del Pokémon
// (por ejemplo: { name: "attack", baseStat: 49 }).
class PokemonStat {
  final String name;
  final int baseStat;
 
  // Constructor normal, ambos campos obligatorios.
  PokemonStat({required this.name, required this.baseStat});
 
  // Factory que arma el objeto a partir del Map de un solo stat.
  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      // Aquí se usa "?." en vez de solo "['stat']" por seguridad:
      // si json['stat'] fuera null, json['stat']?['name'] da null
      // en vez de tronar, y ahí entra el '?? ''" como valor final.
      name: json['stat']?['name'] ?? '',
      baseStat: json['base_stat'] ?? 0,
    );
  }
}
 
// Referencia a una habilidad dentro del detalle de un Pokémon.
class PokemonAbilityRef {
  final String name;
  // Las habilidades ocultas solo se consiguen de formas especiales
  // en los juegos, por eso se marcan distinto en la pantalla.
  final bool isHidden;
 
  PokemonAbilityRef({required this.name, required this.isHidden});
}
 