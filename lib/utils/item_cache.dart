import '../models/item_response.dart';
import '../providers/poke_api_provider.dart';
 
// Guarda en memoria los objetos que ya se descargaron.
//
// La API solo da nombre y url de cada objeto en las listas, así que para
// mostrar su nombre en español y su sprite en la cuadrícula hay que pedir
// el detalle de cada uno. Cada casilla lo pide cuando aparece en pantalla,
// y esta caché evita repetir la petición si la casilla vuelve a dibujarse
// o si luego se abre el detalle de ese mismo objeto.
class ItemCache {
  static final PokeApiProvider _api = PokeApiProvider();
  static final Map<int, Future<ItemResponse>> _cache = {};
 
  // Si ya hay un Future para ese id lo reutiliza; si no, lo crea.
  static Future<ItemResponse> get(int id) {
    return _cache.putIfAbsent(id, () => _fetch(id));
  }
 
  static Future<ItemResponse> _fetch(int id) async {
    try {
      final response = await _api.getItemDetail(id);
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }
      return ItemResponse.fromRawJson(response.body);
    } catch (_) {
      // Si falló, lo sacamos de la caché para que el próximo intento
      // vuelva a pedirlo en vez de repetir el mismo error.
      _cache.remove(id);
      rethrow;
    }
  }
}