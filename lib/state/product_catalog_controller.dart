import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/product.dart';
import '../models/product_draft.dart';
import '../models/sale_record.dart';

class ProductCatalogController extends ChangeNotifier {
  final List<Product> _products = <Product>[];
  final List<SaleRecord> _sales = <SaleRecord>[];
  double _totalPurchaseValue = 0;
  double _totalPurchasedQuantityMm = 0;

  UnmodifiableListView<Product> get products => UnmodifiableListView(_products);
  UnmodifiableListView<SaleRecord> get sales => UnmodifiableListView(_sales);

  int get productCount => _products.length;
  int get saleCount => _sales.length;
  double get totalPurchaseValue => _totalPurchaseValue;
  double get totalSalesValue =>
      _sales.fold<double>(0, (sum, sale) => sum + sale.finalTotal);
  double get totalPurchasedQuantityMm => _totalPurchasedQuantityMm;
  double get totalSoldQuantityMm =>
      _sales.fold<double>(0, (sum, sale) => sum + sale.quantityMm);
  double get netRevenue => totalSalesValue - _totalPurchaseValue;

  double get totalQuantityMm =>
      _products.fold<double>(0, (sum, product) => sum + product.quantityMm);

  double get totalInventoryValue =>
      _products.fold<double>(0, (sum, product) => sum + product.stockValue);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'products': _products.map((product) => product.toJson()).toList(),
      'sales': _sales.map((sale) => sale.toJson()).toList(),
      'totalPurchaseValue': _totalPurchaseValue,
      'totalPurchasedQuantityMm': _totalPurchasedQuantityMm,
    };
  }

  void restoreFromJson(Map<String, dynamic>? json) {
    _products
      ..clear()
      ..addAll(
        ((json?['products'] as List<dynamic>?) ?? <dynamic>[]).map(
          (item) => Product.fromJson(item as Map<String, dynamic>),
        ),
      );
    _sales
      ..clear()
      ..addAll(
        ((json?['sales'] as List<dynamic>?) ?? <dynamic>[]).map(
          (item) => SaleRecord.fromJson(item as Map<String, dynamic>),
        ),
      );
    _totalPurchaseValue = ((json?['totalPurchaseValue'] as num?) ?? 0).toDouble();
    _totalPurchasedQuantityMm =
        ((json?['totalPurchasedQuantityMm'] as num?) ?? 0).toDouble();
    notifyListeners();
  }

  Product addProduct(ProductDraft draft) {
    final product = Product(
      id: IdGenerator.product(),
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      sellPrice: draft.sellPrice,
      quantityMm: draft.quantityMm,
      initialQuantityMm: draft.quantityMm,
    );

    _products.insert(0, product);
    _totalPurchaseValue += product.purchasePrice;
    _totalPurchasedQuantityMm += product.quantityMm;
    notifyListeners();
    return product;
  }

  void removeProduct(String id) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) {
      throw ArgumentError('Product not found.');
    }
    final product = _products.removeAt(index);
    _totalPurchaseValue -= product.purchasePrice;
    _totalPurchasedQuantityMm -= product.quantityMm;
    notifyListeners();
  }

  void updateProduct(String id, ProductDraft draft) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) {
      throw ArgumentError('Product not found.');
    }
    final oldProduct = _products[index];
    final newProduct = oldProduct.copyWith(
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      sellPrice: draft.sellPrice,
      quantityMm: draft.quantityMm,
      initialQuantityMm: draft.quantityMm,
    );
    _products[index] = newProduct;
    _totalPurchaseValue += draft.purchasePrice - oldProduct.purchasePrice;
    _totalPurchasedQuantityMm +=
        draft.quantityMm - oldProduct.initialQuantityMm;
    notifyListeners();
  }

  Product? productById(String id) {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  List<Product> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    return _products
        .where((product) => product.matches(normalizedQuery))
        .toList(growable: false);
  }

  double sellProduct({
    required String productId,
    required double quantityMm,
    required double unitPrice,
    required double discountPercent,
    required double subtotal,
    required double finalTotal,
    String? customerId,
    String? customerName,
  }) {
    final index = _products.indexWhere((product) => product.id == productId);
    if (index == -1) {
      throw ArgumentError('Product not found.');
    }

    final currentProduct = _products[index];
    if (quantityMm <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    if (quantityMm > currentProduct.quantityMm) {
      throw ArgumentError('Not enough quantity in stock.');
    }

    if (finalTotal <= 0) {
      throw ArgumentError('Final price must be greater than zero.');
    }

    _products[index] = currentProduct.copyWith(
      quantityMm: currentProduct.quantityMm - quantityMm,
    );
    _sales.insert(
      0,
      SaleRecord(
        id: IdGenerator.sale(),
        productId: currentProduct.id,
        productName: currentProduct.name,
        quantityMm: quantityMm,
        unitPrice: unitPrice,
        discountPercent: discountPercent,
        subtotal: subtotal,
        finalTotal: finalTotal,
        soldAt: DateTime.now(),
        customerId: customerId,
        customerName: customerName,
      ),
    );
    notifyListeners();
    return finalTotal;
  }

  List<SaleRecord> salesBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return _sales
        .where(
          (sale) => !sale.soldAt.isBefore(fromDate) && !sale.soldAt.isAfter(toDate),
        )
        .toList(growable: false);
  }

  SaleRecord? bestSellingProductBetween(DateTime from, DateTime to) {
    final filteredSales = salesBetween(from, to);
    if (filteredSales.isEmpty) {
      return null;
    }

    final totals = <String, SaleRecord>{};
    final amounts = <String, double>{};
    for (final sale in filteredSales) {
      totals.putIfAbsent(sale.productId, () => sale);
      amounts.update(
        sale.productId,
        (current) => current + sale.finalTotal,
        ifAbsent: () => sale.finalTotal,
      );
    }

    String? bestId;
    double bestAmount = -1;
    for (final entry in amounts.entries) {
      if (entry.value > bestAmount) {
        bestId = entry.key;
        bestAmount = entry.value;
      }
    }

    return bestId == null ? null : totals[bestId];
  }

  double totalSalesValueBetween(DateTime from, DateTime to) {
    return salesBetween(from, to).fold<double>(
      0,
      (sum, sale) => sum + sale.finalTotal,
    );
  }

  double totalSoldQuantityBetween(DateTime from, DateTime to) {
    return salesBetween(from, to).fold<double>(
      0,
      (sum, sale) => sum + sale.quantityMm,
    );
  }
}
