import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/customer.dart';
import '../models/sale_record.dart';
import '../state/customer_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/page_header.dart';

class SellProductPage extends StatefulWidget {
  const SellProductPage({
    super.key,
    required this.products,
    required this.customers,
    this.initialProductId,
  });

  static const String routeName = '/sell';

  final ProductCatalogController products;
  final CustomerController customers;
  final String? initialProductId;

  @override
  State<SellProductPage> createState() => _SellProductPageState();
}

class _SellProductPageState extends State<SellProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _finalTotalController = TextEditingController();

  String? _selectedProductId;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    _finalTotalController.dispose();
    super.dispose();
  }

  void _syncDiscountFromCustomer(Customer? customer) {
    _discountController.text = customer == null
        ? '0'
        : customer.discountPercent.toStringAsFixed(
            customer.discountPercent % 1 == 0 ? 0 : 2,
          );
  }

  void _syncProductDefaults() {
    final product = _selectedProductId == null
        ? null
        : widget.products.productById(_selectedProductId!);
    if (product == null) {
      return;
    }

    _unitPriceController.text = product.sellPrice.toStringAsFixed(2);
    _applySuggestedFinalTotal();
  }

  void _applySuggestedFinalTotal() {
    final quantityMm = double.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    final discountPercent = double.tryParse(_discountController.text.trim()) ?? 0;
    final suggestedTotal = (unitPrice * quantityMm) * (1 - (discountPercent / 100));
    _finalTotalController.text = suggestedTotal.toStringAsFixed(2);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) {
      return;
    }

    final customer = _selectedCustomerId == null
        ? null
        : widget.customers.customerById(_selectedCustomerId!);

    try {
      final quantityMm = double.parse(_quantityController.text.trim());
      final unitPrice = double.parse(_unitPriceController.text.trim());
      final discountPercent = double.parse(_discountController.text.trim());
      final subtotal = quantityMm * unitPrice;
      final total = widget.products.sellProduct(
        productId: _selectedProductId!,
        quantityMm: quantityMm,
        unitPrice: unitPrice,
        discountPercent: discountPercent,
        subtotal: subtotal,
        finalTotal: double.parse(_finalTotalController.text.trim()),
        customerId: customer?.customerId,
        customerName: customer?.name,
      );

      final product = widget.products.productById(_selectedProductId!);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Sale saved for ${product?.name ?? 'product'}${customer == null ? '' : ' to ${customer.customerId} - ${customer.name}'}: ${formatCurrency(total)}',
            ),
          ),
        );

      _quantityController.clear();
      _finalTotalController.clear();
      _syncProductDefaults();
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[widget.products, widget.customers]),
      builder: (context, _) {
        final products = widget.products.products;
        final customers = widget.customers.customers;
        final selectedProduct = _selectedProductId == null
            ? null
            : widget.products.productById(_selectedProductId!);

        if (selectedProduct == null && products.isNotEmpty && _selectedProductId == null) {
          _selectedProductId = products.first.id;
          _syncProductDefaults();
        }

        final selectedCustomer = _selectedCustomerId == null
            ? null
            : widget.customers.customerById(_selectedCustomerId!);
        final quantityMm = double.tryParse(_quantityController.text.trim()) ?? 0;
        final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
        final discountPercent = double.tryParse(_discountController.text.trim()) ?? 0;
        final subtotal = unitPrice * quantityMm;
        final suggestedTotal = subtotal * (1 - (discountPercent / 100));
        final finalTotal = double.tryParse(_finalTotalController.text.trim()) ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PageHeader(
                title: 'Sell a product',
                subtitle:
                    'Save full sale data, review every sale, and prepare report-ready records.',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: products.isEmpty
                    ? const _SellEmptyState()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: Card(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    DropdownButtonFormField<String>(
                                      value: widget.products.productById(_selectedProductId ?? '') == null
                                          ? null
                                          : _selectedProductId,
                                      items: products
                                          .map(
                                            (product) => DropdownMenuItem<String>(
                                              value: product.id,
                                              child: Text(product.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedProductId = value;
                                          _syncProductDefaults();
                                        });
                                      },
                                      decoration: const InputDecoration(labelText: 'Product'),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _quantityController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity in ml',
                                      ),
                                      validator: _positiveDoubleValidator,
                                      onChanged: (_) => setState(_applySuggestedFinalTotal),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _unitPriceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Unit price per ml',
                                      ),
                                      validator: _positiveDoubleValidator,
                                      onChanged: (_) => setState(_applySuggestedFinalTotal),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: widget.customers.customerById(_selectedCustomerId ?? '') == null
                                          ? null
                                          : _selectedCustomerId,
                                      items: <DropdownMenuItem<String>>[
                                        const DropdownMenuItem<String>(
                                          value: '',
                                          child: Text('No special customer'),
                                        ),
                                        ...customers.map(
                                          (customer) => DropdownMenuItem<String>(
                                            value: customer.id,
                                            child: Text(
                                              '${customer.customerId} - ${customer.name} (${formatDiscount(customer.discountPercent)})',
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCustomerId =
                                              (value == null || value.isEmpty) ? null : value;
                                          _syncDiscountFromCustomer(
                                            _selectedCustomerId == null
                                                ? null
                                                : widget.customers.customerById(_selectedCustomerId!),
                                          );
                                          _applySuggestedFinalTotal();
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Special customer',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _discountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Discount percent',
                                      ),
                                      validator: _discountValidator,
                                      onChanged: (_) => setState(_applySuggestedFinalTotal),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _finalTotalController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Final price'),
                                      validator: _positiveDoubleValidator,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => setState(_applySuggestedFinalTotal),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Use suggested total'),
                                    ),
                                    const SizedBox(height: 20),
                                    if (selectedProduct != null)
                                      _SalePreview(
                                        productName: selectedProduct.name,
                                        stockLeft: formatMillimeters(selectedProduct.quantityMm),
                                        saleCount: widget.products.saleCount,
                                        unitPrice: formatCurrency(unitPrice),
                                        customerLabel: selectedCustomer == null
                                            ? 'Regular customer'
                                            : '${selectedCustomer.customerId} - ${selectedCustomer.name}',
                                        subtotal: formatCurrency(subtotal),
                                        discount: formatDiscount(discountPercent),
                                        suggestedTotal: formatCurrency(suggestedTotal),
                                        finalTotal: formatCurrency(finalTotal),
                                      ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _submit,
                                        icon: const Icon(Icons.point_of_sale),
                                        label: const Text('Confirm sale'),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _SalesHistorySection(sales: widget.products.sales),
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
      },
    );
  }
}

class _SalePreview extends StatelessWidget {
  const _SalePreview({
    required this.productName,
    required this.stockLeft,
    required this.saleCount,
    required this.unitPrice,
    required this.customerLabel,
    required this.subtotal,
    required this.discount,
    required this.suggestedTotal,
    required this.finalTotal,
  });

  final String productName;
  final String stockLeft;
  final int saleCount;
  final String unitPrice;
  final String customerLabel;
  final String subtotal;
  final String discount;
  final String suggestedTotal;
  final String finalTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5DCCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(productName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Current stock: $stockLeft'),
          Text('Saved sales: $saleCount'),
          Text('Unit price per mm: $unitPrice'),
          Text('Customer: $customerLabel'),
          Text('Subtotal: $subtotal'),
          Text('Discount: $discount'),
          Text('Suggested total: $suggestedTotal'),
          const SizedBox(height: 8),
          Text(
            'Final total: $finalTotal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SalesHistorySection extends StatelessWidget {
  const _SalesHistorySection({required this.sales});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Sales history',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          const Text('No sales saved yet.')
        else
          Column(
            children: sales
                .take(12)
                .map((sale) => _SaleHistoryTile(sale: sale))
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _SaleHistoryTile extends StatelessWidget {
  const _SaleHistoryTile({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    final customerText = sale.customerName == null
        ? 'Regular customer'
        : '${sale.customerId == null ? '' : '${sale.customerId} - '}${sale.customerName!}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DCCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sale.productName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text('Date: ${formatDateTime(sale.soldAt)}'),
          Text('Customer: $customerText'),
          Text('Quantity: ${formatMillimeters(sale.quantityMm)}'),
          Text('Unit price: ${formatCurrency(sale.unitPrice)}'),
          Text('Discount: ${formatDiscount(sale.discountPercent)}'),
          Text('Subtotal: ${formatCurrency(sale.subtotal)}'),
          Text(
            'Final total: ${formatCurrency(sale.finalTotal)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SellEmptyState extends StatelessWidget {
  const _SellEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Add at least one product before recording a sale.'),
    );
  }
}

String? _positiveDoubleValidator(String? value) {
  final parsed = double.tryParse((value ?? '').trim());
  if (parsed == null || parsed <= 0) {
    return 'Enter a number greater than zero.';
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
