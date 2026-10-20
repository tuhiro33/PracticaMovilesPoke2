import 'package:flutter/material.dart';
 
// Envuelve un FutureBuilder con los estados que se repiten en todas las
// pantallas nuevas: círculo de carga mientras espera y mensaje de error
// con botón "Reintentar". Solo hay que decirle qué dibujar cuando ya
// hay datos (builder).
class FutureView<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
 
  const FutureView({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
  });
 
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'No se pudo cargar la información.\nRevisa tu conexión e inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
 
// Mensaje centrado con un ícono, para estados vacíos
// ("no hay datos", "sin resultados", etc.).
class InfoMessage extends StatelessWidget {
  final IconData icon;
  final String text;
 
  const InfoMessage({super.key, required this.icon, required this.text});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
 