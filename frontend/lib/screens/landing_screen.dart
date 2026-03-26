import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:toets_scan_app/config/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: isWide ? 80 : 48,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primaryLight.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Nav bar
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.scanLine, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Toets Scan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Inloggen'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Registreren'),
                      ),
                    ],
                  ),

                  SizedBox(height: isWide ? 80 : 48),

                  // Hero content
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        Text(
                          'Toetsen nakijken\nmet AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isWide ? 48 : 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Upload een foto van een handgeschreven toets en laat Gemini AI het nakijken. '
                          'Binnen seconden een cijfer, feedback per vraag en inzicht in wat je klas nog moet oefenen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isWide ? 18 : 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(LucideIcons.arrowRight, size: 18),
                            label: const Text('Gratis beginnen', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Features section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: isWide ? 64 : 40,
              ),
              child: Column(
                children: [
                  const Text(
                    'Hoe het werkt',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      _FeatureCard(
                        icon: LucideIcons.users,
                        title: '1. Klas aanmaken',
                        description: 'Voeg je klassen en leerlingen toe aan het systeem.',
                        width: isWide ? 280 : double.infinity,
                      ),
                      _FeatureCard(
                        icon: LucideIcons.clipboardList,
                        title: '2. Antwoordmodel invoeren',
                        description: 'Voer de vragen en antwoorden in, of upload een foto van het antwoordmodel.',
                        width: isWide ? 280 : double.infinity,
                      ),
                      _FeatureCard(
                        icon: LucideIcons.camera,
                        title: '3. Foto uploaden',
                        description: 'Maak een foto van de ingevulde toets. De naam wordt automatisch zwartgemaakt.',
                        width: isWide ? 280 : double.infinity,
                      ),
                      _FeatureCard(
                        icon: LucideIcons.sparkles,
                        title: '4. AI kijkt na',
                        description: 'Gemini Vision analyseert het handschrift en vergelijkt met het antwoordmodel.',
                        width: isWide ? 280 : double.infinity,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Privacy section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: 40,
              ),
              color: AppColors.primary.withValues(alpha: 0.03),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const Column(
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 32, color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Privacy-first',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Leerlingnamen worden automatisch van de foto verwijderd voordat ze naar de AI worden gestuurd. '
                      'Geen persoonlijke gegevens verlaten je school onbeschermd.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                '© 2026 Toets Scan App',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double width;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
