import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/product.dart';
import '../models/product_draft.dart';
import '../models/sale_record.dart';

class ProductCatalogController extends ChangeNotifier {
  final List<Product> _products = <Product>[];
  final List<SaleRecord> _sales = <SaleRecord>[];

  // HashMap index for O(1) lookups instead of O(n) linear scan.
  final Map<String, Product> _productIndex = <String, Product>{};

  // Running totals maintained incrementally — no fold() on every access.
  double _totalPurchaseValue = 0;
  double _totalPurchasedQuantityMm = 0;
  double _totalSalesValue = 0;
  double _totalSoldQuantityMm = 0;
  double _totalQuantityMm = 0;

  UnmodifiableListView<Product> get products => UnmodifiableListView(_products);
  UnmodifiableListView<SaleRecord> get sales => UnmodifiableListView(_sales);

  int get productCount => _products.length;
  int get saleCount => _sales.length;
  double get totalPurchaseValue => _totalPurchaseValue;
  double get totalPurchasedQuantityMm => _totalPurchasedQuantityMm;
  double get totalSalesValue => _totalSalesValue;
  double get totalSoldQuantityMm => _totalSoldQuantityMm;
  double get totalQuantityMm => _totalQuantityMm;
  double get netRevenue => _totalSalesValue - _totalPurchaseValue;

