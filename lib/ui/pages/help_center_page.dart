import 'package:flutter/material.dart';

import '../../controllers/help_center_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/help_article.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({
    super.key,
    required this.helpCenterController,
  });

  final HelpCenterController helpCenterController;

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.helpCenterController.query.value,
    );
    _searchController.addListener(() {
      widget.helpCenterController.updateQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('helpCenterTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: t.translate('helpCenterClearHistory'),
            onPressed: widget.helpCenterController.clearHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: t.translate('helpCenterSearchHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onSubmitted: widget.helpCenterController.addToHistory,
            ),
            const SizedBox(height: 12),
            _HistoryChips(controller: widget.helpCenterController),
            const SizedBox(height: 12),
            _CategoryChips(controller: widget.helpCenterController),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: widget.helpCenterController.query,
                builder: (context, _, __) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: widget.helpCenterController.selectedCategory,
                    builder: (context, __, ___) {
                      final articles =
                          widget.helpCenterController.filteredArticles;
                      if (articles.isEmpty) {
                        return _EmptyHelpState(
                          onReset: () {
                            widget.helpCenterController.updateQuery('');
                            _searchController.clear();
                            widget.helpCenterController.setCategory(null);
                          },
                        );
                      }
                      return ListView.builder(
                        itemCount: articles.length,
                        itemBuilder: (context, index) {
                          final article = articles[index];
                          return _HelpArticleCard(
                            article: article,
                            onTap: () => _showArticle(context, article),
                          );
                        },
                      );
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

  void _showArticle(BuildContext context, HelpArticleModel article) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final related = widget.helpCenterController.allArticles
            .where((item) => article.relatedIds.contains(item.id))
            .toList();
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in article.tags)
                      Chip(label: Text('#$tag')),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  article.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    t.translate('helpCenterRelated'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final item in related)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        _showArticle(context, item);
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final HelpCenterController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final categories = controller.categories;
    return ValueListenableBuilder<String?>(
      valueListenable: controller.selectedCategory,
      builder: (context, current, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(t.translate('helpCenterCategoryAll')),
                  selected: current == null,
                  onSelected: (_) => controller.setCategory(null),
                ),
              ),
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: current == category,
                    onSelected: (_) => controller.setCategory(category),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryChips extends StatelessWidget {
  const _HistoryChips({required this.controller});

  final HelpCenterController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<List<String>>(
      valueListenable: controller.historyNotifier,
      builder: (context, history, _) {
        if (history.isEmpty) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  t.translate('helpCenterSearchHistory'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              for (final entry in history)
                ActionChip(
                  label: Text(entry),
                  onPressed: () {
                    controller.updateQuery(entry);
                    controller.addToHistory(entry);
                  },
                  onLongPress: () => controller.removeFromHistory(entry),
                ),
              TextButton(
                onPressed: controller.clearHistory,
                child: Text(t.translate('clear')), 
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HelpArticleCard extends StatelessWidget {
  const _HelpArticleCard({
    required this.article,
    required this.onTap,
  });

  final HelpArticleModel article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        title: Text(article.title),
        subtitle: Text(article.category),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withOpacity(0.12),
          child: const Icon(Icons.menu_book_rounded),
        ),
      ),
    );
  }
}

class _EmptyHelpState extends StatelessWidget {
  const _EmptyHelpState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            t.translate('helpCenterEmptyTitle'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            t.translate('helpCenterEmptySubtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onReset,
            child: Text(t.translate('reset')), 
          ),
        ],
      ),
    );
  }
}
