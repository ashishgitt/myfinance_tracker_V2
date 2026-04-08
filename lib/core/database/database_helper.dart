import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final p = join(dbPath, 'myfinance.db');
    return openDatabase(p,
        version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  // ─── Schema Creation ──────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int old, int newV) async {
    if (old < 2) {
      // v1→v2: add sub_category_id to transactions
      try { await db.execute('ALTER TABLE transactions ADD COLUMN sub_category_id TEXT'); } catch (_) {}
      await _createV2Tables(db);
    }
    if (old < 3) {
      // v2→v3:
      // 1. Fix duplicate categories (de-dup then add UNIQUE constraint)
      await _deduplicateCategories(db);
      await _recreateCategoriesWithUnique(db);
      // 2. Create person-wise debt tables
      await _createV3Tables(db);
      // 3. Migrate old debts → people + debt_transactions
      await _migrateDebtsToPersons(db);
    }
  }

  Future<void> _createAllTables(Database db) async {
    await _createV1Tables(db);
    await _createV2Tables(db);
    await _createV3Tables(db);
  }

  Future<void> _createV1Tables(Database db) async {
    // Fix 3: UNIQUE constraint on (name, type) prevents duplicate inserts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color INTEGER NOT NULL,
        emoji TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        UNIQUE(name, type)
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        sub_category_id TEXT,
        date TEXT NOT NULL,
        note TEXT,
        payment_mode TEXT DEFAULT 'Cash',
        is_recurring INTEGER DEFAULT 0,
        recurrence_type TEXT,
        receipt_image TEXT,
        created_at TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL DEFAULT 0,
        deadline TEXT,
        created_at TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )''');

    // Keep old debts table for migration purposes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        due_date TEXT,
        is_settled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sub_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS labels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_labels (
        transaction_id TEXT NOT NULL,
        label_id TEXT NOT NULL,
        PRIMARY KEY (transaction_id, label_id)
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bank TEXT NOT NULL,
        last_four TEXT NOT NULL,
        credit_limit REAL NOT NULL,
        bill_date INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_card_transactions (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        merchant TEXT,
        category_id TEXT NOT NULL,
        sub_category_id TEXT,
        is_recoverable INTEGER DEFAULT 0,
        recover_from TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )''');
  }

  Future<void> _createV3Tables(Database db) async {
    // Person-wise debt ledger (Khatabook style)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS people (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_transactions (
        id TEXT PRIMARY KEY,
        person_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        receipt_image TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(person_id) REFERENCES people(id)
      )''');
    // type values: 'lent' (I lent them), 'borrowed' (I borrowed from them),
    //              'received' (they paid me back), 'paid' (I paid them back)
  }

  // ─── Migration helpers ────────────────────────────────────────
  Future<void> _deduplicateCategories(Database db) async {
    // Keep only the first occurrence of each (name, type) pair
    await db.execute('''
      DELETE FROM categories
      WHERE id NOT IN (
        SELECT MIN(id) FROM categories
        GROUP BY name, type
      )
    ''');
  }

  Future<void> _recreateCategoriesWithUnique(Database db) async {
    // SQLite can't add UNIQUE to existing table — recreate it
    await db.execute('ALTER TABLE categories RENAME TO categories_old');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color INTEGER NOT NULL,
        emoji TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        UNIQUE(name, type)
      )''');
    await db.execute('''
      INSERT OR IGNORE INTO categories
      SELECT * FROM categories_old
    ''');
    await db.execute('DROP TABLE categories_old');
  }

  Future<void> _migrateDebtsToPersons(Database db) async {
    final oldDebts = await db.query('debts');
    if (oldDebts.isEmpty) return;

    // Group by person name
    final Map<String, String> personIds = {};
    for (final d in oldDebts) {
      final name = d['person_name'] as String;
      if (!personIds.containsKey(name)) {
        final pid = 'migrated_${name.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}';
        personIds[name] = pid;
        await db.insert('people', {
          'id': pid,
          'name': name,
          'phone': null,
          'notes': 'Migrated from previous version',
          'created_at': d['created_at'] ?? DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final pid = personIds[name]!;
      // 'owe' = I owe them = 'borrowed'; 'owed' = they owe me = 'lent'
      final txnType = (d['type'] as String) == 'owe' ? 'borrowed' : 'lent';
      await db.insert('debt_transactions', {
        'id': 'migrated_${d['id']}',
        'person_id': pid,
        'amount': d['amount'],
        'type': txnType,
        'date': (d['due_date'] as String?) ??
            (d['created_at'] as String).substring(0, 10),
        'note': d['note'],
        'receipt_image': null,
        'created_at': d['created_at'] ?? DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ─── Transactions ─────────────────────────────────────────────
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('transactions', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('transactions', row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transaction_labels',
        where: 'transaction_id = ?', whereArgs: [id]);
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return db.query('transactions', orderBy: 'date DESC, created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByMonth(
      int month, int year) async {
    final db = await database;
    final s = '$year-${month.toString().padLeft(2, '0')}-01';
    final e = '$year-${month.toString().padLeft(2, '0')}-31';
    return db.query('transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [s, e],
        orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(
      String start, String end) async {
    final db = await database;
    return db.query('transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start, end],
        orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> searchTransactions(
      String query) async {
    final db = await database;
    final catRows = await db.query('categories',
        where: 'name LIKE ? AND is_deleted = 0',
        whereArgs: ['%$query%']);
    final catIds = catRows.map((r) => "'${r['id']}'").join(',');
    String where = '(note LIKE ? OR amount LIKE ?)';
    final args = <dynamic>['%$query%', '%$query%'];

    if (catIds.isNotEmpty) where += ' OR category_id IN ($catIds)';

    final subRows = await db.query('sub_categories',
        where: 'name LIKE ?', whereArgs: ['%$query%']);
    final subIds = subRows.map((r) => "'${r['id']}'").join(',');
    if (subIds.isNotEmpty) where += ' OR sub_category_id IN ($subIds)';

    final labelRows = await db.query('labels',
        where: 'name LIKE ?', whereArgs: ['%$query%']);
    if (labelRows.isNotEmpty) {
      final lids = labelRows.map((r) => "'${r['id']}'").join(',');
      final tlRows = await db.rawQuery(
          'SELECT DISTINCT transaction_id FROM transaction_labels WHERE label_id IN ($lids)');
      final tids = tlRows.map((r) => "'${r['transaction_id']}'").join(',');
      if (tids.isNotEmpty) where += ' OR id IN ($tids)';
    }
    return db.query('transactions',
        where: where, whereArgs: args, orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDate(
      String date) async {
    final db = await database;
    return db.query('transactions',
        where: 'date = ?', whereArgs: [date], orderBy: 'created_at DESC');
  }

  // ─── Transaction Labels ───────────────────────────────────────
  Future<void> setTransactionLabels(String txnId, List<String> labelIds) async {
    final db = await database;
    await db.delete('transaction_labels',
        where: 'transaction_id = ?', whereArgs: [txnId]);
    for (final lid in labelIds) {
      await db.insert('transaction_labels',
          {'transaction_id': txnId, 'label_id': lid},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<String>> getLabelsForTransaction(String txnId) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT l.name FROM labels l '
        'JOIN transaction_labels tl ON l.id = tl.label_id '
        'WHERE tl.transaction_id = ?',
        [txnId]);
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<String> insertOrGetLabel(String name) async {
    final db = await database;
    final ex = await db.query('labels', where: 'name = ?', whereArgs: [name]);
    if (ex.isNotEmpty) return ex.first['id'] as String;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await db.insert('labels', {'id': id, 'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllLabels() async {
    final db = await database;
    return db.query('labels', orderBy: 'name ASC');
  }

  // ─── Sub-categories ───────────────────────────────────────────
  Future<int> insertSubCategory(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('sub_categories', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSubCategoriesByCategoryId(
      String categoryId) async {
    final db = await database;
    return db.query('sub_categories',
        where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'name ASC');
  }

  Future<int> deleteSubCategory(String id) async {
    final db = await database;
    return db.delete('sub_categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Categories (Fix 3: INSERT OR IGNORE prevents duplicates) ─
  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('categories', row,
        conflictAlgorithm: ConflictAlgorithm.ignore); // IGNORE duplicates
  }

  Future<int> updateCategory(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('categories', row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    // Fix 3: Hard delete (soft-delete with is_deleted=1)
    return db.update('categories', {'is_deleted': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return db.query('categories', where: 'is_deleted = 0');
  }

  Future<int> categoryCount() async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM categories WHERE is_deleted=0');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> transactionCountForCategory(String categoryId) async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM transactions WHERE category_id = ?',
        [categoryId]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> reassignTransactionsCategory(String fromId, String toId) async {
    final db = await database;
    await db.update('transactions', {'category_id': toId},
        where: 'category_id = ?', whereArgs: [fromId]);
  }

  // ─── Budgets ──────────────────────────────────────────────────
  Future<int> insertOrUpdateBudget(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('budgets', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getBudgetsForMonth(
      int month, int year) async {
    final db = await database;
    return db.query('budgets',
        where: 'month = ? AND year = ?', whereArgs: [month, year]);
  }

  // ─── Savings Goals ────────────────────────────────────────────
  Future<int> insertSavingsGoal(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('savings_goals', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSavingsGoal(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('savings_goals', row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteSavingsGoal(String id) async {
    final db = await database;
    return db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllSavingsGoals() async {
    final db = await database;
    return db.query('savings_goals', orderBy: 'created_at DESC');
  }

  // ─── People (Khatabook-style debt) ────────────────────────────
  Future<int> insertPerson(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('people', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updatePerson(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('people', row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deletePerson(String id) async {
    final db = await database;
    await db.delete('debt_transactions',
        where: 'person_id = ?', whereArgs: [id]);
    return db.delete('people', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllPeople() async {
    final db = await database;
    return db.query('people', orderBy: 'name ASC');
  }

  // ─── Debt Transactions ────────────────────────────────────────
  Future<int> insertDebtTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('debt_transactions', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteDebtTransaction(String id) async {
    final db = await database;
    return db.delete('debt_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDebtTransactionsByPerson(
      String personId) async {
    final db = await database;
    return db.query('debt_transactions',
        where: 'person_id = ?',
        whereArgs: [personId],
        orderBy: 'date ASC, created_at ASC');
  }

  Future<List<Map<String, dynamic>>> getAllDebtTransactions() async {
    final db = await database;
    return db.query('debt_transactions', orderBy: 'created_at DESC');
  }

  // ─── Credit Cards ─────────────────────────────────────────────
  Future<int> insertCreditCard(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('credit_cards', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCreditCard(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('credit_cards', row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCreditCard(String id) async {
    final db = await database;
    await db.delete('credit_card_transactions',
        where: 'card_id = ?', whereArgs: [id]);
    return db.delete('credit_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllCreditCards() async {
    final db = await database;
    return db.query('credit_cards', orderBy: 'created_at DESC');
  }

  Future<int> insertCreditCardTransaction(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('credit_card_transactions', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteCreditCardTransaction(String id) async {
    final db = await database;
    return db.delete('credit_card_transactions',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCreditCardTransactionsByCard(
      String cardId) async {
    final db = await database;
    return db.query('credit_card_transactions',
        where: 'card_id = ?', whereArgs: [cardId], orderBy: 'date DESC');
  }
}
