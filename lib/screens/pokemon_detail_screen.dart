import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:practicasmovilespoke2/models/ability_response.dart';
import 'package:practicasmovilespoke2/models/evolution_chain_response.dart';
import 'package:practicasmovilespoke2/models/pokemon_detail_response.dart';
import 'package:practicasmovilespoke2/models/pokemon_species_response.dart';
import 'package:practicasmovilespoke2/models/type_relations_response.dart';
import 'package:practicasmovilespoke2/providers/poke_api_provider.dart';
import 'package:practicasmovilespoke2/utils/pokemon_type_colors.dart';
import 'package:practicasmovilespoke2/utils/type_effectiveness.dart';

 
// Esta es la pantalla de detalle de UN Pokémon: imagen grande,
// sonido, descripción, altura/peso, stats, evoluciones y movimientos.
//
// A diferencia de las otras pantallas (que eran StatelessWidget),
// esta es un StatefulWidget porque SÍ necesita guardar estado propio
// que "vive" mientras la pantalla está abierta:
// 1) el Future con los datos ya cargados (para no volver a pedirlos
//    de internet cada vez que Flutter redibuja la pantalla), y
// 2) el AudioPlayer, que necesita existir mientras la pantalla esté
//    abierta y hay que liberarlo (dispose) cuando se cierra.
//
// Un StatefulWidget en Flutter en realidad son DOS clases: esta de
// aquí (la "configuración" del widget, con los datos que recibe
// desde afuera) y su State (la clase de abajo, que sí puede cambiar
// y "recordar" cosas mientras la pantalla está viva).
class PokemonDetailScreen extends StatefulWidget {
  // Id del Pokémon a mostrar (lo recibimos desde la pantalla anterior,
  // ya sea la lista de una generación o la tarjeta de otra evolución).
  final int pokemonId;
  // Nombre del Pokémon; lo usamos para el título del AppBar mientras
  // los datos completos todavía se están cargando.
  final String pokemonName;
 
  const PokemonDetailScreen({
    super.key,
    required this.pokemonId,
    required this.pokemonName,
  });
 
  // Todo StatefulWidget debe implementar createState(), que le dice
  // a Flutter cuál es la clase State asociada a este widget.
  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}
 
