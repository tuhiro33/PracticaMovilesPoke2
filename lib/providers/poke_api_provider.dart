import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
 
class PokeApiProvider extends ChangeNotifier{
  final String _baseUrl = 'pokeapi.co';
  final String _apiPatch = '/api/v2';
 
  Future<http.Response> getGenerations() async{
      final url = Uri.https(_baseUrl, "$_apiPatch/generation");
      final response = await http.get(url);
      print(response.body);
      return response;
 
  }
 
  Future<http.Response> getGenerationDetails(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/generation/$id');
    final response = await http.get(url);
    return response;
  }
 
  Future<http.Response> getPokemonDetail(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/pokemon/$id');
    final response = await http.get(url);
    return response;
  }
 
  Future<http.Response> getPokemonSpecies(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/pokemon-species/$id');
    final response = await http.get(url);
    return response;
  }
 
  //La cadena evolutiva viene con su propia URL completa desde pokemon-species
  Future<http.Response> getEvolutionChain(String url) async{
    final response = await http.get(Uri.parse(url));
    return response;
  }
 
  //Lista de pokemon (solo nombre y url). Se usa en el juego para tener
  //los nombres de todos y armar las opciones. Los ids 1..1025 son los
  //pokemon "normales" de la Pokedex nacional.
  Future<http.Response> getPokemonList({int limit = 1025, int offset = 0}) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/pokemon', {
      'limit': '$limit',
      'offset': '$offset',
    });
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de una habilidad por nombre (ej: "overgrow"): descripcion y nombre en español
  Future<http.Response> getAbility(String name) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/ability/$name');
    final response = await http.get(url);
    return response;
  }
 
  //Relaciones de daño de un tipo por nombre (ej: "fire"): contra que es debil o resistente
  Future<http.Response> getType(String name) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/type/$name');
    final response = await http.get(url);
    return response;
  }
 
  //Lista de regiones (kanto, johto, hoenn...)
  Future<http.Response> getRegions() async{
    final url = Uri.https(_baseUrl, '$_apiPatch/region');
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de una region: trae la lista de sus ubicaciones
  Future<http.Response> getRegionDetail(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/region/$id');
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de una ubicacion (ej: una ruta o ciudad): trae sus areas
  Future<http.Response> getLocationDetail(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/location/$id');
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de un area: trae los pokemon que aparecen ahi
  Future<http.Response> getLocationArea(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/location-area/$id');
    final response = await http.get(url);
    return response;
  }
 
  //Lista de bolsillos de la mochila (medicine, pokeballs, berries...)
  Future<http.Response> getItemPockets() async{
    final url = Uri.https(_baseUrl, '$_apiPatch/item-pocket');
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de un bolsillo: trae sus categorias
  Future<http.Response> getItemPocketDetail(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/item-pocket/$id');
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de una categoria: trae la lista de sus objetos
  Future<http.Response> getItemCategoryDetail(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/item-category/$id');
    final response = await http.get(url);
    return response;
  }
 
  //Detalle de un objeto (precio, descripcion, sprite, quien lo lleva...)
  Future<http.Response> getItemDetail(int id) async{
    final url = Uri.https(_baseUrl, '$_apiPatch/item/$id');
    final response = await http.get(url);
    return response;
  }
}