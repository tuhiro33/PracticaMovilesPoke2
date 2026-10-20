import 'package:flutter/material.dart';
import 'package:practicasmovilespoke2/models/generation_detail_response.dart';
import 'package:practicasmovilespoke2/providers/poke_api_provider.dart';
import 'package:practicasmovilespoke2/screens/pokemon_detail_screen.dart';

 
// Esta pantalla muestra el detalle de UNA generación: una cuadrícula
// (grid) con todos los Pokémon que pertenecen a ella. Al tocar uno,
// navega hacia PokemonDetailScreen.
//
// Es un StatelessWidget porque esta pantalla no guarda ningún estado
// propio que cambie con el tiempo (no hay checkboxes, contadores, etc.
// que dependan de setState): solo recibe el 'generationId' y con eso
// pide los datos y los pinta.
class GenerationDetailScreen extends StatelessWidget {
  // El id de la generación que vamos a mostrar (ej: 1 para "generation-i").
  // Lo recibe la pantalla anterior (la lista de generaciones) al navegar aquí.
  final int generationId;
 
  // Constructor: pide 'generationId' como obligatorio.
  // 'Key? key' y 'super(key: key)' son el patrón clásico de Flutter para
  // que el widget pueda tener una "key" (identificador interno que usa
  // Flutter para saber qué widget es cuál cuando se reconstruye el árbol).
  const GenerationDetailScreen({Key? key, required this.generationId}) : super(key: key);
 
  // Método auxiliar (no es parte del ciclo de vida del widget, es solo
  // una función normal de la clase) que arma la url del sprite de un
  // Pokémon a partir de su id, usando el repositorio de imágenes
  // oficial de PokeAPI en GitHub.
  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
 
