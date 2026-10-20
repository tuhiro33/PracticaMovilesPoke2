import 'dart:convert';
import 'dart:math';
 
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:practicasmovilespoke2/models/pokemon_detail_response.dart';
import 'package:practicasmovilespoke2/providers/poke_api_provider.dart';
 
// Juego "¿Quién es ese Pokémon?": se muestra la silueta de un Pokémon
// y hay que adivinar su nombre entre 4 opciones. Son 10 rondas y al
// final se muestra el puntaje.
class WhoIsThatPokemonScreen extends StatefulWidget {
  const WhoIsThatPokemonScreen({super.key});
 
  @override
  State<WhoIsThatPokemonScreen> createState() => _WhoIsThatPokemonScreenState();
}
 
class _WhoIsThatPokemonScreenState extends State<WhoIsThatPokemonScreen> {
  static const int _totalRounds = 10;
  static const Color _bgColor = Color(0xFF1D3B8B);
 
  final PokeApiProvider _api = PokeApiProvider();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
 
  // Nombres de todos los pokemon. El nombre del pokemon con id N está
  // en la posición N-1 de esta lista (id 1 -> posición 0).
  List<String> _names = [];
 
  bool _loading = true;
  String? _error;
 
  // Estado de la partida
  int _round = 1;
  int _score = 0;
  bool _finished = false;
 
  // Estado de la ronda actual
  int _correctId = 0;
  List<int> _options = [];
  int? _selectedId; // null = todavía no responde
  String? _cryUrl;
 
  bool get _answered => _selectedId != null;
 
  @override
  void initState() {
    super.initState();
    _loadNames();
  }
 
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
 
  // Trae la lista de nombres UNA sola vez y arranca la primera ronda.
  Future<void> _loadNames() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.getPokemonList();
      if (response.statusCode != 200) {
        throw Exception('El servidor respondió ${response.statusCode}');
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      _names = (data['results'] as List)
          .map((p) => p['name'] as String)
          .toList();
      await _startRound();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
 
  // Prepara una ronda nueva: 4 pokemon distintos, uno de ellos es el correcto.
  Future<void> _startRound() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _selectedId = null;
        _cryUrl = null;
      });
    }
 
    // Un Set no permite repetidos, así que seguimos agregando ids
    // aleatorios hasta tener 4 distintos.
    final ids = <int>{};
    while (ids.length < 4) {
      ids.add(_random.nextInt(_names.length) + 1);
    }
    final options = ids.toList()..shuffle(_random);
    final correct = options[_random.nextInt(options.length)];
 
    // Pedimos el detalle del correcto solo para sacar la url de su sonido.
    // Si falla, el juego sigue funcionando, simplemente sin sonido.
    String? cry;
    try {
      final response = await _api.getPokemonDetail(correct);
      cry = PokemonDetailResponse.fromRawJson(response.body).cryUrl;
    } catch (_) {}
 
    if (!mounted) return;
    setState(() {
      _options = options;
      _correctId = correct;
      _cryUrl = cry;
      _loading = false;
    });
  }
 
  void _answer(int id) {
    if (_answered) return; // evita responder dos veces la misma ronda
    setState(() {
      _selectedId = id;
      if (id == _correctId) _score++;
    });
    _playCry();
  }
 
  Future<void> _playCry() async {
    if (_cryUrl == null) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(_cryUrl!));
    } catch (_) {
      // Si el sonido falla no pasa nada, el juego continúa.
    }
  }
 
  void _next() {
    if (_round >= _totalRounds) {
      setState(() => _finished = true);
      return;
    }
    setState(() => _round++);
    _startRound();
  }
 
  void _restart() {
    setState(() {
      _round = 1;
      _score = 0;
      _finished = false;
    });
    _startRound();
  }
 
  // "mr-mime" -> "Mr Mime"
  String _displayName(int id) => _names[id - 1]
      .split('-')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
 
  String _artworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: Colors.white,
        title: const Text('¿Quién es ese Pokémon?'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Puntos: $_score',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
 
  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudo cargar el juego:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNames,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_finished) return _buildResult();
    return _buildRound();
  }
 
  Widget _buildRound() {
    final isCorrect = _selectedId == _correctId;
 
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Text(
            'Ronda $_round de $_totalRounds',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _round / _totalRounds,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 16),
          // --- Silueta / imagen revelada ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(16),
              child: Image.network(
                _artworkUrl(_correctId),
                // La key hace que Flutter cree una imagen nueva en cada
                // ronda (y reinicie la animación de la silueta).
                key: ValueKey(_correctId),
                fit: BoxFit.contain,
                // frameBuilder: frame == null significa que la imagen
                // todavía no termina de descargarse.
                frameBuilder: (context, child, frame, wasSyncLoaded) {
                  if (frame == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  // Silueta: pintamos la imagen de negro. Al responder,
                  // t va de 0 a 1 y el negro se desvanece revelando
                  // los colores reales del Pokémon.
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _answered ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, t, child) => ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color.fromRGBO(0, 0, 0, 1 - t),
                        BlendMode.srcATop,
                      ),
                      child: child,
                    ),
                    child: child,
                  );
                },
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.catching_pokemon,
                  color: Colors.white,
                  size: 120,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // --- Mensaje de resultado ---
          SizedBox(
            height: 28,
            child: _answered
                ? Text(
                    isCorrect
                        ? '¡Correcto! Es ${_displayName(_correctId)}'
                        : 'Era ${_displayName(_correctId)}',
                    style: TextStyle(
                      color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : const Text(
                    'Elige el nombre correcto',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 8),
          // --- Las 4 opciones ---
          ..._options.map(_buildOption),
          const SizedBox(height: 8),
          // --- Botón siguiente (solo después de responder) ---
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _answered
                ? ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      _round >= _totalRounds ? 'Ver resultado' : 'Siguiente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
 
  Widget _buildOption(int id) {
    Color background = Colors.white;
    Color foreground = Colors.black87;
 
    if (_answered) {
      if (id == _correctId) {
        // La correcta siempre se marca en verde
        background = Colors.green;
        foreground = Colors.white;
      } else if (id == _selectedId) {
        // Si el usuario eligió una incorrecta, esa se marca en rojo
        background = Colors.red;
        foreground = Colors.white;
      } else {
        background = Colors.white54;
      }
    }
 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => _answer(id),
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            _displayName(id),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
 
  Widget _buildResult() {
    String message;
    if (_score == _totalRounds) {
      message = '¡Perfecto! Eres un maestro Pokémon';
    } else if (_score >= 7) {
      message = '¡Muy bien! Conoces a tus Pokémon';
    } else if (_score >= 4) {
      message = 'Nada mal, sigue entrenando';
    } else {
      message = 'Te falta repasar la Pokédex';
    }
 
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 96),
            const SizedBox(height: 16),
            Text(
              '$_score / $_totalRounds',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Jugar de nuevo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Salir',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 