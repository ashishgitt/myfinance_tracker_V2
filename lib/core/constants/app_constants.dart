import 'package:flutter/material.dart';

class AppConstants {
  // ─── Currency ────────────────────────────────────────────────
  static const List<String> currencies = [
    '₹', '\$', '€', '£', '¥', '₩', '₣', '₺', '₴', '₫', 'د.إ',
  ];

  // ─── Payment Modes ───────────────────────────────────────────
  static const List<String> paymentModes = [
    'Cash', 'UPI', 'Card', 'Bank Transfer', 'Other',
  ];

  // ─── Recurrence Types ────────────────────────────────────────
  static const List<String> recurrenceTypes = [
    'Daily', 'Weekly', 'Monthly',
  ];

  // ─── Default Expense Categories ──────────────────────────────
  static final List<Map<String, dynamic>> defaultExpenseCategories = [
    {'name': 'Food & Dining',       'emoji': '🍔', 'color': 0xFFE53935},
    {'name': 'Transport',           'emoji': '🚗', 'color': 0xFF1E88E5},
    {'name': 'Shopping',            'emoji': '🛍️', 'color': 0xFF8E24AA},
    {'name': 'Entertainment',       'emoji': '🎬', 'color': 0xFFFF6F00},
    {'name': 'Health & Medical',    'emoji': '💊', 'color': 0xFF43A047},
    {'name': 'Education',           'emoji': '📚', 'color': 0xFF00ACC1},
    {'name': 'Bills & Utilities',   'emoji': '💡', 'color': 0xFFFDD835},
    {'name': 'Rent / EMI',          'emoji': '🏠', 'color': 0xFF6D4C41},
    {'name': 'Groceries',           'emoji': '🥦', 'color': 0xFF7CB342},
    {'name': 'Personal Care',       'emoji': '💅', 'color': 0xFFEC407A},
    {'name': 'Travel',              'emoji': '✈️', 'color': 0xFF039BE5},
    {'name': 'Subscriptions',       'emoji': '📺', 'color': 0xFF5E35B1},
    {'name': 'Gifts & Donations',   'emoji': '🎁', 'color': 0xFFD81B60},
    {'name': 'Miscellaneous',       'emoji': '📦', 'color': 0xFF757575},
  ];

  // ─── Default Income Categories ───────────────────────────────
  static final List<Map<String, dynamic>> defaultIncomeCategories = [
    {'name': 'Salary',             'emoji': '💼', 'color': 0xFF26A69A},
    {'name': 'Freelance',          'emoji': '💻', 'color': 0xFF00897B},
    {'name': 'Business',           'emoji': '🏢', 'color': 0xFF00695C},
    {'name': 'Investment Returns', 'emoji': '📈', 'color': 0xFF2E7D32},
    {'name': 'Rental Income',      'emoji': '🏡', 'color': 0xFF558B2F},
    {'name': 'Bonus',              'emoji': '🎉', 'color': 0xFFF57F17},
    {'name': 'Other Income',       'emoji': '💰', 'color': 0xFF6A1B9A},
  ];

  // ─── Category Color Palette ───────────────────────────────────
  static const List<int> categoryColors = [
    0xFFE53935, 0xFF1E88E5, 0xFF8E24AA, 0xFF43A047,
    0xFFFF6F00, 0xFF00ACC1, 0xFFFDD835, 0xFF6D4C41,
    0xFF7CB342, 0xFFEC407A, 0xFF039BE5, 0xFF5E35B1,
    0xFFD81B60, 0xFF757575, 0xFF26A69A, 0xFFF57F17,
  ];

  // ─── Category Emojis ─────────────────────────────────────────
  static const List<String> categoryEmojis = [
    '🍔','🚗','🛍️','🎬','💊','📚','💡','🏠','🥦','💅','✈️',
    '📺','🎁','📦','💼','💻','🏢','📈','🏡','🎉','💰','⚡',
    '🎮','🍺','☕','🏋️','🌿','🎓','💒','🔧','🧴','👗','📱',
  ];

  // ─── Theme Names ─────────────────────────────────────────────
  static const List<String> themeOptions = ['Light', 'Dark', 'AMOLED Black'];

  // ─── Week Start Options ───────────────────────────────────────
  static const List<String> weekStartOptions = ['Monday', 'Sunday'];

  // ─── Month Start Days ─────────────────────────────────────────
  static final List<int> monthStartDays = List.generate(28, (i) => i + 1);

  // ─── Primary Colors for Seed ─────────────────────────────────
  static const Color primarySeed = Color(0xFF3F51B5); // Indigo
  static const Color accentTeal  = Color(0xFF009688);
}
