import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UniverseScreen extends StatefulWidget {
  const UniverseScreen({super.key});

  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isInit = false;
  String? _userId;
  String? _userName;

  Map<String, dynamic>? _universe;
  List<dynamic> _planets = [];
  Map<String, dynamic>? _selectedPlanet;

  // Controllers for background animations
  late AnimationController _masterController;
  late AnimationController _driftController;
  late AnimationController _scanController;

  late final List<_StarParticle> _stars;
  late final List<_NebulaCloud> _nebulae;

  bool _isScanning = false;
  String _scanStatusText = "";

  @override
  void initState() {
    super.initState();

    final Random rng = Random(88);
    _stars = List.generate(80, (i) => _StarParticle.random(rng));
    _nebulae = List.generate(3, (i) => _NebulaCloud.random(rng));

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _userId = args['_id'];
        _userName = args['name'];
      }
      _fetchUniverse();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _driftController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _fetchUniverse() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getUniverse(_userId!);
      setState(() {
        _universe = data;
        _planets = data['planets'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al cargar universo: $e', Colors.red);
    }
  }

  Future<void> _resetUniverse() async {
    if (_userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Regenerar Galaxia?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Esto destruirá todos tus planetas actuales y generará un sistema solar completamente nuevo con una semilla diferente. ¿Deseas proceder?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Regenerar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.resetUniverse(_userId!);
      if (res['success'] == true) {
        _selectedPlanet = null;
        await _fetchUniverse();
        _showSnackBar('¡Galaxia regenerada con éxito!', const Color(0xFF10B981));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al reiniciar universo: $e', Colors.red);
    }
  }

  Future<void> _colonizePlanet() async {
    if (_userId == null) return;

    setState(() {
      _isScanning = true;
      _scanStatusText = "Escaneando el sector espacial...";
    });
    _scanController.repeat();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _scanStatusText = "Analizando anomalías gravitacionales...");
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _scanStatusText = "Estableciendo órbita estable...");
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final res = await _apiService.addPlanet(_userId!);
      if (res['success'] == true) {
        final newPlanet = res['planet'];
        setState(() {
          _isScanning = false;
        });
        _scanController.stop();
        await _fetchUniverse();
        _showPlanetDiscoveredDialog(newPlanet);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _scanController.stop();
      _showSnackBar('Error al colonizar: $e', Colors.red);
    }
  }

  void _showPlanetDiscoveredDialog(dynamic planet) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: const Color(0xFFFFC107).withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡PLANETA DESCUBIERTO!',
                  style: TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                // Planet visualization
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        _getPlanetBaseColor(planet['type']),
                        _getPlanetBaseColor(planet['type']).withOpacity(0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getPlanetBaseColor(planet['type']).withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  planet['name'] ?? 'Planeta Desconocido',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (planet['type'] ?? 'Desértico').toString().toUpperCase(),
                  style: TextStyle(
                    color: _getPlanetBaseColor(planet['type']),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                // Stats summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.04),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Tamaño', '${planet['size']} km'),
                      _buildMiniStat('Coord', '(${planet['x']}, ${planet['y']})'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Select this planet to show detail
                    setState(() {
                      _selectedPlanet = planet;
                    });
                  },
                  child: const Text(
                    'COLONIZAR Y VER DETALLES',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  void _showSnackBar(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getPlanetBaseColor(String? type) {
    switch (type) {
      case 'terrestre':
        return const Color(0xFF10B981); // Verde Esmeralda
      case 'gaseoso':
        return const Color(0xFFF97316); // Naranja Neón
      case 'helado':
        return const Color(0xFF06B6D4); // Cian Cristal
      case 'volcánico':
        return const Color(0xFFEF4444); // Rojo Fuego
      case 'desértico':
      default:
        return const Color(0xFFF59E0B); // Dorado
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Spacial Parallax background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_masterController, _driftController]),
              builder: (ctx, _) {
                return CustomPaint(
                  painter: _UniverseBackgroundPainter(
                    masterT: _masterController.value,
                    driftT: _driftController.value,
                    stars: _stars,
                    nebulae: _nebulae,
                  ),
                );
              },
            ),
          ),

          // 2. Interactive Solar System Map
          if (!_isLoading && _planets.isNotEmpty)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _masterController,
                builder: (ctx, _) {
                  return GestureDetector(
                    onTapDown: (details) => _handleMapTap(details.localPosition, size),
                    child: CustomPaint(
                      painter: _SolarSystemPainter(
                        masterT: _masterController.value,
                        planets: _planets,
                        selectedPlanet: _selectedPlanet,
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. Central loading state
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFC107)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando coordenadas galácticas...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

          // 4. Header Resource dashboard
          if (!_isLoading && _universe != null) _buildHeaderDashboard(),

          // 5. Planet detail bottom card (Glassmorphic drawer)
          if (_selectedPlanet != null) _buildPlanetDetailDrawer(size),

          // 6. Action FAB (Colonization)
          if (!_isLoading && _universe != null && !_isScanning)
            Positioned(
              bottom: _selectedPlanet != null ? 360 : 32,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: _colonizePlanet,
                child: const Icon(Icons.rocket_launch_rounded),
              ),
            ),

          // 7. Fullscreen Scanning Overlay
          if (_isScanning) _buildScanningOverlay(),

          // 8. Sleek Glass back button
          Positioned(
            top: 50,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.08),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDashboard() {
    return Positioned(
      top: 50,
      right: 20,
      left: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _universe!['name'] ?? 'Galaxia',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SEED: ${_universe!['seed'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white.withOpacity(0.12)),
                const SizedBox(width: 14),
                // Energy
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFFC107), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_universe!['resources']?['energy'] ?? 100}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Matter
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.blur_circular_rounded, color: Color(0xFFD946EF), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_universe!['resources']?['matter'] ?? 50}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Reset Button
                IconButton(
                  icon: const Icon(Icons.sync_rounded, color: Colors.white60, size: 18),
                  onPressed: _resetUniverse,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanetDetailDrawer(Size size) {
    final planetColor = _getPlanetBaseColor(_selectedPlanet!['type']);
    final resources = _selectedPlanet!['resources'] as List<dynamic>? ?? [];
    final infrastructures = _selectedPlanet!['infrastructure'] as List<dynamic>? ?? [];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527).withOpacity(0.85),
              border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag line handle
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Planet name and badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlanet!['name'] ?? 'Sin nombre',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (_selectedPlanet!['type'] ?? 'Desértico').toString().toUpperCase(),
                            style: TextStyle(color: planetColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0x8DFFFFFF)),
                      onPressed: () => setState(() => _selectedPlanet = null),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Horizontal statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatLabel('Diámetro', '${_selectedPlanet!['size']} km'),
                    _buildStatLabel('Coordenadas', '(${_selectedPlanet!['x']}, ${_selectedPlanet!['y']})'),
                    _buildStatLabel('Población', '${_selectedPlanet!['population'] ?? 0} M'),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('RECURSOS NATURALES', style: TextStyle(color: Color(0x8DFFFFFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 8),
                // Resources list as dynamic pill chips
                resources.isEmpty
                    ? const Text('Ningún recurso descubierto.', style: TextStyle(color: Colors.white30, fontSize: 12))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: resources.map((res) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: planetColor.withOpacity(0.12),
                                border: Border.all(color: planetColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Text(_getResourceEmoji(res.toString()), style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    res.toString(),
                                    style: TextStyle(color: planetColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                const SizedBox(height: 18),
                const Text('INFRAESTRUCTURA', style: TextStyle(color: Color(0x8DFFFFFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 8),
                // Infrastructure items list
                Expanded(
                  child: infrastructures.isEmpty
                      ? Center(
                          child: Text(
                            'Sin edificaciones. ¡Construye infraestructura para poblar el planeta!',
                            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: infrastructures.length,
                          itemBuilder: (ctx, i) {
                            final inf = infrastructures[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withOpacity(0.04),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.domain_rounded, color: Colors.white60, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      inf['name'] ?? 'Edificio',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: const Color(0xFFFFC107).withOpacity(0.15),
                                    ),
                                    child: Text(
                                      'NIVEL ${inf['level'] ?? 1}',
                                      style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 9),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatLabel(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  String _getResourceEmoji(String name) {
    switch (name.toLowerCase()) {
      case 'agua':
      case 'agua helada':
        return '💧';
      case 'magma':
        return '🔥';
      case 'helio-3':
        return '🧪';
      case 'hierro':
      case 'níquel':
      case 'cobre':
        return '🔩';
      case 'oxígeno':
        return '💨';
      case 'silicio':
      case 'arena de cristal':
      case 'cristales de fría':
      case 'cristales de energía':
        return '💎';
      default:
        return '🌌';
    }
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scanController,
                builder: (ctx, _) {
                  return Transform.rotate(
                    angle: _scanController.value * 2 * pi,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.15), width: 3),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 42,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFC107)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'COLONIZANDO SECTOR',
                style: TextStyle(color: Color(0xFFFFC107), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                _scanStatusText,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMapTap(Offset localPos, Size screenSize) {
    if (_planets.isEmpty) return;

    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2 - 20; // Match painter center

    // Check click hit range for each planet
    for (int i = 0; i < _planets.length; i++) {
      final p = _planets[i];

      // Orbit size
      final double rx = 65.0 + i * 45.0;
      final double ry = rx * 0.48;

      // Angular calculation matching painter
      final double orbitSpeed = 0.08 - i * 0.012;
      final double initialPhase = i * (2 * pi / 5);
      final double angle = _masterController.value * 2 * pi * orbitSpeed + initialPhase;

      // Actual planet offset
      final double px = centerX + cos(angle) * rx;
      final double py = centerY + sin(angle) * ry;

      // Tap hit box radius: 26 pixels around planet coordinates
      final double dx = localPos.dx - px;
      final double dy = localPos.dy - py;
      final double distance = sqrt(dx * dx + dy * dy);

      if (distance <= 26.0) {
        setState(() {
          _selectedPlanet = p;
        });
        return;
      }
    }
  }
}

// ────────────────────────────────────────────────────────────────
//  Spacial Background Painter
// ────────────────────────────────────────────────────────────────
class _UniverseBackgroundPainter extends CustomPainter {
  final double masterT;
  final double driftT;
  final List<_StarParticle> stars;
  final List<_NebulaCloud> nebulae;

  _UniverseBackgroundPainter({
    required this.masterT,
    required this.driftT,
    required this.stars,
    required this.nebulae,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Spatial gradient background
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF020512),
          Color(0xFF070B1F),
          Color(0xFF0D122D),
          Color(0xFF070B1F),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Nebulae
    for (final n in nebulae) {
      final pulse = 0.85 + sin(masterT * pi * 2 + n.phase) * 0.15;
      final cx = n.x * size.width;
      final cy = n.y * size.height;
      final r = n.radius * size.width * pulse;

      final p = Paint()
        ..shader = RadialGradient(
          colors: [
            n.color.withOpacity(n.opacity * pulse),
            n.color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
      canvas.drawCircle(Offset(cx, cy), r, p);
    }

    // Stars
    for (final s in stars) {
      final twinkle = 0.4 + sin(masterT * pi * 2 * s.twinkleSpeed + s.phase) * 0.6;
      final px = s.x * size.width;
      final py = s.y * size.height;

      final p = Paint()
        ..color = s.color.withOpacity((s.opacity * twinkle).clamp(0, 1))
        ..maskFilter = s.size > 1.5 ? MaskFilter.blur(BlurStyle.normal, s.size * 0.8) : null;
      canvas.drawCircle(Offset(px, py), s.size, p);
    }
  }

  @override
  bool shouldRepaint(_UniverseBackgroundPainter old) => true;
}

// ────────────────────────────────────────────────────────────────
//  Solar System Orbit & Planet Painter
// ────────────────────────────────────────────────────────────────
class _SolarSystemPainter extends CustomPainter {
  final double masterT;
  final List<dynamic> planets;
  final Map<String, dynamic>? selectedPlanet;

  _SolarSystemPainter({
    required this.masterT,
    required this.planets,
    required this.selectedPlanet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 20;

    // 1. Draw central Sun
    final double sunRadius = 26;
    _drawSun(canvas, Offset(centerX, centerY), sunRadius);

    // 2. Draw Orbit rings and Planets
    for (int i = 0; i < planets.length; i++) {
      final p = planets[i];
      final isSelected = selectedPlanet != null && selectedPlanet!['_id'] == p['_id'];

      // Orbital ellipse parameters
      final double rx = 65.0 + i * 45.0;
      final double ry = rx * 0.48; // Perspective tilt

      // Draw Orbit line
      final orbitPaint = Paint()
        ..color = isSelected ? const Color(0xFFFFC107).withOpacity(0.35) : Colors.white.withOpacity(0.1)
        ..strokeWidth = isSelected ? 1.4 : 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX, centerY), width: rx * 2, height: ry * 2),
        orbitPaint,
      );

      // Draw Planet orbiting on the ellipse
      // Speed declines as distance index increases
      final double orbitSpeed = 0.08 - i * 0.012;
      final double initialPhase = i * (2 * pi / 5);
      final double angle = masterT * 2 * pi * orbitSpeed + initialPhase;

      final double px = centerX + cos(angle) * rx;
      final double py = centerY + sin(angle) * ry;

      _drawPlanetBody(canvas, Offset(px, py), p, isSelected);
    }
  }

  void _drawSun(Canvas canvas, Offset center, double radius) {
    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.5);
    canvas.drawCircle(center, radius * 1.6, glowPaint);

    // Solar body
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        colors: [
          Colors.white,
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);
  }

  void _drawPlanetBody(Canvas canvas, Offset center, dynamic planet, bool isSelected) {
    final double baseRadius = 8 + (((planet['size'] as num) / 18000.0).clamp(2.0, 10.0)).toDouble();
    final Color pColor = _getPlanetColor(planet['type']);

    // Target Selection cursor halo
    if (isSelected) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFC107).withOpacity(0.8)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, baseRadius * 1.7, ringPaint);
    }

    // Outer gas glow
    final glowPaint = Paint()
      ..color = pColor.withOpacity(0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 1.2);
    canvas.drawCircle(center, baseRadius * 1.4, glowPaint);

    // Planet body radial gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withOpacity(0.8),
          pColor,
          pColor.withOpacity(0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));
    canvas.drawCircle(center, baseRadius, bodyPaint);

    // Draw gaseous ring for giants (gaseoso)
    if (planet['type'] == 'gaseoso') {
      final ringPaint = Paint()
        ..color = pColor.withOpacity(0.35)
        ..strokeWidth = baseRadius * 0.35
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: baseRadius * 3.0,
          height: baseRadius * 0.7,
        ),
        ringPaint,
      );
    }

    // Label name tag above the planet
    final textPainter = TextPainter(
      text: TextSpan(
        text: planet['name'] ?? 'Planeta',
        style: TextStyle(
          color: isSelected ? const Color(0xFFFFC107) : Colors.white70,
          fontSize: 9,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - baseRadius - textPainter.height - 4),
    );
  }

  Color _getPlanetColor(String? type) {
    switch (type) {
      case 'terrestre':
        return const Color(0xFF10B981);
      case 'gaseoso':
        return const Color(0xFFF97316);
      case 'helado':
        return const Color(0xFF06B6D4);
      case 'volcánico':
        return const Color(0xFFEF4444);
      case 'desértico':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  bool shouldRepaint(_SolarSystemPainter old) => true;
}

// ────────────────────────────────────────────────────────────────
//  Mini Models
// ────────────────────────────────────────────────────────────────
class _StarParticle {
  final double x, y, size, opacity, phase, twinkleSpeed;
  final Color color;

  const _StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
    required this.twinkleSpeed,
    required this.color,
  });

  static const _colors = [
    Colors.white,
    Color(0xFFE0F2FE),
    Color(0xFFFEF3C7),
    Color(0xFFFCE7F3),
  ];

  factory _StarParticle.random(Random rng) {
    return _StarParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 0.5 + rng.nextDouble() * 1.5,
      opacity: 0.2 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * 2 * pi,
      twinkleSpeed: 0.15 + rng.nextDouble() * 0.45,
      color: _colors[rng.nextInt(_colors.length)],
    );
  }
}

class _NebulaCloud {
  final double x, y, radius, opacity, phase;
  final Color color;

  const _NebulaCloud({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.phase,
    required this.color,
  });

  static const _colors = [
    Color(0xFF1E1B4B), // Indigo oscuro
    Color(0xFF311042), // Púrpura cósmico
    Color(0xFF082F49), // Azul espacial
  ];

  factory _NebulaCloud.random(Random rng) {
    return _NebulaCloud(
      x: 0.1 + rng.nextDouble() * 0.8,
      y: 0.1 + rng.nextDouble() * 0.8,
      radius: 0.2 + rng.nextDouble() * 0.25,
      opacity: 0.15 + rng.nextDouble() * 0.25,
      phase: rng.nextDouble() * 2 * pi,
      color: _colors[rng.nextInt(_colors.length)],
    );
  }
}
