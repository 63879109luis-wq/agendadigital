// ============================================================
// screens/edit_agenda_screen.dart — Pantalla de Edición de Evento
// ============================================================
// Pantalla completa (no dialog) para editar un evento de la agenda
// del estudiante. Diseño dark premium con:
//   - Título del Evento
//   - Tipo de Evento (dropdown)
//   - Fecha y Hora (lado a lado)
//   - Descripción con contador de caracteres
//   - Imagen Asociada con vista previa y botón Cambiar
//   - Estado del Evento (dropdown)
//   - Botones Actualizar Evento y Cancelar
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EditAgendaScreen extends StatefulWidget {
  const EditAgendaScreen({super.key});

  @override
  State<EditAgendaScreen> createState() => _EditAgendaScreenState();
}

class _EditAgendaScreenState extends State<EditAgendaScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isInit = false;

  // ── Controladores de texto ──────────────────────────────────
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  // ── Estado del formulario ───────────────────────────────────
  String _agendaId = '';
  String _type = 'homework';
  String _status = 'pending';
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String? _imageBase64; // imagen actual del evento
  bool _isSaving = false;
  bool _isDeleting = false;
  int _descLength = 0;

  // ── Animación ──────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Tipos y estados disponibles ────────────────────────────
  final List<Map<String, dynamic>> _types = [
    {'value': 'homework', 'label': 'Tarea', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF5C6BC0)},
    {'value': 'exam', 'label': 'Examen', 'icon': Icons.assignment_late_rounded, 'color': Color(0xFFEF5350)},
    {'value': 'reminder', 'label': 'Recordatorio', 'icon': Icons.notifications_active_rounded, 'color': Color(0xFFFF8F00)},
    {'value': 'event', 'label': 'Evento', 'icon': Icons.push_pin_rounded, 'color': Color(0xFF26A69A)},
  ];

  final List<Map<String, dynamic>> _statuses = [
    {'value': 'pending', 'label': 'Pendiente', 'icon': Icons.radio_button_unchecked_rounded, 'color': Color(0xFFFFB74D)},
    {'value': 'in_progress', 'label': 'En progreso', 'icon': Icons.timelapse_rounded, 'color': Color(0xFF42A5F5)},
    {'value': 'completed', 'label': 'Completado', 'icon': Icons.check_circle_rounded, 'color': Color(0xFF66BB6A)},
    {'value': 'cancelled', 'label': 'Cancelado', 'icon': Icons.cancel_rounded, 'color': Color(0xFFEF5350)},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final item = args['item'] as Map<String, dynamic>? ?? args;
        _agendaId = item['_id']?.toString() ?? '';
        _titleCtrl.text = item['title'] ?? '';
        _descCtrl.text = item['description'] ?? '';
        _type = item['type'] ?? 'homework';
        _status = item['status'] ?? 'pending';
        _imageBase64 = item['imageUrl'];
        final parsedDate = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
        _date = parsedDate;
        _time = TimeOfDay(hour: parsedDate.hour, minute: parsedDate.minute);
      }
      _animCtrl.forward();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────
  Map<String, dynamic> get _currentType =>
      _types.firstWhere((t) => t['value'] == _type, orElse: () => _types.first);

  Map<String, dynamic> get _currentStatus =>
      _statuses.firstWhere((s) => s['value'] == _status, orElse: () => _statuses.first);

  // ── Seleccionar nueva imagen ───────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Seleccionar imagen',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF5C6BC0)),
              ),
              title: const Text('Cámara', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF26A69A)),
              ),
              title: const Text('Galería', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;
    final file = await picker.pickImage(source: result, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  // ── Guardar cambios ────────────────────────────────────────
  Future<void> _saveChanges() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('El título no puede estar vacío', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final newDateTime = DateTime(
        _date.year, _date.month, _date.day,
        _time.hour, _time.minute,
      );
      final updates = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'date': newDateTime.toIso8601String(),
        'type': _type,
        'status': _status,
        if (_imageBase64 != null) 'imageUrl': _imageBase64,
      };
      await _apiService.updateAgendaItem(_agendaId, updates);
      if (mounted) {
        _showSnack('✅ Evento actualizado correctamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Error al actualizar: $e', isError: true);
    }
  }

  // ── Eliminar evento ────────────────────────────────────────
  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('¿Eliminar Evento?', style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _apiService.deleteAgendaItem(_agendaId);
      if (mounted) {
        _showSnack('🗑️ Evento eliminado');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      _showSnack('Error al eliminar: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131625),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildTypeDropdown(),
                      const SizedBox(height: 20),
                      _buildDateTimeRow(),
                      const SizedBox(height: 20),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      _buildImageSection(),
                      const SizedBox(height: 20),
                      _buildStatusDropdown(),
                      const SizedBox(height: 32),
                      _buildUpdateButton(),
                      const SizedBox(height: 12),
                      _buildCancelButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D2E),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // Botón atrás
              _buildHeaderIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              // Título + subtítulo
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Evento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Modifica los detalles de tu evento',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Botón Eliminar
              _buildHeaderIconBtn(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                label: 'Eliminar',
                isLoading: _isDeleting,
                onTap: (_isSaving || _isDeleting) ? null : _deleteEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconBtn({
    required IconData icon,
    required Color color,
    String? label,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: isLoading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  if (label != null) ...[
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
      ),
    );
  }

  // ── Sección: Título del Evento ─────────────────────────────
  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Título del Evento'),
        const SizedBox(height: 8),
        _darkTextField(
          controller: _titleCtrl,
          hint: 'Ej: Tarea de Matemáticas...',
          prefixIcon: Icons.edit_rounded,
          prefixColor: const Color(0xFF5C6BC0),
          maxLines: 1,
        ),
      ],
    );
  }

  // ── Sección: Tipo de Evento ────────────────────────────────
  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Tipo de Evento'),
        const SizedBox(height: 8),
        _darkDropdown<String>(
          value: _type,
          items: _types.map((t) {
            return DropdownMenuItem<String>(
              value: t['value'] as String,
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: t['color'] as Color, size: 18),
                  const SizedBox(width: 10),
                  Text(t['label'] as String, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _type = val!),
          prefixIcon: _currentType['icon'] as IconData,
          prefixColor: _currentType['color'] as Color,
        ),
      ],
    );
  }

  // ── Sección: Fecha y Hora ──────────────────────────────────
  Widget _buildDateTimeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Programar para:'),
        const SizedBox(height: 8),
        Row(
          children: [
            // Fecha
            Expanded(
              child: _darkPickerButton(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF5C6BC0),
                label: 'Fecha',
                value: DateFormat('dd/MM/yyyy').format(_date),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 12),
            // Hora
            Expanded(
              child: _darkPickerButton(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF26A69A),
                label: 'Hora',
                value: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                onTap: _pickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2028),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF5C6BC0)),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF1E2235),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF5C6BC0)),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: const Color(0xFF1E2235),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  // ── Sección: Descripción ───────────────────────────────────
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Descripción', optional: true),
        const SizedBox(height: 8),
        Stack(
          children: [
            _darkTextField(
              controller: _descCtrl,
              hint: 'Descripción de la tarea escaneada...',
              prefixIcon: Icons.description_rounded,
              prefixColor: const Color(0xFF5C6BC0),
              maxLines: 5,
            ),
            // Contador manual reactivo sin reconstruir toda la pantalla
            Positioned(
              bottom: 10,
              right: 14,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _descCtrl,
                builder: (_, val, __) {
                  final len = val.text.length;
                  return Text(
                    '$len/500',
                    style: TextStyle(
                      color: len > 450 ? Colors.orangeAccent : Colors.white38,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Sección: Imagen Asociada ───────────────────────────────
  Widget _buildImageSection() {
    final hasImage = _imageBase64 != null && _imageBase64!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Imagen Asociada'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: hasImage
                ? _buildImagePreview()
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Miniatura
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(_imageBase64!),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'tarea_escaneada.jpg',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agregada el ${DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now())}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          // Botón Cambiar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Cambiar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF5C6BC0), size: 28),
          ),
          const SizedBox(width: 14),
          const Text(
            'Toca para añadir una imagen',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Sección: Estado del Evento ─────────────────────────────
  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Estado del Evento'),
        const SizedBox(height: 8),
        _darkDropdown<String>(
          value: _status,
          items: _statuses.map((s) {
            return DropdownMenuItem<String>(
              value: s['value'] as String,
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, color: s['color'] as Color, size: 18),
                  const SizedBox(width: 10),
                  Text(s['label'] as String, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _status = val!),
          prefixIcon: _currentStatus['icon'] as IconData,
          prefixColor: _currentStatus['color'] as Color,
        ),
      ],
    );
  }

  // ── Botón: Actualizar Evento ───────────────────────────────
  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: (_isSaving || _isDeleting) ? null : _saveChanges,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: (_isSaving || _isDeleting)
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: (_isSaving || _isDeleting)
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.save_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              _isSaving ? 'Actualizando...' : 'Actualizar Evento',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botón: Cancelar ─────────────────────────────────────────
  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: (_isSaving || _isDeleting) ? null : () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close_rounded, color: Colors.white54, size: 18),
            SizedBox(width: 8),
            Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets reutilizables ───────────────────────────────────

  Widget _sectionLabel(String text, {bool optional = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        if (optional)
          const Text(
            '  (opcional)',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
      ],
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required Color prefixColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      maxLines: maxLines,
      // maxLength eliminado: causaba conflicto de nombres en buildCounter → crash
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E2235),
        contentPadding: EdgeInsets.fromLTRB(
          14,
          maxLines > 1 ? 14 : 0,
          14,
          maxLines > 1 ? 40 : 0,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(prefixIcon, color: prefixColor, size: 18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white10, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
        ),
      ),
    );
  }

  Widget _darkDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData prefixIcon,
    required Color prefixColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(prefixIcon, color: prefixColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E2235),
                iconEnabledColor: Colors.white38,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkPickerButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }
}
