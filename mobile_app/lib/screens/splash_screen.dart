import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controladores ──────────────────────────────────────────────────────────
  late AnimationController _logoController;      // Giro 3D del logo
  late AnimationController _particleController;  // Partículas
  late AnimationController _orbitController;     // Órbita de anillos
  late AnimationController _textController;      // Texto de entrada
  late AnimationController _floatController;     // Flotación continua del logo
  late AnimationController _glowController;      // Pulso del glow

  // ── Animaciones ────────────────────────────────────────────────────────────
  late Animation<double> _logoRotateY;   // Rotación Y (flip 3D)
  late Animation<double> _logoRotateX;   // Inclinación X
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _orbitAngle;
  late Animation<double> _floatY;        // Flotación vertical suave
  late Animation<double> _glowPulse;

  final List<_Particle3D> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Partículas con profundidad Z (tamaño y opacidad varían según Z)
    for (int i = 0; i < 22; i++) {
      final z = _random.nextDouble(); // 0 = fondo, 1 = primer plano
      _particles.add(_Particle3D(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        z: z,
        size: 3.0 + z * 9.0,       // más grande si más cerca
        speed: 0.15 + z * 0.35,    // más rápido si más cerca
        opacity: 0.1 + z * 0.55,   // más opaco si más cerca
        color: i % 3 == 0
            ? const Color(0xFFFFC107)
            : i % 3 == 1
                ? const Color(0xFF64B5F6)
                : Colors.white,
        xDrift: (_random.nextDouble() - 0.5) * 0.06,
      ));
    }

    // ── Logo: entrada con flip 3D en Y ─────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoRotateY = Tween<double>(begin: -pi, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoRotateX = Tween<double>(begin: pi / 6, end: 0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // ── Órbita de anillos girando en 3D ───────────────────────────────────
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _orbitAngle = Tween<double>(begin: 0, end: 2 * pi).animate(_orbitController);

    // ── Partículas continuas ───────────────────────────────────────────────
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // ── Texto entrada ──────────────────────────────────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // ── Flotación suave del logo ───────────────────────────────────────────
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // ── Pulso del glow ─────────────────────────────────────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _orbitController.dispose();
    _textController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _particleController,
          _logoController,
          _orbitController,
          _textController,
          _floatController,
          _glowController,
        ]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF060D2E),
                  Color(0xFF0D1B4E),
                  Color(0xFF1A237E),
                ],
              ),
            ),
            child: Stack(
              children: [
                // ── Partículas 3D (profundidad por tamaño y opacidad) ───────
                ..._particles.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final progress =
                      (_particleController.value + p.speed * i * 0.07) % 1.0;
                  final yPos = (p.y - progress * p.speed * 1.2) % 1.0;
                  final xWave = p.x + sin(progress * 2 * pi + i) * p.xDrift;
                  return Positioned(
                    left: xWave * size.width,
                    top: yPos < 0
                        ? yPos * size.height + size.height
                        : yPos * size.height,
                    child: Opacity(
                      opacity: p.opacity,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color,
                          boxShadow: p.z > 0.6
                              ? [
                                  BoxShadow(
                                    color: p.color.withOpacity(0.5),
                                    blurRadius: p.size * 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),

                // ── Glow de fondo (pulso) ─────────────────────────────────
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFC107).withOpacity(_glowPulse.value * 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Logo central con 3D + flotación ──────────────────────
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _floatY.value),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Anillo 1: órbita giratoria 3D (elipse)
                        _buildOrbitRing(
                          angle: _orbitAngle.value,
                          radiusX: 100,
                          radiusY: 30,
                          color: const Color(0xFFFFC107).withOpacity(0.35),
                          strokeWidth: 1.8,
                        ),
                        // Anillo 2: órbita inversa
                        _buildOrbitRing(
                          angle: -_orbitAngle.value * 0.7,
                          radiusX: 130,
                          radiusY: 38,
                          color: const Color(0xFF64B5F6).withOpacity(0.22),
                          strokeWidth: 1.2,
                        ),
                        // Anillo 3: más grande, lento
                        _buildOrbitRing(
                          angle: _orbitAngle.value * 0.4,
                          radiusX: 162,
                          radiusY: 48,
                          color: Colors.white.withOpacity(0.10),
                          strokeWidth: 0.8,
                        ),

                        // Logo con flip 3D en Y + inclinación X
                        Opacity(
                          opacity: _logoOpacity.value.clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspectiva
                              ..rotateY(_logoRotateY.value)
                              ..rotateX(_logoRotateX.value)
                              ..scale(_logoScale.value),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFFC107),
                                    Color(0xFFFF8F00),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFC107)
                                        .withOpacity(_glowPulse.value * 0.8),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                  const BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 62,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Texto inferior con slide 3D ───────────────────────────
                Positioned(
                  bottom: size.height * 0.26,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(
                              (1 - _textController.value) * -0.3),
                        child: Column(
                          children: [
                            const Text(
                              'GERMÁN BUSCH "A"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 60),
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFFFFC107),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Agenda Digital Profesional',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 15,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Dots de carga animados ────────────────────────────────
                Positioned(
                  bottom: size.height * 0.10,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final t =
                            (_particleController.value + i * 0.2) % 1.0;
                        final scale = sin(t * pi).clamp(0.5, 1.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 8 * scale,
                          height: 8 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFC107).withOpacity(scale),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107)
                                    .withOpacity(scale * 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dibuja un anillo elíptico que simula una órbita en 3D
  Widget _buildOrbitRing({
    required double angle,
    required double radiusX,
    required double radiusY,
    required Color color,
    required double strokeWidth,
  }) {
    return SizedBox(
      width: radiusX * 2,
      height: radiusY * 2,
      child: CustomPaint(
        painter: _OrbitPainter(
          color: color,
          strokeWidth: strokeWidth,
          rotationAngle: angle,
        ),
      ),
    );
  }
}

/// Pinta una elipse girada para simular órbita 3D
class _OrbitPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double rotationAngle;

  _OrbitPainter({
    required this.color,
    required this.strokeWidth,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationAngle * 0.15); // inclinación del plano orbital
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width,
        height: size.height,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.rotationAngle != rotationAngle || old.color != color;
}

class _Particle3D {
  final double x, y, z, size, speed, opacity, xDrift;
  final Color color;

  _Particle3D({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.xDrift,
    required this.color,
  });
}
