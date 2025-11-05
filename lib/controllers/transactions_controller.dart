import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/transaction.dart';
import '../data/models/transaction_filter_definition.dart';
import '../data/models/transaction_timeline.dart';
import '../data/mock/mock_data.dart';

class TransactionsController {
  TransactionsController._(
    this._allTransactions,
    this.timelineNotifier,
    this.isLoading,
    this.categoryFilter,
    this.tagFilters,
    this.selectedTransactions,
    this.undoHistory,
    this.savedViews,
    this.activeView,
    this._prefs,
  ) : _locale = const Locale('en');

  final List<TransactionModel> _allTransactions;
  final ValueNotifier<List<TransactionTimelineSection>> timelineNotifier;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<String?> categoryFilter;
  final ValueNotifier<Set<String>> tagFilters;
  final ValueNotifier<Set<String>> selectedTransactions;
  final ValueNotifier<List<TransactionsUndoEntry>> undoHistory;
  final ValueNotifier<List<TransactionFilterDefinition>> savedViews;
  final ValueNotifier<TransactionFilterDefinition?> activeView;
  final SharedPreferences _prefs;
  Locale _locale;

  TransactionFilterDefinition? _activeAdvancedFilter;
  bool _suppressActiveClear = false;

  final StreamController<TransactionModel> _recentlyArchived =
      StreamController.broadcast();

  final List<TransactionsUndoEntry> _undoStack = <TransactionsUndoEntry>[];
  final List<VoidCallback> _listeners = <VoidCallback>[];

  String? _query;
  int _currentPage = 0;
  static const _pageSize = 25;

  static Future<TransactionsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = MockDataGenerator.generateTransactions(count: 180)
      ..sort((a, b) => b.date.compareTo(a.date));

    final storedCategory = prefs.getString(AppConstants.prefLastCategoryFilter);
    final storedTags = prefs.getStringList(AppConstants.prefLastTagFilters);

    String? initialCategory;
    if (storedCategory != null &&
        data.any((transaction) => transaction.category == storedCategory)) {
      initialCategory = storedCategory;
    } else if (storedCategory != null) {
      await prefs.remove(AppConstants.prefLastCategoryFilter);
    }

    final availableTags = data.expand((tx) => tx.tags).toSet();
    final initialTags = <String>{};
    final sanitizedEncoded = <String>[];
    var tagsWereSanitized = false;
    if (storedTags != null) {
      for (final encoded in storedTags) {
        try {
          final decoded = utf8.decode(base64Decode(encoded));
          if (!availableTags.contains(decoded)) {
            tagsWereSanitized = true;
            continue;
          }
          final inserted = initialTags.add(decoded);
          if (!inserted) {
            tagsWereSanitized = true;
            continue;
          }
          sanitizedEncoded.add(base64Encode(utf8.encode(decoded)));
        } on FormatException {
          tagsWereSanitized = true;
        }
      }
      if (tagsWereSanitized) {
        await prefs.setStringList(
          AppConstants.prefLastTagFilters,
          sanitizedEncoded,
        );
      }
    }

    final savedViewsRaw =
        prefs.getStringList(AppConstants.prefSavedTransactionViews) ?? const [];
    final savedViewDefinitions = <TransactionFilterDefinition>[];
    final seenSavedViewIds = <String>{};
    var savedViewsWereSanitized = false;
    for (final entry in savedViewsRaw) {
      try {
        final definition = TransactionFilterDefinition.fromJson(entry);
        if (seenSavedViewIds.add(definition.id)) {
          savedViewDefinitions.add(definition);
        } else {
          savedViewsWereSanitized = true;
        }
      } on FormatException {
        savedViewsWereSanitized = true;
      } on TypeError {
        savedViewsWereSanitized = true;
      }
    }
    if (savedViewsWereSanitized) {
      final sanitizedSavedViews = savedViewDefinitions
          .map((definition) => definition.toJson())
          .toList(growable: false);
      await prefs.setStringList(
        AppConstants.prefSavedTransactionViews,
        sanitizedSavedViews,
      );
    }

    savedViewDefinitions.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final controller = TransactionsController._(
      data,
      ValueNotifier<List<TransactionTimelineSection>>(<TransactionTimelineSection>[]),
      ValueNotifier<bool>(false),
      ValueNotifier<String?>(initialCategory),
      ValueNotifier<Set<String>>(Set<String>.from(initialTags)),
      ValueNotifier<Set<String>>(<String>{}),
      ValueNotifier<List<TransactionsUndoEntry>>(<TransactionsUndoEntry>[]),
      ValueNotifier<List<TransactionFilterDefinition>>(
        List<TransactionFilterDefinition>.unmodifiable(savedViewDefinitions),
      ),
      ValueNotifier<TransactionFilterDefinition?>(null),
      prefs,
    );

