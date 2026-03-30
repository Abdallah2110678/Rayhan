import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/id_generator.dart';
import '../models/customer.dart';
import '../models/customer_draft.dart';

class CustomerController extends ChangeNotifier {
  final List<Customer> _customers = <Customer>[];

  UnmodifiableListView<Customer> get customers =>
      UnmodifiableListView(_customers);

  int get customerCount => _customers.length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'customers': _customers.map((customer) => customer.toJson()).toList(),
    };
  }

  void restoreFromJson(Map<String, dynamic>? json) {
    _customers
      ..clear()
      ..addAll(
        ((json?['customers'] as List<dynamic>?) ?? <dynamic>[]).map(
          (item) => Customer.fromJson(item as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Customer addCustomer(CustomerDraft draft) {
    final customer = Customer(
      id: IdGenerator.product(),
      customerId: draft.customerId,
      name: draft.name,
      phone: draft.phone,
      discountPercent: draft.discountPercent,
      notes: draft.notes,
    );

    _customers.insert(0, customer);
    notifyListeners();
    return customer;
  }

  void updateCustomer(String customerId, CustomerDraft draft) {
    final index = _customers.indexWhere((customer) => customer.id == customerId);
    if (index == -1) {
      return;
    }

    _customers[index] = _customers[index].copyWith(
      customerId: draft.customerId,
      name: draft.name,
      phone: draft.phone,
      discountPercent: draft.discountPercent,
      notes: draft.notes,
    );
    notifyListeners();
  }

  void deleteCustomer(String customerId) {
    _customers.removeWhere((customer) => customer.id == customerId);
    notifyListeners();
  }

  Customer? customerById(String id) {
    for (final customer in _customers) {
      if (customer.id == id) {
        return customer;
      }
    }
    return null;
  }

  List<Customer> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    return _customers
        .where((customer) => customer.matches(normalizedQuery))
        .toList(growable: false);
  }
}
