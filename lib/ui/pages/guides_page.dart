import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/profile_controller.dart';
import '../../core/localization/app_localizations.dart';

class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key, required this.profileController});

  final ProfileController profileController;

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> {
  final ValueNotifier<String> _filter = ValueNotifier<String>('all');

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final guides = _GuideItem.items(t);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: widget.profileController.nameNotifier,
              builder: (context, name, _) {
                final trimmed = name.trim();
                final display = trimmed.isEmpty
                    ? t.translate('guidesFallbackName')
                    : trimmed.split(' ').first;
                return Text(
                  t.translate('guidesTitle').replaceAll('{name}', display),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.2, end: 0);
              },
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('guidesSubtitle'),
              style: theme.textTheme.bodyMedium,
            ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0);
            const SizedBox(height: 20),
            _FilterPills(filter: _filter, t: t),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _filter,
                builder: (context, filter, _) {
                  final visible = filter == 'all'
                      ? guides
                      : guides.where((guide) => guide.category == filter).toList();
                  if (visible.isEmpty) {
                    return Center(
                      child: Text(
                        t.translate('guidesEmpty'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final guide = visible[index];
                      return _GuideCard(guide: guide);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.filter, required this.t});

  final ValueNotifier<String> filter;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final entries = [
      _FilterEntry('all', t.translate('guidesFilterAll')),
      _FilterEntry('basics', t.translate('guidesFilterBasics')),
      _FilterEntry('automation', t.translate('guidesFilterAutomation')),
      _FilterEntry('security', t.translate('guidesFilterSecurity')),
    ];
    return ValueListenableBuilder<String>(
      valueListenable: filter,
      builder: (context, current, _) {
        return Wrap(
          spacing: 8,
          children: entries.map((entry) {
            final isSelected = current == entry.value;
            return ChoiceChip(
              label: Text(entry.label),
              selected: isSelected,
              onSelected: (_) => filter.value = entry.value,
            );
          }).toList(),
        );
      },
    );
  }
}

class _FilterEntry {
  const _FilterEntry(this.value, this.label);

  final String value;
  final String label;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final _GuideItem guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Ink.image(
              image: NetworkImage(guide.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(guide.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      guide.categoryLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  guide.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  guide.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(guide.actionLabel)),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(guide.actionLabel),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(guide.savedLabel)),
                        );
                      },
                      icon: const Icon(Icons.bookmark_add_outlined),
                      tooltip: guide.savedLabel,
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.2, end: 0);
  }
}

class _GuideItem {
  const _GuideItem({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.imageUrl,
    required this.categoryLabel,
    required this.actionLabel,
    required this.savedLabel,
  });

  final String category;
  final String title;
  final String description;
  final IconData icon;
  final String imageUrl;
  final String categoryLabel;
  final String actionLabel;
  final String savedLabel;

  static List<_GuideItem> items(AppLocalizations t) {
    return [
      _GuideItem(
        category: 'basics',
        title: t.translate('guideBasicsTrack'),
        description: t.translate('guideBasicsTrackDesc'),
        icon: Icons.layers_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=1200&q=80',
        categoryLabel: t.translate('guidesFilterBasics'),
        actionLabel: t.translate('guidesReadMore'),
        savedLabel: t.translate('guidesSaved'),
      ),
      _GuideItem(
        category: 'automation',
        title: t.translate('guideAutomationFlows'),
        description: t.translate('guideAutomationFlowsDesc'),
        icon: Icons.bolt_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
        categoryLabel: t.translate('guidesFilterAutomation'),
        actionLabel: t.translate('guidesReadMore'),
        savedLabel: t.translate('guidesSaved'),
      ),
      _GuideItem(
        category: 'security',
        title: t.translate('guidePrivacyTips'),
        description: t.translate('guidePrivacyTipsDesc'),
        icon: Icons.shield_moon_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
        categoryLabel: t.translate('guidesFilterSecurity'),
        actionLabel: t.translate('guidesReadMore'),
        savedLabel: t.translate('guidesSaved'),
      ),
      _GuideItem(
        category: 'basics',
        title: t.translate('guideGuestMode'),
        description: t.translate('guideGuestModeDesc'),
        icon: Icons.explore_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1483478550801-ceba5fe50e8e?auto=format&fit=crop&w=1200&q=80',
        categoryLabel: t.translate('guidesFilterBasics'),
        actionLabel: t.translate('guidesReadMore'),
        savedLabel: t.translate('guidesSaved'),
      ),
    ];
  }
}