    await controller._refreshTimeline(resetPage: true);
    return controller;
  }

  Future<void> updateLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _refreshTimeline(resetPage: true);
  }

  Stream<TransactionModel> get recentlyArchivedStream =>
      _recentlyArchived.stream;

  void addListener(VoidCallback listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  List<String> get categories =>
      _allTransactions.map((tx) => tx.category).toSet().toList()..sort();

  Set<String> get availableTags =>
      _allTransactions.expand((tx) => tx.tags).toSet();

  List<TransactionModel> get allTransactions =>
      List<TransactionModel>.unmodifiable(_allTransactions);

  bool get hasSelection => selectedTransactions.value.isNotEmpty;

  bool get canUndo => _undoStack.isNotEmpty;

  Future<void> applyQuery(String? query) async {
    _query = query?.trim().isEmpty ?? true ? null : query?.trim();
    await _refreshTimeline(resetPage: true);
  }

  Future<void> selectCategory(String? category) async {
    categoryFilter.value = category;
    _maybeClearActiveFilter();
    if (category == null) {
      await _prefs.remove(AppConstants.prefLastCategoryFilter);
    } else {
      await _prefs.setString(AppConstants.prefLastCategoryFilter, category);
    }
    await _refreshTimeline(resetPage: true);
  }

  Future<void> toggleTag(String tag) async {
    final tags = {...tagFilters.value};
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    tagFilters.value = tags;
    _maybeClearActiveFilter();
    await _persistTags(tags);
    await _refreshTimeline(resetPage: true);
  }

  Future<void> clearTags() async {
    tagFilters.value = <String>{};
    _maybeClearActiveFilter();
    await _persistTags(tagFilters.value);
    await _refreshTimeline(resetPage: true);
  }

  Future<void> applyAdvancedFilter(
    TransactionFilterDefinition? definition, {
    bool updateBaseFilters = false,
  }) async {
    if (definition == null) {
      _activeAdvancedFilter = null;
      activeView.value = null;
      await _refreshTimeline(resetPage: true);
      return;
    }

    if (updateBaseFilters) {
      _suppressActiveClear = true;
      try {
        categoryFilter.value = definition.category;
        if (definition.category == null) {
          await _prefs.remove(AppConstants.prefLastCategoryFilter);
        } else {
          await _prefs.setString(
            AppConstants.prefLastCategoryFilter,
            definition.category!,
          );
        }
        final tags = definition.tags.toSet();
        tagFilters.value = tags;
        await _persistTags(tags);
      } finally {
        _suppressActiveClear = false;
      }
    }

    _activeAdvancedFilter = definition;
    activeView.value = definition;
    await _refreshTimeline(resetPage: true);
  }

  Future<void> saveView(TransactionFilterDefinition definition) async {
    final views = [...savedViews.value];
    final index = views.indexWhere((item) => item.id == definition.id);
    if (index >= 0) {
      views[index] = definition;
    } else {
      views.add(definition);
    }
    views.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    savedViews.value =
        List<TransactionFilterDefinition>.unmodifiable(views);
    await _persistSavedViews();
  }

  Future<void> deleteView(String id) async {
    final views = [...savedViews.value]..removeWhere((view) => view.id == id);
    savedViews.value =
        List<TransactionFilterDefinition>.unmodifiable(views);
    await _persistSavedViews();
    if (_activeAdvancedFilter != null && _activeAdvancedFilter!.id == id) {
      await applyAdvancedFilter(null);
    }
  }

  Future<void> clearAdvancedFilter() async {
    await applyAdvancedFilter(null);
  }

  Future<void> loadMore() async {
    await _refreshTimeline(resetPage: false);
  }

  Future<void> refresh() async {
    await _refreshTimeline(resetPage: true);
  }

  Future<void> _refreshTimeline({required bool resetPage}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    if (resetPage) {
      _currentPage = 0;
    }

    await Future<void>.delayed(const Duration(milliseconds: 320));

    final filtered = _allTransactions.where((tx) {
      final matchesQuery = _query == null
          ? true
          : (tx.title.toLowerCase().contains(_query!.toLowerCase()) ||
              tx.description.toLowerCase().contains(_query!.toLowerCase()) ||
              tx.tags.any(
                  (tag) => tag.toLowerCase().contains(_query!.toLowerCase())));
      final matchesCategory = categoryFilter.value == null
          ? true
          : tx.category == categoryFilter.value;
      final tags = tagFilters.value;
      final matchesTags = tags.isEmpty
          ? true
          : tags.every((tag) => tx.tags.contains(tag));
      final matchesAdvanced = _matchesAdvancedFilter(tx);
      return matchesQuery && matchesCategory && matchesTags && matchesAdvanced;
    }).toList();

    final endIndex = ((_currentPage + 1) * _pageSize);
    final limitedEnd = endIndex.clamp(0, filtered.length) as int;
    final slice = filtered.take(limitedEnd).toList();

    final sections = _buildTimeline(slice);
    timelineNotifier.value = sections;

    if (limitedEnd < filtered.length) {
      _currentPage += 1;
    }

    isLoading.value = false;
    _notifyListeners();
  }

  List<TransactionTimelineSection> _buildTimeline(
      List<TransactionModel> items) {
    final grouped = <DateTime, List<TransactionModel>>{};
    for (final tx in items) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => <TransactionModel>[]).add(tx);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final key in sortedKeys)
        TransactionTimelineSection(
          label: _formatDateLabel(key),
          total: grouped[key]!
              .where((tx) => tx.type == TransactionType.expense)
              .fold<double>(0, (sum, tx) => sum + tx.amount),
          transactions: grouped[key]!,
          date: key,
        ),
    ];
  }

  Future<void> archiveTransaction(TransactionModel tx) async {
    final index = _allTransactions.indexWhere((element) => element.id == tx.id);
    if (index == -1) return;
    _allTransactions.removeAt(index);
    _pushUndo(
      TransactionsUndoEntry(
        type: TransactionsActionType.archive,
        before: [tx],
        metadata: const {'reason': 'single'},
      ),
    );
    await _refreshTimeline(resetPage: true);
    _recentlyArchived.add(tx);
  }

  Future<void> restoreTransaction(TransactionModel tx) async {
    _allTransactions.insert(0, tx);
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
    _undoStack.removeWhere((entry) =>
        entry.type == TransactionsActionType.archive &&
        entry.before.any((item) => item.id == tx.id));
    undoHistory.value = List<TransactionsUndoEntry>.unmodifiable(_undoStack);
    await _refreshTimeline(resetPage: true);
  }

  Future<TransactionModel> categorizeTransaction(TransactionModel tx) async {
    final index = _allTransactions.indexWhere((element) => element.id == tx.id);
    if (index == -1) return tx;
    final updatedTags = {...tx.tags, 'focus'};
    final updated = tx.copyWith(tags: updatedTags.toList());
    _pushUndo(
      TransactionsUndoEntry(
        type: TransactionsActionType.tag,
        before: [tx],
        after: [updated],
        metadata: const {'tag': 'focus'},
      ),
    );
    _allTransactions[index] = updated;
    await _refreshTimeline(resetPage: true);
    return updated;
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final index = _allTransactions.indexWhere((element) => element.id == tx.id);
    if (index == -1) return;
    _allTransactions[index] = tx;
    await _refreshTimeline(resetPage: true);
  }

  Future<void> addManualTransaction(TransactionModel tx) async {
    _allTransactions.insert(0, tx);
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
    await _refreshTimeline(resetPage: true);
  }

  void toggleSelection(String id) {
    final selected = {...selectedTransactions.value};
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    selectedTransactions.value = selected;
  }

  void clearSelection() {
    selectedTransactions.value = <String>{};
  }

  Future<void> bulkArchive(Set<String> ids) async {
    if (ids.isEmpty) return;
    final removed =
        _allTransactions.where((transaction) => ids.contains(transaction.id)).toList();
    if (removed.isEmpty) return;
    _allTransactions.removeWhere((transaction) => ids.contains(transaction.id));
    _pushUndo(
      TransactionsUndoEntry(
        type: TransactionsActionType.archive,
        before: removed,
        metadata: const {'reason': 'bulk'},
      ),
    );
    clearSelection();
    await _refreshTimeline(resetPage: true);
  }

  Future<void> bulkApplyTag(Set<String> ids, String tag) async {
    if (ids.isEmpty) return;
    final before = <TransactionModel>[];
    final after = <TransactionModel>[];
    for (var i = 0; i < _allTransactions.length; i++) {
      final tx = _allTransactions[i];
      if (!ids.contains(tx.id)) continue;
      before.add(tx);
      final updatedTags = {...tx.tags, tag};
      final updated = tx.copyWith(tags: updatedTags.toList());
      after.add(updated);
      _allTransactions[i] = updated;
    }
    if (after.isEmpty) return;
    _pushUndo(
      TransactionsUndoEntry(
        type: TransactionsActionType.tag,
        before: before,
        after: after,
        metadata: {'tag': tag},
      ),
    );
    clearSelection();
    await _refreshTimeline(resetPage: true);
  }

  Future<void> undoLastAction() async {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeAt(0);
    switch (entry.type) {
      case TransactionsActionType.archive:
        _allTransactions.addAll(entry.before);
        _allTransactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionsActionType.tag:
        for (final original in entry.before) {
          final index =
              _allTransactions.indexWhere((element) => element.id == original.id);
          if (index != -1) {
            _allTransactions[index] = original;
          }
        }
        break;
    }
    undoHistory.value = List<TransactionsUndoEntry>.unmodifiable(_undoStack);
    await _refreshTimeline(resetPage: true);
  }

  void _pushUndo(TransactionsUndoEntry entry) {
    _undoStack.insert(0, entry);
    if (_undoStack.length > 5) {
      _undoStack.removeLast();
    }
    undoHistory.value = List<TransactionsUndoEntry>.unmodifiable(_undoStack);
  }

  void _maybeClearActiveFilter() {
    if (_suppressActiveClear || _activeAdvancedFilter == null) {
      return;
    }
    _activeAdvancedFilter = null;
    activeView.value = null;
  }

  Future<void> _persistTags(Set<String> tags) async {
    final encoded =
        tags.map((tag) => base64Encode(utf8.encode(tag))).toList(growable: false);
    await _prefs.setStringList(AppConstants.prefLastTagFilters, encoded);
  }

  Future<void> _persistSavedViews() async {
    final encoded = savedViews.value
        .map((definition) => definition.toJson())
        .toList(growable: false);
    await _prefs.setStringList(AppConstants.prefSavedTransactionViews, encoded);
  }

  bool _matchesAdvancedFilter(TransactionModel transaction) {
    final definition = _activeAdvancedFilter;
    if (definition == null) {
      return true;
    }

    if (definition.minAmount != null &&
        transaction.amount < definition.minAmount!) {
      return false;
    }
    if (definition.maxAmount != null &&
        transaction.amount > definition.maxAmount!) {
      return false;
    }
    if (definition.startDate != null &&
        transaction.date.isBefore(definition.startDate!)) {
      return false;
    }
    if (definition.endDate != null &&
        transaction.date.isAfter(definition.endDate!)) {
      return false;
    }
    if (definition.type != null && transaction.type != definition.type) {
      return false;
    }
    if (definition.status != null && transaction.status != definition.status) {
      return false;
    }
    if (definition.category != null &&
        transaction.category != definition.category) {
      return false;
    }
    if (definition.tags.isNotEmpty &&
        !definition.tags.every(transaction.tags.contains)) {
      return false;
    }
    if (definition.merchant != null &&
        definition.merchant!.trim().isNotEmpty &&
        !transaction.merchant
            .toLowerCase()
            .contains(definition.merchant!.toLowerCase().trim())) {
      return false;
    }
    return true;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    final code = _locale.languageCode.toLowerCase();
    final todayLabel = code == 'ar' ? 'اليوم' : 'Today';
    final yesterdayLabel = code == 'ar' ? 'أمس' : 'Yesterday';

    if (diff == 0) return todayLabel;
    if (diff == 1) return yesterdayLabel;

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final formatted = '${date.year}-$month-$day';

    if (code == 'ar') {
      const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return formatted
          .split('')
          .map((char) => int.tryParse(char) != null
              ? arabicDigits[int.parse(char)]
              : char)
          .join();
    }
    return formatted;
  }

  void dispose() {
    timelineNotifier.dispose();
    isLoading.dispose();
    categoryFilter.dispose();
    tagFilters.dispose();
    selectedTransactions.dispose();
    undoHistory.dispose();
    savedViews.dispose();
    activeView.dispose();
    _recentlyArchived.close();
    _listeners.clear();
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}

enum TransactionsActionType { archive, tag }

class TransactionsUndoEntry {
  const TransactionsUndoEntry({
    required this.type,
    required this.before,
    this.after,
    this.metadata,
  });

  final TransactionsActionType type;
  final List<TransactionModel> before;
  final List<TransactionModel>? after;
  final Map<String, Object?>? metadata;
}
