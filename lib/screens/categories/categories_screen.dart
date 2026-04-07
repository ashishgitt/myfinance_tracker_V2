import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/models.dart';
import '../../core/constants/app_constants.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  // Feature 1: Delete with confirmation + reassign
  Future<void> _confirmDelete(
      CategoryModel cat, CategoryProvider catP) async {
    final txnCount = await catP.transactionCount(cat.id);
    if (!mounted) return;

    if (txnCount > 0) {
      // Has transactions — ask what to do
      final action = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Delete "${cat.name}"?'),
          content: Text(
            '$txnCount transaction${txnCount > 1 ? 's are' : ' is'} linked to this category.\n\nWhat would you like to do?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, 'reassign'),
              child:
                  const Text('Move to Miscellaneous'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.error),
              onPressed: () =>
                  Navigator.pop(context, 'delete'),
              child: const Text('Delete Anyway'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) return;

      if (action == 'reassign') {
        // Find Miscellaneous category
        final misc = catP.expenseCategories
            .where((c) =>
                c.name.toLowerCase().contains('misc'))
            .toList();
        final toId = misc.isNotEmpty ? misc.first.id : null;
        await catP.deleteCategory(cat.id,
            reassignToId: toId);
        // Reload transactions since category changed
        if (mounted) {
          await context.read<TransactionProvider>().loadAll();
        }
      } else if (action == 'delete') {
        await catP.deleteCategory(cat.id);
      }
    } else {
      // No transactions — simple confirm
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Delete "${cat.name}"?'),
          content: const Text(
              'This category will be permanently deleted.'),
          actions: [
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) {
        await catP.deleteCategory(cat.id);
      }
    }
  }

  void _showAddEditSheet(BuildContext context,
      {CategoryModel? existing, required String type}) {
    final nameCtrl =
        TextEditingController(text: existing?.name);
    String selectedEmoji =
        existing?.emoji ?? '📦';
    int selectedColor =
        existing?.color ?? AppConstants.categoryColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    existing != null
                        ? 'Edit Category'
                        : 'New Category',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                            fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Category Name',
                      prefixIcon:
                          Icon(Icons.label_outline)),
                ),
                const SizedBox(height: 16),
                Text('Icon',
                    style: Theme.of(ctx)
                        .textTheme
                        .labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants
                        .categoryEmojis.length,
                    itemBuilder: (_, i) {
                      final e = AppConstants.categoryEmojis[i];
                      return GestureDetector(
                        onTap: () =>
                            setSt(() => selectedEmoji = e),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(
                              right: 8),
                          decoration: BoxDecoration(
                            color: selectedEmoji == e
                                ? Theme.of(ctx)
                                    .colorScheme
                                    .primaryContainer
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(e,
                              style: const TextStyle(
                                  fontSize: 22)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('Color',
                    style: Theme.of(ctx)
                        .textTheme
                        .labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants
                        .categoryColors.length,
                    itemBuilder: (_, i) {
                      final c =
                          AppConstants.categoryColors[i];
                      return GestureDetector(
                        onTap: () =>
                            setSt(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(
                              right: 8),
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: selectedColor == c
                                ? Border.all(
                                    width: 3,
                                    color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty)
                      return;
                    final cat = CategoryModel(
                      id: existing?.id ??
                          const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      type: type,
                      color: selectedColor,
                      emoji: selectedEmoji,
                      isDefault:
                          existing?.isDefault ?? false,
                    );
                    final catP =
                        context.read<CategoryProvider>();
                    if (existing != null) {
                      await catP.updateCategory(cat);
                    } else {
                      await catP.addCategory(cat);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(48)),
                  child: Text(existing != null
                      ? 'Update'
                      : 'Add Category'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catP = context.watch<CategoryProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tc,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context,
            type: _tc.index == 0 ? 'expense' : 'income'),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _CatList(
            cats: catP.expenseCategories,
            cs: cs,
            onEdit: (c) => _showAddEditSheet(context,
                existing: c, type: 'expense'),
            onDelete: (c) => _confirmDelete(c, catP),
          ),
          _CatList(
            cats: catP.incomeCategories,
            cs: cs,
            onEdit: (c) => _showAddEditSheet(context,
                existing: c, type: 'income'),
            onDelete: (c) => _confirmDelete(c, catP),
          ),
        ],
      ),
    );
  }
}

class _CatList extends StatelessWidget {
  final List<CategoryModel> cats;
  final ColorScheme cs;
  final void Function(CategoryModel) onEdit;
  final void Function(CategoryModel) onDelete;

  const _CatList({
    required this.cats,
    required this.cs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (cats.isEmpty) {
      return Center(
          child: Text('No categories',
              style:
                  TextStyle(color: cs.onSurfaceVariant)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final cat = cats[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    Color(cat.color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(cat.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
            title: Text(cat.name),
            subtitle: cat.isDefault
                ? const Text('Default')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onEdit(cat),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: cat.isDefault
                          ? cs.outlineVariant
                          : cs.error),
                  onPressed: cat.isDefault
                      ? null
                      : () => onDelete(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
