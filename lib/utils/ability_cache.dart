import '../models/ability_response.dart';
import '../providers/poke_api_provider.dart';
 
// Guarda en memoria las habilidades ya descargadas. Muchos Pokémon
// comparten habilidades (Intimidación, Levitación...), así que cada una
// se pide a la API una sola vez.
class AbilityCache {
  static final PokeApiProvider _api = PokeApiProvider();
  static final Map<String, Future<AbilityResponse>> _cache = {};
 
  // Si ya hay un Future para esa habilidad lo reutiliza; si no, lo crea.
  static Future<AbilityResponse> get(String name) {
    return _cache.putIfAbsent(name, () => _fetch(name));
  }
 
  static Future<AbilityResponse> _fetch(String name) async {
    try {
      final response = await _api.getAbility(name);
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }
      return AbilityResponse.fromRawJson(response.body);
    } catch (_) {
      // Si falló, lo sacamos de la caché para poder reintentar después.
      _cache.remove(name);
      rethrow;
    }
  }
}