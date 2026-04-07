import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_savings_debt_providers.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/models.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _fromDate = DateTime(
      DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _exporting = false;

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null && mounted) {
      setState(() {
        if (isFrom) _fromDate = d;
        else _toDate = d;
      });
    }
  }

  Future<List<TransactionModel>> _getFilteredTxns() {
    return context
        .read<TransactionProvider>()
        .getByDateRange(_fromDate, _toDate);
  }

  // ─── PDF Export ───────────────────────────────────────────────
  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final txns = await _getFilteredTxns();
      final catP = context.read<CategoryProvider>();
      final currency =
          context.read<SettingsProvider>().currency;

      final pdf = pw.Document();
      final dateRange =
          '${DateFormat('dd MMM yyyy').format(_fromDate)} – '
          '${DateFormat('dd MMM yyyy').format(_toDate)}';

      final totalIncome = txns
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final totalExpense = txns
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: const PdfColor.fromInt(0xFF3F51B5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MyFinance Tracker',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Transaction Report: $dateRange',
                      style: const pw.TextStyle(
                          color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            // Summary row
            pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceAround,
                children: [
              _pdfStat('Total Income',
                  '$currency${totalIncome.toStringAsFixed(2)}',
                  PdfColors.green700),
              _pdfStat('Total Expense',
                  '$currency${totalExpense.toStringAsFixed(2)}',
                  PdfColors.red700),
              _pdfStat('Net Savings',
                  '$currency${(totalIncome - totalExpense).toStringAsFixed(2)}',
                  totalIncome >= totalExpense
                      ? PdfColors.blue700
                      : PdfColors.red700),
            ]),
            pw.SizedBox(height: 16),
            // Table
            pw.Text('Transactions',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF3F51B5)),
                  children: ['Date', 'Category', 'Amount',
                    'Type', 'Payment']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight:
                                        pw.FontWeight.bold,
                                    fontSize: 10)),
                          ))
                      .toList(),
                ),
                ...txns.asMap().entries.map((e) {
                  final i = e.key;
                  final t = e.value;
                  final cat = catP.findById(t.categoryId);
                  final bg = i.isEven
                      ? PdfColors.white
                      : const PdfColor.fromInt(0xFFF5F5F5);
                  return pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: bg),
                    children: [
                      t.date,
                      cat?.name ?? '?',
                      '$currency${t.amount.toStringAsFixed(2)}',
                      t.type,
                      t.paymentMode,
                    ]
                        .map((cell) => pw.Padding(
                              padding:
                                  const pw.EdgeInsets.all(5),
                              child: pw.Text(cell,
                                  style: const pw.TextStyle(
                                      fontSize: 9)),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          ],
        ),
      );

      final dir = await _getExportDir();
      final filename =
          'myfinance_${_fromDate.year}${_fromDate.month.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)],
            subject: 'MyFinance Report $dateRange');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfStat(String label, String value, PdfColor color) =>
      pw.Column(children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: color,
                fontSize: 13)),
        pw.Text(label,
            style: const pw.TextStyle(
                color: PdfColors.grey700, fontSize: 10)),
      ]);

  // ─── Excel Export ─────────────────────────────────────────────
  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final txns = await _getFilteredTxns();
      final catP = context.read<CategoryProvider>();
      final budP = context.read<BudgetProvider>();
      final debtP = context.read<DebtProvider>();
      final currency =
          context.read<SettingsProvider>().currency;
      final now = DateTime.now();

      final excel = Excel.createExcel();

      // ── Sheet 1: Dashboard Summary ──────────────────────
      final summarySheet =
          excel['Dashboard Summary'];
      excel.setDefaultSheet('Dashboard Summary');

      _excelHeader(summarySheet, 0,
          ['MyFinance Tracker — Summary Report']);
      _excelHeader(summarySheet, 1, [
        'Period',
        '${DateFormat('dd MMM yyyy').format(_fromDate)} – ${DateFormat('dd MMM yyyy').format(_toDate)}'
      ]);

      final totalIncome = txns
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final totalExpense = txns
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);

      _excelRow(summarySheet, 3,
          ['Metric', 'Amount'], isHeader: true);
      _excelRow(summarySheet, 4,
          ['Total Income', '$currency${totalIncome.toStringAsFixed(2)}']);
      _excelRow(summarySheet, 5,
          ['Total Expense', '$currency${totalExpense.toStringAsFixed(2)}']);
      _excelRow(summarySheet, 6, [
        'Net Savings',
        '$currency${(totalIncome - totalExpense).toStringAsFixed(2)}'
      ]);
      _excelRow(summarySheet, 7, ['Transactions', '${txns.length}']);

      // Budget vs actuals
      _excelRow(summarySheet, 9,
          ['Category Budgets — ${DateFormat('MMMM yyyy').format(now)}'],
          isHeader: true);
      _excelRow(summarySheet, 10,
          ['Category', 'Budget', 'Spent', 'Remaining'],
          isHeader: true);

      final catBreakdown = <String, double>{};
      for (final t in txns.where((t) => t.type == 'expense')) {
        catBreakdown[t.categoryId] =
            (catBreakdown[t.categoryId] ?? 0) + t.amount;
      }

      int row = 11;
      for (final e in catBreakdown.entries) {
        final cat = catP.findById(e.key);
        final budget = budP.budgetForCategory(e.key);
        _excelRow(summarySheet, row, [
          '${cat?.emoji ?? ''} ${cat?.name ?? '?'}',
          budget != null
              ? '$currency${budget.amount.toStringAsFixed(2)}'
              : 'Not set',
          '$currency${e.value.toStringAsFixed(2)}',
          budget != null
              ? '$currency${(budget.amount - e.value).toStringAsFixed(2)}'
              : '-',
        ]);
        row++;
      }

      // Debt summary
      row += 2;
      _excelRow(summarySheet, row, ['Debt Summary'], isHeader: true);
      row++;
      _excelRow(summarySheet, row, ['Type', 'Person', 'Amount'],
          isHeader: true);
      row++;
      for (final d in debtP.debts.where((d) => !d.isSettled)) {
        _excelRow(summarySheet, row, [
          d.type == 'owe' ? 'I Owe' : 'Owed to Me',
          d.personName,
          '$currency${d.amount.toStringAsFixed(2)}',
        ]);
        row++;
      }

      // ── Sheet 2: All Transactions ───────────────────────
      final txnSheet = excel['All Transactions'];
      _excelRow(txnSheet, 0,
          ['Date', 'Category', 'Sub-category', 'Labels',
            'Amount', 'Type', 'Payment Method', 'Notes'],
          isHeader: true);

      for (int i = 0; i < txns.length; i++) {
        final t = txns[i];
        final cat = catP.findById(t.categoryId);
        _excelRow(txnSheet, i + 1, [
          t.date,
          '${cat?.emoji ?? ''} ${cat?.name ?? '?'}',
          t.subCategoryId ?? '',
          t.labels.join(', '),
          '$currency${t.amount.toStringAsFixed(2)}',
          t.type,
          t.paymentMode,
          t.note ?? '',
        ], isEven: i.isEven);
      }

      // Delete default blank sheet
      excel.delete('Sheet1');

      final dir = await _getExportDir();
      final filename =
          'myfinance_${now.year}${now.month.toString().padLeft(2, '0')}.xlsx';
      final file = File('${dir.path}/$filename');
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)],
            subject:
                'MyFinance Export ${DateFormat('MMM yyyy').format(now)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Excel export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _excelHeader(Sheet sheet, int row, List<dynamic> values) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(values[c].toString());
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#3F51B5'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
  }

  void _excelRow(Sheet sheet, int row, List<dynamic> values,
      {bool isHeader = false, bool isEven = true}) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(values[c].toString());
      if (isHeader) {
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
        );
      } else if (!isEven) {
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
        );
      }
    }
  }

  Future<Directory> _getExportDir() async {
    try {
      return await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } catch (_) {
      return getApplicationDocumentsDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Share')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date Range',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(true),
                        icon: const Icon(Icons.calendar_today,
                            size: 16),
                        label: Text(DateFormat('dd MMM yyyy')
                            .format(_fromDate)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(false),
                        icon: const Icon(Icons.calendar_today,
                            size: 16),
                        label: Text(DateFormat('dd MMM yyyy')
                            .format(_toDate)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Quick range chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _rangeChip('This Month', () {
                        final now = DateTime.now();
                        setState(() {
                          _fromDate =
                              DateTime(now.year, now.month, 1);
                          _toDate = now;
                        });
                      }),
                      _rangeChip('Last Month', () {
                        final now = DateTime.now();
                        final last =
                            DateTime(now.year, now.month - 1);
                        setState(() {
                          _fromDate =
                              DateTime(last.year, last.month, 1);
                          _toDate = DateTime(now.year, now.month,
                              1)
                              .subtract(const Duration(days: 1));
                        });
                      }),
                      _rangeChip('This Year', () {
                        final now = DateTime.now();
                        setState(() {
                          _fromDate = DateTime(now.year, 1, 1);
                          _toDate = now;
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_exporting)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Generating export…'),
                ]),
              ),
            )
          else ...[
            // PDF export
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.red),
                ),
                title: const Text('Export as PDF',
                    style:
                        TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Formatted report with all transactions'),
                trailing: FilledButton(
                  onPressed: _exportPdf,
                  child: const Text('Export'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Excel export
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_chart_outlined,
                      color: Colors.green),
                ),
                title: const Text('Export as Excel',
                    style:
                        TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    '3 sheets: Summary, Transactions, Budgets'),
                trailing: FilledButton(
                  onPressed: _exportExcel,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green),
                  child: const Text('Export'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: cs.primaryContainer.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      color: cs.primary, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Files are saved to your device storage and shared via your preferred app (email, WhatsApp, Drive, etc.)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rangeChip(String label, VoidCallback onTap) =>
      ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
      );
}
