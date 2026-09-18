import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/api_service.dart';

// ───────────────────────────────────────────────────────────────
//  Modelo de resolución de cámara
// ───────────────────────────────────────────────────────────────
class CameraResolution {
  final String label;
  final int megapixels;       // MP representativos
  final int imageQuality;     // 0-100 para image_picker
  final double widthMult;     // multiplicador para maxWidth en PickImageOptions

  const CameraResolution({
    required this.label,
    required this.megapixels,
    required this.imageQuality,
    required this.widthMult,
  });

  /// Ancho máximo aproximado según megapíxeles
  double get maxWidth => widthMult * 1000;
}

// Resoluciones con maxWidth SEGURO para no congelar la UI
const List<CameraResolution> kResolutions = [
  CameraResolution(label: 'Normal',  megapixels: 8,  imageQuality: 80, widthMult: 2.0),
  CameraResolution(label: 'Alta',    megapixels: 12, imageQuality: 88, widthMult: 3.0),
  CameraResolution(label: 'Máxima',  megapixels: 16, imageQuality: 92, widthMult: 4.0),
  CameraResolution(label: 'Ultra',   megapixels: 20, imageQuality: 95, widthMult: 5.0),
];

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  // ── Estado de imagen ──────────────────────────────────────────
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isLoadingImage = false;
  final picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // ── Cámara ───────────────────────────────────────────────────
  CameraDevice _cameraDevice = CameraDevice.rear;
  CameraResolution _selectedResolution = kResolutions[0];

  // ── OCR / agenda ─────────────────────────────────────────────
  final _titleController = TextEditingController(text: 'Tarea Escaneada');
  bool _isProcessing = false;
  bool _isSavingPhoto = false;
  String? _extractedText;
  String? _userId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'homework';
  String? _ocrSavedId;
  // ID del evento de agenda recién guardado (para poder editarlo)
  String? _savedAgendaId;

  // ── Animación ─────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (user != null && user['_id'] != null) {
      _userId = user['_id'];
    }
  }

  // ── Capturar / seleccionar imagen y OCR automático ───────────
  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      preferredCameraDevice: _cameraDevice,
      imageQuality: _selectedResolution.imageQuality,
      maxWidth: _selectedResolution.maxWidth,
    );

    if (pickedFile != null) {
      setState(() {
        _isLoadingImage = true;
        _image = pickedFile;
        _imageBytes = null;
        _extractedText = null;
        _ocrSavedId = null;
        _titleController.text = 'Tarea Escaneada';
      });

      final bytes = await pickedFile.readAsBytes();

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoadingImage = false;
        });
        _animCtrl.forward(from: 0);

        // ✅ OCR automático con ML Kit (on-device, sin servidor)
        _processImageMlKit(pickedFile);
      }
    }
  }

  // ── OCR con Google ML Kit (funciona offline en el dispositivo) ──
  Future<void> _processImageMlKit(XFile imageFile) async {
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final String fullText = recognizedText.text.trim();

      // Usar la primera línea no vacía como título automático
      final String firstLine = fullText
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => 'Tarea Escaneada');
      final String autoTitle =
          firstLine.length > 80 ? '${firstLine.substring(0, 80)}...' : firstLine;

      if (mounted) {
        setState(() {
          _extractedText = fullText.isNotEmpty ? fullText : 'No se pudo extraer texto de la imagen.';
          _titleController.text = autoTitle;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extractedText = 'Error al leer el texto: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Guardar foto en galería del dispositivo ────────────────────
  Future<void> _savePhotoToGallery() async {
    if (_imageBytes == null) return;

    setState(() => _isSavingPhoto = true);
    try {
      final bool hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final bool granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          _showSnack('❌ Permiso denegado para guardar en galería', Colors.red);
          return;
        }
      }

      final now = DateTime.now();
      final fileName = 'escaner_${DateFormat('yyyyMMdd_HHmmss').format(now)}.jpg';

      await Gal.putImageBytes(_imageBytes!, name: fileName, album: 'Escáner Escolar');

      _showSnack('✅ Foto guardada en Galería → álbum "Escáner Escolar"', Colors.green[700]!);
    } catch (e) {
      _showSnack('Error al guardar: $e', Colors.red);
    } finally {
      setState(() => _isSavingPhoto = false);
    }
  }

  // ── OCR ───────────────────────────────────────────────────────
  Future<void> _processImage() async {
    if (_image == null) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _apiService.scanImage(
        _image!,
        userId: _userId ?? 'guest',
      );
      final String scannedText = result['text'] ?? '';
      // Usar la primera línea no vacía del texto escaneado como título
      final String firstLine = scannedText
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => 'Tarea Escaneada');
      final String autoTitle = firstLine.length > 80
          ? '${firstLine.substring(0, 80)}...'
          : firstLine;
      setState(() {
        _extractedText = scannedText;
        _ocrSavedId = result['saved_id'];
        _titleController.text = autoTitle;
      });
    } catch (e) {
      _showSnack('Error al procesar: $e', Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ── Guardar en agenda ─────────────────────────────────────────
  Future<void> _saveToAgenda() async {
    if (_extractedText == null) return;

    setState(() => _isProcessing = true);
    try {
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final String base64Image = base64Encode(_imageBytes!);

      await _apiService.createTask({
        'userId':      _userId ?? 'guest_user',
        'title':       _titleController.text,
        'description': _extractedText,
        'dueDate':     finalDateTime.toIso8601String(),
        'type':        _selectedType,
        'ocrResultId': _ocrSavedId,
        'attachments': [
          {
            'fileName': _image?.name ?? 'imagen.jpg',
            'fileUrl':  'data:image/jpeg;base64,$base64Image',
            'fileType': 'image',
          }
        ],
      });

      final savedItem = await _apiService.saveAgendaItem({
        'userId':      _userId ?? 'guest_user',
        'title':       _titleController.text,
        'description': _extractedText,
        'date':        finalDateTime.toIso8601String(),
        'type':        _selectedType,
        'imageUrl':    base64Image,
      });

      // Guardar el ID del evento recién creado para poder editarlo
      _savedAgendaId = savedItem['_id']?.toString();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✅ ¡Guardado! Ahora puedes editar el evento.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        if (savedItem != null && savedItem['_id'] != null) {
          await Navigator.pushReplacementNamed(
            context,
            '/edit-agenda',
            arguments: savedItem,
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showSnack('Error al guardar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Helper snackbar ───────────────────────────────────────────
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Si ya tenemos texto extraído, mostramos la vista tipo "resultado de escaneo"
    if (_extractedText != null) {
      return _buildScanResultView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('📷 Escáner Inteligente',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── Controles de cámara ─────────────────────────
                _buildCameraControls(),
                const SizedBox(height: 16),

                // ── Vista previa ────────────────────────────────
                _buildImagePreview(),
                const SizedBox(height: 20),

                // ── Botones de acción ───────────────────────────
                _buildActionButtons(),
                const SizedBox(height: 20),

                // ── OCR automático corriendo: spinner informativo ─
                if (_isProcessing && _imageBytes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Analizando texto de la imagen...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A237E),
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

  // ══════════════════════════════════════════════════════════════
  //  Vista de resultado de escaneo (igual que en la foto)
  // ══════════════════════════════════════════════════════════════
  Widget _buildScanResultView() {
    final String fechaStr = _formatFecha(_selectedDate);
    final String horaStr  = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('📄 Resultado del Escaneo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón para volver a escanear
          TextButton.icon(
            onPressed: () {
              setState(() {
                _extractedText = null;
                _image = null;
                _imageBytes = null;
                _ocrSavedId = null;
                _titleController.text = 'Tarea Escaneada';
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
            label: const Text('Nuevo', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── 1. Imagen escaneada en tarjeta ──────────────────
            if (_imageBytes != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Image.memory(
                        _imageBytes!,
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Badge de tipo en esquina superior derecha
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildTypeBadgeResult(_selectedType),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ── 2. Tarjeta de texto escaneado (estilo foto) ──────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado: título + icono editar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF0D1B4E),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF90A4AE), size: 22),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Texto extraído por OCR
                  Text(
                    _extractedText!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.65,
                      color: Color(0xFF37474F),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Chips de fecha y hora
                  Row(
                    children: [
                      _buildInfoChipLight(
                        Icons.calendar_today_rounded,
                        fechaStr,
                        const Color(0xFFE8EAF6),
                        const Color(0xFF3949AB),
                      ),
                      const SizedBox(width: 10),
                      _buildInfoChipLight(
                        Icons.access_time_rounded,
                        horaStr,
                        const Color(0xFFFFF9C4),
                        const Color(0xFF795548),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Opciones adicionales (tipo + fecha para guardar) ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Programar evento',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A237E))),
                  const SizedBox(height: 14),

                  // Tipo
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0D1B4E)),
                    items: const [
                      DropdownMenuItem(
                          value: 'homework',
                          child: Row(children: [
                            Icon(Icons.menu_book_rounded,
                                size: 20, color: Color(0xFF1A237E)),
                            SizedBox(width: 10),
                            Text('Tarea')
                          ])),
                      DropdownMenuItem(
                          value: 'exam',
                          child: Row(children: [
                            Icon(Icons.assignment_late_rounded,
                                size: 20, color: Colors.orange),
                            SizedBox(width: 10),
                            Text('Examen')
                          ])),
                      DropdownMenuItem(
                          value: 'reminder',
                          child: Row(children: [
                            Icon(Icons.notifications_active_rounded,
                                size: 20, color: Colors.green),
                            SizedBox(width: 10),
                            Text('Recordatorio')
                          ])),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val!),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F7FF),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fecha y hora
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null)
                              setState(() => _selectedDate = date);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBBDEFB)),
                            foregroundColor: const Color(0xFF1A237E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16),
                          label: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null)
                              setState(() => _selectedTime = time);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFF9C4)),
                            foregroundColor: const Color(0xFF795548),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 4. Botón guardar en agenda ─────────────────────
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF1A237E)),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveToAgenda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('GUARDAR EN MI AGENDA',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Formatea la fecha como "vie 21 ago"
  String _formatFecha(DateTime d) {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]}';
  }

  // Badge de tipo (EXAMEN / TAREA / etc.) igual al de la foto
  Widget _buildTypeBadgeResult(String type) {
    String label;
    Color bg;
    IconData icon;
    switch (type) {
      case 'exam':
        label = 'EXAMEN'; bg = const Color(0xFFE53935); icon = Icons.assignment_late_rounded;
        break;
      case 'reminder':
        label = 'RECORDATORIO'; bg = const Color(0xFF43A047); icon = Icons.notifications_active_rounded;
        break;
      default:
        label = 'TAREA'; bg = const Color(0xFF1976D2); icon = Icons.menu_book_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: bg.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // Chip de info claro (para la tarjeta blanca)
  Widget _buildInfoChipLight(
      IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ── Panel de controles de cámara ───────────────────────────────
  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selector cámara frontal/trasera ────────────────
          Row(
            children: [
              const Icon(Icons.camera, color: Colors.indigo, size: 18),
              const SizedBox(width: 8),
              const Text('Cámara', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const Spacer(),
              _CameraToggle(
                isFront: _cameraDevice == CameraDevice.front,
                onToggle: (front) =>
                    setState(() => _cameraDevice = front ? CameraDevice.front : CameraDevice.rear),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Selector de resolución (megapíxeles) ───────────
          Row(
            children: [
              const Icon(Icons.high_quality, color: Colors.indigoAccent, size: 18),
              const SizedBox(width: 8),
              const Text('Resolución', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: kResolutions.map((res) {
              final selected = res == _selectedResolution;
              return GestureDetector(
                onTap: () => setState(() => _selectedResolution = res),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? Colors.indigo : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.indigoAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    res.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Vista previa de imagen ─────────────────────────────────────
  Widget _buildImagePreview() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _isLoadingImage
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.indigoAccent),
                    SizedBox(height: 16),
                    Text('Cargando imagen...',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              )
            : _imageBytes != null
            ? FadeTransition(
                opacity: _fadeAnim,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                      cacheWidth: 1080,
                    ),
                    // Botón guardar en galería (esquina superior derecha)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _isSavingPhoto
                          ? const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : GestureDetector(
                              onTap: _savePhotoToGallery,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white30, width: 1),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save_alt,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 4),
                                    Text('Guardar foto',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    // Badge de resolución
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedResolution.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      size: 80, color: Colors.indigo.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Usa la cámara o galería\npara capturar una imagen',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Botones de acción ──────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBtn(
                onPressed: () => _getImage(ImageSource.camera),
                icon: Icons.camera_alt_rounded,
                label: 'CÁMARA',
                gradient: const LinearGradient(
                    colors: [Color(0xFF3949AB), Color(0xFF1A237E)]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBtn(
                onPressed: () => _getImage(ImageSource.gallery),
                icon: Icons.photo_library_rounded,
                label: 'GALERÍA',
                gradient: const LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF1A237E)]),
              ),
            ),
          ],
        ),
        // Botón guardar foto (solo si hay imagen)
        if (_image != null) ...[
          const SizedBox(height: 12),
          _buildBtn(
            onPressed: !_isSavingPhoto ? _savePhotoToGallery : null,
            icon: Icons.save_alt_rounded,
            label: 'GUARDAR FOTO EN GALERÍA',
            gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
          ),
        ],
      ],
    );
  }

  Widget _buildBtn({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
    bool flex = true,
  }) {
    final Widget inner = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null ? Colors.white12 : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: onPressed,
      child: flex ? inner : SizedBox(width: 140, child: inner),
    );
  }

  // _buildResultCard ya no se usa directamente (la lógica está en _buildScanResultView)
  // Se mantiene por compatibilidad pero no se llama.
}

// ── Widget toggle cámara front/back ─────────────────────────────
class _CameraToggle extends StatelessWidget {
  final bool isFront;
  final ValueChanged<bool> onToggle;

  const _CameraToggle({required this.isFront, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            label: '⬅ Trasera',
            selected: !isFront,
            onTap: () => onToggle(false),
          ),
          _Chip(
            label: 'Frontal ➡',
            selected: isFront,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 12),
        ),
      ),
    );
  }
}
