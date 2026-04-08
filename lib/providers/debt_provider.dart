import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

class DebtProvider extends ChangeNotifier {
  final _db = DatabaseHelper();

  List<PersonModel> _people = [];
  final Map<String, List<DebtTransactionModel>> _txns = {};

  List<PersonModel> get people => _people;

  List<DebtTransactionModel> txnsForPerson(String personId) =>
      _txns[personId] ?? [];

  /// Net balance for a person:
  /// positive = they owe ME, negative = I owe THEM
  double netBalance(String personId) {
    final txns = _txns[personId] ?? [];
    double net = 0;
    for (final t in txns) {
      if (t.type == 'lent')     net += t.amount;   // +ve: they owe me
      if (t.type == 'received') net -= t.amount;   // they paid back
      if (t.type == 'borrowed') net -= t.amount;   // -ve: I owe them
      if (t.type == 'paid')     net += t.amount;   // I paid back
    }
    return net;
  }

  /// Total across all people that others owe ME
  double get totalOwedToMe {
    double total = 0;
    for (final p in _people) {
      final nb = netBalance(p.id);
      if (nb > 0) total += nb;
    }
    return total;
  }

  /// Total across all people that I OWE others
  double get totalIOwe {
    double total = 0;
    for (final p in _people) {
      final nb = netBalance(p.id);
      if (nb < 0) total += nb.abs();
    }
    return total;
  }

  int get pendingPeopleCount =>
      _people.where((p) => netBalance(p.id) != 0).length;

  Future<void> loadAll() async {
    final pRows = await _db.getAllPeople();
    _people = pRows.map((r) => PersonModel.fromMap(r)).toList();
    for (final p in _people) {
      await _loadTxnsForPerson(p.id);
    }
    notifyListeners();
  }

  Future<void> _loadTxnsForPerson(String personId) async {
    final rows = await _db.getDebtTransactionsByPerson(personId);
    _txns[personId] =
        rows.map((r) => DebtTransactionModel.fromMap(r)).toList();
  }

  Future<PersonModel> addPerson(String name,
      {String? phone, String? notes}) async {
    final p = PersonModel(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insertPerson(p.toMap());
    await loadAll();
    return p;
  }

  Future<void> updatePerson(PersonModel p) async {
    await _db.updatePerson(p.toMap());
    await loadAll();
  }

  Future<void> deletePerson(String id) async {
    await _db.deletePerson(id);
    _txns.remove(id);
    await loadAll();
  }

  Future<DebtTransactionModel> addDebtTransaction({
    required String personId,
    required double amount,
    required String type,
    required String date,
    String? note,
    String? receiptImage,
  }) async {
    final t = DebtTransactionModel(
      id: const Uuid().v4(),
      personId: personId,
      amount: amount,
      type: type,
      date: date,
      note: note,
      receiptImage: receiptImage,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insertDebtTransaction(t.toMap());
    await _loadTxnsForPerson(personId);
    notifyListeners();
    return t;
  }

  Future<void> deleteDebtTransaction(
      String id, String personId) async {
    await _db.deleteDebtTransaction(id);
    await _loadTxnsForPerson(personId);
    notifyListeners();
  }

  Future<void> settleUp(String personId) async {
    final nb = netBalance(personId);
    if (nb == 0) return;
    final person = _people.firstWhere((p) => p.id == personId);
    // Add settlement transaction
    final type = nb > 0 ? 'received' : 'paid';
    await addDebtTransaction(
      personId: personId,
      amount: nb.abs(),
      type: type,
      date: DateTime.now()
          .toString()
          .substring(0, 10),
      note: 'Settlement with ${person.name}',
    );
  }

  PersonModel? findById(String id) {
    try { return _people.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }
}