  // build() es el método que TODO widget de Flutter debe implementar:
  // describe qué widgets se deben mostrar en pantalla. Flutter lo
  // vuelve a llamar cada vez que necesita "redibujar" este widget.
  @override
  Widget build(BuildContext context) {
    // Theme.of(context) nos da acceso al tema visual de toda la app
    // (colores, tipografías, etc.) que se configuró en main.dart.
    // colorScheme trae los colores principales (primary, surface, etc.)
    // para que toda la app se vea consistente sin tener que "inventar"
    // colores sueltos en cada pantalla.
    final colorScheme = Theme.of(context).colorScheme;
 
    // Scaffold es la estructura base de una pantalla en Flutter:
    // le da espacio para un AppBar (la barra de arriba), un body
    // (el contenido principal), etc.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Generación $generationId'),
      ),
      // FutureBuilder es un widget especial que sabe "esperar" a que
      // un Future (una tarea asíncrona, en este caso una petición HTTP)
      // termine, y mientras tanto va reconstruyendo la pantalla según
      // el estado de esa tarea (cargando, con error, o con datos listos).
      body: FutureBuilder(
        // 'future' es la tarea que estamos esperando: pedirle a la API
        // el detalle de esta generación. Como es un StatelessWidget,
        // creamos el provider directo aquí (PokeApiProvider()) en vez
        // de recibirlo por 'Provider.of', siguiendo el mismo estilo
        // que ya traía el resto del proyecto.
        future: PokeApiProvider().getGenerationDetails(generationId),
        // 'builder' es la función que decide QUÉ mostrar según cómo
        // vaya el Future. Recibe 'snapshot', que es como una "foto"
        // del estado actual de esa tarea en este momento.
        builder: (context, snapshot) {
          // Mientras el Future todavía no termina (sigue esperando
          // la respuesta de internet), mostramos un círculo de carga.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Si el Future terminó pero con un error (por ejemplo,
            // no hay conexión a internet), mostramos el error en pantalla.
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            // Caso raro: terminó sin error pero tampoco trajo datos.
            return const Center(child: Text('No data available'));
          } else {
            // ¡Ya tenemos la respuesta! snapshot.data! es el
            // http.Response que devolvió getGenerationDetails
            // (el '!' le dice a Dart "confía en mí, en este punto
            // sé que esto no es null" porque ya pasamos por hasData).
            //
            // fromRawJson recibe snapshot.data!.body (el texto JSON
            // crudo de la respuesta) y lo convierte en un objeto
            // GenerationDetailResponse ya utilizable.
            final generationDetailResponse = GenerationDetailResponse.fromRawJson(snapshot.data!.body);
 
            // De ese objeto, sacamos solo la lista de especies
            // (lo único que necesitamos para armar la cuadrícula).
            final speciesList = generationDetailResponse.pokemonSpecies;
 
            // GridView.builder arma una cuadrícula de widgets, pero
            // de forma "perezosa" (lazy): solo construye las tarjetas
            // que realmente se van a ver en pantalla en cada momento,
            // en vez de crear las 100+ de golpe (mejor rendimiento).
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              // Cuántos elementos va a tener la cuadrícula en total.
              itemCount: speciesList.length,
              // Configura cómo se ve la cuadrícula: cuántas columnas,
              // cuánto espacio entre ellas, y la proporción ancho/alto
              // de cada celda.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columnas fijas
                crossAxisSpacing: 10, // espacio horizontal entre celdas
                mainAxisSpacing: 10, // espacio vertical entre filas
                childAspectRatio: 0.8, // celdas un poco más altas que anchas
              ),
              // itemBuilder es la función que arma CADA celda de la
              // cuadrícula. Flutter la llama una vez por cada índice
              // que necesita mostrar (0, 1, 2, ... hasta itemCount-1).
              itemBuilder: (context, index) {
                // Tomamos la especie que le corresponde a este índice.
                final species = speciesList[index];
 
                // Armamos la tarjeta visual de este Pokémon usando
                // el widget privado _PokemonCard (definido más abajo
                // en este mismo archivo).
                return _PokemonCard(
                  id: species.id,
                  name: species.name,
                  imageUrl: _spriteUrl(species.id),
                  colorScheme: colorScheme,
                  // onTap: qué hacer cuando el usuario toca la tarjeta.
                  // Aquí navegamos a la pantalla de detalle del Pokémon,
                  // pasándole su id y su nombre.
                  onTap: () {
                    // Navigator.push agrega una nueva pantalla encima
                    // de la pila de navegación (como "avanzar" en la app).
                    Navigator.push(
                      context,
                      // MaterialPageRoute define CÓMO se hace esa
                      // transición (con la animación estándar de Android/iOS)
                      // y QUÉ pantalla se muestra (el 'builder').
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailScreen(pokemonId: species.id, pokemonName: species.name),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
 
// Widget privado (el guion bajo '_' al inicio del nombre hace que
// solo se pueda usar dentro de este mismo archivo) que dibuja
// UNA tarjeta individual de Pokémon dentro de la cuadrícula.
//
// Separar esto en su propia clase (en vez de armarlo directo dentro
// de itemBuilder) hace el código más ordenado y fácil de leer.
class _PokemonCard extends StatelessWidget {
  final int id;
  final String name;
  final String imageUrl;
  // Recibimos el colorScheme ya calculado desde afuera, en vez de
  // volver a pedirlo con Theme.of(context) aquí adentro (ambas formas
  // funcionan, pero así evitamos pedirlo dos veces).
  final ColorScheme colorScheme;
  // VoidCallback es un tipo de dato que representa "una función que
  // no recibe nada y no devuelve nada" (void). Se usa mucho en Flutter
  // para pasar acciones como onTap, onPressed, etc.
  final VoidCallback onTap;
 
  const _PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.colorScheme,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    // Material da el "fondo" de la tarjeta: color, bordes redondeados,
    // y la sombra (elevation) típica de las tarjetas de Material Design.
    return Material(
      color: colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(16),
      elevation: 4, // qué tan "levantada"/con sombra se ve la tarjeta
      // InkWell envuelve el contenido y le da el efecto de "ripple"
      // (la onda que se ve al tocar en Android) además de manejar
      // el onTap. Tiene que ir DENTRO de un Material para que el
      // efecto se vea bien.
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          // Column apila widgets verticalmente, uno debajo del otro.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Número del Pokémon con formato "#001", "#025", etc.
              // padLeft(3, '0') rellena con ceros a la izquierda hasta
              // que el texto tenga 3 caracteres (1 -> "001").
              Text(
                '#${id.toString().padLeft(3, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2), // pequeño espacio vertical
              // Nombre del Pokémon, con la primera letra en mayúscula.
              // name[0] es el primer carácter, .toUpperCase() lo pasa
              // a mayúscula, y luego se pega con el resto del string
              // (name.substring(1), o sea "desde la posición 1 hasta el final").
              Text(
                name[0].toUpperCase() + name.substring(1),
                textAlign: TextAlign.center,
                maxLines: 1, // nunca más de una línea
                // Si el nombre no cabe en una línea, corta el texto
                // y pone "..." al final en vez de desbordar la tarjeta.
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              // Expanded hace que este widget ocupe todo el espacio
              // vertical restante dentro de la Column (necesario
              // porque, a diferencia de Text, una imagen no tiene
              // un tamaño "natural" que Flutter pueda calcular solo
              // dentro de un espacio flexible como este).
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain, // ajusta la imagen sin recortarla ni deformarla
                  // loadingBuilder se llama mientras la imagen todavía
                  // se está descargando de internet.
                  loadingBuilder: (context, child, progress) {
                    // 'progress' es null cuando la imagen YA terminó
                    // de cargar; en ese caso mostramos la imagen normal (child).
                    if (progress == null) return child;
                    // Mientras sigue cargando, mostramos un pequeño
                    // círculo de progreso en su lugar.
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  // errorBuilder se llama si la imagen falla al cargar
                  // (por ejemplo, url rota o sin conexión). En vez de
                  // mostrar un ícono roto feo, mostramos un ícono
                  // de Pokébola como respaldo.
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.catching_pokemon, color: colorScheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
