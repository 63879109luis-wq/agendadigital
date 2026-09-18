import 'dart:math';
import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────
//  Universe3DBackground  —  Múltiples universos 3D animados
//  Cada universo tiene su propio sistema solar con planetas
//  orbitando, estrellas y un movimiento 3D en el espacio.
// ────────────────────────────────────────────────────────────────
class Universe3DBackground extends StatefulWidget {
  final double tiltX;
  final double tiltY;
  const Universe3DBackground({
    super.key,
    this.tiltX = 0,
    this.tiltY = 0,
  });

  @override
  State<Universe3DBackground> createState() => _Universe3DBackgroundState();
}

class _Universe3DBackgroundState extends State<Universe3DBackground>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _driftController;
  late AnimationController _nebulaController;

  final Random _rng = Random(42);
  late final List<_MiniUniverse> _universes;
  late final List<_StarParticle> _stars;
  late final List<_NebulaCloud> _nebulae;

  @override
  void initState() {
    super.initState();

    // ── Controlador maestro (órbitas + rotación de universos) ────
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // ── Deriva lenta de universos ─────────────────────────────────
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // ── Pulso nebulosa ────────────────────────────────────────────
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _universes = List.generate(7, (i) => _MiniUniverse.random(_rng, i));
    _stars = List.generate(120, (i) => _StarParticle.random(_rng));
    _nebulae = List.generate(4, (i) => _NebulaCloud.random(_rng));
  }

  @override
  void dispose() {
    _masterController.dispose();
    _driftController.dispose();
    _nebulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_masterController, _driftController, _nebulaController]),
        builder: (ctx, _) {
          return CustomPaint(
            size: size,
            painter: _UniversePainter(
              masterT: _masterController.value,
              driftT: _driftController.value,
              nebulaT: _nebulaController.value,
              tiltX: widget.tiltX,
              tiltY: widget.tiltY,
              universes: _universes,
              stars: _stars,
              nebulae: _nebulae,
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Painter principal
// ────────────────────────────────────────────────────────────────
class _UniversePainter extends CustomPainter {
  final double masterT;
  final double driftT;
  final double nebulaT;
  final double tiltX;
  final double tiltY;
  final List<_MiniUniverse> universes;
  final List<_StarParticle> stars;
  final List<_NebulaCloud> nebulae;

  _UniversePainter({
    required this.masterT,
    required this.driftT,
    required this.nebulaT,
    required this.tiltX,
    required this.tiltY,
    required this.universes,
    required this.stars,
    required this.nebulae,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fondo gradiente espacial ──────────────────────────────────
    _drawBackground(canvas, size);

    // ── Nebulosas ─────────────────────────────────────────────────
    _drawNebulae(canvas, size);

    // ── Estrellas con parallax ─────────────────────────────────────
    _drawStars(canvas, size);

    // ── Mini Universos ────────────────────────────────────────────
    for (final u in universes) {
      _drawUniverse(canvas, size, u);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF02051A),
          Color(0xFF060D2E),
          Color(0xFF0A1540),
          Color(0xFF060D2E),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawNebulae(Canvas canvas, Size size) {
    for (final n in nebulae) {
      final pulse = 0.85 + sin(nebulaT * pi * 2 + n.phase) * 0.15;
      final cx = n.x * size.width + tiltY * size.width * 0.04 * n.depth;
      final cy = n.y * size.height + tiltX * size.height * 0.04 * n.depth;
      final r = n.radius * size.width * pulse;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            n.color.withOpacity(n.opacity * pulse),
            n.color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    for (final s in stars) {
      final twinkle = 0.4 + sin(masterT * pi * 2 * s.twinkleSpeed + s.phase) * 0.6;
      // parallax con tilt
      final px = s.x * size.width + tiltY * size.width * 0.03 * s.depth;
      final py = s.y * size.height + tiltX * size.height * 0.03 * s.depth;

      final paint = Paint()
        ..color = s.color.withOpacity((s.opacity * twinkle).clamp(0, 1))
        ..maskFilter = s.size > 1.5
            ? MaskFilter.blur(BlurStyle.normal, s.size * 0.8)
            : null;
      canvas.drawCircle(Offset(px, py), s.size, paint);
    }
  }

  void _drawUniverse(Canvas canvas, Size size, _MiniUniverse u) {
    // ── Posición con deriva 3D + parallax ────────────────────────
    final driftAngle = driftT * 2 * pi * u.driftSpeed + u.driftPhase;
    final driftX = cos(driftAngle) * u.driftRadius * size.width;
    final driftY = sin(driftAngle * 0.7) * u.driftRadius * size.height;

    // profundidad Z → escala + parallax
    final scale = 0.5 + u.depth * 0.8; // 0.5 … 1.3
    final px = u.x * size.width + driftX + tiltY * size.width * 0.08 * u.depth;
    final py = u.y * size.height + driftY + tiltX * size.height * 0.08 * u.depth;

    canvas.save();
    canvas.translate(px, py);
    canvas.scale(scale);

    // ── Halo exterior del universo ────────────────────────────────
    final haloPulse = 0.7 + sin(masterT * pi * 2 * u.pulseSpeed + u.phase) * 0.3;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          u.starColor.withOpacity(0.12 * haloPulse),
          u.starColor.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: u.haloRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset.zero, u.haloRadius, haloPaint);

    // ── Anillos orbitales (elipses en perspectiva 3D) ─────────────
    for (int r = 0; r < u.rings.length; r++) {
      final ring = u.rings[r];
      final ringAngle = masterT * pi * 2 * ring.rotationSpeed + ring.phase;
      _drawOrbitRing(canvas, ring, ringAngle, u.starColor);
    }

    // ── Sol / estrella central ────────────────────────────────────
    final starPulse = 0.85 + sin(masterT * pi * 2 * u.pulseSpeed + u.phase) * 0.15;
    _drawStar(canvas, u.starRadius * starPulse, u.starColor, u.starGlow);

    // ── Planetas en órbita ────────────────────────────────────────
    for (final ring in u.rings) {
      final angle = masterT * 2 * pi * ring.rotationSpeed + ring.phase;
      _drawPlanet(canvas, ring, angle);
    }

    canvas.restore();
  }

  void _drawOrbitRing(
      Canvas canvas, _OrbitRing ring, double angle, Color starColor) {
    // La elipse simula perspectiva inclinada
    final tiltAngle = ring.tiltAngle;
    final rx = ring.radius;
    final ry = ring.radius * sin(tiltAngle).abs().clamp(0.08, 0.55);

    final paint = Paint()
      ..color = starColor.withOpacity(0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.rotate(ring.orbitInclination);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      paint,
    );
    canvas.restore();
  }

  void _drawStar(
      Canvas canvas, double radius, Color color, Color glowColor) {
    // Glow exterior
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.8);
    canvas.drawCircle(Offset.zero, radius * 1.6, glowPaint);

    // Corona solar
    final coronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(1.0),
          color.withOpacity(0.6),
          Colors.transparent,
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, coronaPaint);

    // Punto central brillante
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(Offset.zero, radius * 0.35, centerPaint);
  }

  void _drawPlanet(Canvas canvas, _OrbitRing ring, double angle) {
    final tiltAngle = ring.tiltAngle;
    final rx = ring.radius;
    final ry = ring.radius * sin(tiltAngle).abs().clamp(0.08, 0.55);

    // Posición del planeta sobre la elipse
    final px = cos(angle) * rx;
    final py = sin(angle) * ry;

    canvas.save();
    canvas.rotate(ring.orbitInclination);

    // Sombra del planeta (profundidad)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring.planetRadius * 1.2);
    canvas.drawCircle(Offset(px + ring.planetRadius * 0.3, py + ring.planetRadius * 0.4),
        ring.planetRadius * 0.8, shadowPaint);

    // Glow del planeta
    final glowPaint = Paint()
      ..color = ring.planetColor.withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring.planetRadius * 2);
    canvas.drawCircle(Offset(px, py), ring.planetRadius * 1.5, glowPaint);

    // Cuerpo del planeta
    final planetPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [
          Colors.white.withOpacity(0.8),
          ring.planetColor,
          ring.planetColor.withOpacity(0.5),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(px, py), radius: ring.planetRadius));
    canvas.drawCircle(Offset(px, py), ring.planetRadius, planetPaint);

    // Anillo de saturno (solo para planetas grandes)
    if (ring.hasSaturnRing) {
      final ringPaint = Paint()
        ..color = ring.planetColor.withOpacity(0.3)
        ..strokeWidth = ring.planetRadius * 0.4
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: ring.planetRadius * 3.4,
          height: ring.planetRadius * 0.7,
        ),
        ringPaint,
      );
    }

    // Luna (solo en algunos planetas)
    if (ring.hasMoon) {
      final moonAngle = angle * 6 + ring.phase;
      final moonR = ring.planetRadius * 2.2;
      final mx = px + cos(moonAngle) * moonR;
      final my = py + sin(moonAngle) * moonR * 0.4;
      final moonPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(
          Offset(mx, my), ring.planetRadius * 0.28, moonPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_UniversePainter old) => true;
}

// ────────────────────────────────────────────────────────────────
//  Modelos de datos
// ────────────────────────────────────────────────────────────────

class _MiniUniverse {
  final double x, y, depth;
  final double haloRadius, starRadius;
  final Color starColor, starGlow;
  final double phase, pulseSpeed;
  final double driftSpeed, driftPhase, driftRadius;
  final List<_OrbitRing> rings;

  _MiniUniverse({
    required this.x,
    required this.y,
    required this.depth,
    required this.haloRadius,
    required this.starRadius,
    required this.starColor,
    required this.starGlow,
    required this.phase,
    required this.pulseSpeed,
    required this.driftSpeed,
    required this.driftPhase,
    required this.driftRadius,
    required this.rings,
  });

  static const _palettes = [
    [Color(0xFFFFC107), Color(0xFFFF8F00)], // Dorado
    [Color(0xFF42A5F5), Color(0xFF1565C0)], // Azul frío
    [Color(0xFFEC407A), Color(0xFFAD1457)], // Rosa
    [Color(0xFF66BB6A), Color(0xFF2E7D32)], // Verde
    [Color(0xFFAB47BC), Color(0xFF6A1B9A)], // Violeta
    [Color(0xFF26C6DA), Color(0xFF006064)], // Cian
    [Color(0xFFFF7043), Color(0xFFBF360C)], // Naranja
  ];

  static const _planetPalettes = [
    [Color(0xFFFFD54F), Color(0xFF00E5FF), Color(0xFFFF8A80)],
    [Color(0xFF80DEEA), Color(0xFFFFCC02), Color(0xFFCE93D8)],
    [Color(0xFFF48FB1), Color(0xFF80CBC4), Color(0xFFFFE082)],
    [Color(0xFFA5D6A7), Color(0xFFEF9A9A), Color(0xFF90CAF9)],
    [Color(0xFFB39DDB), Color(0xFF80DEEA), Color(0xFFFFF176)],
    [Color(0xFF80CBC4), Color(0xFFF48FB1), Color(0xFFFFCC02)],
    [Color(0xFFFFAB91), Color(0xFFCE93D8), Color(0xFF80DEEA)],
  ];

  factory _MiniUniverse.random(Random rng, int index) {
    final palette = _palettes[index % _palettes.length];
    final pPalette = _planetPalettes[index % _planetPalettes.length];
    final depth = rng.nextDouble(); // 0 = fondo, 1 = primer plano

    final numRings = 2 + rng.nextInt(3); // 2, 3 o 4 anillos
    final rings = <_OrbitRing>[];
    for (int r = 0; r < numRings; r++) {
      rings.add(_OrbitRing(
        radius: 28.0 + r * (14 + rng.nextDouble() * 12),
        tiltAngle: 0.2 + rng.nextDouble() * 1.1,
        orbitInclination: rng.nextDouble() * pi,
        rotationSpeed: (0.08 + rng.nextDouble() * 0.25) * (rng.nextBool() ? 1 : -1),
        phase: rng.nextDouble() * 2 * pi,
        planetRadius: 3.5 + rng.nextDouble() * 5.0,
        planetColor: pPalette[r % pPalette.length],
        hasSaturnRing: r == numRings - 1 && rng.nextBool(),
        hasMoon: r > 0 && rng.nextBool(),
      ));
    }

    return _MiniUniverse(
      x: 0.08 + rng.nextDouble() * 0.84,
      y: 0.06 + rng.nextDouble() * 0.88,
      depth: depth,
      haloRadius: 55 + depth * 40,
      starRadius: 7 + depth * 6,
      starColor: palette[0],
      starGlow: palette[1],
      phase: rng.nextDouble() * 2 * pi,
      pulseSpeed: 0.12 + rng.nextDouble() * 0.2,
      driftSpeed: 0.012 + rng.nextDouble() * 0.025,
      driftPhase: rng.nextDouble() * 2 * pi,
      driftRadius: 0.012 + rng.nextDouble() * 0.035,
      rings: rings,
    );
  }
}

class _OrbitRing {
  final double radius;
  final double tiltAngle;       // inclinación de la órbita (perspectiva)
  final double orbitInclination; // rotación del plano orbital
  final double rotationSpeed;   // velocidad angular
  final double phase;           // fase inicial
  final double planetRadius;
  final Color planetColor;
  final bool hasSaturnRing;
  final bool hasMoon;

  const _OrbitRing({
    required this.radius,
    required this.tiltAngle,
    required this.orbitInclination,
    required this.rotationSpeed,
    required this.phase,
    required this.planetRadius,
    required this.planetColor,
    required this.hasSaturnRing,
    required this.hasMoon,
  });
}

class _StarParticle {
  final double x, y, depth;
  final double size, opacity, phase, twinkleSpeed;
  final Color color;

  const _StarParticle({
    required this.x,
    required this.y,
    required this.depth,
    required this.size,
    required this.opacity,
    required this.phase,
    required this.twinkleSpeed,
    required this.color,
  });

  static const _starColors = [
    Colors.white,
    Color(0xFFBBDEFB),
    Color(0xFFFFE0B2),
    Color(0xFFFCE4EC),
    Color(0xFFE8EAF6),
  ];

  factory _StarParticle.random(Random rng) {
    return _StarParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      depth: rng.nextDouble(),
      size: 0.5 + rng.nextDouble() * 1.8,
      opacity: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * 2 * pi,
      twinkleSpeed: 0.15 + rng.nextDouble() * 0.5,
      color: _starColors[rng.nextInt(_starColors.length)],
    );
  }
}

class _NebulaCloud {
  final double x, y, depth, radius, opacity, phase;
  final Color color;

  const _NebulaCloud({
    required this.x,
    required this.y,
    required this.depth,
    required this.radius,
    required this.opacity,
    required this.phase,
    required this.color,
  });

  static const _nebulaColors = [
    Color(0xFF1A237E),
    Color(0xFF4A148C),
    Color(0xFF0D47A1),
    Color(0xFF006064),
  ];

  factory _NebulaCloud.random(Random rng) {
    return _NebulaCloud(
      x: 0.1 + rng.nextDouble() * 0.8,
      y: 0.1 + rng.nextDouble() * 0.8,
      depth: rng.nextDouble(),
      radius: 0.18 + rng.nextDouble() * 0.22,
      opacity: 0.25 + rng.nextDouble() * 0.35,
      phase: rng.nextDouble() * 2 * pi,
      color: _nebulaColors[rng.nextInt(_nebulaColors.length)],
    );
  }
}
