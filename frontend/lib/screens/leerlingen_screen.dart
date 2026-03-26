import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/models/klas_model.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';

class LeerlingenScreen extends StatefulWidget {
  final KlasModel klas;

  const LeerlingenScreen({super.key, required this.klas});

  @override
  State<LeerlingenScreen> createState() => _LeerlingenScreenState();
}

class _LeerlingenScreenState extends State<LeerlingenScreen> {
  List<LeerlingModel> _leerlingen = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadLeerlingen();
  }

  Future<void> _loadLeerlingen() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final base = '/klassen/${widget.klas.id}/leerlingen';
      final path = _search.isEmpty ? base : '$base?search=$_search';
      final response = await api.get(path);
      setState(() {
        _leerlingen = (response as List).map((j) => LeerlingModel.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
    }
  }

  Future<void> _showAddDialog() async {
    final voornaamController = TextEditingController();
    final achternaamController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leerling toevoegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: voornaamController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Voornaam'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: achternaamController,
              decoration: const InputDecoration(labelText: 'Achternaam'),
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );

    if (result == true && voornaamController.text.trim().isNotEmpty && achternaamController.text.trim().isNotEmpty) {
      try {
        final api = context.read<ApiService>();
        await api.post('/klassen/${widget.klas.id}/leerlingen', {
          'voornaam': voornaamController.text.trim(),
          'achternaam': achternaamController.text.trim(),
        });
        if (mounted) {
          showAppSnackBar(context, 'Leerling toegevoegd', type: SnackBarType.success);
        }
        _loadLeerlingen();
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _showEditDialog(LeerlingModel leerling) async {
    final voornaamController = TextEditingController(text: leerling.voornaam);
    final achternaamController = TextEditingController(text: leerling.achternaam);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leerling bewerken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: voornaamController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Voornaam'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: achternaamController,
              decoration: const InputDecoration(labelText: 'Achternaam'),
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final api = context.read<ApiService>();
        await api.put('/klassen/${widget.klas.id}/leerlingen/${leerling.id}', {
          'voornaam': voornaamController.text.trim(),
          'achternaam': achternaamController.text.trim(),
        });
        if (mounted) showAppSnackBar(context, 'Leerling bijgewerkt', type: SnackBarType.success);
        _loadLeerlingen();
      } catch (e) {
        if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _confirmDelete(LeerlingModel leerling) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leerling verwijderen'),
        content: Text('Weet je zeker dat je "${leerling.volledigeNaam}" wilt verwijderen?'),
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
        await api.delete('/klassen/${widget.klas.id}/leerlingen/${leerling.id}');
        if (mounted) showAppSnackBar(context, '"${leerling.volledigeNaam}" verwijderd', type: SnackBarType.success);
        _loadLeerlingen();
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
        title: Text(widget.klas.naam),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('Leerling toevoegen'),
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
                hintText: 'Zoek een leerling...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          setState(() => _search = '');
                          _loadLeerlingen();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _search = value);
                _loadLeerlingen();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_leerlingen.length} leerling${_leerlingen.length == 1 ? '' : 'en'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _leerlingen.isEmpty
                    ? _buildEmptyState()
                    : _buildLeerlingenList(),
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
          const Icon(LucideIcons.graduationCap, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty ? 'Geen leerlingen gevonden' : 'Nog geen leerlingen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty ? 'Probeer een andere zoekterm.' : 'Voeg je eerste leerling toe.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLeerlingenList() {
    return RefreshIndicator(
      onRefresh: _loadLeerlingen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _leerlingen.length,
        itemBuilder: (context, index) {
          final leerling = _leerlingen[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    radius: 20,
                    child: Text(
                      '${leerling.voornaam[0]}${leerling.achternaam[0]}'.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      leerling.volledigeNaam,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.textSecondary),
                    onPressed: () => _showEditDialog(leerling),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                    onPressed: () => _confirmDelete(leerling),
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
