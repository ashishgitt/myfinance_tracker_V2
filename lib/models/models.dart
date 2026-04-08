import 'package:flutter/material.dart';

// ─── Category ─────────────────────────────────────────────────────────────────
class CategoryModel {
  final String id;
  final String name;
  final String type;
  final int color;
  final String emoji;
  final bool isDefault;
  final bool isDeleted;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.emoji,
    this.isDefault = false,
    this.isDeleted = false,
  });

  Color get colorValue => Color(color);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'emoji': emoji,
        'is_default': isDefault ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] as String,
        name: m['name'] as String,
        type: m['type'] as String,
        color: m['color'] as int,
        emoji: m['emoji'] as String,
        isDefault: (m['is_default'] as int? ?? 0) == 1,
        isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
      );

  CategoryModel copyWith({
    String? id, String? name, String? type, int? color, String? emoji,
    bool? isDefault, bool? isDeleted,
  }) =>
      CategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        color: color ?? this.color,
        emoji: emoji ?? this.emoji,
        isDefault: isDefault ?? this.isDefault,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}

// ─── SubCategory ──────────────────────────────────────────────────────────────
class SubCategoryModel {
  final String id;
  final String name;
  final String categoryId;
  final String createdAt;

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'created_at': createdAt,
      };

  factory SubCategoryModel.fromMap(Map<String, dynamic> m) =>
      SubCategoryModel(
        id: m['id'] as String,
        name: m['name'] as String,
        categoryId: m['category_id'] as String,
        createdAt: m['created_at'] as String,
      );
}

// ─── Budget ───────────────────────────────────────────────────────────────────
class BudgetModel {
  final String id;
  final String? categoryId;
  final double amount;
  final int month;
  final int year;

  BudgetModel({
    required this.id,
    this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
  });

  bool get isOverall => categoryId == null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
        id: m['id'] as String,
        categoryId: m['category_id'] as String?,
        amount: (m['amount'] as num).toDouble(),
        month: m['month'] as int,
        year: m['year'] as int,
      );

  BudgetModel copyWith({
    String? id, String? categoryId, double? amount, int? month, int? year,
  }) =>
      BudgetModel(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        month: month ?? this.month,
        year: year ?? this.year,
      );
}

