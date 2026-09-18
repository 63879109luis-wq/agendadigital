// ============================================================
// screens/submit_task_screen.dart — Pantalla de entrega de tarea en PDF
// ============================================================
// Permite al estudiante seleccionar un archivo PDF desde su dispositivo
// y entregarlo como respuesta a una tarea asignada.
//
// Características:
//   - Selección de PDF con file_picker
//   - Campo de nota/comentario opcional
//   - Barra de progreso animada durante la subida
//   - Estado de éxito con animación
//   - Diseño premium con gradientes y efectos de glassmorfismo
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class SubmitTaskScreen extends StatefulWidget {
  const SubmitTaskScreen({super.key});

  @override
  State<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends State<SubmitTaskScreen>
    with TickerProviderStateMixin {
  // ── Servicios y datos ───────────────────────────────────────
  final ApiService _api = ApiService();
  final TextEditingController _noteCtrl = TextEditingController();

  // Argumentos recibidos desde la ruta
  String? _taskId;
  String? _taskTitle;
  String? _taskSubject;
  String? _userId;

  // ── Selector de materia ─────────────────────────────────────
  String? _selectedSubject;

  // Lista fija de materias con icono y color
  static const List<Map<String, dynamic>> _subjectOptions = [
    {'name': 'Matemáticas',       'color': 0xFF1565C0},
    {'name': 'Lenguaje',          'color': 0xFF6A1B9A},
    {'name': 'Ciencias',          'color': 0xFF00695C},
    {'name': 'Historia',          'color': 0xFF4E342E},
    {'name': 'Inglés',            'color': 0xFF00838F},
    {'name': 'Educación Física',  'color': 0xFFAD1457},
    {'name': 'Arte',              'color': 0xFFE65100},
    {'name': 'Informática',       'color': 0xFF37474F},
    {'name': 'Otra',              'color': 0xFF455A64},
  ];

  // Mapa de íconos constantes por nombre de materia (evita IconData dinámico)
  static const Map<String, IconData> _subjectIcons = {
    'Matemáticas':      Icons.calculate_rounded,
    'Lenguaje':         Icons.menu_book_rounded,
    'Ciencias':         Icons.science_rounded,
    'Historia':         Icons.account_balance_rounded,
    'Inglés':           Icons.language_rounded,
    'Educación Física': Icons.sports_rounded,
    'Arte':             Icons.palette_rounded,
    'Informática':      Icons.computer_rounded,
    'Otra':             Icons.help_outline_rounded,
  };

  // Estado del PDF seleccionado
  PlatformFile? _selectedFile;
  String? _errorMsg;

  // Estado de la subida
  bool _isUploading = false;
  bool _uploadSuccess = false;
  double _uploadProgress = 0.0;

  // ── Controladores de animación ──────────────────────────────
  late AnimationController _headerCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _successCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgParticleCtrl;

  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _successScale;
  late Animation<double> _pulse;

  // ── Partículas decorativas ──────────────────────────────────
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic),
    );

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _bgParticleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  void _generateParticles() {
    final rng = Random();
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 4 + 1,
        speed: rng.nextDouble() * 0.015 + 0.005,
        phase: rng.nextDouble() * 2 * pi,
      ));
    }
  }

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) return;
    _isInit = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _taskId      = args['taskId'];
      _taskTitle   = args['taskTitle'] ?? 'Tarea';
      _taskSubject = args['taskSubject'];
      _userId      = args['userId'];
    }
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardCtrl.dispose();
    _successCtrl.dispose();
    _pulseCtrl.dispose();
    _bgParticleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Seleccionar PDF ─────────────────────────────────────────
  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // Cargar bytes directamente
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMsg = null;
        });
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error al seleccionar archivo: $e');
    }
  }

  // ── Entregar PDF ────────────────────────────────────────────
  Future<void> _submitPdf() async {
    if (_selectedFile == null) {
      setState(() => _errorMsg = 'Por favor selecciona un archivo PDF antes de entregar');
      return;
    }
    if (_taskId == null) {
      setState(() => _errorMsg = 'Error: ID de tarea no disponible');
      return;
    }
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      setState(() => _errorMsg = 'Por favor selecciona la materia antes de entregar (el docente la necesita para identificar tu tarea)');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _errorMsg = null;
    });

    // Simular progreso visual mientras se sube
    _animateProgress();

    try {
      final bytes = _selectedFile!.bytes;
      if (bytes == null) {
        throw Exception('No se pudieron leer los bytes del archivo');
      }

      await _api.submitTaskPdf(
        _taskId!,
        bytes,
        _selectedFile!.name,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        subject: _selectedSubject,
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _uploadSuccess = true;
      });
      _successCtrl.forward();

    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
        _errorMsg = 'Error al entregar: ${e.toString().replaceAll('Exception:', '').trim()}';
      });
    }
  }

  void _animateProgress() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted || !_isUploading) return;
      setState(() {
        _uploadProgress = (_uploadProgress + 0.04).clamp(0.0, 0.90);
      });
      if (_uploadProgress < 0.90) _animateProgress();
    });
  }

  // ── UI Principal ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D24),
      body: Stack(
        children: [
          // Fondo animado con partículas
          _buildAnimatedBackground(),
          // Contenido principal
          SafeArea(
            child: _uploadSuccess ? _buildSuccessState() : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgParticleCtrl,
      builder: (ctx, _) {
        return CustomPaint(
          painter: _BackgroundPainter(
            particles: _particles,
            progress: _bgParticleCtrl.value,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050D24),
                  Color(0xFF0D1B4E),
                  Color(0xFF0A2540),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: AnimatedBuilder(
              animation: _cardCtrl,
              builder: (ctx, _) => FadeTransition(
                opacity: _cardOpacity,
                child: SlideTransition(
                  position: _cardSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskInfoCard(),
                      const SizedBox(height: 20),
                      _buildSubjectSelector(),
                      const SizedBox(height: 20),
                      _buildPdfPickerCard(),
                      const SizedBox(height: 20),
                      _buildNoteCard(),
                      const SizedBox(height: 28),
                      if (_errorMsg != null) _buildErrorBanner(),
                      if (_isUploading) _buildProgressBar(),
                      if (!_isUploading) _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (ctx, _) => FadeTransition(
        opacity: _headerOpacity,
        child: SlideTransition(
          position: _headerSlide,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A237E).withOpacity(0.85),
                  const Color(0xFF0D1B4E).withOpacity(0.9),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFFC107).withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Botón volver
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Icono PDF
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.4),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entregar Tarea',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Enviar PDF al profesor',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tarjeta info de la tarea ─────────────────────────────────
  Widget _buildTaskInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withOpacity(0.6),
            const Color(0xFF283593).withOpacity(0.4),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFC107).withOpacity(0.4),
              ),
            ),
            child: const Icon(Icons.assignment_rounded,
                color: Color(0xFFFFC107), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _taskTitle ?? 'Tarea',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_taskSubject != null && _taskSubject!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school_rounded,
                          color: Colors.white.withOpacity(0.5), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _taskSubject!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.5)),
            ),
            child: const Text(
              'Pendiente',
              style: TextStyle(
                color: Color(0xFF64B5F6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de Materia ─────────────────────────────────────
  Widget _buildSubjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7C4DFF), Color(0xFF3F51B5)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Materia',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Requerido',
                  style: TextStyle(
                    color: Color(0xFFEF9A9A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grid de chips de materias
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(
              color: const Color(0xFF7C4DFF).withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjectOptions.map((subj) {
              final name    = subj['name'] as String;
              final color   = Color(subj['color'] as int);
              final isSelected = _selectedSubject == name;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSubject = isSelected ? null : name;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: isSelected
                        ? color.withOpacity(0.28)
                        : Colors.white.withOpacity(0.07),
                    border: Border.all(
                      color: isSelected ? color.withOpacity(0.85) : Colors.white.withOpacity(0.15),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 0,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _subjectIcons[name] ?? Icons.circle_rounded,
                        color: isSelected ? color : Colors.white.withOpacity(0.45),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.55),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle_rounded,
                            color: color, size: 13),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Indicador de selección actual
        if (_selectedSubject != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF7C4DFF), size: 13),
                const SizedBox(width: 5),
                Text(
                  'Materia seleccionada: $_selectedSubject',
                  style: const TextStyle(
                    color: Color(0xFFB39DDB),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Selector de PDF ──────────────────────────────────────────
  Widget _buildPdfPickerCard() {
    final bool hasFile = _selectedFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Archivo PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Requerido',
                  style: TextStyle(
                    color: Color(0xFFEF9A9A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Zona de selección
        GestureDetector(
          onTap: _pickPdf,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: hasFile
                  ? const Color(0xFF1B5E20).withOpacity(0.25)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: hasFile
                    ? const Color(0xFF4CAF50).withOpacity(0.6)
                    : const Color(0xFF3F51B5).withOpacity(0.4),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: hasFile
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        blurRadius: 16,
                      )
                    ]
                  : [],
            ),
            child: hasFile ? _buildFileSelected() : _buildFilePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePlaceholder() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, _) => Transform.scale(
        scale: _pulse.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.2),
                    const Color(0xFFE53935).withOpacity(0.15),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFFF6B35),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Toca para seleccionar PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Desde tu almacenamiento interno',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_rounded,
                      color: Color(0xFFFF6B35), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Explorar archivos',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelected() {
    final sizeKb = (_selectedFile!.size / 1024).toStringAsFixed(1);
    final sizeMb = (_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2);
    final displaySize = _selectedFile!.size > 1024 * 1024 ? '$sizeMb MB' : '$sizeKb KB';

    return Row(
      children: [
        // Icono PDF
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.4),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Color(0xFFE53935), size: 28),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFile!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.storage_rounded,
                      color: Colors.white.withOpacity(0.45), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    displaySize,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PDF listo',
                      style: TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Botón cambiar archivo
        GestureDetector(
          onTap: _pickPdf,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // ── Nota del estudiante ──────────────────────────────────────
  Widget _buildNoteCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7C4DFF), Color(0xFF3F51B5)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Nota para el profesor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(Opcional)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: const Color(0xFF7C4DFF).withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _noteCtrl,
            maxLines: 4,
            maxLength: 300,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej: Hice la tarea basándome en los apuntes del martes...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8, top: 14),
                child: Icon(Icons.edit_note_rounded,
                    color: const Color(0xFF7C4DFF).withOpacity(0.7), size: 22),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
      ],
    );
  }

  // ── Barra de progreso ────────────────────────────────────────
  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subiendo PDF...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Por favor espera mientras se entrega tu tarea...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ── Banner de error ──────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF9A9A), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg!,
              style: const TextStyle(
                color: Color(0xFFEF9A9A),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFFEF9A9A), size: 18),
          ),
        ],
      ),
    );
  }

  // ── Botón entregar ───────────────────────────────────────────
  Widget _buildSubmitButton() {
    final bool canSubmit = _selectedFile != null && !_isUploading;
    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, _) => Transform.scale(
          scale: canSubmit ? _pulse.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: canSubmit
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
              boxShadow: canSubmit
                  ? [
                      BoxShadow(
                        color: const Color(0xFF43A047).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: canSubmit ? _submitPdf : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: canSubmit ? Colors.white : Colors.white.withOpacity(0.3),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        canSubmit ? 'ENTREGAR TAREA' : 'Selecciona un PDF primero',
                        style: TextStyle(
                          color: canSubmit ? Colors.white : Colors.white.withOpacity(0.3),
                          fontWeight: FontWeight.w900,
                          fontSize: canSubmit ? 16 : 13,
                          letterSpacing: canSubmit ? 1.0 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Estado de éxito ──────────────────────────────────────────
  Widget _buildSuccessState() {
    return AnimatedBuilder(
      animation: _successCtrl,
      builder: (ctx, _) => Transform.scale(
        scale: _successScale.value,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Círculo animado de éxito
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF43A047).withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 70),
                ),
                const SizedBox(height: 32),
                const Text(
                  '¡Tarea Entregada!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedSubject != null
                      ? 'Tu PDF de $_selectedSubject fue enviado.\nEl profesor lo recibirá pronto.'
                      : 'Tu PDF fue enviado exitosamente.\nEl profesor lo recibirá pronto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                // Nombre del archivo entregado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF43A047).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFF81C784), size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _selectedFile?.name ?? 'tarea.pdf',
                          style: const TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Botón volver al inicio
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF283593)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(context, true),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Volver al inicio',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Partícula decorativa ─────────────────────────────────────
class _Particle {
  final double x, y, radius, speed, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });
}

// ── Painter de fondo animado ─────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _BackgroundPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final dy = sin(progress * 2 * pi * p.speed * 10 + p.phase) * 20;
      final cx = p.x * size.width;
      final cy = (p.y * size.height + dy) % size.height;

      // Efecto glow con opacidad baja
      paint.color = const Color(0xFF3F51B5).withOpacity(0.08 + p.radius * 0.015);
      canvas.drawCircle(Offset(cx, cy), p.radius * 3, paint);

      paint.color = const Color(0xFFFFC107).withOpacity(0.04 + p.radius * 0.005);
      canvas.drawCircle(Offset(cx, cy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => true;
}
