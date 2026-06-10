import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/expense_record.dart';

class ExpenseController extends ChangeNotifier {
  final List<ExpenseRecord> _expenses = <ExpenseRecord>[];

  // Running total maintained incrementally — no fold() on every access.
  double _totalExpenses = 0;

  UnmodifiableListView<ExpenseRecord> get expenses =>
      UnmodifiableListView(_expenses);

  int get expenseCount => _expenses.length;
  double get totalExpenses => _totalExpenses;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'expenses': _expenses.map((expense) => expense.toJson()).toList(),
    };
  }

  ({int added, int duplicates}) mergeFromJson(Map<String, dynamic>? json) {
    final existingIds = {for (final e in _expenses) e.id};

    final incoming = ((json?['expenses'] as List<dynamic>?) ?? <dynamic>[])
        .map((item) => ExpenseRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    int added = 0, duplicates = 0;
    for (final expense in incoming) {
      if (existingIds.contains(expense.id)) {
        duplicates++;
      } else {
        _expenses.add(expense);
        _totalExpenses += expense.amount;
        added++;
      }
    }

    if (added > 0) notifyListeners();
    return (added: added, duplicates: duplicates);
  }

  void restoreFromJson(Map<String, dynamic>? json) {
    _expenses
      ..clear()
      ..addAll(
        ((json?['expenses'] as List<dynamic>?) ?? <dynamic>[]).map(
          (item) => ExpenseRecord.fromJson(item as Map<String, dynamic>),
        ),
      );
    _totalExpenses = _expenses.fold<double>(0, (sum, e) => sum + e.amount);
    notifyListeners();
  }

  ExpenseRecord addExpense(DateTime date, double amount, String reason) {
    final expense = ExpenseRecord(
      id: IdGenerator.expense(),
      date: date,
      amount: amount,
      reason: reason,
    );

    _expenses.insert(0, expense);
    _totalExpenses += amount;
    notifyListeners();
    return expense;
  }

  void removeExpense(String expenseId) {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    _totalExpenses -= _expenses[index].amount;
    _expenses.removeAt(index);
    notifyListeners();
  }

  void updateExpense(
    String id,
    DateTime date,
    double amount,
    String reason,
  ) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _totalExpenses += amount - _expenses[index].amount;
    _expenses[index] = ExpenseRecord(
      id: id,
      date: date,
      amount: amount,
      reason: reason,
    );
    notifyListeners();
  }

  List<ExpenseRecord> expensesBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return _expenses
        .where((e) => !e.date.isBefore(fromDate) && !e.date.isAfter(toDate))
        .toList(growable: false);
  }

  double totalExpensesBetween(DateTime from, DateTime to) =>
      expensesBetween(from, to).fold<double>(0, (sum, e) => sum + e.amount);
}
