import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/customer.dart';
import '../models/customer_draft.dart';

class CustomerController extends ChangeNotifier {
  final List<Customer> _customers = <Customer>[];
  final Map<String, Customer> _customerIndex = <String, Customer>{};

  UnmodifiableListView<Customer> get customers =>
      UnmodifiableListView(_customers);

  int get customerCount => _customers.length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'customers': _customers.map((customer) => customer.toJson()).toList(),
    };
  }

  ({int added, int duplicates}) mergeFromJson(Map<String, dynamic>? json) {
    final existingIds = {for (final c in _customers) c.id};

    final incoming = ((json?['customers'] as List<dynamic>?) ?? <dynamic>[])
        .map((item) => Customer.fromJson(item as Map<String, dynamic>))
        .toList();

    int added = 0, duplicates = 0;
    for (final customer in incoming) {
      if (existingIds.contains(customer.id)) {
        duplicates++;
      } else {
        _customers.add(customer);
        _customerIndex[customer.id] = customer;
        added++;
      }
    }

    if (added > 0) notifyListeners();
    return (added: added, duplicates: duplicates);
  }

  void restoreFromJson(Map<String, dynamic>? json) {
    _customers
      ..clear()
      ..addAll(
        ((json?['customers'] as List<dynamic>?) ?? <dynamic>[]).map(
          (item) => Customer.fromJson(item as Map<String, dynamic>),
        ),
      );
    _customerIndex
      ..clear()
      ..addEntries(_customers.map((c) => MapEntry(c.id, c)));
    notifyListeners();
  }

  Customer addCustomer(CustomerDraft draft) {
    final customer = Customer(
      id: IdGenerator.customer(),
      customerId: draft.customerId,
      name: draft.name,
      phone: draft.phone,
      discountPercent: draft.discountPercent,
      notes: draft.notes,
    );

    _customers.insert(0, customer);
    _customerIndex[customer.id] = customer;
    notifyListeners();
    return customer;
  }

  void updateCustomer(String customerId, CustomerDraft draft) {
    final index = _customers.indexWhere((customer) => customer.id == customerId);
    if (index == -1) return;

    final updated = _customers[index].copyWith(
      customerId: draft.customerId,
      name: draft.name,
      phone: draft.phone,
      discountPercent: draft.discountPercent,
      notes: draft.notes,
    );
    _customers[index] = updated;
    _customerIndex[customerId] = updated;
    notifyListeners();
  }

  void deleteCustomer(String customerId) {
    _customers.removeWhere((customer) => customer.id == customerId);
    _customerIndex.remove(customerId);
    notifyListeners();
  }

  Customer? customerById(String id) => _customerIndex[id];

  List<Customer> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return List.unmodifiable(_customers);
    return _customers
        .where((customer) => customer.matches(normalizedQuery))
        .toList(growable: false);
  }
}
