import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';
import 'package:toets_scan_app/screens/resultaat_detail_screen.dart';

class ToetsAnalyseScreen extends StatefulWidget {
  final int toetsId;

  const ToetsAnalyseScreen({super.key, required this.toetsId});

  @override
  State<ToetsAnalyseScreen> createState() => _ToetsAnalyseScreenState();
}

class _ToetsAnalyseScreenState extends State<ToetsAnalyseScreen> {
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
      final response = await api.get('/dashboard/toets-analyse/${widget.toetsId}');
      if (mounted) setState(() { _data = response; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading analyse: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_data?['toets_titel'] ?? 'Analyse'),
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
    final aantalResultaten = d['aantal_resultaten'] as int? ?? 0;

    if (aantalResultaten == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.barChart3, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Nog geen resultaten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Scan eerst toetsen in om de analyse te zien.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final gemiddeld = d['gemiddeld_cijfer'] as num?;
    final hoogste = d['hoogste_cijfer'] as num?;
    final laagste = d['laagste_cijfer'] as num?;
    final verdeling = Map<String, dynamic>.from(d['score_verdeling'] ?? {});
    final vraagAnalyse = List<Map<String, dynamic>>.from(d['vraag_analyse'] ?? []);
    final resultaten = List<Map<String, dynamic>>.from(d['resultaten'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _miniStat('Gemiddeld', gemiddeld?.toStringAsFixed(1) ?? '-', _gradeColor(gemiddeld)),
              const SizedBox(width: 12),
              _miniStat('Hoogste', hoogste?.toStringAsFixed(1) ?? '-', AppColors.success),
              const SizedBox(width: 12),
              _miniStat('Laagste', laagste?.toStringAsFixed(1) ?? '-', AppColors.error),
              const SizedBox(width: 12),
              _miniStat('Leerlingen', '$aantalResultaten', AppColors.primary),
            ],
          ),
          const SizedBox(height: 28),

          // Score distribution chart
          if (verdeling.isNotEmpty) ...[
            const Text('Cijferverdeling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildBarChart(verdeling),
            ),
            const SizedBox(height: 28),
          ],

          // Per-question analysis
          if (vraagAnalyse.isNotEmpty) ...[
            const Text('Analyse per vraag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Tik op een vraag voor details', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ...vraagAnalyse.map((v) {
              final pct = v['correct_percentage'] as int? ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showVraagDetail(v['vraag_nummer'] as int),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _pctColor(pct).withValues(alpha: 0.1),
                          radius: 16,
                          child: Text('${v['vraag_nummer']}', style: TextStyle(color: _pctColor(pct), fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('$pct% goed', style: TextStyle(fontWeight: FontWeight.w600, color: _pctColor(pct))),
                                  Text('  (${v['correct']}/${v['totaal']})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                                  color: _pctColor(pct),
                                  minHeight: 6,
                                ),
                              ),
                              if (v['meest_gemaakte_fout'] != null) ...[
                                const SizedBox(height: 4),
                                Text('Meest gemaakte fout: ${v['meest_gemaakte_fout']}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                              ],
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),
          ],

          // Individual results
          const Text('Resultaten per leerling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...List.generate(resultaten.length, (i) {
            final r = resultaten[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: r['resultaat_id'] != null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ResultaatDetailScreen(resultaatId: r['resultaat_id']),
                          ),
                        ).then((_) => _load())
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _gradeColor(r['cijfer']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${(r['cijfer'] as num?)?.toStringAsFixed(1) ?? '-'}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _gradeColor(r['cijfer'])),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['leerling'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('${r['score'] ?? 0}/${r['max_score'] ?? 0} punten', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (r['confidence'] != null && (r['confidence'] as num) < 0.8)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.warning),
                        ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
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

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> verdeling) {
    final sortedKeys = ['1-2', '2-3', '3-4', '4-5', '5-6', '6-7', '7-8', '8-9', '9-10'];
    final bars = <BarChartGroupData>[];
    int index = 0;
    for (final key in sortedKeys) {
      final count = (verdeling[key] as num?)?.toDouble() ?? 0;
      if (count > 0 || verdeling.containsKey(key)) {
        bars.add(BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count,
              color: _gradeColor(index + 1.5),
              width: 24,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
        ));
      }
      index++;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: bars,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < sortedKeys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(sortedKeys[idx], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _gradeColor(dynamic cijfer) {
    final c = (cijfer as num?) ?? 1;
    if (c >= 7.5) return AppColors.success;
    if (c >= 5.5) return AppColors.warning;
    return AppColors.error;
  }

  Color _pctColor(int pct) {
    if (pct >= 75) return AppColors.success;
    if (pct >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _showVraagDetail(int vraagNummer) async {
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/dashboard/toets-analyse/${widget.toetsId}/vraag/$vraagNummer');

      if (!mounted) return;

      final goed = List<Map<String, dynamic>>.from(data['goed'] ?? []);
      final fout = List<Map<String, dynamic>>.from(data['fout'] ?? []);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text('Vraag $vraagNummer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${goed.length + fout.length} leerlingen', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    if (fout.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text('Fout (${fout.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                      ),
                      ...fout.map((f) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResultaatDetailScreen(resultaatId: f['resultaat_id']),
                              ),
                            ).then((_) => _load());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.x, size: 16, color: AppColors.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f['leerling'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('Antwoord: ${f['gegeven_antwoord']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      if (f['feedback'] != null && (f['feedback'] as String).isNotEmpty)
                                        Text(f['feedback'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                Text('${f['behaalde_punten']}/${f['max_punten']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                    if (goed.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text('Goed (${goed.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                      ),
                      ...goed.map((g) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.check, size: 16, color: AppColors.success),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(g['leerling'], style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              Text('${g['behaalde_punten']}/${g['max_punten']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success, fontSize: 13)),
                            ],
                          ),
                        ),
                      )),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), type: SnackBarType.error);
    }
  }
}
