import 'package:flutter/material.dart';

import '../models/product_draft.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/page_header.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, required this.catalog});

  final ProductCatalogController catalog;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = widget.catalog.addProduct(
      ProductDraft(
        name: _nameController.text.trim(),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        sellPrice: double.parse(_sellPriceController.text.trim()),
        quantityMm: double.parse(_quantityController.text.trim()),
      ),
    );

    _formKey.currentState!.reset();
    _nameController.clear();
    _purchasePriceController.clear();
    _sellPriceController.clear();
    _quantityController.clear();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${product.name} created.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PageHeader(
            title: 'Add a product',
            subtitle:
                'Write the total buy amount for the whole quantity, not a price per mm.',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Product information',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF173531),
                                ),
                          ),
                          const SizedBox(height: 24),
                          _FormLabel(label: 'Name'),
                          TextFormField(
                            controller: _nameController,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const _FormLabel(label: 'Bought for total amount'),
                                    TextFormField(
                                      controller: _purchasePriceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      validator: _positiveDoubleValidator,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const _FormLabel(label: 'Sell price per mm'),
                                    TextFormField(
                                      controller: _sellPriceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      validator: _positiveDoubleValidator,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FormLabel(label: 'Quantity in mm'),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _positiveDoubleValidator,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Save product'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF31413C),
            ),
      ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

String? _positiveDoubleValidator(String? value) {
  final parsed = double.tryParse((value ?? '').trim());
  if (parsed == null || parsed <= 0) {
    return 'Enter a number greater than 0.';
  }
  return null;
}
