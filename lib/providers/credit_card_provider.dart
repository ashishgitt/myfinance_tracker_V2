import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

class CreditCardProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<CreditCardModel> _cards = [];
  final Map<String, List<CreditCardTransactionModel>> _txns = {};

  List<CreditCardModel> get cards => _cards;

  double get totalLimit =>
      _cards.fold(0, (s, c) => s + c.creditLimit);

  double usedForCard(String cardId) =>
      (_txns[cardId] ?? []).fold(0, (s, t) => s + t.amount);

  double get totalUsed =>
      _cards.fold(0, (s, c) => s + usedForCard(c.id));

  List<CreditCardTransactionModel> txnsForCard(String cardId) =>
      _txns[cardId] ?? [];

  Future<void> loadCards() async {
    final rows = await _db.getAllCreditCards();
    _cards = rows.map((r) => CreditCardModel.fromMap(r)).toList();
    for (final c in _cards) {
      await loadTransactions(c.id);
    }
    notifyListeners();
  }

  Future<void> loadTransactions(String cardId) async {
    final rows =
        await _db.getCreditCardTransactionsByCard(cardId);
    _txns[cardId] = rows
        .map((r) => CreditCardTransactionModel.fromMap(r))
        .toList();
  }

  Future<void> addCard(CreditCardModel card) async {
    await _db.insertCreditCard(card.toMap());
    await loadCards();
  }

  Future<void> updateCard(CreditCardModel card) async {
    await _db.updateCreditCard(card.toMap());
    await loadCards();
  }

  Future<void> deleteCard(String id) async {
    await _db.deleteCreditCard(id);
    _txns.remove(id);
    await loadCards();
  }

  Future<void> addTransaction(
      CreditCardTransactionModel txn) async {
    await _db.insertCreditCardTransaction(txn.toMap());
    await loadTransactions(txn.cardId);
    notifyListeners();
  }

  Future<void> deleteTransaction(
      String id, String cardId) async {
    await _db.deleteCreditCardTransaction(id);
    await loadTransactions(cardId);
    notifyListeners();
  }

  bool isDueSoon(CreditCardModel card) {
    final now = DateTime.now();
    final dueThisMonth =
        DateTime(now.year, now.month, card.dueDate);
    final diff = dueThisMonth.difference(now).inDays;
    return diff >= 0 && diff <= 5;
  }
}
