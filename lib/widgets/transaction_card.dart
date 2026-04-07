import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/models.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExpense = transaction.type == 'expense';
    final amtColor =
        isExpense ? cs.error : const Color(0xFF2E7D32);
    final catColor = category != null
        ? Color(category!.color)
        : cs.primary;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(category?.emoji ?? '💰',
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty)
                    Text(
                      transaction.note!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      _fmtDate(transaction.date),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: cs.onSurfaceVariant),
                    ),
                  // Labels
                  if (transaction.labels.isNotEmpty)
                    SizedBox(
                      height: 20,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: transaction.labels.length,
                        itemBuilder: (_, i) => Container(
                          margin: const EdgeInsets.only(
                              right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.labels[i],
                            style: TextStyle(
                                fontSize: 9,
                                color:
                                    cs.onSecondaryContainer),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Amount + mode
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}$currency${_fmtAmt(transaction.amount)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amtColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.paymentMode,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                            color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: cs.error, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  String _fmtDate(String date) {
    try {
      return DateFormat('dd MMM yyyy')
          .format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _fmtAmt(double amount) {
    if (amount >= 10000000)
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000)
      return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000)
      return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(2);
  }
}
