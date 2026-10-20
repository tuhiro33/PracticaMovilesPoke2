import '../models/type_relations_response.dart';
import '../providers/poke_api_provider.dart';
 
// Guarda en memoria las relaciones de daño de cada tipo ya descargadas.
//
// Solo existen 18 tipos, así que al armar un equipo casi siempre se repiten
// (varios Pokémon de tipo agua, por ejemplo). Con esta caché cada tipo se
// pide a la API una sola vez, sin importar cuántos Pokémon lo tengan.
class TypeCache {
  static final PokeApiProvider _api = PokeApiProvider();
  static final Map<String, Future<TypeRelationsResponse>> _cache = {};
 
  // Si ya hay un Future para ese tipo lo reutiliza; si no, lo crea.
  static Future<TypeRelationsResponse> get(String typeName) {
    return _cache.putIfAbsent(typeName, () => _fetch(typeName));
  }
 
  static Future<TypeRelationsResponse> _fetch(String typeName) async {
    try {
      final response = await _api.getType(typeName);
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }
      return TypeRelationsResponse.fromRawJson(response.body);
    } catch (_) {
      // Si falló, lo sacamos de la caché para que el próximo intento
      // vuelva a pedirlo en vez de repetir el mismo error.
      _cache.remove(typeName);
      rethrow;
    }
  }
}