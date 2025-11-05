import 'package:flutter/material.dart';

class AppConstants {
  static const String prefThemeMode = 'theme_mode';
  static const String prefPrimaryColor = 'primary_color';
  static const String prefLocale = 'locale';
  static const String prefSeenOnboarding = 'seen_onboarding';
  static const String prefIsGuest = 'is_guest';
  static const String prefIsAuthenticated = 'is_authenticated';
  static const String prefBudgets = 'budgets';
  static const String prefSearchHistory = 'search_history';
  static const String prefLastCategoryFilter = 'last_category_filter';
  static const String prefLastTagFilters = 'last_tag_filters';
  static const String prefWalletCards = 'wallet_cards';
  static const String prefWalletActiveIndex = 'wallet_active_index';
  static const String prefWalletFlippedCards = 'wallet_flipped_cards';
  static const String prefPrivacyMode = 'privacy_mode_enabled';
  static const String prefProfileName = 'profile_name';
  static const String prefProfileTitle = 'profile_title';
  static const String prefProfileBio = 'profile_bio';
  static const String prefSeenCoach = 'seen_home_coach';
  static const String prefCardStyle = 'card_surface_style';
  static const String prefReduceMotion = 'reduce_motion_enabled';
  static const String prefSavingsGoals = 'savings_goals';
  static const String prefRecurringPayments = 'recurring_payments';
  static const String prefRecipients = 'all_recipients';
  static const String prefFavoriteRecipients = 'favorite_recipient_ids';
  static const String prefQuickSendAmounts = 'quick_send_amounts';
  static const String prefAnalyticsRange = 'analytics_range';
  static const String prefStatementMonth = 'statement_month';
  static const String prefFeeCalculator = 'fee_calculator_state';
  static const String prefInterestCalculator = 'interest_calculator_state';
  static const String prefSavedTransactionViews = 'saved_transaction_views';
  static const String prefNotifications = 'app_notifications';
  static const String prefHelpCenterHistory = 'help_center_history';
  static const String prefNavShortcuts = 'nav_quick_actions';
  static const String prefAppRating = 'app_rating_value';
  static const String prefAppFeedback = 'app_feedback_text';
  static const String prefLastSeenVersion = 'last_seen_version';

  static const String currentVersion = '1.4.0';

  static const List<Color> primarySwatches = [
    Color(0xFF2BAA7D),
    Color(0xFF2E89FF),
    Color(0xFFFF8A3D),
    Color(0xFF9B5DE5),
    Color(0xFFEF4565),
    Color(0xFF1FA7FF),
  ];

  static const List<String> walletCurrencies = ['USD', 'EUR', 'AED', 'SAR'];
  static const List<String> walletNetworks = ['VISA', 'Mastercard', 'UnionPay', 'Amethyst'];
  static const List<List<int>> walletGradients = [
    [0xFF2BAA7D, 0xFF58C6A3],
    [0xFF3A7BFF, 0xFF7FA6FF],
    [0xFF9B5DE5, 0xFFB48BFF],
    [0xFFFF8A3D, 0xFFFFB37A],
  ];

  static const List<Color> analyticsPalette = [
    Color(0xFF2BAA7D),
    Color(0xFF58C6A3),
    Color(0xFF3A7BFF),
    Color(0xFF9B5DE5),
    Color(0xFFFF8A3D),
    Color(0xFFFFC15E),
  ];
}
