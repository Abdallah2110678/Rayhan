import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalStore {
  static const String _productsFileName = 'rayhan_products.json';
  static const String _customersFileName = 'rayhan_customers.json';
  static const String _expensesFileName = 'rayhan_expenses.json';

  // Cached to avoid repeated async calls on every read/write.
  Directory? _cachedDirectory;

  Future<Map<String, dynamic>> loadProducts() => _loadFile(_productsFileName);
  Future<Map<String, dynamic>> loadCustomers() => _loadFile(_customersFileName);
  Future<Map<String, dynamic>> loadExpenses() => _loadFile(_expensesFileName);

  Future<void> saveProducts(Map<String, dynamic> data) =>
      _saveFile(_productsFileName, data);
  Future<void> saveCustomers(Map<String, dynamic> data) =>
      _saveFile(_customersFileName, data);
  Future<void> saveExpenses(Map<String, dynamic> data) =>
      _saveFile(_expensesFileName, data);

  Future<Map<String, dynamic>> _loadFile(String fileName) async {
    try {
      final file = await _file(fileName);
      if (!await file.exists()) return <String, dynamic>{};
      final content = await file.readAsString();
      if (content.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _saveFile(String fileName, Map<String, dynamic> data) async {
    final file = await _file(fileName);
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  Future<File> _file(String fileName) async {
    _cachedDirectory ??= await getApplicationDocumentsDirectory();
    return File('${_cachedDirectory!.path}${Platform.pathSeparator}$fileName');
  }
}
