import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../models/expense_record.dart';
import '../state/expense_controller.dart';
import '../widgets/page_header.dart';

class FinancesPage extends StatefulWidget {
  const FinancesPage({super.key, required this.expenses});

  final ExpenseController expenses;

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
          Translator.translate('delete_expense_confirmation', {'reason': expense.reason}),
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
    return AnimatedBuilder(
      animation: widget.expenses,
      builder: (context, _) {
        final expenses = widget.expenses.expenses;
        final total = widget.expenses.totalExpenses;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(
                title: Translator.translate('finances'),
                subtitle: Translator.translate('track_business_expenses'),
                trailing: FilledButton.icon(
                  onPressed: _openEditor,
                  icon: const Icon(Icons.add),
                  label: Text(Translator.translate('add_expense')),
                ),
              ),
              const SizedBox(height: 20),
              _TotalCard(total: total),
              const SizedBox(height: 20),
              Expanded(
                child: expenses.isEmpty
                    ? _EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: Translator.translate('no_expenses_yet'),
                        description: Translator.translate('no_expenses_yet_description'),
                      )
                    : ListView.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return _ExpenseTile(
                            expense: expense,
                            onEdit: () => _openEditor(expense),
                            onDelete: () => _deleteExpense(expense),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF8A5A24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    Translator.translate('total_expenses_label'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF173531),
                        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EEF5),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Color(0xFF3D6B8C),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    expense.reason,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF173531),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency(expense.amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8A5A24),
                  ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              style: IconButton.styleFrom(foregroundColor: const Color(0xFF18534F)),
              tooltip: Translator.translate('edit'),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              style: IconButton.styleFrom(foregroundColor: Colors.red.shade600),
              tooltip: Translator.translate('delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFE8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF18534F)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF173531),
                  ),
            ),
            if (description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5A625D),
                    ),
              ),
            ],
          ],
        ),
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
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late double _amount;
  late String _reason;

  @override
  void initState() {
    super.initState();
    _date = widget.expense?.date ?? DateTime.now();
    _amount = widget.expense?.amount ?? 0;
    _reason = widget.expense?.reason ?? '';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.expense == null
            ? Translator.translate('add_expense_dialog_title')
            : Translator.translate('edit_expense_dialog_title'),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: formatDateOnly(_date),
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(
                labelText: Translator.translate('date'),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return Translator.translate('please_select_date');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _amount == 0 ? '' : _amount.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: Translator.translate('amount')),
              onChanged: (value) => _amount = double.tryParse(value) ?? 0,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return Translator.translate('please_enter_amount');
                }
                final num = double.tryParse(value);
                if (num == null || num <= 0) {
                  return Translator.translate('please_enter_valid_amount');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _reason,
              decoration: InputDecoration(labelText: Translator.translate('reason')),
              onChanged: (value) => _reason = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return Translator.translate('please_enter_reason');
                }
                return null;
              },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(<String, dynamic>{
                'date': _date,
                'amount': _amount,
                'reason': _reason,
              });
            }
          },
          child: Text(Translator.translate('save')),
        ),
      ],
    );
  }
}
