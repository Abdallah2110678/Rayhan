import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/expense_record.dart';

class ExpenseController extends ChangeNotifier {
  final List<ExpenseRecord> _expenses = <ExpenseRecord>[];

  UnmodifiableListView<ExpenseRecord> get expenses =>
      UnmodifiableListView(_expenses);

  int get expenseCount => _expenses.length;

  double get totalExpenses =>
      _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

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
    notifyListeners();
  }

  ExpenseRecord addExpense(DateTime date, double amount, String reason) {
    final expense = ExpenseRecord(
      id: IdGenerator.product(),
      date: date,
      amount: amount,
      reason: reason,
    );

    _expenses.insert(0, expense);
    notifyListeners();
    return expense;
  }

  void removeExpense(String expenseId) {
    _expenses.removeWhere((expense) => expense.id == expenseId);
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
    _expenses[index] = ExpenseRecord(
      id: id,
      date: date,
      amount: amount,
      reason: reason,
    );
    notifyListeners();
  }
}