  // stockValue depends on per-product ratios; computed on demand (products list is short).
  double get totalInventoryValue =>
      _products.fold<double>(0, (sum, p) => sum + p.stockValue);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'products': _products.map((p) => p.toJson()).toList(),
      'sales': _sales.map((s) => s.toJson()).toList(),
      'totalPurchaseValue': _totalPurchaseValue,
      'totalPurchasedQuantityMm': _totalPurchasedQuantityMm,
    };
  }

  ({
    int productsAdded,
    int productsDuplicate,
    int salesAdded,
    int salesDuplicate,
  }) mergeFromJson(Map<String, dynamic>? json) {
    final existingProductIds = {for (final p in _products) p.id};
    final existingSaleIds = {for (final s in _sales) s.id};

    final incomingProducts =
        ((json?['products'] as List<dynamic>?) ?? <dynamic>[])
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();

    final incomingSales = ((json?['sales'] as List<dynamic>?) ?? <dynamic>[])
        .map((item) => SaleRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    int productsAdded = 0,
        productsDuplicate = 0,
        salesAdded = 0,
        salesDuplicate = 0;

    for (final product in incomingProducts) {
      if (existingProductIds.contains(product.id)) {
        productsDuplicate++;
      } else {
        _products.add(product);
        _productIndex[product.id] = product;
        _totalPurchaseValue += product.purchasePrice;
        _totalPurchasedQuantityMm += product.initialQuantityMm;
        _totalQuantityMm += product.quantityMm;
        productsAdded++;
      }
    }

    for (final sale in incomingSales) {
      if (existingSaleIds.contains(sale.id)) {
        salesDuplicate++;
      } else {
        _sales.add(sale);
        _totalSalesValue += sale.finalTotal;
        _totalSoldQuantityMm += sale.quantityMm;
        salesAdded++;
      }
    }

    if (productsAdded > 0 || salesAdded > 0) notifyListeners();

    return (
      productsAdded: productsAdded,
      productsDuplicate: productsDuplicate,
      salesAdded: salesAdded,
      salesDuplicate: salesDuplicate,
    );
  }

  void restoreFromJson(Map<String, dynamic>? json) {
    _products
      ..clear()
      ..addAll(
        ((json?['products'] as List<dynamic>?) ?? <dynamic>[])
            .map((item) => Product.fromJson(item as Map<String, dynamic>)),
      );
    _sales
      ..clear()
      ..addAll(
        ((json?['sales'] as List<dynamic>?) ?? <dynamic>[])
            .map((item) => SaleRecord.fromJson(item as Map<String, dynamic>)),
      );
    _totalPurchaseValue =
        ((json?['totalPurchaseValue'] as num?) ?? 0).toDouble();
    _totalPurchasedQuantityMm =
        ((json?['totalPurchasedQuantityMm'] as num?) ?? 0).toDouble();

    // Rebuild index and running totals from scratch.
    _productIndex
      ..clear()
      ..addEntries(_products.map((p) => MapEntry(p.id, p)));
    _totalSalesValue =
        _sales.fold<double>(0, (sum, s) => sum + s.finalTotal);
    _totalSoldQuantityMm =
        _sales.fold<double>(0, (sum, s) => sum + s.quantityMm);
    _totalQuantityMm =
        _products.fold<double>(0, (sum, p) => sum + p.quantityMm);

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
    _productIndex[product.id] = product;
    _totalPurchaseValue += product.purchasePrice;
    _totalPurchasedQuantityMm += product.quantityMm;
    _totalQuantityMm += product.quantityMm;
    notifyListeners();
    return product;
  }

  void removeProduct(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) throw ArgumentError('Product not found.');
    final product = _products.removeAt(index);
    _productIndex.remove(id);
    _totalPurchaseValue -= product.purchasePrice;
    _totalPurchasedQuantityMm -= product.initialQuantityMm;
    _totalQuantityMm -= product.quantityMm;
    notifyListeners();
  }

  void updateProduct(String id, ProductDraft draft) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) throw ArgumentError('Product not found.');
    final old = _products[index];
    final updated = old.copyWith(
      name: draft.name,
      purchasePrice: draft.purchasePrice,
      sellPrice: draft.sellPrice,
      quantityMm: draft.quantityMm,
      initialQuantityMm: draft.quantityMm,
    );
    _products[index] = updated;
    _productIndex[id] = updated;
    _totalPurchaseValue += draft.purchasePrice - old.purchasePrice;
    _totalPurchasedQuantityMm += draft.quantityMm - old.initialQuantityMm;
    _totalQuantityMm += draft.quantityMm - old.quantityMm;
    notifyListeners();
  }

  Product? productById(String id) => _productIndex[id];

  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_products);
    return _products
        .where((p) => p.matches(q))
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
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) throw ArgumentError('Product not found.');

    final current = _products[index];
    if (quantityMm <= 0) throw ArgumentError('Quantity must be greater than zero.');
    if (quantityMm > current.quantityMm) throw ArgumentError('Not enough quantity in stock.');
    if (finalTotal <= 0) throw ArgumentError('Final price must be greater than zero.');

    final updated = current.copyWith(quantityMm: current.quantityMm - quantityMm);
    _products[index] = updated;
    _productIndex[productId] = updated;
    _totalQuantityMm -= quantityMm;

    final sale = SaleRecord(
      id: IdGenerator.sale(),
      productId: current.id,
      productName: current.name,
      quantityMm: quantityMm,
      unitPrice: unitPrice,
      discountPercent: discountPercent,
      subtotal: subtotal,
      finalTotal: finalTotal,
      soldAt: DateTime.now(),
      customerId: customerId,
      customerName: customerName,
    );
    _sales.insert(0, sale);
    _totalSalesValue += finalTotal;
    _totalSoldQuantityMm += quantityMm;

    notifyListeners();
    return finalTotal;
  }

  List<SaleRecord> salesBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return _sales
        .where((s) => !s.soldAt.isBefore(fromDate) && !s.soldAt.isAfter(toDate))
        .toList(growable: false);
  }

  SaleRecord? bestSellingProductBetween(DateTime from, DateTime to) {
    final filtered = salesBetween(from, to);
    if (filtered.isEmpty) return null;

    final totals = <String, SaleRecord>{};
    final amounts = <String, double>{};
    for (final sale in filtered) {
      totals.putIfAbsent(sale.productId, () => sale);
      amounts.update(
        sale.productId,
        (v) => v + sale.finalTotal,
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

  double totalSalesValueBetween(DateTime from, DateTime to) =>
      salesBetween(from, to)
          .fold<double>(0, (sum, s) => sum + s.finalTotal);

  double totalSoldQuantityBetween(DateTime from, DateTime to) =>
      salesBetween(from, to)
          .fold<double>(0, (sum, s) => sum + s.quantityMm);

  List<ProductSaleSummary> topSellingProductsBetween(DateTime from, DateTime to) {
    final filtered = salesBetween(from, to);
    final Map<String, ProductSaleSummary> map = {};

    for (final sale in filtered) {
      final existing = map[sale.productId];
      if (existing != null) {
        map[sale.productId] = (
          productId: existing.productId,
          productName: existing.productName,
          totalRevenue: existing.totalRevenue + sale.finalTotal,
          totalQuantityMm: existing.totalQuantityMm + sale.quantityMm,
          salesCount: existing.salesCount + 1,
        );
      } else {
        map[sale.productId] = (
          productId: sale.productId,
          productName: sale.productName,
          totalRevenue: sale.finalTotal,
          totalQuantityMm: sale.quantityMm,
          salesCount: 1,
        );
      }
    }

    return map.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }
}

typedef ProductSaleSummary = ({
  String productId,
  String productName,
  double totalRevenue,
  double totalQuantityMm,
  int salesCount,
});