// Esta es la clase "State": aquí SÍ podemos guardar variables que
// cambian con el tiempo, y usar setState() si quisiéramos forzar un
// redibujado (en este archivo en particular no se usa setState()
// directamente, porque el redibujado ya lo maneja FutureBuilder solo).
class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  // Creamos nuestra propia instancia del provider, igual que en
  // generation_detail_screen.dart (en vez de usar Provider.of).
  final PokeApiProvider _api = PokeApiProvider();
 
  // AudioPlayer es la clase del paquete 'audioplayers' que sabe
  // reproducir sonidos. La creamos UNA sola vez (aquí, como campo
  // de la clase) y la reutilizamos, en vez de crear una nueva cada
  // vez que se toca el botón de sonido.
  final AudioPlayer _audioPlayer = AudioPlayer();
 
  // 'late' le dice a Dart "esta variable no tiene valor todavía,
  // pero prometo asignarle uno antes de usarla" (se asigna en
  // initState, un poco más abajo). Es un Future que, cuando termine,
  // nos va a dar un objeto _PokemonFullData con todo lo necesario.
  //
  // Guardarlo aquí como campo (en vez de llamar a _loadFullData()
  // directamente dentro de build()) es MUY importante: build() se
  // puede llamar muchas veces mientras la pantalla está abierta
  // (por ejemplo, si el usuario gira el celular), y si volviéramos
  // a llamar _loadFullData() cada vez, haríamos peticiones a internet
  // de más sin necesidad. Al guardar el Future una sola vez, todos
  // los FutureBuilder que lo usen "recuerdan" el resultado sin
  // volver a pedirlo.
  late Future<_PokemonFullData> _future;
 
  // initState() es un método del ciclo de vida de un StatefulWidget:
  // Flutter lo llama UNA SOLA VEZ, justo cuando el widget se crea
  // por primera vez (antes de que se muestre en pantalla). Es el
  // lugar correcto para iniciar cosas que solo deben pasar una vez,
  // como arrancar esta petición a la API.
  @override
  void initState() {
    // Siempre hay que llamar primero al initState() de la clase
    // padre (State), para que Flutter haga su propia inicialización interna.
    super.initState();
    // Arrancamos la carga de datos y guardamos el Future resultante.
    // Ojo: aquí NO usamos 'await'; solo guardamos la "promesa" de que
    // en algún momento este Future va a terminar. FutureBuilder,
    // más abajo en build(), es quien realmente "espera" el resultado.
    _future = _loadFullData();
  }
 
  // dispose() es el método opuesto a initState(): Flutter lo llama
  // cuando este widget se va a destruir para siempre (por ejemplo,
  // cuando el usuario navega hacia atrás y sale de esta pantalla).
  // Es el lugar correcto para "limpiar" recursos que no se liberan
  // solos, como este AudioPlayer (si no lo cerráramos aquí, se
  // quedaría reproduciendo/ocupando memoria de fondo aunque ya
  // hayamos cerrado la pantalla).
  @override
  void dispose() {
    _audioPlayer.dispose();
    // Igual que con initState, hay que llamar al dispose() del padre,
    // y por convención se hace AL FINAL (al revés que en initState).
    super.dispose();
  }
 
  // Junta los 3 llamados que necesitamos: detalle del pokemon, su especie
  // (para la descripción) y la cadena evolutiva (a partir de la url de la especie).
  //
  // Es una función 'async' (asíncrona): puede usar 'await' adentro para
  // "pausar" su ejecución hasta que cada petición termine, sin bloquear
  // el resto de la app mientras tanto (la interfaz sigue respondiendo).
  Future<_PokemonFullData> _loadFullData() async {
    // Primer paso: pedimos el detalle del Pokémon (stats, tipos, etc.)
    // y esperamos ('await') a que la respuesta llegue antes de seguir.
    final detailResponse = await _api.getPokemonDetail(widget.pokemonId);
    // 'widget.pokemonId' -- dentro de la clase State, para acceder a
    // los datos que le pasaron al widget "de afuera" (los que están
    // en PokemonDetailScreen), se usa el prefijo 'widget.'.
    final pokemon = PokemonDetailResponse.fromRawJson(detailResponse.body);
 
    // Segundo paso: con el mismo id, pedimos los datos de la especie
    // (para sacar la descripción y la url de la cadena evolutiva).
    final speciesResponse = await _api.getPokemonSpecies(widget.pokemonId);
    final species = PokemonSpeciesResponse.fromRawJson(speciesResponse.body);
 
    // Empezamos con una lista vacía de evoluciones por si algo falla
    // o si esta especie no tuviera cadena evolutiva registrada.
    List<EvolutionNode> evolutions = [];
 
    // Solo pedimos la cadena evolutiva si species SÍ trajo una url
    // válida (recordemos que en PokemonSpeciesResponse, si no viene,
    // evolutionChainUrl queda como '' string vacío).
    if (species.evolutionChainUrl.isNotEmpty) {
      // Tercer paso: con esa url, pedimos la cadena evolutiva completa.
      final evoResponse =
          await _api.getEvolutionChain(species.evolutionChainUrl);
      final evoChain = EvolutionChainResponse.fromRawJson(evoResponse.body);
      evolutions = evoChain.chain;
    }
 
    // Cuarto paso: habilidades y tipos. Se piden EN PARALELO con
    // Future.wait (todas las peticiones salen a la vez y esperamos a que
    // terminen todas), en vez de una por una, para que la pantalla cargue
    // más rápido. Cada helper devuelve null si su petición falla, así un
    // error aquí no tumba toda la pantalla; solo se omite esa sección.
    final abilityResults =
        await Future.wait(pokemon.abilities.map(_loadAbility));
    final abilities = abilityResults.whereType<_AbilityData>().toList();
 
    final typeResults =
        await Future.wait(pokemon.types.map(_loadTypeRelations));
    final typeRelations = typeResults.whereType<TypeRelationsResponse>().toList();
 
    // Solo calculamos debilidades si pudimos cargar TODOS los tipos del
    // Pokémon: con datos de un solo tipo el resultado sería engañoso.
    final effectiveness = typeRelations.length == pokemon.types.length
        ? calculateTypeEffectiveness(typeRelations)
        : <String, double>{};
 
    // Ya con todas las peticiones resueltas, empaquetamos todo en un solo
    // objeto _PokemonFullData (definido más abajo en este archivo)
    // para que el resto de la pantalla solo tenga que manejar UN
    // Future en vez de varios por separado.
    return _PokemonFullData(
      pokemon: pokemon,
      species: species,
      evolutions: evolutions,
      abilities: abilities,
      effectiveness: effectiveness,
    );
  }
 
  // Pide una habilidad y la junta con el dato "es oculta" del Pokémon.
  // Devuelve null si algo falla (sin internet, 404, etc.).
  Future<_AbilityData?> _loadAbility(PokemonAbilityRef ref) async {
    try {
      final response = await _api.getAbility(ref.name);
      final ability = AbilityResponse.fromRawJson(response.body);
      return _AbilityData(
        name: ability.name,
        description: ability.description,
        isHidden: ref.isHidden,
      );
    } catch (_) {
      return null;
    }
  }
 
  // Pide las relaciones de daño de un tipo. Devuelve null si falla.
  Future<TypeRelationsResponse?> _loadTypeRelations(String typeName) async {
    try {
      final response = await _api.getType(typeName);
      return TypeRelationsResponse.fromRawJson(response.body);
    } catch (_) {
      return null;
    }
  }
 
  // Método que reproduce el sonido del Pokémon. Recibe la url (que
  // puede ser null, por eso 'String?') y no devuelve nada útil hacia
  // afuera, por eso 'Future<void>' (una tarea asíncrona sin resultado).
  Future<void> _playCry(String? url) async {
    // Si no hay url (este Pokémon no tiene sonido registrado),
    // simplemente no hacemos nada.
    if (url == null) return;
 
    // try/catch: intentamos reproducir el sonido, y si algo sale mal
    // (por ejemplo, sin conexión, o la url no es un audio válido),
    // lo atrapamos en el catch en vez de que la app truene.
    try {
      // Detenemos cualquier sonido que ya estuviera sonando antes,
      // por si el usuario toca el botón varias veces seguidas.
      await _audioPlayer.stop();
      // UrlSource le dice al AudioPlayer "el audio está en esta url
      // de internet" (a diferencia de, por ejemplo, un archivo local).
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      // El guion bajo '_' aquí significa "no me interesa guardar el
      // error en una variable, solo quiero saber que algo falló".
      //
      // 'mounted' es una propiedad de todo State que nos dice si el
      // widget SIGUE existiendo en pantalla en este momento. Es
      // importante revisarla antes de usar 'context' dentro de un
      // 'await': si el usuario ya cerró esta pantalla mientras
      // esperábamos la respuesta, 'context' ya no sería válido y
      // usarlo causaría un error.
      if (mounted) {
        // ScaffoldMessenger muestra una notificación pequeña abajo
        // de la pantalla (un "snackbar") avisando que algo falló.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reproducir el sonido')),
        );
      }
    }
  }
 
  // Función auxiliar simple: convierte "pikachu" en "Pikachu"
  // (primera letra en mayúscula, el resto igual).
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
 
  // Igual que en generation_detail_screen.dart: arma la url del
  // sprite/artwork de un Pokémon a partir de su id.
  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
 
  @override
  Widget build(BuildContext context) {
    // Envolvemos TODO el Scaffold dentro de un FutureBuilder para
    // poder decidir, entre otras cosas, el color de fondo según el
    // tipo del Pokémon apenas los datos estén disponibles (por eso
    // el FutureBuilder está aquí arriba, y no solo adentro del body).
    return FutureBuilder<_PokemonFullData>(
      future: _future,
      builder: (context, snapshot) {
        // Mientras no tengamos datos todavía (snapshot.data es null),
        // 'types' queda como lista vacía gracias al '?? []'.
        final types = snapshot.data?.pokemon.types ?? [];
 
        // Si ya sabemos el/los tipo(s) del Pokémon, usamos el color
        // del PRIMER tipo (types.first) para pintar el fondo. Si
        // todavía no hay datos, usamos un morado genérico como
        // color por defecto mientras carga.
        final backgroundColor =
            types.isNotEmpty ? colorForType(types.first) : const Color(0xFF5345AB);
 
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            // Mientras carga, mostramos el nombre que ya nos pasaron
            // desde la pantalla anterior (widget.pokemonName), para
            // no dejar el título vacío durante la espera.
            title: Text(_capitalize(widget.pokemonName)),
          ),
          // Delegamos el contenido del body a un método aparte
          // (_buildBody) para que build() no quede gigante y sea
          // más fácil de leer.
          body: _buildBody(snapshot, backgroundColor),
        );
      },
    );
  }
 
  // Método que arma el contenido principal de la pantalla, según
  // el estado actual del snapshot (cargando / error / con datos).
  Widget _buildBody(
      AsyncSnapshot<_PokemonFullData> snapshot, Color backgroundColor) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error al cargar el Pokémon: ${snapshot.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } else if (!snapshot.hasData) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
 
    // A partir de aquí, ya sabemos con certeza que snapshot.data
    // existe (pasamos los tres 'if' de arriba), así que podemos
    // usar el '!' con confianza.
    final data = snapshot.data!;
    final pokemon = data.pokemon;
 
    // SingleChildScrollView permite que TODO el contenido de abajo
    // se pueda desplazar verticalmente si no cabe en la pantalla
    // (por ejemplo, en celulares chicos con muchos movimientos).
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Número del Pokémon con formato "#001".
          Text(
            '#${pokemon.id.toString().padLeft(3, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          // --- Imagen grande arriba ---
          // Usamos el operador ternario (condición ? siVerdadero : siFalso):
          // si SÍ hay spriteUrl, mostramos la imagen; si es null,
          // mostramos un ícono de Pokébola en su lugar.
          pokemon.spriteUrl != null
              ? Image.network(
                  pokemon.spriteUrl!,
                  height: 200,
                  fit: BoxFit.contain,
                  // Si la imagen falla al cargar (url rota, sin
                  // internet, etc.), mostramos el ícono de respaldo.
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.catching_pokemon,
                    color: Colors.white,
                    size: 120,
                  ),
                )
              : const Icon(Icons.catching_pokemon,
                  color: Colors.white, size: 120),
          // --- Botón de sonido ---
          // El 'if' aquí adentro de la lista 'children' es una de las
          // llamadas "collection if" de Dart: si la condición es
          // falsa, este widget simplemente NO se agrega a la lista
          // (no ocupa espacio ni existe), en vez de tener que mostrar
          // un SizedBox.shrink() o algo así como reemplazo.
          if (pokemon.cryUrl != null)
            IconButton(
              onPressed: () => _playCry(pokemon.cryUrl),
              icon: const Icon(Icons.volume_up, color: Colors.white, size: 32),
              tooltip: 'Reproducir sonido',
            ),
          const SizedBox(height: 4),
          // --- Chips de tipo(s), define el color de fondo ---
          // Wrap acomoda sus elementos en fila, y si no caben todos
          // en el ancho disponible, pasa automáticamente a una
          // segunda fila (a diferencia de Row, que los encimaría
          // o desbordaría la pantalla).
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, // espacio horizontal entre chips
            // .map() convierte cada nombre de tipo (String) en un
            // widget Chip, y .toList() junta todo en una List<Widget>
            // (Wrap necesita una List, no puede recibir el Iterable
            // que da .map() directamente).
            children: pokemon.types.map((type) {
              return Chip(
                label: Text(
                  // typeNameEs traduce el nombre del tipo al español
                  // (ej: "grass" -> "Planta"), definido en pokemon_types_colors.dart.
                  typeNameEs(type),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                // colorForType nos da el color asociado a ese tipo;
                // .withOpacity(0.85) lo hace levemente transparente
                // para que se note que está "flotando" sobre el fondo.
                backgroundColor: colorForType(type).withOpacity(0.85),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Este Container blanco es la "tarjeta" grande de abajo
          // que contiene toda la info detallada, con las esquinas
          // superiores redondeadas para que se vea como una hoja
          // que se desliza sobre el fondo de color.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Descripción ---
                // Este 'if (...) [ ... ]' es otra "collection if",
                // pero con VARIOS widgets adentro (por eso lleva los
                // corchetes [] y el '...' -operador spread- antes,
                // que "desenvuelve" esa lista dentro de 'children').
                // Si la descripción está vacía, ninguno de los dos
                // widgets (el Text y el SizedBox) se agrega.
                if (data.species.description.isNotEmpty) ...[
                  Text(
                    data.species.description,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                ],
                // --- Datos básicos: peso y altura ---
                Row(
                  // spaceEvenly reparte el espacio disponible en
                  // partes iguales, incluyendo antes del primero y
                  // después del último elemento.
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BasicDataItem(
                      icon: Icons.straighten,
                      label: 'Altura',
                      // toStringAsFixed(1) redondea el número a 1
                      // decimal y lo convierte a String, ej: 0.7.
                      value: '${pokemon.heightInMeters.toStringAsFixed(1)} m',
                      color: backgroundColor,
                    ),
                    _BasicDataItem(
                      icon: Icons.monitor_weight,
                      label: 'Peso',
                      value: '${pokemon.weightInKg.toStringAsFixed(1)} kg',
                      color: backgroundColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // --- Habilidades ---
                // Solo se muestra si se pudo cargar al menos una.
                if (data.abilities.isNotEmpty) ...[
                  const Text(
                    'Habilidades',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...data.abilities.map((ability) =>
                      _AbilityCard(ability: ability, color: backgroundColor)),
                  const SizedBox(height: 24),
                ],
                // --- Stats base ---
                const Text(
                  'Estadísticas base',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // El operador '...' (spread) aquí "desenvuelve" el
                // resultado de .map() (una lista de widgets _StatBar,
                // uno por cada stat) directamente dentro de la lista
                // 'children' de la Column de más arriba, como si cada
                // _StatBar se hubiera escrito ahí a mano uno por uno.
                ...pokemon.stats
                    .map((stat) => _StatBar(stat: stat, color: backgroundColor)),
                const SizedBox(height: 24),
                // --- Debilidades y resistencias ---
                if (data.effectiveness.isNotEmpty) ...[
                  const Text(
                    'Debilidades y resistencias',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _EffectivenessSection(effectiveness: data.effectiveness),
                  const SizedBox(height: 24),
                ],
                // --- Evoluciones ---
                // Solo mostramos esta sección si hay MÁS de 1 elemento
                // en la cadena (si solo hay 1, significa que este
                // Pokémon no tiene evoluciones ni pre-evoluciones,
                // así que no tendría sentido mostrar la sección).
                if (data.evolutions.length > 1) ...[
                  const Text(
                    'Evoluciones',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Le damos una altura FIJA (110) a este SizedBox
                  // porque ListView necesita saber cuánto espacio
                  // tiene disponible cuando se desplaza en la
                  // dirección horizontal (Axis.horizontal) dentro
                  // de una Column, que normalmente da alto "infinito".
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      // Esto hace que la lista se deslice de lado a
                      // lado (como un carrusel) en vez de arriba/abajo.
                      scrollDirection: Axis.horizontal,
                      itemCount: data.evolutions.length,
                      // Entre cada evolución, dibujamos una flechita
                      // indicando "evoluciona hacia acá".
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_ios,
                            color: Colors.grey, size: 16),
                      ),
                      itemBuilder: (context, index) {
                        final evo = data.evolutions[index];
                        // Comparamos si esta tarjeta de evolución
                        // corresponde al Pokémon que ya estamos viendo
                        // en esta misma pantalla, para resaltarlo
                        // (y para no dejar que se toque a sí mismo).
                        final isCurrent = evo.id == pokemon.id;
                        return GestureDetector(
                          // Si es el Pokémon actual, 'onTap: null'
                          // desactiva el toque (no pasa nada al tocarlo).
                          // Si es otra evolución, navegamos hacia ella.
                          onTap: isCurrent
                              ? null
                              : () {
                                  // pushReplacement (en vez de push)
                                  // reemplaza la pantalla actual por
                                  // la nueva, en vez de apilarla encima.
                                  // Así, si el usuario navega Bulbasaur
                                  // -> Ivysaur -> Venusaur y luego
                                  // presiona "atrás", vuelve directo
                                  // a la lista de la generación, en
                                  // vez de tener que retroceder
                                  // pantalla por pantalla entre cada
                                  // evolución.
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PokemonDetailScreen(
                                        pokemonId: evo.id,
                                        pokemonName: evo.name,
                                      ),
                                    ),
                                  );
                                },
                          child: SizedBox(
                            width: 80,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  _spriteUrl(evo.id),
                                  height: 70,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(Icons.catching_pokemon),
                                ),
                                Text(
                                  _capitalize(evo.name),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    // Si es la evolución actual, la
                                    // dejamos en negrita y con el
                                    // color del tipo; si no, en gris
                                    // oscuro normal.
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? backgroundColor
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // --- Movimientos ---
                Text(
                  'Movimientos (${pokemon.moves.length})',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Igual que con los tipos, usamos Wrap para que los
                // chips de movimientos vayan pasando de línea en línea
                // automáticamente según el ancho disponible.
                Wrap(
                  spacing: 8, // espacio horizontal entre chips
                  runSpacing: 8, // espacio vertical entre líneas de chips
                  children: pokemon.moves.map((move) {
                    return Chip(
                      label: Text(
                        // Los nombres de movimientos vienen con guiones
                        // (ej: "razor-leaf"), los cambiamos por espacios
                        // para que se lean como texto normal.
                        move.replaceAll('-', ' '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey.shade200,
                      // 'compact' hace que el chip ocupe menos espacio
                      // vertical del que usaría por defecto, útil
                      // porque aquí puede haber decenas de chips.
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
// Estructura interna para juntar los 3 responses que necesita esta pantalla.
// No es un modelo de la API en sí (no viene de ningún endpoint tal cual);
// es solo una "cajita" nuestra para poder manejar UN solo Future en vez
// de tres por separado, y así simplificar el FutureBuilder de arriba.
class _PokemonFullData {
  final PokemonDetailResponse pokemon;
  final PokemonSpeciesResponse species;
  final List<EvolutionNode> evolutions;
  // Habilidades ya con su nombre en español y descripción
  final List<_AbilityData> abilities;
  // Tipo atacante -> multiplicador de daño que recibe este Pokémon
  // (vacío si no se pudo calcular)
  final Map<String, double> effectiveness;
 
  _PokemonFullData({
    required this.pokemon,
    required this.species,
    required this.evolutions,
    required this.abilities,
    required this.effectiveness,
  });
}
 
// Una habilidad lista para mostrarse en pantalla.
class _AbilityData {
  final String name;
  final String description;
  final bool isHidden;
 
  _AbilityData({
    required this.name,
    required this.description,
    required this.isHidden,
  });
}
 
// Widget privado y pequeño y reutilizable para mostrar un dato básico
// (ícono + valor + etiqueta), usado dos veces: para Altura y para Peso.
// Separarlo evita repetir la misma Column dos veces con solo los
// textos distintos.
class _BasicDataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
 
  const _BasicDataItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
 
// Widget privado que dibuja UNA fila de estadística base, con su
// nombre, el número, y una barra de progreso visual.
class _StatBar extends StatelessWidget {
  final PokemonStat stat;
  final Color color;
 
  const _StatBar({required this.stat, required this.color});
 
  @override
  Widget build(BuildContext context) {
    // 200 es aprox. el máximo teórico de un stat base, sirve como referencia visual.
    // Dividimos el stat actual entre ese máximo para sacar un porcentaje
    // entre 0.0 y 1.0 (lo que espera LinearProgressIndicator en 'value').
    // .clamp(0.0, 1.0) asegura que el resultado nunca se pase de ese
    // rango, por si algún stat rarísimo superara los 200 puntos.
    final percentage = (stat.baseStat / 200).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Ancho FIJO para el nombre del stat, así todas las barras
          // quedan alineadas entre sí sin importar si el nombre es
          // corto ("PS") o largo ("Ataque especial").
          SizedBox(
            width: 92,
            // statNameEs traduce el nombre técnico del stat (ej: "hp")
            // a su nombre en español (ej: "PS"), definido en pokemon_types_colors.dart.
            child: Text(statNameEs(stat.name), style: const TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 28,
            child: Text(
              stat.baseStat.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          // Expanded hace que la barra de progreso ocupe TODO el
          // espacio horizontal que sobra en la fila (después de
          // restar los dos SizedBox de ancho fijo de arriba).
          Expanded(
            // ClipRRect recorta a su hijo con esquinas redondeadas;
            // se necesita porque LinearProgressIndicator, por sí solo,
            // no soporta un 'borderRadius' directamente.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage, // qué tan llena se ve la barra (0.0 a 1.0)
                minHeight: 8,
                backgroundColor: Colors.grey.shade200, // color de la parte "vacía"
                color: color, // color de la parte "llena" (el color del tipo)
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// Tarjeta con una habilidad: nombre, etiqueta "Oculta" si aplica y descripción.
class _AbilityCard extends StatelessWidget {
  final _AbilityData ability;
  final Color color;
 
  const _AbilityCard({required this.ability, required this.color});
 
  @override
  Widget build(BuildContext context) {
    // Primera letra en mayúscula (el nombre en español ya suele venir así,
    // pero el nombre de respaldo en inglés viene en minúsculas).
    final name = ability.name.isEmpty
        ? ability.name
        : ability.name[0].toUpperCase() + ability.name.substring(1);
 
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // El color del tipo, muy suave, como fondo de la tarjeta.
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (ability.isHidden) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Oculta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (ability.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ability.description,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
 
// Agrupa los tipos atacantes por cuánto daño le hacen al Pokémon
// y muestra cada grupo con su etiqueta. Los grupos vacíos no se muestran.
class _EffectivenessSection extends StatelessWidget {
  final Map<String, double> effectiveness;
 
  const _EffectivenessSection({required this.effectiveness});
 
  @override
  Widget build(BuildContext context) {
    // (multiplicador, etiqueta) en orden de más a menos peligroso.
    // Los multiplicadores son potencias de 2 (o 0), así que comparar
    // doubles con == es exacto aquí.
    const groups = <(double, String)>[
      (4.0, 'Muy débil (x4)'),
      (2.0, 'Débil (x2)'),
      (0.5, 'Resistente (x½)'),
      (0.25, 'Muy resistente (x¼)'),
      (0.0, 'Inmune (x0)'),
    ];
 
    final rows = <Widget>[];
    for (final (multiplier, label) in groups) {
      final types = effectiveness.entries
          .where((e) => e.value == multiplier)
          .map((e) => e.key)
          .toList();
      if (types.isEmpty) continue;
 
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: types.map((t) => _TypeChip(type: t)).toList(),
            ),
          ],
        ),
      ));
    }
 
    // Si ningún grupo tiene tipos (todo es x1), lo decimos explícitamente.
    if (rows.isEmpty) {
      return const Text(
        'Recibe daño normal de todos los tipos.',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
 
// Etiqueta pequeña con el nombre de un tipo, pintada con su color.
class _TypeChip extends StatelessWidget {
  final String type;
 
  const _TypeChip({required this.type});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colorForType(type),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        typeNameEs(type),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
 