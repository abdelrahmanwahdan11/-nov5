import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_constants.dart';
import '../data/models/nav_quick_action.dart';

class NavShortcutDefinition {
  const NavShortcutDefinition({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.target,
  });

  final String id;
  final String labelKey;
  final IconData icon;
  final String target;
}

class ShortcutsController {
  ShortcutsController._(
    this._prefs,
    Map<String, List<String>> enabled,
  ) : _enabled = ValueNotifier<Map<String, List<String>>>(enabled);

  final SharedPreferences _prefs;
  final ValueNotifier<Map<String, List<String>>> _enabled;

  static const tabs = ['home', 'insights', 'budgets', 'transactions', 'settings'];

  static Map<String, List<String>> _defaultMapping() {
    return {
      'home': ['openNotifications', 'openWallets', 'openInsights'],
      'insights': ['openInsights', 'openStatement', 'openCalculators'],
      'budgets': ['openBudgets', 'openWallets', 'openInsights'],
      'transactions': ['openTransactions', 'openStatement', 'openNotifications'],
      'settings': ['openHelpCenter', 'openContact', 'openRating'],
    };
  }

  static Map<String, List<String>> defaultSuggestions() {
    return _defaultMapping();
  }

  static Map<String, NavShortcutDefinition> definitions() {
    return {
      'openNotifications': NavShortcutDefinition(
        id: 'openNotifications',
        labelKey: 'shortcutNotifications',
        icon: Icons.notifications_active_rounded,
        target: '/home/notifications',
      ),
      'openWallets': NavShortcutDefinition(
        id: 'openWallets',
        labelKey: 'shortcutWallets',
        icon: Icons.credit_card_rounded,
        target: '/home/wallets',
      ),
      'openInsights': NavShortcutDefinition(
        id: 'openInsights',
        labelKey: 'shortcutInsights',
        icon: Icons.stacked_line_chart_rounded,
        target: 'switch:insights',
      ),
      'openStatement': NavShortcutDefinition(
        id: 'openStatement',
        labelKey: 'shortcutStatement',
        icon: Icons.description_rounded,
        target: '/home/statement',
      ),
      'openCalculators': NavShortcutDefinition(
        id: 'openCalculators',
        labelKey: 'shortcutCalculators',
        icon: Icons.calculate_rounded,
        target: '/home/calculators',
      ),
      'openBudgets': NavShortcutDefinition(
        id: 'openBudgets',
        labelKey: 'shortcutBudgets',
        icon: Icons.pie_chart_rounded,
        target: 'switch:budgets',
      ),
      'openTransactions': NavShortcutDefinition(
        id: 'openTransactions',
        labelKey: 'shortcutTransactions',
        icon: Icons.receipt_long_rounded,
        target: 'switch:transactions',
      ),
      'openHelpCenter': NavShortcutDefinition(
        id: 'openHelpCenter',
        labelKey: 'shortcutHelp',
        icon: Icons.help_center_rounded,
        target: '/home/help',
      ),
      'openContact': NavShortcutDefinition(
        id: 'openContact',
        labelKey: 'shortcutContact',
        icon: Icons.mail_outline_rounded,
        target: 'show:contact',
      ),
      'openRating': NavShortcutDefinition(
        id: 'openRating',
        labelKey: 'shortcutRating',
        icon: Icons.star_rate_rounded,
        target: '/home/rate',
      ),
    };
  }

  static Future<ShortcutsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = NavQuickAction.decodeMap(
      prefs.getString(AppConstants.prefNavShortcuts),
    );
    final initial = stored.isEmpty ? _defaultMapping() : stored;
    return ShortcutsController._(prefs, initial);
  }

  ValueListenable<Map<String, List<String>>> get enabledListenable => _enabled;

  List<NavShortcutDefinition> shortcutsFor(String tab) {
    final mapping = _enabled.value;
    final ids = mapping[tab] ?? const <String>[];
    final defs = definitions();
    return [
      for (final id in ids)
        if (defs.containsKey(id)) defs[id]!,
    ];
  }

  void toggleShortcut(String tab, String actionId, bool enabled) {
    final mapping = Map<String, List<String>>.from(_enabled.value);
    final entries = mapping.putIfAbsent(tab, () => []);
    if (enabled) {
      if (!entries.contains(actionId)) {
        entries.add(actionId);
      }
    } else {
      entries.remove(actionId);
    }
    mapping[tab] = entries;
    _enabled.value = mapping;
    _prefs.setString(
      AppConstants.prefNavShortcuts,
      NavQuickAction.encodeMap(mapping),
    );
  }

  void reorder(String tab, List<String> newOrder) {
    final mapping = Map<String, List<String>>.from(_enabled.value);
    mapping[tab] = newOrder;
    _enabled.value = mapping;
    _prefs.setString(
      AppConstants.prefNavShortcuts,
      NavQuickAction.encodeMap(mapping),
    );
  }

  void resetDefaults() {
    final defaults = _defaultMapping();
    _enabled.value = defaults;
    _prefs.setString(
      AppConstants.prefNavShortcuts,
      NavQuickAction.encodeMap(defaults),
    );
  }

  void dispose() {
    _enabled.dispose();
  }
}
