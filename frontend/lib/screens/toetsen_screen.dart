import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/models/klas_model.dart';
import 'package:toets_scan_app/models/toets_model.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';
import 'package:toets_scan_app/screens/toets_detail_screen.dart';

class ToetsenScreen extends StatefulWidget {
  const ToetsenScreen({super.key});

  @override
  State<ToetsenScreen> createState() => _ToetsenScreenState();
}

class _ToetsenScreenState extends State<ToetsenScreen> {
  List<ToetsListModel> _toetsen = [];
  List<KlasModel> _klassen = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKlassen();
      _loadToetsen();
    });
  }

  Future<void> _loadKlassen() async {
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/klassen');
      if (mounted) {
        setState(() {
          _klassen = (response as List).map((j) => KlasModel.fromJson(j)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading klassen: $e');
    }
  }

  Future<void> _loadToetsen() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final path = _search.isEmpty ? '/toetsen' : '/toetsen?search=$_search';
      final response = await api.get(path);
      if (mounted) {
        setState(() {
          _toetsen = (response as List).map((j) => ToetsListModel.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading toetsen: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _showCreateDialog() async {
    if (_klassen.isEmpty) {
      showAppSnackBar(context, 'Maak eerst een klas aan', type: SnackBarType.warning);
      return;
    }

    final titelController = TextEditingController();
    final vakController = TextEditingController();
    final beschrijvingController = TextEditingController();
    KlasModel? selectedKlas = _klassen.first;

    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nieuwe toets'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<KlasModel>(
                  initialValue: selectedKlas,
                  decoration: const InputDecoration(
                    labelText: 'Klas',
                    prefixIcon: Icon(LucideIcons.users, size: 18),
                  ),
                  items: _klassen.map((k) => DropdownMenuItem(
                    value: k,
                    child: Text(k.naam),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedKlas = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titelController,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    hintText: 'bijv. Rekenen Week 12',
                    prefixIcon: Icon(LucideIcons.fileText, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vakController,
                  decoration: const InputDecoration(
                    labelText: 'Vak',
                    hintText: 'bijv. Rekenen',
                    prefixIcon: Icon(LucideIcons.bookOpen, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: beschrijvingController,
                  decoration: const InputDecoration(
                    labelText: 'Beschrijving (optioneel)',
                    prefixIcon: Icon(LucideIcons.alignLeft, size: 18),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuleren')),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Aanmaken'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titelController.text.trim().isNotEmpty && vakController.text.trim().isNotEmpty && selectedKlas != null) {
      try {
        final api = context.read<ApiService>();
        await api.post('/toetsen', {
          'titel': titelController.text.trim(),
          'vak': vakController.text.trim(),
          'beschrijving': beschrijvingController.text.trim().isEmpty ? null : beschrijvingController.text.trim(),
          'klas_id': selectedKlas!.id,
        });
        if (mounted) showAppSnackBar(context, 'Toets aangemaakt', type: SnackBarType.success);
        _loadToetsen();
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _confirmDelete(ToetsListModel toets) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Toets verwijderen'),
        content: Text('Weet je zeker dat je "${toets.titel}" wilt verwijderen? Alle resultaten worden ook verwijderd.'),
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
        await api.delete('/toetsen/${toets.id}');
        if (mounted) showAppSnackBar(context, '"${toets.titel}" verwijderd', type: SnackBarType.success);
        _loadToetsen();
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
        title: const Text('Toetsen'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Nieuwe toets'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Zoek op titel of vak...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          setState(() => _search = '');
                          _loadToetsen();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _search = value);
                _loadToetsen();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _toetsen.isEmpty
                    ? _buildEmptyState()
                    : _buildToetsenList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty ? 'Geen toetsen gevonden' : 'Nog geen toetsen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty ? 'Probeer een andere zoekterm.' : 'Maak je eerste toets aan om te beginnen.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildToetsenList() {
    return RefreshIndicator(
      onRefresh: _loadToetsen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: _toetsen.length,
        itemBuilder: (context, index) {
          final toets = _toetsen[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ToetsDetailScreen(toetsId: toets.id)),
                );
                _loadToetsen();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: toets.aantalVragen > 0
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        toets.aantalVragen > 0 ? LucideIcons.fileCheck : LucideIcons.fileText,
                        size: 20,
                        color: toets.aantalVragen > 0 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(toets.titel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildChip(toets.vak, LucideIcons.bookOpen),
                              const SizedBox(width: 8),
                              _buildChip(toets.klasNaam, LucideIcons.users),
                              if (toets.aantalVragen > 0) ...[
                                const SizedBox(width: 8),
                                _buildChip('${toets.aantalVragen} vragen', LucideIcons.list),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                      onPressed: () => _confirmDelete(toets),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
