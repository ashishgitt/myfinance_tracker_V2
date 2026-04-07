import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

// ─── Budget Provider ──────────────────────────────────────────────────────────
class BudgetProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<BudgetModel> _budgets = [];

  List<BudgetModel> get budgets => _budgets;

  BudgetModel? get overallBudget {
    try { return _budgets.firstWhere((b) => b.isOverall); }
    catch (_) { return null; }
  }

  List<BudgetModel> get categoryBudgets =>
      _budgets.where((b) => !b.isOverall).toList();

  BudgetModel? budgetForCategory(String catId) {
    try { return _budgets.firstWhere((b) => b.categoryId == catId); }
    catch (_) { return null; }
  }

  Future<void> loadBudgets(int month, int year) async {
    final rows = await _db.getBudgetsForMonth(month, year);
    _budgets = rows.map((r) => BudgetModel.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> setOverallBudget(double amount, int month, int year) async {
    final existing = _budgets.where((b) => b.isOverall).toList();
    final id = existing.isNotEmpty ? existing.first.id : const Uuid().v4();
    final budget = BudgetModel(id: id, categoryId: null, amount: amount, month: month, year: year);
    await _db.insertOrUpdateBudget(budget.toMap());
    await loadBudgets(month, year);
  }

  Future<void> setCategoryBudget(String catId, double amount, int month, int year) async {
    final existing = _budgets.where((b) => b.categoryId == catId).toList();
    final id = existing.isNotEmpty ? existing.first.id : const Uuid().v4();
    final budget = BudgetModel(id: id, categoryId: catId, amount: amount, month: month, year: year);
    await _db.insertOrUpdateBudget(budget.toMap());
    await loadBudgets(month, year);
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
    final now = DateTime.now();
    await loadBudgets(now.month, now.year);
  }
}

// ─── Savings Provider ─────────────────────────────────────────────────────────
class SavingsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<SavingsGoalModel> _goals = [];

  List<SavingsGoalModel> get goals => _goals;
  List<SavingsGoalModel> get activeGoals => _goals.where((g) => !g.isCompleted).toList();

  Future<void> loadGoals() async {
    final rows = await _db.getAllSavingsGoals();
    _goals = rows.map((r) => SavingsGoalModel.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    await _db.insertSavingsGoal(goal.toMap());
    await loadGoals();
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    await _db.updateSavingsGoal(goal.toMap());
    await loadGoals();
  }

  Future<void> addContribution(String goalId, double amount) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    final completed = updated.savedAmount >= updated.targetAmount;
    await _db.updateSavingsGoal(updated.copyWith(isCompleted: completed).toMap());
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _db.deleteSavingsGoal(id);
    await loadGoals();
  }
}

// ─── Debt Provider ────────────────────────────────────────────────────────────
class DebtProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<DebtModel> _debts = [];

  List<DebtModel> get debts => _debts;
  List<DebtModel> get iOwe => _debts.where((d) => d.type == 'owe' && !d.isSettled).toList();
  List<DebtModel> get owedToMe => _debts.where((d) => d.type == 'owed' && !d.isSettled).toList();

  Future<void> loadDebts() async {
    final rows = await _db.getAllDebts();
    _debts = rows.map((r) => DebtModel.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addDebt(DebtModel debt) async {
    await _db.insertDebt(debt.toMap());
    await loadDebts();
  }

  Future<void> markSettled(String id) async {
    final debt = _debts.firstWhere((d) => d.id == id);
    await _db.updateDebt(debt.copyWith(isSettled: true).toMap());
    await loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _db.deleteDebt(id);
    await loadDebts();
  }
}
