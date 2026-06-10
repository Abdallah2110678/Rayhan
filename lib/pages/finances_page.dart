import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../models/expense_record.dart';
import '../state/expense_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/collapsing_header_page.dart';
import '../widgets/page_header.dart';

class FinancesPage extends StatefulWidget {
  const FinancesPage({
    super.key,
    required this.expenses,
    required this.products,
  });

  final ExpenseController expenses;
  final ProductCatalogController products;

  @override
  State<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends State<FinancesPage> {
  Future<void> _openEditor([ExpenseRecord? expense]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ExpenseEditor(expense: expense),
    );

    if (result == null) return;

    if (expense == null) {
      widget.expenses.addExpense(
        result['date'] as DateTime,
        result['amount'] as double,
        result['reason'] as String,
      );
    } else {
      widget.expenses.updateExpense(
        expense.id,
        result['date'] as DateTime,
        result['amount'] as double,
        result['reason'] as String,
      );
    }
  }

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translator.translate('delete_expense')),
        content: Text(
          Translator.translate(
            'delete_expense_confirmation',
            {'reason': expense.reason},
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Translator.translate('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Translator.translate('delete')),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      widget.expenses.removeExpense(expense.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          widget.expenses,
          widget.products,
        ]),
        builder: (context, _) {
          final expenses = widget.expenses.expenses;
          final total = widget.expenses.totalExpenses;

          return CollapsingHeaderPage(
            header: PageHeader(
              title: Translator.translate('finances'),
              subtitle: Translator.translate('track_business_expenses'),
              trailing: FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: Text(Translator.translate('add_expense')),
              ),
            ),
            between: TabBar(
              tabs: <Tab>[
                Tab(text: Translator.translate('expenses_tab')),
                Tab(text: Translator.translate('report_tab')),
              ],
            ),
            betweenSpacing: 12,
            child: TabBarView(
              children: <Widget>[
                // ── Tab 1: Expenses ──────────────────────────────────────────
                _ExpensesTab(
                  expenses: expenses.toList(),
                  total: total,
                  onEdit: _openEditor,
                  onDelete: _deleteExpense,
                ),
                // ── Tab 2: Report ────────────────────────────────────────────
                _ReportTab(
                  products: widget.products,
                  expenses: widget.expenses,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Tab 1: Expenses list ──────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.expenses,
    required this.total,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ExpenseRecord> expenses;
  final double total;
  final void Function([ExpenseRecord?]) onEdit;
  final Future<void> Function(ExpenseRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const _EmptyState();

    return Column(
      children: <Widget>[
        _TotalBanner(total: total),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: expenses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _ExpenseTile(
                expense: expense,
                onEdit: () => onEdit(expense),
                onDelete: () => onDelete(expense),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Tab 2: Report ─────────────────────────────────────────────────────────────

class _ReportTab extends StatefulWidget {
  const _ReportTab({required this.products, required this.expenses});

  final ProductCatalogController products;
  final ExpenseController expenses;

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
    );
    if (picked != null) {
      setState(() => _from = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _to = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topProducts = widget.products.topSellingProductsBetween(_from, _to);
    final periodExpenses = widget.expenses.expensesBetween(_from, _to);
    final totalSales = widget.products.totalSalesValueBetween(_from, _to);
    final totalExpenses = widget.expenses.totalExpensesBetween(_from, _to);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Date range
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _DateButton(
                      label: Translator.translate('from'),
                      value: formatDateOnly(_from),
                      onTap: _pickFrom,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: Translator.translate('to'),
                      value: formatDateOnly(_to),
                      onTap: _pickTo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  title: Translator.translate('sales_in_period'),
                  value: formatCurrency(totalSales),
                  color: const Color(0xFF18534F),
                  icon: Icons.point_of_sale_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: Translator.translate('expenses_in_period'),
                  value: formatCurrency(totalExpenses),
                  color: const Color(0xFFD32F2F),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top selling products
          _SectionLabel(Translator.translate('top_selling_products')),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            _EmptyCard(Translator.translate('no_data_in_period'))
          else
            ...topProducts.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProductRankTile(
                  rank: entry.key + 1,
                  productName: entry.value.productName,
                  totalRevenue: entry.value.totalRevenue,
                  totalQuantityMm: entry.value.totalQuantityMm,
                  salesCount: entry.value.salesCount,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Expenses breakdown for the period
          _SectionLabel(Translator.translate('expenses_in_period')),
          const SizedBox(height: 12),
          if (periodExpenses.isEmpty)
            _EmptyCard(Translator.translate('no_data_in_period'))
          else
            ...periodExpenses.map(
              (expense) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReportExpenseTile(expense: expense),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173531),
              ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8D9490),
              ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF173531),
                ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.calendar_month_outlined,
                size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRankTile extends StatelessWidget {
  const _ProductRankTile({
    required this.rank,
    required this.productName,
    required this.totalRevenue,
    required this.totalQuantityMm,
    required this.salesCount,
  });

  final int rank;
  final String productName;
  final double totalRevenue;
  final double totalQuantityMm;
  final int salesCount;

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? const Color(0xFFFFA000)
        : rank == 2
            ? const Color(0xFF9E9E9E)
            : rank == 3
                ? const Color(0xFF8A5A24)
                : const Color(0xFF5B635E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(Icons.emoji_events_outlined,
                      color: rankColor, size: 22)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF173531),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    children: <Widget>[
                      Text(
                        formatCurrency(totalRevenue),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF18534F),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        formatMillimeters(totalQuantityMm),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8D9490),
                            ),
                      ),
                      Text(
                        '$salesCount×',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8D9490),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _ReportExpenseTile extends StatelessWidget {
  const _ReportExpenseTile({required this.expense});

  final ExpenseRecord expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 5,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    expense.reason,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF173531),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateOnly(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8D9490),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(expense.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD32F2F),
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ── Existing widgets (expenses tab) ───────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF173531),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                Translator.translate('total_expenses_label'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatCurrency(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseRecord expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 5,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF8A5A24),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    expense.reason,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF173531),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateOnly(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8D9490),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(expense.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF8A5A24),
                ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF18534F),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
                color: Colors.red.shade400,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EDE0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: Color(0xFF8A5A24),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            Translator.translate('no_expenses_yet'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173531),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            Translator.translate('no_expenses_yet_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8D9490),
                ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEditor extends StatefulWidget {
  const _ExpenseEditor({this.expense});

  final ExpenseRecord? expense;

  @override
  State<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<_ExpenseEditor> {
  DateTime? _selectedDate;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _selectedDate = widget.expense!.date;
      _amountController.text = widget.expense!.amount.toString();
      _reasonController.text = widget.expense!.reason;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translator.translate('please_select_date'))),
      );
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'date': _selectedDate,
      'amount': double.parse(_amountController.text.trim()),
      'reason': _reasonController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        Translator.translate(
          widget.expense == null
              ? 'add_expense_dialog_title'
              : 'edit_expense_dialog_title',
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(
                _selectedDate == null
                    ? Translator.translate('please_select_date')
                    : formatDateOnly(_selectedDate!),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: Translator.translate('amount')),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return Translator.translate('please_enter_valid_amount');
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration:
                  InputDecoration(labelText: Translator.translate('reason')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? Translator.translate('please_enter_reason')
                  : null,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Translator.translate('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(Translator.translate('save')),
        ),
      ],
    );
  }
}
