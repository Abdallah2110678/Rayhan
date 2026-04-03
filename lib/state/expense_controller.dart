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
}
