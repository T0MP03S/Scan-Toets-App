import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/models/klas_model.dart';
import 'package:toets_scan_app/models/toets_model.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Step 0: select klas + toets
  List<KlasModel> _klassen = [];
  List<ToetsListModel> _toetsen = [];
  KlasModel? _selectedKlas;
  ToetsListModel? _selectedToets;

  // Step 1: scan status (student list)
  List<Map<String, dynamic>> _leerlingen = [];
  int _gescand = 0;

  // Step 2: scan a student
  Map<String, dynamic>? _currentLeerling;
  List<_PagePhoto> _pages = [];
  bool _isUploading = false;
  bool _isGrading = false;

  // Step 3: result
  Map<String, dynamic>? _gradeResult;

  int _step = 0; // 0=select, 1=student list, 2=upload photos, 3=result

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadKlassen());
  }

  // ── Data loading ───────────────────────────────────────────

  Future<void> _loadKlassen() async {
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/klassen');
      if (mounted) setState(() => _klassen = (response as List).map((j) => KlasModel.fromJson(j)).toList());
    } catch (e) {
      debugPrint('Error loading klassen: $e');
    }
  }

  Future<void> _loadToetsen(int klasId) async {
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/toetsen?klas_id=$klasId');
      if (mounted) {
        setState(() {
          _toetsen = (response as List).map((j) => ToetsListModel.fromJson(j)).toList();
          _selectedToets = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading toetsen: $e');
    }
  }

  Future<void> _loadScanStatus() async {
    if (_selectedToets == null) return;
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/scan/status/${_selectedToets!.id}');
      if (mounted) {
        setState(() {
          _leerlingen = List<Map<String, dynamic>>.from(response['items']);
          _gescand = response['gescand'];
        });
      }
    } catch (e) {
      debugPrint('Error loading scan status: $e');
    }
  }

  // ── Actions ────────────────────────────────────────────────

  void _startScanStraat() {
    if (_selectedToets == null) return;
    if (_selectedToets!.aantalVragen == 0) {
      showAppSnackBar(context, 'Deze toets heeft nog geen antwoordmodel', type: SnackBarType.warning);
      return;
    }
    _loadScanStatus();
    setState(() => _step = 1);
  }

  void _selectLeerling(Map<String, dynamic> leerling) {
    setState(() {
      _currentLeerling = leerling;
      _pages = [];
      _gradeResult = null;
      _step = 2;
    });
  }

  Future<void> _pickImage() async {
    if (_pages.length >= 4) {
      showAppSnackBar(context, 'Maximaal 4 pagina\'s per leerling', type: SnackBarType.warning);
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final name = picked.name;

    setState(() => _isUploading = true);

    try {
      final api = context.read<ApiService>();
      final uri = Uri.parse('${api.baseUrl}/scan/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${api.token}';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
        contentType: MediaType('image', name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'),
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = _parseJson(body);
        setState(() {
          _pages.add(_PagePhoto(filename: json['filename'], bytes: bytes));
        });
      } else {
        if (mounted) showAppSnackBar(context, 'Upload mislukt', type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Upload fout: $e', type: SnackBarType.error);
    }

    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _gradeCurrentStudent() async {
    if (_pages.isEmpty || _currentLeerling == null || _selectedToets == null) return;

    setState(() => _isGrading = true);

    try {
      final api = context.read<ApiService>();
      final result = await api.post('/scan/grade', {
        'toets_id': _selectedToets!.id,
        'leerling_id': _currentLeerling!['leerling_id'],
        'filenames': _pages.map((p) => p.filename).toList(),
      });

      setState(() {
        _gradeResult = result;
        _step = 3;
      });
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Nakijken mislukt: $e', type: SnackBarType.error);
    }

    if (mounted) setState(() => _isGrading = false);
  }

  void _nextStudent() {
    _loadScanStatus();
    setState(() {
      _currentLeerling = null;
      _pages = [];
      _gradeResult = null;
      _step = 1;
    });
  }

  void _backToSelection() {
    setState(() {
      _step = 0;
      _selectedToets = null;
      _leerlingen = [];
      _gescand = 0;
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepTitle()),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () {
                  if (_step == 3) { _nextStudent(); }
                  else if (_step == 2) { setState(() => _step = 1); }
                  else if (_step == 1) { _backToSelection(); }
                },
              )
            : null,
      ),
      body: switch (_step) {
        0 => _buildSelectStep(),
        1 => _buildStudentListStep(),
        2 => _buildUploadStep(),
        3 => _buildResultStep(),
        _ => const SizedBox(),
      },
    );
  }

  String _stepTitle() => switch (_step) {
    0 => 'Scannen',
    1 => 'Leerlingen',
    2 => '${_currentLeerling?['voornaam'] ?? ''} ${_currentLeerling?['achternaam'] ?? ''}',
    3 => 'Resultaat',
    _ => 'Scannen',
  };

  // ── Step 0: Select klas + toets ────────────────────────────

  Widget _buildSelectStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Start een scan-sessie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Kies een klas en toets om te beginnen met nakijken.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<KlasModel>(
                    decoration: const InputDecoration(labelText: 'Klas', prefixIcon: Icon(LucideIcons.users, size: 18)),
                    items: _klassen.map((k) => DropdownMenuItem(value: k, child: Text(k.naam))).toList(),
                    onChanged: (k) {
                      setState(() { _selectedKlas = k; _selectedToets = null; _toetsen = []; });
                      if (k != null) _loadToetsen(k.id);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ToetsListModel>(
                    decoration: const InputDecoration(labelText: 'Toets', prefixIcon: Icon(LucideIcons.fileText, size: 18)),
                    items: _toetsen.map((t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Expanded(child: Text(t.titel)),
                          if (t.aantalVragen > 0)
                            Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success)
                          else
                            Icon(LucideIcons.alertCircle, size: 14, color: AppColors.warning),
                        ],
                      ),
                    )).toList(),
                    onChanged: (t) => setState(() => _selectedToets = t),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _selectedToets != null ? _startScanStraat : null,
                      icon: const Icon(LucideIcons.scanLine, size: 18),
                      label: const Text('Start scannen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Student list with status ───────────────────────

  Widget _buildStudentListStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(LucideIcons.barChart3, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '$_gescand van ${_leerlingen.length} leerlingen nagekeken',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const Spacer(),
              if (_gescand > 0)
                Text(
                  '${(_gescand / _leerlingen.length * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
            ],
          ),
        ),
        if (_leerlingen.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _leerlingen.isEmpty ? 0 : _gescand / _leerlingen.length,
                backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            itemCount: _leerlingen.length,
            itemBuilder: (context, index) {
              final l = _leerlingen[index];
              final isGraded = l['status'] == 'nagekeken';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectLeerling(l),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isGraded
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.textSecondary.withValues(alpha: 0.1),
                          radius: 20,
                          child: isGraded
                              ? const Icon(LucideIcons.check, size: 18, color: AppColors.success)
                              : Text(
                                  '${l['voornaam'][0]}${l['achternaam'][0]}'.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l['voornaam']} ${l['achternaam']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isGraded ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                              if (isGraded && l['cijfer'] != null)
                                Text(
                                  'Cijfer: ${l['cijfer']}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.success),
                                ),
                            ],
                          ),
                        ),
                        if (isGraded)
                          const Icon(LucideIcons.checkCircle, size: 18, color: AppColors.success)
                        else
                          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 2: Upload photos ──────────────────────────────────

  Widget _buildUploadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(LucideIcons.user, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    '${_currentLeerling?['voornaam']} ${_currentLeerling?['achternaam']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Pagina\'s (${_pages.length}/4)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          if (_pages.isEmpty)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('Tik om een foto te uploaden', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(_pages.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Image.memory(_pages[i].bytes, height: 200, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Text('Pagina ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                            onPressed: () => setState(() => _pages.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),

          const SizedBox(height: 12),

          Row(
            children: [
              if (_pages.length < 4)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: _isUploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.plus, size: 16),
                    label: Text(_pages.isEmpty ? 'Foto uploaden' : 'Nog een pagina'),
                  ),
                ),
              if (_pages.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isGrading ? null : _gradeCurrentStudent,
                      icon: _isGrading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.sparkles, size: 16),
                      label: Text(_isGrading ? 'Bezig met nakijken...' : 'Nakijken'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 3: Result ─────────────────────────────────────────

  Widget _buildResultStep() {
    if (_gradeResult == null) return const SizedBox();
    final feedback = _gradeResult!['feedback'] as Map<String, dynamic>? ?? {};
    final resultaten = (feedback['resultaten'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final cijfer = _gradeResult!['cijfer'];
    final score = _gradeResult!['score'];
    final maxScore = _gradeResult!['max_score'];
    final confidence = _gradeResult!['confidence'] as num? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade card
          Card(
            color: confidence < 0.8
                ? AppColors.warning.withValues(alpha: 0.05)
                : AppColors.success.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _gradeColor(cijfer),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${(cijfer as num).toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentLeerling?['voornaam']} ${_currentLeerling?['achternaam']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text('$score / $maxScore punten', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              confidence >= 0.8 ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                              size: 14,
                              color: confidence >= 0.8 ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Zekerheid: ${(confidence * 100).round()}%',
                              style: TextStyle(
                                fontSize: 13,
                                color: confidence >= 0.8 ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (confidence < 0.8) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.warning.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 18, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'De AI is niet helemaal zeker van het resultaat. Controleer de antwoorden hieronder.',
                        style: TextStyle(fontSize: 13, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Text('Per vraag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          ...resultaten.map((r) {
            final isCorrect = r['is_correct'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: isCorrect
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      radius: 14,
                      child: Icon(
                        isCorrect ? LucideIcons.check : LucideIcons.x,
                        size: 14,
                        color: isCorrect ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vraag ${r['vraag_nummer']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            'Antwoord: ${r['gegeven_antwoord'] ?? '?'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (r['feedback'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(r['feedback'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${r['behaalde_punten']}/${r['max_punten']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isCorrect ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _nextStudent,
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: const Text('Volgende leerling'),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(dynamic cijfer) {
    final c = (cijfer as num?) ?? 1;
    if (c >= 7.5) return AppColors.success;
    if (c >= 5.5) return AppColors.warning;
    return AppColors.error;
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      return Map<String, dynamic>.from(jsonDecode(body));
    } catch (_) {
      return {};
    }
  }
}

class _PagePhoto {
  final String filename;
  final Uint8List bytes;
  _PagePhoto({required this.filename, required this.bytes});
}

