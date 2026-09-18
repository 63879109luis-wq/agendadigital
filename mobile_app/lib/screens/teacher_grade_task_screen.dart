// ============================================================
// screens/teacher_grade_task_screen.dart — Calificar Tarea
// ============================================================
// Pantalla para que el docente revise y califique una tarea
// entregada por un estudiante.
//
// Funcionalidades:
//   - Ver información completa de la tarea y el estudiante
//   - Visor del PDF adjunto (base64 → bytes)
//   - Slider + campo numérico para ingresar la nota (0–100)
//   - Indicador de color según rango de nota
//   - Campo de comentario/retroalimentación
//   - Botón "Calificar" con animación de confirmación
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TeacherGradeTaskScreen extends StatefulWidget {
  const TeacherGradeTaskScreen({super.key});

  @override
  State<TeacherGradeTaskScreen> createState() => _TeacherGradeTaskScreenState();
}

class _TeacherGradeTaskScreenState extends State<TeacherGradeTaskScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  dynamic _task;
  String? _teacherId;
  String? _teacherName;
  bool _isInit = false;

  // Estado del PDF
  bool _loadingPdf = false;
  bool _pdfLoaded  = false;
  Uint8List? _pdfBytes;
  String?    _pdfFileName;
  String?    _pdfError;

  // Estado de calificación
  double _gradeValue       = 70;
  final TextEditingController _gradeController   = TextEditingController(text: '70');
  final TextEditingController _commentController = TextEditingController();
  bool _isGrading = false;
  bool _graded    = false;

  // Animaciones
  late AnimationController _headerController;
  late AnimationController _successController;
  late Animation<double>   _headerOpacity;
  late Animation<Offset>   _headerSlide;
  late Animation<double>   _successScale;
  late Animation<double>   _successOpacity;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _successController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _task        = args?['task'];
      _teacherId   = args?['teacherId']   ?? '';
      _teacherName = args?['teacherName'] ?? 'Docente';
      _headerController.forward();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _successController.dispose();
    _gradeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ── Cargar PDF ──────────────────────────────────────────────

  Future<void> _loadPdf() async {
    if (_loadingPdf || _pdfLoaded) return;
    final itemId = _task?['_id']?.toString() ?? '';
    if (itemId.isEmpty) return;

    setState(() { _loadingPdf = true; _pdfError = null; });
    try {
      final result = await _apiService.getAgendaItemPdf(itemId);
      _pdfFileName  = result['fileName'] as String? ?? 'tarea.pdf';

      if (result['pdfBytes'] != null) {
        // ── Sistema nuevo: bytes ya descargados desde disco ────
        _pdfBytes = result['pdfBytes'] as Uint8List;

      } else {
        // ── Sistema legado: fileUrl en Base64 ─────────────────
        // Formato: "data:application/pdf;base64,XXXXXX"
        final fileUrl = result['fileUrl'] as String? ?? '';
        if (fileUrl.isEmpty) throw Exception('El servidor no devolvió un PDF válido');
        final base64Data = fileUrl.contains(',') ? fileUrl.split(',').last : fileUrl;
        _pdfBytes = base64Decode(base64Data);
      }

      if (!mounted) return;
      setState(() { _pdfLoaded = true; _loadingPdf = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pdfError   = 'No se pudo cargar el PDF: $e';
        _loadingPdf = false;
      });
    }
  }



  // ── Calificar ───────────────────────────────────────────────

  Future<void> _submitGrade() async {
    final taskId = _task?['_id']?.toString() ?? '';
    if (taskId.isEmpty || _teacherId == null) return;

    final gradeInt = _gradeValue.round();

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar calificación',
          style: TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_gradeColor(gradeInt), _gradeColor(gradeInt).withOpacity(0.6)],
                ),
              ),
              child: Center(
                child: Text(
                  '$gradeInt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '¿Calificar con $gradeInt/100?',
              style: const TextStyle(fontSize: 16),
            ),
            if (_commentController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${_commentController.text.trim()}"',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Calificar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isGrading = true);
    try {
      // Calificar el item de agenda (donde realmente vive la entrega del estudiante)
      await _apiService.gradeAgendaTask(
        taskId,
        gradeInt,
        _teacherId!,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      setState(() { _isGrading = false; _graded = true; });
      _successController.forward();

      // Volver con éxito tras 2.5 segundos
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGrading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al calificar: $e'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_graded) return _buildSuccessScreen();

    final subject = _task?['subject'] ?? 'Sin materia';
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(subject),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentCard(),
                  const SizedBox(height: 16),
                  _buildTaskInfoCard(),
                  const SizedBox(height: 16),
                  _buildPdfSection(),
                  const SizedBox(height: 16),
                  _buildGradeSection(),
                  const SizedBox(height: 16),
                  _buildCommentSection(),
                  const SizedBox(height: 24),
                  _buildGradeButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader(String subject) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (_, __) => SlideTransition(
        position: _headerSlide,
        child: FadeTransition(
          opacity: _headerOpacity,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B4E), Color(0xFF1A237E), Color(0xFF283593)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _task?['title'] ?? 'Calificar Tarea',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFC107).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.4)),
                      ),
                      child: Tooltip(
                        message: _teacherName ?? 'Docente',
                        child: const Icon(Icons.grading_rounded,
                            color: Color(0xFFFFC107), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Tarjeta del estudiante ──────────────────────────────────

  Widget _buildStudentCard() {
    final student = _task?['userId'];
    final name  = (student is Map) ? (student['name'] ?? 'Estudiante') : 'Estudiante';
    final grade = (student is Map) ? (student['grade'] ?? '') : '';
    final email = (student is Map) ? (student['email'] ?? '') : '';

    return _buildCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'E',
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF0D1B4E),
                  ),
                ),
                if (grade.isNotEmpty)
                  _buildInfoRow(Icons.class_rounded, grade),
                if (email.isNotEmpty)
                  _buildInfoRow(Icons.email_outlined, email),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, color: Color(0xFF43A047), size: 14),
                SizedBox(width: 4),
                Text(
                  'Estudiante',
                  style: TextStyle(
                    color: Color(0xFF43A047),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Información de la tarea ─────────────────────────────────

  Widget _buildTaskInfoCard() {
    final description = _task?['description']?.toString() ?? '';
    final dueDate     = _task?['dueDate'] != null
        ? DateTime.tryParse(_task!['dueDate'])
        : null;
    final updatedAt   = _task?['updated_at'] != null
        ? DateTime.tryParse(_task!['updated_at'])
        : null;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_rounded, color: Color(0xFF1A237E), size: 18),
              SizedBox(width: 8),
              Text(
                'Detalles de la tarea',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          if (dueDate != null)
            _buildInfoRow(
              Icons.event_rounded,
              'Vencía: ${DateFormat('EEEE d MMM, HH:mm', 'es_ES').format(dueDate.toLocal())}',
            ),
          if (updatedAt != null)
            _buildInfoRow(
              Icons.upload_file_rounded,
              'Entregado: ${DateFormat('EEEE d MMM, HH:mm', 'es_ES').format(updatedAt.toLocal())}',
            ),
        ],
      ),
    );
  }

  // ── Sección PDF ─────────────────────────────────────────────

  Widget _buildPdfSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE53935), size: 18),
              SizedBox(width: 8),
              Text(
                'PDF entregado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!_pdfLoaded && !_loadingPdf && _pdfError == null)
            // Botón para cargar el PDF
            GestureDetector(
              onTap: _loadPdf,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE53935).withOpacity(0.9),
                      const Color(0xFFC62828),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Cargar PDF del estudiante',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_loadingPdf)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFFE53935)),
              ),
            ),

          if (_pdfError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _pdfError!,
                style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
              ),
            ),

          if (_pdfLoaded && _pdfBytes != null)
            Column(
              children: [
                // Vista previa simplificada del PDF como archivo descargado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF8F00).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pdfFileName ?? 'tarea.pdf',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0D1B4E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_pdfBytes!.length / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF43A047), size: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFF1565C0), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF cargado correctamente. Revisa el contenido y asigna la nota a continuación.',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Sección de nota ─────────────────────────────────────────

  Widget _buildGradeSection() {
    final gradeInt = _gradeValue.round();
    final color    = _gradeColor(gradeInt);
    final label    = _gradeLabel(gradeInt);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
              SizedBox(width: 8),
              Text(
                'Calificación',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nota grande en el centro
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$gradeInt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Label descriptivo
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(label),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:   color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor:         color,
              overlayColor:       color.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
              trackHeight: 6,
            ),
            child: Slider(
              value: _gradeValue,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) {
                setState(() {
                  _gradeValue = v;
                  _gradeController.text = v.round().toString();
                });
              },
            ),
          ),

          // Etiquetas de rango
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                Text('50', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                Text('100', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Campo de texto para ingresar nota manual
          Row(
            children: [
              const Text(
                'Nota exacta:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1B4E),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _gradeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: color.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    suffixText: '/100',
                    suffixStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? 0;
                    final clamped = n.clamp(0, 100).toDouble();
                    setState(() => _gradeValue = clamped);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Leyenda de colores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendChip('0–49', const Color(0xFFE53935),  'Insuf.'),
              _buildLegendChip('50–69', const Color(0xFFFF8F00), 'Regular'),
              _buildLegendChip('70–89', const Color(0xFF1565C0), 'Bueno'),
              _buildLegendChip('90–100', const Color(0xFF2E7D32), 'Excl.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(String range, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(height: 3),
        Text(range, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Sección comentario ──────────────────────────────────────

  Widget _buildCommentSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment_rounded, color: Color(0xFF6A1B9A), size: 18),
              SizedBox(width: 8),
              Text(
                'Retroalimentación (opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Escribe un comentario para el estudiante...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8F0FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
              ),
              counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón calificar ─────────────────────────────────────────

  Widget _buildGradeButton() {
    return GestureDetector(
      onTap: _isGrading ? null : _submitGrade,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _isGrading
                ? [Colors.grey[400]!, Colors.grey[300]!]
                : [const Color(0xFF1A237E), const Color(0xFF283593)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isGrading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGrading)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.grading_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              _isGrading ? 'Guardando calificación...' : 'Calificar tarea',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pantalla de éxito ───────────────────────────────────────

  Widget _buildSuccessScreen() {
    final gradeInt = _gradeValue.round();
    final color    = _gradeColor(gradeInt);
    final label    = _gradeLabel(gradeInt);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Center(
        child: AnimatedBuilder(
          animation: _successController,
          builder: (_, __) => FadeTransition(
            opacity: _successOpacity,
            child: ScaleTransition(
              scale: _successScale,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$gradeInt',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF43A047), size: 52),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Tarea calificada!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El estudiante verá su nota de inmediato.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(int grade) {
    if (grade < 50) return const Color(0xFFE53935);
    if (grade < 70) return const Color(0xFFFF8F00);
    if (grade < 90) return const Color(0xFF1565C0);
    return const Color(0xFF2E7D32);
  }

  String _gradeLabel(int grade) {
    if (grade < 50) return '😔 Insuficiente';
    if (grade < 70) return '📘 Regular';
    if (grade < 90) return '👍 Bueno';
    return '🌟 Excelente';
  }
}
