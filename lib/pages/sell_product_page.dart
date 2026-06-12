import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../models/customer.dart';
import '../models/sale_record.dart';
import '../state/customer_controller.dart';
import '../state/packaging_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/collapsing_header_page.dart';
import '../widgets/page_header.dart';

class SellProductPage extends StatefulWidget {
  const SellProductPage({
    super.key,
    required this.products,
    required this.customers,
    required this.packaging,
    this.initialProductId,
  });

  static const String routeName = '/sell';

  final ProductCatalogController products;
  final CustomerController customers;
  final PackagingController packaging;
  final String? initialProductId;

  @override
  State<SellProductPage> createState() => _SellProductPageState();
}

class _SellProductPageState extends State<SellProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  final List<_SaleRow> _saleRows = <_SaleRow>[];

  @override
  void initState() {
    super.initState();
    _saleRows.add(_createSaleRow(widget.initialProductId));
    _syncSaleRowDefaults(_saleRows.first);
  }

  @override
  void dispose() {
    for (final row in _saleRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _syncDiscountFromCustomer(Customer? customer) {
    final text = customer == null
        ? '0'
        : customer.discountPercent.toStringAsFixed(
            customer.discountPercent % 1 == 0 ? 0 : 2,
          );
    for (final row in _saleRows) {
      row.discountController.text = text;
      _applySuggestedFinalTotalForRow(row);
    }
  }

  void _applySuggestedFinalTotalForAllRows() {
    setState(() {
      for (final row in _saleRows) {
        _applySuggestedFinalTotalForRow(row);
      }
    });
  }

  _SaleRow _createSaleRow(String? productId) {
    return _SaleRow(
      selectedProductId: productId,
      quantityController: TextEditingController(),
      unitPriceController: TextEditingController(),
      discountController: TextEditingController(text: '0'),
      subtotalController: TextEditingController(),
      finalTotalController: TextEditingController(),
    );
  }

  void _syncSaleRowDefaults(_SaleRow row) {
    final product = row.selectedProductId == null
        ? null
        : widget.products.productById(row.selectedProductId!);
    if (product == null) return;
    row.unitPriceController.text = product.sellPrice.toStringAsFixed(2);
    _applySuggestedFinalTotalForRow(row);
  }

  void _applySuggestedFinalTotalForRow(_SaleRow row) {
    final quantityMm = double.tryParse(row.quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(row.unitPriceController.text.trim()) ?? 0;
    final discountPercent =
        double.tryParse(row.discountController.text.trim()) ?? 0;
    final subtotal = unitPrice * quantityMm;
    row.subtotalController.text = subtotal.toStringAsFixed(2);
    row.finalTotalController.text =
        (subtotal * (1 - discountPercent / 100)).toStringAsFixed(2);
  }

  void _applyFinalFromSubtotal(_SaleRow row) {
    final subtotal =
        double.tryParse(row.subtotalController.text.trim()) ?? 0;
    final discountPercent =
        double.tryParse(row.discountController.text.trim()) ?? 0;
    row.finalTotalController.text =
        (subtotal * (1 - discountPercent / 100)).toStringAsFixed(2);
  }

  void _addSaleRow() {
    setState(() {
      final defaultProductId = widget.products.products.isNotEmpty
          ? widget.products.products.first.id
          : null;
      final row = _createSaleRow(defaultProductId);
      _saleRows.add(row);
      _syncSaleRowDefaults(row);
    });
  }

  void _removeSaleRow(int index) {
    if (_saleRows.length <= 1) return;
    setState(() {
      _saleRows[index].dispose();
      _saleRows.removeAt(index);
    });
  }

  double get _totalOrderValue {
    return _saleRows.fold<double>(
      0,
      (sum, row) =>
          sum + (double.tryParse(row.finalTotalController.text.trim()) ?? 0),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Pre-check: ensure every row has a bottle in stock before committing anything.
    for (final row in _saleRows) {
      final productId = row.selectedProductId;
      if (productId == null) continue;
      final quantityMm = double.tryParse(row.quantityController.text.trim()) ?? 0;
      final bottle = widget.packaging.bottleBySize(quantityMm);
      if (bottle == null || bottle.quantity <= 0) {
        final sizeLabel = quantityMm % 1 == 0
            ? quantityMm.toInt().toString()
            : quantityMm.toString();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                Translator.translate('no_matching_bottle', {'size': sizeLabel}),
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        return;
      }
    }

    final customer = _selectedCustomerId == null
        ? null
        : widget.customers.customerById(_selectedCustomerId!);

    try {
      double totalSale = 0;
      final List<String> bottleMessages = <String>[];

      for (final row in _saleRows) {
        final productId = row.selectedProductId;
        if (productId == null) continue;

        final quantityMm = double.parse(row.quantityController.text.trim());
        final unitPrice = double.parse(row.unitPriceController.text.trim());
        final discountPercent =
            double.parse(row.discountController.text.trim());
        final subtotal = quantityMm * unitPrice;
        final total = widget.products.sellProduct(
          productId: productId,
          quantityMm: quantityMm,
          unitPrice: unitPrice,
          discountPercent: discountPercent,
          subtotal: subtotal,
          finalTotal: double.parse(row.finalTotalController.text.trim()),
          customerId: customer?.customerId,
          customerName: customer?.name,
        );
        totalSale += total;

        final sizeLabel = quantityMm % 1 == 0
            ? quantityMm.toInt().toString()
            : quantityMm.toString();

        final deducted = widget.packaging.deductBottle(quantityMm);
        if (!deducted) {
          bottleMessages.add(
            Translator.translate('no_matching_bottle', {'size': sizeLabel}),
          );
        } else {
          final bottle = widget.packaging.bottleBySize(quantityMm);
          if (bottle != null && bottle.quantity <= 5) {
            bottleMessages.add(
              Translator.translate('low_bottle_stock', {
                'size': sizeLabel,
                'count': '${bottle.quantity}',
              }),
            );
          }
        }

        final boxDeducted = widget.packaging.deductBox(quantityMm);
        if (!boxDeducted) {
          bottleMessages.add(
            Translator.translate('no_matching_box', {'size': sizeLabel}),
          );
        } else {
          final box = widget.packaging.boxBySize(quantityMm);
          if (box != null && box.quantity <= 5) {
            bottleMessages.add(
              Translator.translate('low_box_stock', {
                'size': sizeLabel,
                'count': '${box.quantity}',
              }),
            );
          }
        }
      }

      final productNames = _saleRows
          .map(
            (row) =>
                widget.products.productById(row.selectedProductId ?? '')?.name,
          )
          .whereType<String>()
          .join(', ');

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              Translator.translate('sale_saved', {
                'product':
                    productNames.isEmpty ? Translator.translate('product') : productNames,
                'customer': customer == null
                    ? ''
                    : ' ${Translator.translate('customer')}: ${customer.customerId} - ${customer.name}',
                'total': formatCurrency(totalSale),
              }),
            ),
          ),
        );

      if (bottleMessages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (!mounted) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(bottleMessages.join('\n'))),
            );
        });
      }

      setState(() {
        for (final row in _saleRows) {
          row.dispose();
        }
        _saleRows.clear();
        _saleRows.add(_createSaleRow(widget.initialProductId));
        _syncSaleRowDefaults(_saleRows.first);
      });
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge(<Listenable>[widget.products, widget.customers]),
      builder: (context, _) {
        final products = widget.products.products;
        final customers = widget.customers.customers;

        if (_saleRows.isEmpty) {
          _saleRows.add(_createSaleRow(widget.initialProductId));
        }

        final firstRow = _saleRows.first;
        if ((firstRow.selectedProductId == null ||
                widget.products.productById(firstRow.selectedProductId!) ==
                    null) &&
            products.isNotEmpty) {
          firstRow.selectedProductId = products.first.id;
          _syncSaleRowDefaults(firstRow);
        }

        final selectedCustomer = _selectedCustomerId == null
            ? null
            : widget.customers.customerById(_selectedCustomerId!);

        return CollapsingHeaderPage(
          header: PageHeader(
            title: Translator.translate('sell_a_product'),
            subtitle: Translator.translate('sell_product_subtitle'),
          ),
          child: products.isEmpty
              ? _SellEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ...List<Widget>.generate(_saleRows.length, (index) {
                              final row = _saleRows[index];
                              return _ProductRowCard(
                                index: index,
                                row: row,
                                products: products,
                                canRemove: _saleRows.length > 1,
                                onRemove: () => _removeSaleRow(index),
                                onProductChanged: (value) {
                                  setState(() {
                                    row.selectedProductId = value;
                                    _syncSaleRowDefaults(row);
                                  });
                                },
                                onFieldChanged: () => setState(
                                    () => _applySuggestedFinalTotalForRow(row)),
                                onSubtotalOrDiscountChanged: () => setState(
                                    () => _applyFinalFromSubtotal(row)),
                                onFinalChanged: () => setState(() {}),
                              );
                            }),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                onPressed: _addSaleRow,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                label:
                                    Text(Translator.translate('add_product')),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _CustomerAndSummaryCard(
                              customers: customers,
                              selectedCustomerId: _selectedCustomerId,
                              selectedCustomer: selectedCustomer,
                              rowCount: _saleRows.length,
                              totalOrderValue: _totalOrderValue,
                              onCustomerChanged: (value) {
                                setState(() {
                                  _selectedCustomerId =
                                      (value == null || value.isEmpty)
                                          ? null
                                          : value;
                                  _syncDiscountFromCustomer(
                                    _selectedCustomerId == null
                                        ? null
                                        : widget.customers
                                            .customerById(_selectedCustomerId!),
                                  );
                                });
                              },
                              onUseSuggested:
                                  _applySuggestedFinalTotalForAllRows,
                              onSubmit: _submit,
                            ),
                            const SizedBox(height: 28),
                            _SalesHistorySection(sales: widget.products.sales),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _ProductRowCard extends StatelessWidget {
  const _ProductRowCard({
    required this.index,
    required this.row,
    required this.products,
    required this.canRemove,
    required this.onRemove,
    required this.onProductChanged,
    required this.onFieldChanged,
    required this.onSubtotalOrDiscountChanged,
    required this.onFinalChanged,
  });

  final int index;
  final _SaleRow row;
  final List<dynamic> products;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String?> onProductChanged;
  // qty / price changes → recompute subtotal + final
  final VoidCallback onFieldChanged;
  // subtotal or discount changes → recompute final from subtotal
  final VoidCallback onSubtotalOrDiscountChanged;
  // final price edited by user → just refresh order summary
  final VoidCallback onFinalChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F2E9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18534F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${Translator.translate('product')} ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF173531),
                      ),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red.shade400,
                    visualDensity: VisualDensity.compact,
                    tooltip: Translator.translate('remove'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ProductSearchField(
                  selectedProductId: row.selectedProductId,
                  products: products,
                  onChanged: onProductChanged,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useRow = constraints.maxWidth >= 400;
                    final qtyField = TextFormField(
                      controller: row.quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: Translator.translate('quantity_in_mm'),
                        suffixText: 'ml',
                      ),
                      validator: _positiveDoubleValidator,
                      onChanged: (_) => onFieldChanged(),
                    );
                    final priceField = TextFormField(
                      controller: row.unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: Translator.translate('unit_price_per_mm'),
                      ),
                      validator: _positiveDoubleValidator,
                      onChanged: (_) => onFieldChanged(),
                    );
                    return useRow
                        ? Row(
                            children: <Widget>[
                              Expanded(child: qtyField),
                              const SizedBox(width: 12),
                              Expanded(child: priceField),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              qtyField,
                              const SizedBox(height: 12),
                              priceField,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useRow = constraints.maxWidth >= 400;
                    final subtotalField = TextFormField(
                      controller: row.subtotalController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: Translator.translate('subtotal'),
                      ),
                      validator: _positiveDoubleValidator,
                      onChanged: (_) => onSubtotalOrDiscountChanged(),
                    );
                    final discountField = TextFormField(
                      controller: row.discountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: Translator.translate('discount_percent'),
                        suffixText: '%',
                      ),
                      validator: _discountValidator,
                      onChanged: (_) => onSubtotalOrDiscountChanged(),
                    );
                    return useRow
                        ? Row(
                            children: <Widget>[
                              Expanded(child: subtotalField),
                              const SizedBox(width: 12),
                              Expanded(child: discountField),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              subtotalField,
                              const SizedBox(height: 12),
                              discountField,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: row.finalTotalController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: Translator.translate('final_price'),
                  ),
                  validator: _positiveDoubleValidator,
                  onChanged: (_) => onFinalChanged(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductOption {
  const _ProductOption({required this.id, required this.name});
  final String id;
  final String name;
}

/// Searchable product picker — the user can type to filter, then tap a match.
class _ProductSearchField extends StatefulWidget {
  const _ProductSearchField({
    required this.selectedProductId,
    required this.products,
    required this.onChanged,
  });

  final String? selectedProductId;
  final List<dynamic> products;
  final ValueChanged<String?> onChanged;

  @override
  State<_ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<_ProductSearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  List<_ProductOption> get _options => widget.products
      .map((p) => _ProductOption(id: p.id as String, name: p.name as String))
      .toList();

  @override
  void initState() {
    super.initState();
    final match = _options.where((o) => o.id == widget.selectedProductId).firstOrNull;
    _controller = TextEditingController(text: match?.name ?? '');
  }

  @override
  void didUpdateWidget(_ProductSearchField old) {
    super.didUpdateWidget(old);
    if (old.selectedProductId != widget.selectedProductId) {
      final match =
          _options.where((o) => o.id == widget.selectedProductId).firstOrNull;
      final text = match?.name ?? '';
      if (_controller.text != text) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<_ProductOption> _filter(String query) {
    if (query.trim().isEmpty) return _options;
    final lower = query.toLowerCase();
    return _options.where((o) => o.name.toLowerCase().contains(lower));
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<_ProductOption>(
      focusNode: _focusNode,
      textEditingController: _controller,
      displayStringForOption: (option) => option.name,
      optionsBuilder: (textEditingValue) => _filter(textEditingValue.text),
      onSelected: (option) => widget.onChanged(option.id),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: Translator.translate('product'),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged(null);
                    },
                  )
                : null,
          ),
          validator: (value) {
            final ok = widget.selectedProductId != null &&
                widget.products.any((p) => p.id == widget.selectedProductId);
            return ok ? null : Translator.translate('required');
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        option.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomerAndSummaryCard extends StatelessWidget {
  const _CustomerAndSummaryCard({
    required this.customers,
    required this.selectedCustomerId,
    required this.selectedCustomer,
    required this.rowCount,
    required this.totalOrderValue,
    required this.onCustomerChanged,
    required this.onUseSuggested,
    required this.onSubmit,
  });

  final List<dynamic> customers;
  final String? selectedCustomerId;
  final dynamic selectedCustomer;
  final int rowCount;
  final double totalOrderValue;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onUseSuggested;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: DropdownButtonFormField<String>(
              initialValue: selectedCustomerId ?? '',
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(Translator.translate('no_special_customer')),
                ),
                ...customers.map(
                  (customer) => DropdownMenuItem<String>(
                    value: customer.id as String,
                    child: Text(
                      '${customer.customerId} - ${customer.name} (${formatDiscount(customer.discountPercent as double)})',
                    ),
                  ),
                ),
              ],
              onChanged: onCustomerChanged,
              decoration: InputDecoration(
                labelText: Translator.translate('special_customer'),
                prefixIcon: const Icon(Icons.person_outline, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4E8E4)),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$rowCount ${Translator.translate('product')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B635E),
                          ),
                    ),
                    Text(
                      Translator.translate(
                        selectedCustomer == null
                            ? 'regular_customer'
                            : 'special_customer',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: selectedCustomer == null
                                ? const Color(0xFF8D9490)
                                : const Color(0xFF18534F),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      Translator.translate('total'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF173531),
                          ),
                    ),
                    Text(
                      formatCurrency(totalOrderValue),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF18534F),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onUseSuggested,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(Translator.translate('use_suggested_total')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: onSubmit,
                        icon: const Icon(Icons.point_of_sale),
                        label: Text(Translator.translate('confirm_sale')),
                      ),
                    ),
                  ],
                ),
              ],
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
        Row(
          children: <Widget>[
            Text(
              Translator.translate('sales_history'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF173531),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Divider(color: const Color(0xFFEDE5D8), height: 1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (sales.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              Translator.translate('no_sales_saved'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8D9490),
                  ),
            ),
          )
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
        ? Translator.translate('regular_customer')
        : '${sale.customerId == null ? '' : '${sale.customerId} - '}${sale.customerName!}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF18534F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    sale.productName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173531),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$customerText · ${formatDateTime(sale.soldAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8D9490),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      _SaleBadge(
                        label: formatMillimeters(sale.quantityMm),
                        color: const Color(0xFF3D6B8C),
                        background: const Color(0xFFE3EEF5),
                      ),
                      if (sale.discountPercent > 0)
                        _SaleBadge(
                          label: formatDiscount(sale.discountPercent),
                          color: const Color(0xFF8A5A24),
                          background: const Color(0xFFF5EDE0),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Text(
              formatCurrency(sale.finalTotal),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF18534F),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleBadge extends StatelessWidget {
  const _SaleBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SellEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFE8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.point_of_sale_outlined,
              size: 36,
              color: Color(0xFF18534F),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            Translator.translate('sell_empty_state'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5A625D),
                ),
          ),
        ],
      ),
    );
  }
}

class _SaleRow {
  _SaleRow({
    this.selectedProductId,
    required this.quantityController,
    required this.unitPriceController,
    required this.discountController,
    required this.subtotalController,
    required this.finalTotalController,
  });

  String? selectedProductId;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController discountController;
  final TextEditingController subtotalController;
  final TextEditingController finalTotalController;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    discountController.dispose();
    subtotalController.dispose();
    finalTotalController.dispose();
  }
}

String? _positiveDoubleValidator(String? value) {
  final parsed = double.tryParse((value ?? '').trim());
  if (parsed == null || parsed <= 0) {
    return Translator.translate('required');
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
