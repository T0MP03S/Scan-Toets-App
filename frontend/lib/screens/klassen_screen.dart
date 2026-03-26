import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/models/klas_model.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';
import 'package:toets_scan_app/screens/leerlingen_screen.dart';

class KlassenScreen extends StatefulWidget {
  const KlassenScreen({super.key});

  @override
  State<KlassenScreen> createState() => _KlassenScreenState();
}

class _KlassenScreenState extends State<KlassenScreen> {
  List<KlasModel> _klassen = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadKlassen();
  }

  Future<void> _loadKlassen() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final path = _search.isEmpty ? '/klassen' : '/klassen?search=$_search';
      final response = await api.get(path);
      setState(() {
        _klassen = (response as List).map((j) => KlasModel.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
    }
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe klas'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Klasnaam',
            hintText: 'bijv. Groep 6A',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Aanmaken'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        final api = context.read<ApiService>();
        await api.post('/klassen', {'naam': result.trim()});
        if (mounted) showAppSnackBar(context, 'Klas "$result" aangemaakt', type: SnackBarType.success);
        _loadKlassen();
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _showEditDialog(KlasModel klas) async {
    final controller = TextEditingController(text: klas.naam);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klas bewerken'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Klasnaam'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result.trim() != klas.naam) {
      try {
        final api = context.read<ApiService>();
        await api.put('/klassen/${klas.id}', {'naam': result.trim()});
        if (mounted) showAppSnackBar(context, 'Klas hernoemd', type: SnackBarType.success);
        _loadKlassen();
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _confirmDelete(KlasModel klas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klas verwijderen'),
        content: Text(
          'Weet je zeker dat je "${klas.naam}" wilt verwijderen? '
          'Alle ${klas.leerlingCount} leerlingen worden ook verwijderd.',
        ),
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
        await api.delete('/klassen/${klas.id}');
        if (mounted) showAppSnackBar(context, '"${klas.naam}" verwijderd', type: SnackBarType.success);
        _loadKlassen();
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
        title: const Text('Klassen'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Nieuwe klas'),
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
                hintText: 'Zoek een klas...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          setState(() => _search = '');
                          _loadKlassen();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _search = value);
                _loadKlassen();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _klassen.isEmpty
                    ? _buildEmptyState()
                    : _buildKlassenList(),
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
          const Icon(LucideIcons.users, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty ? 'Geen klassen gevonden' : 'Nog geen klassen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty ? 'Probeer een andere zoekterm.' : 'Maak je eerste klas aan om te beginnen.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildKlassenList() {
    return RefreshIndicator(
      onRefresh: _loadKlassen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: _klassen.length,
        itemBuilder: (context, index) {
          final klas = _klassen[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeerlingenScreen(klas: klas),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.users, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            klas.naam,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${klas.leerlingCount} leerling${klas.leerlingCount == 1 ? '' : 'en'}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.textSecondary),
                      onPressed: () => _showEditDialog(klas),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                      onPressed: () => _confirmDelete(klas),
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
}
