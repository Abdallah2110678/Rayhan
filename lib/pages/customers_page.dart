import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
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
        title: Text(Translator.translate('delete_customer')),
        content: Text(
          Translator.translate('delete_customer_confirmation', {
            'name': customer.name,
          }),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Translator.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Translator.translate('delete')),
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
                title: Translator.translate('special_customers'),
                subtitle: Translator.translate('customers_subtitle'),
                trailing: FilledButton.icon(
                  onPressed: _openEditor,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(Translator.translate('add_customer')),
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: Translator.translate('search_hint'),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: !hasCustomers
                    ? Center(
                        child: Text(
                          Translator.translate('no_special_customers_yet'),
                        ),
                      )
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
      title: Text(
        widget.customer == null
            ? Translator.translate('add_customer_dialog_title')
            : Translator.translate('edit_customer'),
      ),
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
                  decoration: InputDecoration(
                    labelText: Translator.translate('customer_id'),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: Translator.translate('name_label'),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: Translator.translate('phone_label'),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: Translator.translate('discount_percent_label'),
                  ),
                  validator: _discountValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: Translator.translate('notes_label'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Translator.translate('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(Translator.translate('save')),
        ),
      ],
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return Translator.translate('field_required');
  }
  return null;
}

String? _discountValidator(String? value) {
  final parsed = double.tryParse((value ?? '').trim());
  if (parsed == null || parsed < 0 || parsed > 100) {
    return Translator.translate('discount_range_error');
  }
  return null;
}
