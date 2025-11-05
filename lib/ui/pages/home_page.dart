import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.headerGradient(brightness),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.translate('welcome'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Mawaid digital wallet prototype',
                      style: theme.textTheme.bodyMedium,
                    )
                        .animate()
                        .fadeIn(duration: 420.ms)
                        .slideY(begin: 0.2, end: 0),
                    const Spacer(),
                    Wrap(
                      spacing: 12,
                      children: List.generate(3, (index) {
                        final labels = ['Pay', 'Save', 'Explore'];
                        final icons = [
                          Icons.qr_code_scanner,
                          Icons.savings_rounded,
                          Icons.explore_outlined,
                        ];
                        return _ActionChip(
                          icon: icons[index],
                          label: labels[index],
                        )
                            .animate(delay: (index * 80).ms)
                            .slideY(begin: 0.3, end: 0)
                            .fadeIn(duration: 320.ms);
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'USD 12,560.23',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Updated 2 mins ago',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.show_chart_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 20),
              Text(
                'Quick insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(2, (index) {
                  final titles = ['Spending', 'Rewards'];
                  final subtitles = ['-12% vs last month', '+850 pts'];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
                      child: _InsightCard(
                        title: titles[index],
                        subtitle: subtitles[index],
                      )
                          .animate(delay: (80 * index).ms)
                          .slideY(begin: 0.25, end: 0)
                          .fadeIn(duration: 340.ms),
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
