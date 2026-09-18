import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gradeController = TextEditingController();
  final _apiService = ApiService();

  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Fondo continuo — aislado en RepaintBoundary
  late AnimationController _bgController;
  // Entrada — corre solo UNA vez
  late AnimationController _entranceController;
  // Éxito — corre solo al registrar
  late AnimationController _successController;

  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;

  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _successOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    _successController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole,
        'grade': _selectedRole == 'student' ? _gradeController.text.trim() : '',
      });
      if (mounted) {
        setState(() => _showSuccess = true);
        _successController.forward();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('¡Cuenta creada! Inicia sesión.',
                    style: TextStyle(color: Colors.white)),
              ]),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B4E),
              Color(0xFF1A237E),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Fondo animado AISLADO ──
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (ctx, _) {
                  final v = _bgController.value;
                  return Stack(children: [
                    Positioned(
                      top: -80 + v * 20,
                      left: -60 + v * 15,
                      child: _blob(260, const Color(0xFF64B5F6), 0.08),
                    ),
                    Positioned(
                      bottom: -100 + v * 15,
                      right: -50 + v * 10,
                      child: _blob(220, const Color(0xFFFFC107), 0.09),
                    ),
                    Positioned(
                      top: 300 + v * 30,
                      right: -40,
                      child: _blob(160, Colors.white, 0.05),
                    ),
                  ]);
                },
              ),
            ),

            // ── Contenido — TextField FUERA del AnimatedBuilder continuo ──
            SafeArea(
              child: SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardOpacity,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopBar()),
                      SliverToBoxAdapter(child: _buildTitle()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                          child: _buildForm(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Overlay de éxito ──
            if (_showSuccess)
              AnimatedBuilder(
                animation: _successController,
                builder: (ctx, _) => FadeTransition(
                  opacity: _successOpacity,
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: Center(
                      child: ScaleTransition(
                        scale: _successScale,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 68),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_outlined,
                    color: Color(0xFFFFC107), size: 15),
                const SizedBox(width: 6),
                Text(
                  'Nuevo Usuario',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crear',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const Text('Cuenta',
              style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          const SizedBox(height: 6),
          Text(
            'Únete al portal educativo',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de rol
            Text('SOY',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                _roleChip('student', 'Estudiante', Icons.school_outlined),
                const SizedBox(width: 12),
                _roleChip('teacher', 'Profesor', Icons.person_outline_rounded),
              ],
            ),
            const SizedBox(height: 22),

            // Nombre
            _glassFormField(
              controller: _nameController,
              hint: 'Nombre Completo',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 13),

            // Email
            _glassFormField(
              controller: _emailController,
              hint: 'Correo Institucional',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu correo';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 13),

            // Contraseña
            _glassFormField(
              controller: _passwordController,
              hint: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 13),

            // Grado (solo estudiantes)
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              child: _selectedRole == 'student'
                  ? Column(children: [
                      _glassFormField(
                        controller: _gradeController,
                        hint: 'Grado (ej: 6A Sec)',
                        icon: Icons.class_outlined,
                        validator: (v) {
                          if (_selectedRole == 'student' &&
                              (v == null || v.isEmpty)) {
                            return 'Ingresa tu grado';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                    ])
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // Botón registrar
            GestureDetector(
              onTap: _isLoading ? null : _register,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _isLoading
                      ? LinearGradient(colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ])
                      : const LinearGradient(
                          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)]),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: Color(0xFF0D1B4E), size: 20),
                            SizedBox(width: 10),
                            Text('REGISTRARSE',
                                style: TextStyle(
                                  color: Color(0xFF0D1B4E),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                )),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    text: '¿Ya tienes cuenta? ',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 14),
                    children: const [
                      TextSpan(
                        text: 'Inicia Sesión',
                        style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String role, String label, IconData icon) {
    final sel = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: sel
                ? const LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFF8F00)])
                : null,
            color: sel ? null : Colors.white.withOpacity(0.07),
            border: Border.all(
              color: sel ? Colors.transparent : Colors.white.withOpacity(0.18),
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.28),
                      blurRadius: 10,
                    )
                  ]
                : [],
          ),
          child: Column(children: [
            Icon(icon,
                color: sel
                    ? const Color(0xFF0D1B4E)
                    : Colors.white.withOpacity(0.55),
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: sel
                      ? const Color(0xFF0D1B4E)
                      : Colors.white.withOpacity(0.55),
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _glassFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.88),
        border: Border.all(color: Colors.white.withOpacity(0.60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        validator: validator,
        cursorColor: const Color(0xFF0D1B4E),
        style: const TextStyle(
          color: Color(0xFF0D1B4E),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF0D1B4E).withOpacity(0.45),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 19),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF1565C0),
                    size: 21,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          errorStyle:
              const TextStyle(color: Color(0xFFB71C1C), fontSize: 11),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );
  }
}
