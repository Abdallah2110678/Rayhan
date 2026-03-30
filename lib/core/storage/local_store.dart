import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalStore {
  static const String _productsFileName = 'rayhan_products.json';
  static const String _customersFileName = 'rayhan_customers.json';

  Future<Map<String, dynamic>> loadProducts() async {
    return _loadFile(_productsFileName);
  }

  Future<Map<String, dynamic>> loadCustomers() async {
    return _loadFile(_customersFileName);
  }

  Future<void> saveProducts(Map<String, dynamic> data) async {
    await _saveFile(_productsFileName, data);
  }

  Future<void> saveCustomers(Map<String, dynamic> data) async {
    await _saveFile(_customersFileName, data);
  }

  Future<String> get productsPath async => (await _file(_productsFileName)).path;

  Future<String> get customersPath async => (await _file(_customersFileName)).path;

  Future<Map<String, dynamic>> _loadFile(String fileName) async {
    try {
      final file = await _file(fileName);
      if (!await file.exists()) {
        return <String, dynamic>{};
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _saveFile(String fileName, Map<String, dynamic> data) async {
    final file = await _file(fileName);
    await file.writeAsString(
      jsonEncode(data),
      flush: true,
    );
  }

  Future<File> _file(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }
}
