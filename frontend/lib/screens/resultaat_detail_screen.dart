import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';

class ResultaatDetailScreen extends StatefulWidget {
  final int resultaatId;

  const ResultaatDetailScreen({super.key, required this.resultaatId});

  @override
  State<ResultaatDetailScreen> createState() => _ResultaatDetailScreenState();
}

class _ResultaatDetailScreenState extends State<ResultaatDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/scan/resultaat/${widget.resultaatId}');
      if (mounted) setState(() { _data = response; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  Future<void> _editVraag(Map<String, dynamic> vraag) async {
    final puntenController = TextEditingController(
      text: '${vraag['behaalde_punten'] ?? 0}',
    );
    final feedbackController = TextEditingController(
      text: vraag['feedback'] ?? '',
    );
    final maxPunten = vraag['max_punten'] ?? 1;

    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text('Vraag ${vraag['vraag_nummer']} aanpassen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: puntenController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Behaalde punten (max $maxPunten)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Feedback'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuleren'),
          ),
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
        await api.put('/scan/resultaat/${widget.resultaatId}/vraag', {
          'vraag_nummer': vraag['vraag_nummer'],
          'behaalde_punten': double.tryParse(puntenController.text) ?? 0,
          'feedback': feedbackController.text,
        });
        if (mounted) {
          showAppSnackBar(context, 'Vraag ${vraag['vraag_nummer']} bijgewerkt', type: SnackBarType.success);
        }
        _load();
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
        title: Text(_data != null ? 'Resultaat ${_data!['leerling']}' : 'Resultaat'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Geen data gevonden'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final feedback = d['feedback'] as Map<String, dynamic>? ?? {};
    final resultaten = (feedback['resultaten'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final samenvatting = feedback['samenvatting'] as String? ?? '';
    final cijfer = d['cijfer'] as num?;
    final isOverruled = d['is_overruled'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _gradeColor(cijfer),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${cijfer?.toStringAsFixed(1) ?? '-'}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['leerling'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(d['toets'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                        Text('${d['score'] ?? 0}/${d['max_score'] ?? 0} punten', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        if (isOverruled)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(LucideIcons.pencil, size: 12, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text('Handmatig aangepast', style: TextStyle(fontSize: 12, color: AppColors.warning)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Summary
          if (samenvatting.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Samenvatting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              color: AppColors.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.lightbulb, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(samenvatting, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Antwoorden per vraag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Tik op een vraag om aan te passen', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          ...resultaten.map((vr) {
            final isCorrect = vr['is_correct'] == true;
            final punten = vr['behaalde_punten'] ?? 0;
            final maxPunten = vr['max_punten'] ?? 1;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _editVraag(vr),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        radius: 16,
                        child: Icon(
                          isCorrect ? LucideIcons.check : LucideIcons.x,
                          size: 16,
                          color: isCorrect ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Vraag ${vr['vraag_nummer']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$punten/$maxPunten',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isCorrect ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Antwoord: ${vr['gegeven_antwoord'] ?? '?'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (vr['feedback'] != null && (vr['feedback'] as String).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                vr['feedback'],
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.pencil, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _gradeColor(num? cijfer) {
    final c = cijfer ?? 1;
    if (c >= 7.5) return AppColors.success;
    if (c >= 5.5) return AppColors.warning;
    return AppColors.error;
  }
}
