import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/packaging_item.dart';

class PackagingController extends ChangeNotifier {
  final List<PackagingItem> _items = <PackagingItem>[];
  final Map<String, PackagingItem> _index = <String, PackagingItem>{};

  UnmodifiableListView<PackagingItem> get items => UnmodifiableListView(_items);
  int get itemCount => _items.length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': _items.map((i) => i.toJson()).toList(),
    };
  }

  void restoreFromJson(Map<String, dynamic>? json) {
    _items
      ..clear()
      ..addAll(
        ((json?['items'] as List<dynamic>?) ?? <dynamic>[])
            .map((e) => PackagingItem.fromJson(e as Map<String, dynamic>)),
      );
    _index
      ..clear()
      ..addEntries(_items.map((i) => MapEntry(i.id, i)));
    notifyListeners();
  }

  PackagingItem addItem(
    double sizeMl,
    int quantity, {
    PackagingType type = PackagingType.bottle,
  }) {
    final item = PackagingItem(
      id: IdGenerator.packaging(),
      sizeMl: sizeMl,
      quantity: quantity,
      createdAt: DateTime.now(),
      type: type,
    );
    _items.insert(0, item);
    _index[item.id] = item;
    notifyListeners();
    return item;
  }

  void updateItem(String id, {double? sizeMl, int? quantity, PackagingType? type}) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final updated = _items[index].copyWith(
      sizeMl: sizeMl,
      quantity: quantity,
      type: type,
    );
    _items[index] = updated;
    _index[id] = updated;
    notifyListeners();
  }

  void removeItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    _items.removeAt(index);
    _index.remove(id);
    notifyListeners();
  }

  /// Finds a bottle matching [sizeMl] and decrements its quantity by 1.
  /// Returns true if a bottle was found and deducted, false otherwise.
  bool deductBottle(double sizeMl) {
    final index = _items.indexWhere(
      (i) =>
          i.type == PackagingType.bottle &&
          (i.sizeMl - sizeMl).abs() < 0.001 &&
          i.quantity > 0,
    );
    if (index == -1) return false;
    final item = _items[index];
    final updated = item.copyWith(quantity: item.quantity - 1);
    _items[index] = updated;
    _index[item.id] = updated;
    notifyListeners();
    return true;
  }

  /// Returns the bottle matching [sizeMl], or null if none exists.
  PackagingItem? bottleBySize(double sizeMl) {
    try {
      return _items.firstWhere(
        (i) => i.type == PackagingType.bottle && (i.sizeMl - sizeMl).abs() < 0.001,
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds a box (علبه) matching [sizeMl] and decrements its quantity by 1.
  /// Returns true if a box was found and deducted, false otherwise.
  bool deductBox(double sizeMl) {
    final index = _items.indexWhere(
      (i) =>
          i.type == PackagingType.box &&
          (i.sizeMl - sizeMl).abs() < 0.001 &&
          i.quantity > 0,
    );
    if (index == -1) return false;
    final item = _items[index];
    final updated = item.copyWith(quantity: item.quantity - 1);
    _items[index] = updated;
    _index[item.id] = updated;
    notifyListeners();
    return true;
  }

  /// Returns the box (علبه) matching [sizeMl], or null if none exists.
  PackagingItem? boxBySize(double sizeMl) {
    try {
      return _items.firstWhere(
        (i) => i.type == PackagingType.box && (i.sizeMl - sizeMl).abs() < 0.001,
      );
    } catch (_) {
      return null;
    }
  }
}
