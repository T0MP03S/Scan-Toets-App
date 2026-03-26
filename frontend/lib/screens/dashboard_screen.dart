import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:toets_scan_app/config/theme.dart';
import 'package:toets_scan_app/providers/auth_provider.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/widgets/snackbar_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final stats = await api.get('/dashboard/stats');
      final recent = await api.get('/dashboard/recent-results');
      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(stats);
          _recentResults = List<Map<String, dynamic>>.from(recent);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
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
        title: const Text('Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welkom terug, ${context.watch<AuthProvider>().user?.fullName ?? ''}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hier is een overzicht van je klassen en toetsen.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Stat cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _StatCard(
                              icon: LucideIcons.users,
                              label: 'Klassen',
                              value: '${_stats['klassen'] ?? 0}',
                              color: AppColors.primary,
                            ),
                            _StatCard(
                              icon: LucideIcons.graduationCap,
                              label: 'Leerlingen',
                              value: '${_stats['leerlingen'] ?? 0}',
                              color: const Color(0xFF3B82F6),
                            ),
                            _StatCard(
                              icon: LucideIcons.fileText,
                              label: 'Toetsen',
                              value: '${_stats['toetsen'] ?? 0}',
                              color: const Color(0xFF8B5CF6),
                            ),
                            _StatCard(
                              icon: LucideIcons.checkCircle,
                              label: 'Nagekeken',
                              value: '${_stats['nagekeken'] ?? 0}',
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Recent results
                    if (_recentResults.isNotEmpty) ...[
                      const Text(
                        'Recente resultaten',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ...(_recentResults.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _gradeColor(r['cijfer']).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${(r['cijfer'] as num?)?.toStringAsFixed(1) ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _gradeColor(r['cijfer']),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['leerling'] ?? '',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r['toets'] ?? ''} • ${r['score'] ?? 0}/${r['max_score'] ?? 0} punten',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (r['confidence'] != null && (r['confidence'] as num) < 0.8)
                                const Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.warning),
                            ],
                          ),
                        ),
                      ))),
                    ] else ...[
                      // Getting started card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(LucideIcons.info, size: 20, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Aan de slag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '1. Maak eerst een klas aan en voeg leerlingen toe\n'
                                '2. Maak een toets aan met het antwoordmodel\n'
                                '3. Scan de gemaakte toetsen van je leerlingen\n'
                                '4. Bekijk de resultaten en analyse op het dashboard',
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