// ─── Savings Goal ─────────────────────────────────────────────────────────────
class SavingsGoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final String? deadline;
  final String createdAt;
  final bool isCompleted;

  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    required this.createdAt,
    this.isCompleted = false,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline,
        'created_at': createdAt,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> m) =>
      SavingsGoalModel(
        id: m['id'] as String,
        title: m['title'] as String,
        targetAmount: (m['target_amount'] as num).toDouble(),
        savedAmount: (m['saved_amount'] as num).toDouble(),
        deadline: m['deadline'] as String?,
        createdAt: m['created_at'] as String,
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
      );

  SavingsGoalModel copyWith({
    String? id, String? title, double? targetAmount, double? savedAmount,
    String? deadline, String? createdAt, bool? isCompleted,
  }) =>
      SavingsGoalModel(
        id: id ?? this.id,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deadline: deadline ?? this.deadline,
        createdAt: createdAt ?? this.createdAt,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

// ─── Debt ─────────────────────────────────────────────────────────────────────
class DebtModel {
  final String id;
  final String personName;
  final double amount;
  final String type; // 'owe' | 'owed'
  final String? note;
  final String? dueDate;
  final bool isSettled;
  final String createdAt;

  DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    this.note,
    this.dueDate,
    this.isSettled = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'person_name': personName,
        'amount': amount,
        'type': type,
        'note': note,
        'due_date': dueDate,
        'is_settled': isSettled ? 1 : 0,
        'created_at': createdAt,
      };

  factory DebtModel.fromMap(Map<String, dynamic> m) => DebtModel(
        id: m['id'] as String,
        personName: m['person_name'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as String,
        note: m['note'] as String?,
        dueDate: m['due_date'] as String?,
        isSettled: (m['is_settled'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  DebtModel copyWith({
    String? id, String? personName, double? amount, String? type,
    String? note, String? dueDate, bool? isSettled, String? createdAt,
  }) =>
      DebtModel(
        id: id ?? this.id,
        personName: personName ?? this.personName,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        note: note ?? this.note,
        dueDate: dueDate ?? this.dueDate,
        isSettled: isSettled ?? this.isSettled,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ─── Credit Card ──────────────────────────────────────────────────────────────
class CreditCardModel {
  final String id;
  final String name;
  final String bank;
  final String lastFour;
  final double creditLimit;
  final int billDate;  // day of month
  final int dueDate;   // day of month
  final int color;
  final String createdAt;

  CreditCardModel({
    required this.id,
    required this.name,
    required this.bank,
    required this.lastFour,
    required this.creditLimit,
    required this.billDate,
    required this.dueDate,
    required this.color,
    required this.createdAt,
  });

  Color get colorValue => Color(color);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'bank': bank,
        'last_four': lastFour,
        'credit_limit': creditLimit,
        'bill_date': billDate,
        'due_date': dueDate,
        'color': color,
        'created_at': createdAt,
      };

  factory CreditCardModel.fromMap(Map<String, dynamic> m) => CreditCardModel(
        id: m['id'] as String,
        name: m['name'] as String,
        bank: m['bank'] as String,
        lastFour: m['last_four'] as String,
        creditLimit: (m['credit_limit'] as num).toDouble(),
        billDate: m['bill_date'] as int,
        dueDate: m['due_date'] as int,
        color: m['color'] as int,
        createdAt: m['created_at'] as String,
      );

  CreditCardModel copyWith({
    String? id, String? name, String? bank, String? lastFour,
    double? creditLimit, int? billDate, int? dueDate, int? color, String? createdAt,
  }) =>
      CreditCardModel(
        id: id ?? this.id,
        name: name ?? this.name,
        bank: bank ?? this.bank,
        lastFour: lastFour ?? this.lastFour,
        creditLimit: creditLimit ?? this.creditLimit,
        billDate: billDate ?? this.billDate,
        dueDate: dueDate ?? this.dueDate,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ─── Credit Card Transaction ──────────────────────────────────────────────────
class CreditCardTransactionModel {
  final String id;
  final String cardId;
  final double amount;
  final String date;
  final String? merchant;
  final String categoryId;
  final String? subCategoryId;
  final bool isRecoverable;
  final String? recoverFrom;
  final String? note;
  final String createdAt;

  CreditCardTransactionModel({
    required this.id,
    required this.cardId,
    required this.amount,
    required this.date,
    this.merchant,
    required this.categoryId,
    this.subCategoryId,
    this.isRecoverable = false,
    this.recoverFrom,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'card_id': cardId,
        'amount': amount,
        'date': date,
        'merchant': merchant,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'is_recoverable': isRecoverable ? 1 : 0,
        'recover_from': recoverFrom,
        'note': note,
        'created_at': createdAt,
      };

  factory CreditCardTransactionModel.fromMap(Map<String, dynamic> m) =>
      CreditCardTransactionModel(
        id: m['id'] as String,
        cardId: m['card_id'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: m['date'] as String,
        merchant: m['merchant'] as String?,
        categoryId: m['category_id'] as String,
        subCategoryId: m['sub_category_id'] as String?,
        isRecoverable: (m['is_recoverable'] as int? ?? 0) == 1,
        recoverFrom: m['recover_from'] as String?,
        note: m['note'] as String?,
        createdAt: m['created_at'] as String,
      );
}

// ─── Person (Khatabook-style debt) ────────────────────────────────────────────
class PersonModel {
  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final String createdAt;

  PersonModel({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt,
      };

  factory PersonModel.fromMap(Map<String, dynamic> m) => PersonModel(
        id: m['id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as String,
      );

  PersonModel copyWith({
    String? id, String? name, String? phone, String? notes, String? createdAt,
  }) =>
      PersonModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ─── Debt Transaction ─────────────────────────────────────────────────────────
class DebtTransactionModel {
  final String id;
  final String personId;
  final double amount;
  /// 'lent' | 'borrowed' | 'received' | 'paid'
  final String type;
  final String date;
  final String? note;
  final String? receiptImage;
  final String createdAt;

  DebtTransactionModel({
    required this.id,
    required this.personId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.receiptImage,
    required this.createdAt,
  });

  bool get isCredit => type == 'lent' || type == 'received';
  // From "I" perspective:
  // lent → I gave money → positive for "owed to me"
  // received → they paid back → reduces what they owe me
  // borrowed → they gave me → positive for "I owe"
  // paid → I paid back → reduces what I owe

  double get signedAmount {
    switch (type) {
      case 'lent':     return amount;   // increases what they owe me
      case 'received': return -amount;  // decreases what they owe me
      case 'borrowed': return amount;   // increases what I owe
      case 'paid':     return -amount;  // decreases what I owe
      default:         return amount;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'person_id': personId,
        'amount': amount,
        'type': type,
        'date': date,
        'note': note,
        'receipt_image': receiptImage,
        'created_at': createdAt,
      };

  factory DebtTransactionModel.fromMap(Map<String, dynamic> m) =>
      DebtTransactionModel(
        id: m['id'] as String,
        personId: m['person_id'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as String,
        date: m['date'] as String,
        note: m['note'] as String?,
        receiptImage: m['receipt_image'] as String?,
        createdAt: m['created_at'] as String,
      );
}
