import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

class SubCategoryProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  final Map<String, List<SubCategoryModel>> _cache = {};

  List<SubCategoryModel> forCategory(String categoryId) =>
      _cache[categoryId] ?? [];

  Future<void> loadForCategory(String categoryId) async {
    final rows =
        await _db.getSubCategoriesByCategoryId(categoryId);
    _cache[categoryId] =
        rows.map((r) => SubCategoryModel.fromMap(r)).toList();
    notifyListeners();
  }

  Future<SubCategoryModel> addSubCategory(
      String name, String categoryId) async {
    final sc = SubCategoryModel(
      id: const Uuid().v4(),
      name: name.trim(),
      categoryId: categoryId,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insertSubCategory(sc.toMap());
    await loadForCategory(categoryId);
    return sc;
  }

  Future<void> deleteSubCategory(String id, String categoryId) async {
    await _db.deleteSubCategory(id);
    await loadForCategory(categoryId);
  }
}
