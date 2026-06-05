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

    if (result == null) return;

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
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
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
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: Translator.translate('search_hint'),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: !hasCustomers
                    ? _EmptyState(
                        icon: Icons.people_outline,
                        title: Translator.translate('no_special_customers_yet'),
                        description: '',
                      )
                    : customers.isEmpty
                    ? _EmptyState(
                        icon: Icons.search_off,
                        title: Translator.translate('no_customers_found'),
                        description: Translator.translate('no_customers_found_description'),
                      )
                    : ListView.separated(
                        itemCount: customers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _CustomerTile(
                            customer: customer,
                            onEdit: () => _openEditor(customer),
                            onDelete: () => _deleteCustomer(customer),
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

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initial = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF18534F), Color(0xFF2A7A6F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${customer.customerId}  •  ${customer.name}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173531),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _InfoChip(
                        icon: Icons.phone_outlined,
                        label: customer.phone,
                        color: const Color(0xFF3D6B8C),
                        background: const Color(0xFFE3EEF5),
                      ),
                      _InfoChip(
                        icon: Icons.local_offer_outlined,
                        label: formatDiscount(customer.discountPercent),
                        color: const Color(0xFF8A5A24),
                        background: const Color(0xFFF5EDE0),
                      ),
                    ],
                  ),
                  if (customer.notes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      customer.notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5B635E),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: <Widget>[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: Translator.translate('edit'),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF18534F),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: Translator.translate('delete'),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFE8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF18534F)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF173531),
                  ),
            ),
            if (description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5A625D),
                    ),
              ),
            ],
          ],
        ),
      ),
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
    if (!_formKey.currentState!.validate()) return;

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
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width > 500
              ? 460
              : MediaQuery.sizeOf(context).width * 0.85,
        ),
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
