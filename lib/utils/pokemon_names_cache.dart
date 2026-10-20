import '../models/item_response.dart';
import '../models/region_response.dart';
import '../providers/poke_api_provider.dart';
 
// Guarda en memoria la lista de todos los Pokémon (solo nombre y url).
// Se pide una sola vez y se reutiliza cada vez que se abre el selector.
class PokemonNamesCache {
  static final PokeApiProvider _api = PokeApiProvider();
  static Future<List<NamedResource>>? _future;
 
  // '??=' significa "si todavía no hay Future, créalo y guárdalo".
  static Future<List<NamedResource>> get() => _future ??= _fetch();
 
  static Future<List<NamedResource>> _fetch() async {
    try {
      final response = await _api.getPokemonList();
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }
      return NamedResourceList.fromRawJson(response.body).results;
    } catch (_) {
      // Si falló, olvidamos el Future para poder reintentar.
      _future = null;
      rethrow;
    }
  }
}