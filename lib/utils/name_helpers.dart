// Convierte un nombre técnico de la API en uno legible:
// "canalave-city" -> "Canalave City", "mr-mime" -> "Mr Mime".
String prettifyName(String technicalName) => technicalName
    .split('-')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
 
// Muchos recursos de la API traen una lista "names" con el nombre en
// varios idiomas: [{ "name": "Kanto", "language": { "name": "es" } }, ...].
// Esta función busca primero español, luego inglés, y si no hay ninguno
// devuelve el nombre técnico "arreglado" con prettifyName.
String pickLocalizedName(Object? names, String technicalName) {
  if (names is List) {
    for (final lang in ['es', 'en']) {
      for (final n in names) {
        if (n is Map && n['language']?['name'] == lang) {
          final value = n['name'];
          if (value is String && value.isNotEmpty) return value;
        }
      }
    }
  }
  return prettifyName(technicalName);
}
 
// Muchos textos de la API vienen en una lista de entradas, una por idioma
// y versión de juego: [{ "text": "...", "language": { "name": "es" } }, ...].
// Devuelve el texto de la ÚLTIMA entrada en el idioma pedido (las más
// nuevas van al final), o null si no hay ninguna con texto.
// [keys] son los nombres posibles de la clave del texto (según el endpoint
// se llama "text", "flavor_text", "short_effect"...).
String? lastTextInLanguage(Object? entries, String language, List<String> keys) {
  if (entries is! List) return null;
  String? found;
  for (final e in entries) {
    if (e is Map && e['language']?['name'] == language) {
      for (final key in keys) {
        final value = e[key];
        if (value is String && value.trim().isNotEmpty) {
          found = value;
          break;
        }
      }
    }
  }
  return found;
}
 
// Quita los saltos de línea y caracteres raros que la API deja en los textos.
String cleanText(String text) => text
    .replaceAll('\n', ' ')
    .replaceAll('\f', ' ')
    .replaceAll('\u00ad', '')
    .trim();
 
// Primera letra en mayúscula: "overgrow" -> "Overgrow".
String capitalizeFirst(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);