import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/utils/formatters.dart';
import '../state/customer_controller.dart';
import '../state/expense_controller.dart';
import '../state/product_catalog_controller.dart';

class DataPorter {
  Future<String> exportAllData({
    required ProductCatalogController products,
    required CustomerController customers,
    required ExpenseController expenses,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'rayhan_export_${formatDateForFileName(DateTime.now())}.json';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');

    final data = <String, dynamic>{
      'products': products.toJson()['products'],
      'sales': products.toJson()['sales'],
      'customers': customers.toJson()['customers'],
      'expenses': expenses.toJson()['expenses'],
    };

    await file.writeAsString(jsonEncode(data), flush: true);
    return file.path;
  }

  Future<void> importAllData({
    required ProductCatalogController products,
    required CustomerController customers,
    required ExpenseController expenses,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file does not exist: $filePath');
    }

    final raw = await file.readAsString();
    final parsed = jsonDecode(raw) as Map<String, dynamic>;

    products.restoreFromJson(<String, dynamic>{
      'products': parsed['products'] ?? <dynamic>[],
      'sales': parsed['sales'] ?? <dynamic>[],
      'totalPurchaseValue': 0,
      'totalPurchasedQuantityMm': 0,
    });
    customers.restoreFromJson(<String, dynamic>{
      'customers': parsed['customers'] ?? <dynamic>[],
    });
    expenses.restoreFromJson(<String, dynamic>{
      'expenses': parsed['expenses'] ?? <dynamic>[],
    });
  }
}
