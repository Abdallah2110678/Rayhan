import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/customer.dart';
import '../models/customer_draft.dart';
import '../state/customer_controller.dart';
import '../widgets/page_header.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key, required this.customers});

  final CustomerController customers;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor([Customer? customer]) async {
    final result = await showDialog<CustomerDraft>(
      context: context,
      builder: (context) => _CustomerEditor(customer: customer),
    );

    if (result == null) {
      return;
    }

    if (customer == null) {
      widget.customers.addCustomer(result);
    } else {
      widget.customers.updateCustomer(customer.id, result);
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text('Delete ${customer.name} from special customers?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      widget.customers.deleteCustomer(customer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.customers,
      builder: (context, _) {
        final customers = widget.customers.search(_query);
        final hasCustomers = widget.customers.customers.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(
                title: 'Special customers',
                subtitle:
                    'CRUD page for customers with a customer ID and custom discount used during sales.',
                trailing: FilledButton.icon(
                  onPressed: _openEditor,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add customer'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search customers by ID, name, phone, or notes',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: !hasCustomers
                    ? const Center(child: Text('No special customers yet.'))
                    : ListView.separated(
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(18),
                              title: Text('${customer.customerId} - ${customer.name}'),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('Phone: ${customer.phone}'),
                                    Text(
                                      'Discount: ${formatDiscount(customer.discountPercent)}',
                                    ),
                                    if (customer.notes.isNotEmpty) Text(customer.notes),
                                  ],
                                ),
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: <Widget>[
                                  IconButton(
                                    onPressed: () => _openEditor(customer),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteCustomer(customer),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerEditor extends StatefulWidget {
  const _CustomerEditor({this.customer});

  final Customer? customer;

  @override
  State<_CustomerEditor> createState() => _CustomerEditorState();
}

class _CustomerEditorState extends State<_CustomerEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _discountController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _customerIdController = TextEditingController(
      text: widget.customer?.customerId ?? '',
    );
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _discountController = TextEditingController(
      text: widget.customer?.discountPercent.toString() ?? '0',
    );
    _notesController = TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      CustomerDraft(
        customerId: _customerIdController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        discountPercent: double.parse(_discountController.text.trim()),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add customer' : 'Edit customer'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _customerIdController,
                  decoration: const InputDecoration(labelText: 'Customer ID'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Discount percent'),
                  validator: _discountValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

String? _discountValidator(String? value) {
  final parsed = double.tryParse((value ?? '').trim());
  if (parsed == null || parsed < 0 || parsed > 100) {
    return 'Enter a discount from 0 to 100.';
  }
  return null;
}
