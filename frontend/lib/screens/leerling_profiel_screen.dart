import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';
import 'package:toets_scan_app/screens/resultaat_detail_screen.dart';

class LeerlingProfielScreen extends StatefulWidget {
  final int klasId;
  final int leerlingId;

  const LeerlingProfielScreen({super.key, required this.klasId, required this.leerlingId});

  @override
  State<LeerlingProfielScreen> createState() => _LeerlingProfielScreenState();
}

class _LeerlingProfielScreenState extends State<LeerlingProfielScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  final _notitiesController = TextEditingController();
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _notitiesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final response = await api.get('/klassen/${widget.klasId}/leerlingen/${widget.leerlingId}/profiel');
      if (mounted) {
        setState(() {
          _data = response;
          _notitiesController.text = response['notities'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppSnackBar(context, e.toString(), type: SnackBarType.error);
      }
    }
  }

  void _onNotitiesChanged(String value) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1500), () => _saveNotities(value));
  }

  Future<void> _saveNotities(String value) async {
    try {
      final api = context.read<ApiService>();
      await api.put('/klassen/${widget.klasId}/leerlingen/${widget.leerlingId}/notities', {
        'notities': value,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final naam = _data != null ? '${_data!['voornaam']} ${_data!['achternaam']}' : 'Profiel';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(naam),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Geen data'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final resultaten = List<Map<String, dynamic>>.from(d['resultaten'] ?? []);
    final samenvattingen = List<Map<String, dynamic>>.from(d['samenvattingen'] ?? []);
    final gemiddeld = d['gemiddeld_cijfer'] as num?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 28,
                    child: Text(
                      '${d['voornaam'][0]}${d['achternaam'][0]}'.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d['voornaam']} ${d['achternaam']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.school, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(d['klas_naam'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(width: 16),
                            const Icon(LucideIcons.user, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(d['leerkracht'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (gemiddeld != null)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _gradeColor(gemiddeld),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          gemiddeld.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Grade chart
          if (resultaten.length >= 2) ...[
            const SizedBox(height: 24),
            const Text('Cijferverloop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: _buildChart(resultaten),
            ),
          ],

          // Grades list
          const SizedBox(height: 24),
          const Text('Cijferlijst', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (resultaten.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('Nog geen resultaten', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            )
          else
            ...resultaten.map((r) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ResultaatDetailScreen(resultaatId: r['resultaat_id']),
                    ),
                  ).then((_) => _load());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            Text(r['toets_titel'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('${r['vak'] ?? ''} • ${r['score'] ?? 0}/${r['max_score'] ?? 0} punten',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            )),

          // Werkpunten (samenvattingen)
          if (samenvattingen.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Werkpunten', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...samenvattingen.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: AppColors.warning.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.target, size: 16, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s['toets']} (${s['vak']})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(s['tekst'] ?? '', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],

          // Notities
          const SizedBox(height: 24),
          const Text('Notities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TextField(
                controller: _notitiesController,
                maxLines: 6,
                onChanged: _onNotitiesChanged,
                decoration: const InputDecoration(
                  hintText: 'Typ hier notities over deze leerling...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Notities worden automatisch opgeslagen',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> resultaten) {
    final reversed = resultaten.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < reversed.length; i++) {
      final c = reversed[i]['cijfer'] as num?;
      if (c != null) spots.add(FlSpot(i.toDouble(), c.toDouble()));
    }
    if (spots.isEmpty) return const SizedBox();

    return LineChart(
      LineChartData(
        minY: 1,
        maxY: 10,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: value == 5.5 ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.3),
            strokeWidth: value == 5.5 ? 1.5 : 0.5,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, meta) =>
                  Text('${value.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: _gradeColor(spot.y),
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.08),
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
}
