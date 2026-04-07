import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  bool _isLoading = false;

  List<TransactionModel> get all => _all;
  List<TransactionModel> get filtered => _filtered;
  bool get isLoading => _isLoading;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    final rows = await _db.getAllTransactions();
    _all = rows.map((r) => TransactionModel.fromMap(r)).toList();
    _filtered = List.from(_all);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel t,
      {List<String> labelNames = const []}) async {
    await _db.insertTransaction(t.toMap());
    if (labelNames.isNotEmpty) {
      final labelIds = <String>[];
      for (final name in labelNames) {
        final id = await _db.insertOrGetLabel(name);
        labelIds.add(id);
      }
      await _db.setTransactionLabels(t.id, labelIds);
    }
    await loadAll();
  }

  Future<void> updateTransaction(TransactionModel t,
      {List<String> labelNames = const []}) async {
    await _db.updateTransaction(t.toMap());
    final labelIds = <String>[];
    for (final name in labelNames) {
      final id = await _db.insertOrGetLabel(name);
      labelIds.add(id);
    }
    await _db.setTransactionLabels(t.id, labelIds);
    await loadAll();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await loadAll();
  }

  Future<List<String>> getLabelsForTransaction(String id) =>
      _db.getLabelsForTransaction(id);

  Future<List<TransactionModel>> getByMonth(
      int month, int year) async {
    final rows = await _db.getTransactionsByMonth(month, year);
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<List<TransactionModel>> getByDateRange(
      DateTime start, DateTime end) async {
    final s = _fmt(start);
    final e = _fmt(end);
    final rows = await _db.getTransactionsByDateRange(s, e);
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<List<TransactionModel>> getByDate(DateTime date) async {
    final rows = await _db.getTransactionsByDate(_fmt(date));
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<List<TransactionModel>> search(String query) async {
    final rows = await _db.searchTransactions(query);
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  void applyFilter({
    String? type,
    String? categoryId,
    String? paymentMode,
    double? minAmount,
    double? maxAmount,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    _filtered = _all.where((t) {
      if (type != null && type.isNotEmpty && t.type != type)
        return false;
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          t.categoryId != categoryId) return false;
      if (paymentMode != null &&
          paymentMode.isNotEmpty &&
          t.paymentMode != paymentMode) return false;
      if (minAmount != null && t.amount < minAmount) return false;
      if (maxAmount != null && t.amount > maxAmount) return false;
      if (fromDate != null && t.date.compareTo(_fmt(fromDate)) < 0)
        return false;
      if (toDate != null && t.date.compareTo(_fmt(toDate)) > 0)
        return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!(t.note?.toLowerCase().contains(q) ?? false) &&
            !t.amount.toString().contains(q)) return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  void clearFilter() {
    _filtered = List.from(_all);
    notifyListeners();
  }

  // ─── Analytics ────────────────────────────────────────────────
  double totalIncome(List<TransactionModel> txns) => txns
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);

  double totalExpense(List<TransactionModel> txns) => txns
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  Map<String, double> categoryBreakdown(
      List<TransactionModel> txns, String type) {
    final Map<String, double> map = {};
    for (final t in txns.where((t) => t.type == type)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> dailyBreakdown(
      List<TransactionModel> txns, String type) {
    final Map<String, double> map = {};
    for (final t in txns.where((t) => t.type == type)) {
      map[t.date] = (map[t.date] ?? 0) + t.amount;
    }
    return map;
  }

  List<TransactionModel> get recentTransactions =>
      _all.take(10).toList();

  double todayExpense() {
    final d = _fmt(DateTime.now());
    return _all
        .where((t) => t.date == d && t.type == 'expense')
        .fold(0, (s, t) => s + t.amount);
  }

  double thisMonthIncome() {
    final prefix = _monthPrefix(DateTime.now());
    return _all
        .where((t) =>
            t.date.startsWith(prefix) && t.type == 'income')
        .fold(0, (s, t) => s + t.amount);
  }

  double thisMonthExpense() {
    final prefix = _monthPrefix(DateTime.now());
    return _all
        .where((t) =>
            t.date.startsWith(prefix) && t.type == 'expense')
        .fold(0, (s, t) => s + t.amount);
  }

  /// Returns total spent in a category in the current month
  /// (including the newly-added transaction already in DB)
  double categorySpendThisMonth(String categoryId) {
    final prefix = _monthPrefix(DateTime.now());
    return _all
        .where((t) =>
            t.type == 'expense' &&
            t.categoryId == categoryId &&
            t.date.startsWith(prefix))
        .fold(0, (s, t) => s + t.amount);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _monthPrefix(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}
