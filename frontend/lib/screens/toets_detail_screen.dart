import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/models/toets_model.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';
import 'package:toets_scan_app/screens/toets_analyse_screen.dart';

class ToetsDetailScreen extends StatefulWidget {
  final int toetsId;

  const ToetsDetailScreen({super.key, required this.toetsId});

  @override
  State<ToetsDetailScreen> createState() => _ToetsDetailScreenState();
}

class _ToetsDetailScreenState extends State<ToetsDetailScreen> {
  ToetsModel? _toets;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToets());
  }

  Future<void> _loadToets() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/toetsen/${widget.toetsId}');
      if (mounted) {
        setState(() {
          _toets = ToetsModel.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading toets: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _openAntwoordmodelEditor() async {
    if (_toets == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AntwoordmodelEditor(
          toetsId: widget.toetsId,
          existingVragen: _toets!.vragen,
        ),
      ),
    );

    if (result == true) _loadToets();
  }

  Future<void> _scanAntwoordmodel() async {
    if (_toets == null) return;

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isEmpty) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Antwoordmodel wordt gescand...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final api = context.read<ApiService>();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${api.baseUrl}/scan/extract-answer-model'),
      );
      request.headers['Authorization'] = 'Bearer ${api.token}';

      for (final image in images) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: image.name,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final vragen = (data['vragen'] as List).map((v) => VraagModel(
          nummer: v['nummer'],
          vraag: v['vraag'] ?? 'Vraag ${v['nummer']}',
          correctAntwoord: v['correct_antwoord'],
          punten: v['punten'] ?? 1,
        )).toList();

        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => _AntwoordmodelEditor(
              toetsId: widget.toetsId,
              existingVragen: vragen,
            ),
          ),
        );

        if (result == true) _loadToets();
      } else {
        final error = json.decode(responseBody);
        if (mounted) showAppSnackBar(context, error['detail'] ?? 'Scan mislukt', type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnackBar(context, 'Fout bij scannen: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _deleteAntwoordmodel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Antwoordmodel verwijderen'),
        content: const Text('Weet je zeker dat je het antwoordmodel wilt verwijderen?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuleren')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = context.read<ApiService>();
        await api.delete('/toetsen/${widget.toetsId}/antwoordmodel');
        if (mounted) showAppSnackBar(context, 'Antwoordmodel verwijderd', type: SnackBarType.success);
        _loadToets();
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_toets?.titel ?? 'Toets'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_toets != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ToetsAnalyseScreen(toetsId: widget.toetsId)),
                ),
                icon: const Icon(LucideIcons.barChart3, size: 16),
                label: const Text('Analyse'),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _toets == null
              ? const Center(child: Text('Toets niet gevonden'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final toets = _toets!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.fileText, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(toets.titel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(LucideIcons.bookOpen, 'Vak', toets.vak),
                  const SizedBox(height: 8),
                  _infoRow(LucideIcons.users, 'Klas', toets.klasNaam),
                  if (toets.beschrijving != null && toets.beschrijving!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow(LucideIcons.alignLeft, 'Beschrijving', toets.beschrijving!),
                  ],
                  if (toets.totaalPunten != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(LucideIcons.hash, 'Totaal punten', '${toets.totaalPunten}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Antwoordmodel section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Antwoordmodel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  if (toets.heeftAntwoordmodel)
                    TextButton.icon(
                      onPressed: _deleteAntwoordmodel,
                      icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                      label: const Text('Verwijderen', style: TextStyle(color: AppColors.error)),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _scanAntwoordmodel,
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: const Text('Scannen'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openAntwoordmodelEditor,
                    icon: Icon(toets.heeftAntwoordmodel ? LucideIcons.pencil : LucideIcons.plus, size: 16),
                    label: Text(toets.heeftAntwoordmodel ? 'Bewerken' : 'Invoeren'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!toets.heeftAntwoordmodel)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.clipboardList, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Nog geen antwoordmodel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Voer de vragen en antwoorden in of scan een antwoordmodel.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...toets.vragen.map((v) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      radius: 16,
                      child: Text(
                        '${v.nummer}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.vraag, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.check, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(v.correctAntwoord, style: const TextStyle(fontSize: 13, color: AppColors.success)),
                              const Spacer(),
                              Text('${v.punten} pt', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      ],
    );
  }
}


// ── Antwoordmodel Editor ─────────────────────────────────────

class _AntwoordmodelEditor extends StatefulWidget {
  final int toetsId;
  final List<VraagModel> existingVragen;

  const _AntwoordmodelEditor({required this.toetsId, required this.existingVragen});

  @override
  State<_AntwoordmodelEditor> createState() => _AntwoordmodelEditorState();
}

class _AntwoordmodelEditorState extends State<_AntwoordmodelEditor> {
  final List<_VraagEntry> _entries = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingVragen.isNotEmpty) {
      for (final v in widget.existingVragen) {
        _entries.add(_VraagEntry(
          vraagController: TextEditingController(text: v.vraag),
          antwoordController: TextEditingController(text: v.correctAntwoord),
          puntenController: TextEditingController(text: '${v.punten}'),
        ));
      }
    } else {
      _addEntry();
    }
  }

  void _addEntry() {
    setState(() {
      _entries.add(_VraagEntry(
        vraagController: TextEditingController(),
        antwoordController: TextEditingController(),
        puntenController: TextEditingController(text: '1'),
      ));
    });
  }

  void _removeEntry(int index) {
    if (_entries.length > 1) {
      setState(() => _entries.removeAt(index));
    }
  }

  Future<void> _save() async {
    final vragen = <Map<String, dynamic>>[];
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.vraagController.text.trim().isEmpty || e.antwoordController.text.trim().isEmpty) {
        showAppSnackBar(context, 'Vul alle velden in bij vraag ${i + 1}', type: SnackBarType.warning);
        return;
      }
      final punten = int.tryParse(e.puntenController.text) ?? 1;
      vragen.add({
        'nummer': i + 1,
        'vraag': e.vraagController.text.trim(),
        'correct_antwoord': e.antwoordController.text.trim(),
        'punten': punten,
      });
    }

    setState(() => _isSaving = true);
    try {
      final api = context.read<ApiService>();
      await api.put('/toetsen/${widget.toetsId}/antwoordmodel', {'vragen': vragen});
      if (mounted) {
        showAppSnackBar(context, 'Antwoordmodel opgeslagen', type: SnackBarType.success);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.vraagController.dispose();
      e.antwoordController.dispose();
      e.puntenController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Antwoordmodel'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.save, size: 16),
              label: const Text('Opslaan'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        radius: 14,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Vraag ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_entries.length > 1)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                          onPressed: () => _removeEntry(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: entry.vraagController,
                    decoration: const InputDecoration(
                      labelText: 'Vraag',
                      hintText: 'bijv. 12 + 15 = ?',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: entry.antwoordController,
                          decoration: const InputDecoration(
                            labelText: 'Correct antwoord',
                            hintText: 'bijv. 27',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: entry.puntenController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Punten'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VraagEntry {
  final TextEditingController vraagController;
  final TextEditingController antwoordController;
  final TextEditingController puntenController;

  _VraagEntry({
    required this.vraagController,
    required this.antwoordController,
    required this.puntenController,
  });
}
