// ============================================================
// login_screen.dart — Pantalla de inicio de sesión
// ============================================================
// Diseño clásico Germán Busch "A":
//  - Fondo azul índigo sólido
//  - Logo: círculo dorado con birrete
//  - Nombre de la institución en blanco
//  - Campos blancos con borde azul
//  - Botón dorado "INGRESAR AL PORTAL"
// ============================================================

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Colores de la paleta institucional
const Color _kBg        = Color(0xFF1A237E); // Azul índigo oscuro
const Color _kBgMid     = Color(0xFF1E3A8A); // Azul medio
const Color _kGold      = Color(0xFFFFB300); // Dorado institucional
const Color _kGoldDark  = Color(0xFFFF8F00); // Dorado oscuro
const Color _kWhite     = Colors.white;
const Color _kFieldBg   = Colors.white;
const Color _kBorder    = Color(0xFF3F51B5); // Azul borde campos

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ── Controladores ──────────────────────────────────────────
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService         = ApiService();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  // ── Animaciones ────────────────────────────────────────────
  late AnimationController _entranceCtrl;
  late AnimationController _logoCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset>  _headerSlide;
  late Animation<double>  _headerOpacity;
  late Animation<Offset>  _formSlide;
  late Animation<double>  _formOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Logo rebote
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // Entrada secuencial
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    ));
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _entranceCtrl,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        _logoCtrl.forward();
        _entranceCtrl.forward();
      }
    });
  }

  // ── Login ──────────────────────────────────────────────────
  Future<void> _login({bool asAdmin = false}) async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        final role = user['role'] ?? 'student';
        if (role == 'admin' || asAdmin) {
          Navigator.pushReplacementNamed(context, '/admin-dashboard',
              arguments: user);
        } else {
          Navigator.pushReplacementNamed(context, '/home', arguments: user);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: _kWhite),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString().contains(':')
                      ? e.toString().split(':')[0]
                      : e.toString(),
                  style: const TextStyle(color: _kWhite),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Fondo azul índigo ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF1E3A8A),
                  Color(0xFF1A237E),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Círculos decorativos sutiles ───────────────────
          Positioned(
            top: -60,
            left: -60,
            child: _decorCircle(220, 0.07),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _decorCircle(260, 0.06),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _decorCircle(160, 0.05),
          ),

          // ── Contenido ──────────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entranceCtrl, _logoCtrl]),
              builder: (ctx, _) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ── LOGO Y NOMBRE ──────────────────────
                      SlideTransition(
                        position: _headerSlide,
                        child: Opacity(
                          opacity: _headerOpacity.value.clamp(0.0, 1.0),
                          child: _buildHeader(),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── FORMULARIO ─────────────────────────
                      SlideTransition(
                        position: _formSlide,
                        child: Opacity(
                          opacity: _formOpacity.value.clamp(0.0, 1.0),
                          child: _buildForm(),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Círculo decorativo ─────────────────────────────────────
  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo: círculo dorado con birrete
        ScaleTransition(
          scale: _logoScale,
          child: Opacity(
            opacity: _logoOpacity.value.clamp(0.0, 1.0),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kGold, _kGoldDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kGold.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 54,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Nombre institución
        const Text(
          'GERMÁN BUSCH "A"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kWhite,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Agenda Digital Profesional',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // FORMULARIO
  // ══════════════════════════════════════════════════════════
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo Correo
        _buildWhiteField(
          controller: _emailController,
          hint: 'Correo Institucional',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Campo Contraseña
        _buildWhiteField(
          controller: _passwordController,
          hint: 'Contraseña',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),

        const SizedBox(height: 10),

        // ¿Olvidaste tu contraseña?
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: _kGold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Botón principal: INGRESAR AL PORTAL
        _buildPortalButton(),

        const SizedBox(height: 20),

        // Separador
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ó',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ¿No tienes cuenta? Crear cuenta
        _buildRegisterRow(),

        const SizedBox(height: 12),

        // Botón docente discreto
        _buildTeacherButton(),

        const SizedBox(height: 12),

        // Botón administrador (discreto)
        _buildAdminButton(),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Campo blanco con borde azul ────────────────────────────
  Widget _buildWhiteField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kFieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kBorder.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        cursorColor: _kBg,
        style: const TextStyle(
          color: Color(0xFF1A237E),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF1A237E).withValues(alpha: 0.35),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1A237E).withValues(alpha: 0.45),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF1A237E).withValues(alpha: 0.45),
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        ),
      ),
    );
  }

  // ── Botón dorado INGRESAR AL PORTAL ───────────────────────
  Widget _buildPortalButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () => _login(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isLoading
              ? LinearGradient(colors: [
                  _kGold.withValues(alpha: 0.5),
                  _kGoldDark.withValues(alpha: 0.5),
                ])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kGold, _kGoldDark],
                ),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kGold.withValues(alpha: 0.50),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, color: _kWhite, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'INGRESAR AL PORTAL',
                      style: TextStyle(
                        color: _kWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Fila ¿No tienes cuenta? ────────────────────────────────
  Widget _buildRegisterRow() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/register'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.2,
            ),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 14,
                ),
              ),
              const Text(
                'Crear cuenta',
                style: TextStyle(
                  color: _kGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Botón administrador discreto ───────────────────────────
  Widget _buildAdminButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () => _login(asAdmin: true),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white.withValues(alpha: 0.60),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Acceso de administrador',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botón docente discreto ───────────────────────────────
  Widget _buildTeacherButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
          backgroundColor: const Color(0xFFFFB300).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          Navigator.pushReplacementNamed(
            context,
            '/teacher-dashboard',
            arguments: {
              '_id': 'teacher_demo_id',
              'name': 'Prof. Juan Pérez',
              'role': 'teacher',
              'materias': 'Matemáticas, Física, Química',
            },
          );
        },
        icon: const Icon(Icons.school_outlined, color: Color(0xFFFFB300), size: 20),
        label: const Text(
          'ACCESO DIRECTO ROL DOCENTE',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
