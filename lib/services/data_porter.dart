import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../core/utils/formatters.dart';
import '../state/customer_controller.dart';
import '../state/expense_controller.dart';
import '../state/product_catalog_controller.dart';

class ImportResult {
  const ImportResult({
    required this.productsAdded,
    required this.productsDuplicate,
    required this.salesAdded,
    required this.salesDuplicate,
    required this.customersAdded,
    required this.customersDuplicate,
    required this.expensesAdded,
    required this.expensesDuplicate,
  });

  final int productsAdded;
  final int productsDuplicate;
  final int salesAdded;
  final int salesDuplicate;
  final int customersAdded;
  final int customersDuplicate;
  final int expensesAdded;
  final int expensesDuplicate;

  bool get hasAnyNew =>
      productsAdded > 0 ||
      salesAdded > 0 ||
      customersAdded > 0 ||
      expensesAdded > 0;

  int get totalDuplicates =>
      productsDuplicate +
      salesDuplicate +
      customersDuplicate +
      expensesDuplicate;
}

class DataPorter {
  // Returns the saved file path, or null if the user cancelled.
  Future<String?> exportAllData({
    required ProductCatalogController products,
    required CustomerController customers,
    required ExpenseController expenses,
  }) async {
    final productsJson = products.toJson();

    final data = <String, dynamic>{
      'products': productsJson['products'],
      'sales': productsJson['sales'],
      'totalPurchaseValue': productsJson['totalPurchaseValue'],
      'totalPurchasedQuantityMm': productsJson['totalPurchasedQuantityMm'],
      'customers': customers.toJson()['customers'],
      'expenses': expenses.toJson()['expenses'],
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final fileName =
        'rayhan_export_${formatDateForFileName(DateTime.now())}.json';

    return FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonEncode(data)),
    );
  }

  // Returns null when the user cancels the file picker.
  Future<ImportResult?> importAllData({
    required ProductCatalogController products,
    required CustomerController customers,
    required ExpenseController expenses,
  }) async {
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) {
      return null;
    }

    final pickedPath = pickerResult.files.single.path;
    if (pickedPath == null) {
      throw Exception('Could not access the selected file.');
    }

    final file = File(pickedPath);
    if (!await file.exists()) {
      throw Exception('Selected file does not exist.');
    }

    final raw = await file.readAsString();
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The selected file is not a valid Rayhan backup.');
    }

    final pr = products.mergeFromJson(<String, dynamic>{
      'products': parsed['products'] ?? <dynamic>[],
      'sales': parsed['sales'] ?? <dynamic>[],
      'totalPurchaseValue': parsed['totalPurchaseValue'] ?? 0,
      'totalPurchasedQuantityMm': parsed['totalPurchasedQuantityMm'] ?? 0,
    });

    final cr = customers.mergeFromJson(<String, dynamic>{
      'customers': parsed['customers'] ?? <dynamic>[],
    });

    final er = expenses.mergeFromJson(<String, dynamic>{
      'expenses': parsed['expenses'] ?? <dynamic>[],
    });

    return ImportResult(
      productsAdded: pr.productsAdded,
      productsDuplicate: pr.productsDuplicate,
      salesAdded: pr.salesAdded,
      salesDuplicate: pr.salesDuplicate,
      customersAdded: cr.added,
      customersDuplicate: cr.duplicates,
      expensesAdded: er.added,
      expensesDuplicate: er.duplicates,
    );
  }
}
