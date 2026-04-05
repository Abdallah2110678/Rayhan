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

    if (result == null) {
      return;
    }

    widget.expenses.addExpense(
      result['date'] as DateTime,
      result['amount'] as double,
      result['reason'] as String,
    );
  }

  Future<void> _deleteExpense(ExpenseRecord expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translator.translate('delete_expense')),
        content: Text(Translator.translate('delete_expense_confirmation', {'reason': expense.reason})),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Translator.translate('cancel')),
          ),
          FilledButton(
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Text(Translator.translate('total_expenses_label')),
                      const Spacer(),
                      Text(
                        formatCurrency(total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: expenses.isEmpty
                    ? Center(child: Text(Translator.translate('no_expenses_recorded_yet')))
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return Card(
                            child: ListTile(
                              title: Text(expense.reason),
                              subtitle: Text(formatDateTime(expense.date)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(formatCurrency(expense.amount)),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteExpense(expense),
                                  ),
                                ],
                              ),
                            ),
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
      title: Text(widget.expense == null ? Translator.translate('add_expense_dialog_title') : Translator.translate('edit_expense_dialog_title')),
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
            TextFormField(
              initialValue: _amount.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: Translator.translate('amount')),
              onChanged: (value) {
                _amount = double.tryParse(value) ?? 0;
              },
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
            TextFormField(
              initialValue: _reason,
              decoration: InputDecoration(labelText: Translator.translate('reason')),
              onChanged: (value) {
                _reason = value;
              },
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
