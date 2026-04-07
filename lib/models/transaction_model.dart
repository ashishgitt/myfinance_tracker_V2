class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String categoryId;
  final String? subCategoryId;
  final String date; // yyyy-MM-dd
  final String? note;
  final String paymentMode;
  final bool isRecurring;
  final String? recurrenceType;
  final String? receiptImage;
  final String createdAt;
  // Labels are loaded separately (junction table)
  final List<String> labels;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.subCategoryId,
    required this.date,
    this.note,
    this.paymentMode = 'Cash',
    this.isRecurring = false,
    this.recurrenceType,
    this.receiptImage,
    required this.createdAt,
    this.labels = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'date': date,
        'note': note,
        'payment_mode': paymentMode,
        'is_recurring': isRecurring ? 1 : 0,
        'recurrence_type': recurrenceType,
        'receipt_image': receiptImage,
        'created_at': createdAt,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> m,
      {List<String>? labels}) =>
      TransactionModel(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as String,
        categoryId: m['category_id'] as String,
        subCategoryId: m['sub_category_id'] as String?,
        date: m['date'] as String,
        note: m['note'] as String?,
        paymentMode: (m['payment_mode'] as String?) ?? 'Cash',
        isRecurring: (m['is_recurring'] as int? ?? 0) == 1,
        recurrenceType: m['recurrence_type'] as String?,
        receiptImage: m['receipt_image'] as String?,
        createdAt: m['created_at'] as String,
        labels: labels ?? const [],
      );

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? categoryId,
    String? subCategoryId,
    String? date,
    String? note,
    String? paymentMode,
    bool? isRecurring,
    String? recurrenceType,
    String? receiptImage,
    String? createdAt,
    List<String>? labels,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        subCategoryId: subCategoryId ?? this.subCategoryId,
        date: date ?? this.date,
        note: note ?? this.note,
        paymentMode: paymentMode ?? this.paymentMode,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceType: recurrenceType ?? this.recurrenceType,
        receiptImage: receiptImage ?? this.receiptImage,
        createdAt: createdAt ?? this.createdAt,
        labels: labels ?? this.labels,
      );
}
