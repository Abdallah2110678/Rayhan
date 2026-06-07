import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../models/customer.dart';
import '../models/sale_record.dart';
import '../state/customer_controller.dart';
import '../state/packaging_controller.dart';
import '../state/product_catalog_controller.dart';
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
    // row controllers disposed above
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
      finalTotalController: TextEditingController(),
    );
  }

  void _syncSaleRowDefaults(_SaleRow row) {
    final product = row.selectedProductId == null
        ? null
        : widget.products.productById(row.selectedProductId!);
    if (product == null) {
      return;
    }

    row.unitPriceController.text = product.sellPrice.toStringAsFixed(2);
    _applySuggestedFinalTotalForRow(row);
  }

  void _applySuggestedFinalTotalForRow(_SaleRow row) {
    final quantityMm = double.tryParse(row.quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(row.unitPriceController.text.trim()) ?? 0;
    final discountPercent =
        double.tryParse(row.discountController.text.trim()) ?? 0;
    final suggestedTotal = (unitPrice * quantityMm) * (1 - (discountPercent / 100));
    row.finalTotalController.text = suggestedTotal.toStringAsFixed(2);
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
    if (_saleRows.length <= 1) {
      return;
    }
    setState(() {
      _saleRows[index].dispose();
      _saleRows.removeAt(index);
    });
  }

  double get _totalOrderValue {
    return _saleRows.fold<double>(0, (sum, row) {
      return sum + (double.tryParse(row.finalTotalController.text.trim()) ?? 0);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final customer = _selectedCustomerId == null
        ? null
        : widget.customers.customerById(_selectedCustomerId!);

    try {
      double totalSale = 0;
      final List<String> bottleMessages = <String>[];

      for (final row in _saleRows) {
        final productId = row.selectedProductId;
        if (productId == null) {
          continue;
        }

        final quantityMm = double.parse(row.quantityController.text.trim());
        final unitPrice = double.parse(row.unitPriceController.text.trim());
        final discountPercent = double.parse(
          row.discountController.text.trim(),
        );
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

        final deducted = widget.packaging.deductBottle(quantityMm);
        final sizeLabel = quantityMm % 1 == 0
            ? quantityMm.toInt().toString()
            : quantityMm.toString();
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
                'product': productNames.isEmpty
                    ? Translator.translate('product')
                    : productNames,
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

      for (final row in _saleRows) {
        row.quantityController.clear();
        row.finalTotalController.clear();
        row.discountController.text = '0';
        row.unitPriceController.clear();
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
      animation: Listenable.merge(<Listenable>[widget.products, widget.customers]),
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

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(
                title: Translator.translate('sell_a_product'),
                subtitle: Translator.translate('sell_product_subtitle'),
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
                                    ...List<Widget>.generate(_saleRows.length, (
                                      index,
                                    ) {
                                      final row = _saleRows[index];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${Translator.translate('product')} ${index + 1}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                              if (_saleRows.length > 1)
                                                IconButton(
                                                  onPressed: () =>
                                                      _removeSaleRow(index),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  tooltip: Translator.translate(
                                                    'remove',
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                            initialValue:
                                                widget.products.productById(
                                                      row.selectedProductId ??
                                                          '',
                                                    ) ==
                                                    null
                                                ? null
                                                : row.selectedProductId,
                                            items: products
                                                .map(
                                                  (product) =>
                                                      DropdownMenuItem<String>(
                                                        value: product.id,
                                                        child: Text(
                                                          product.name,
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                row.selectedProductId = value;
                                                _syncSaleRowDefaults(row);
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return Translator.translate(
                                                  'required',
                                                );
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: Translator.translate(
                                                'product',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: row.quantityController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: Translator.translate(
                                                'quantity_in_mm',
                                              ),
                                            ),
                                            validator: _positiveDoubleValidator,
                                            onChanged: (_) => setState(
                                              () =>
                                                  _applySuggestedFinalTotalForRow(
                                                    row,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: row.unitPriceController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: Translator.translate(
                                                'unit_price_per_mm',
                                              ),
                                            ),
                                            validator: _positiveDoubleValidator,
                                            onChanged: (_) => setState(
                                              () =>
                                                  _applySuggestedFinalTotalForRow(
                                                    row,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: row.discountController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: Translator.translate(
                                                'discount_percent',
                                              ),
                                            ),
                                            validator: _discountValidator,
                                            onChanged: (_) => setState(
                                              () =>
                                                  _applySuggestedFinalTotalForRow(
                                                    row,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller:
                                                row.finalTotalController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: Translator.translate(
                                                'final_price',
                                              ),
                                            ),
                                            validator: _positiveDoubleValidator,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      );
                                    }),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: _addSaleRow,
                                          icon: const Icon(Icons.add),
                                          label: Text(
                                            Translator.translate('add_product'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 36),
                                    DropdownButtonFormField<String>(
                                      initialValue: widget.customers.customerById(_selectedCustomerId ?? '') == null
                                          ? null
                                          : _selectedCustomerId,
                                      items: <DropdownMenuItem<String>>[
                                        DropdownMenuItem<String>(
                                          value: '',
                                          child: Text(
                                            Translator.translate(
                                              'no_special_customer',
                                            ),
                                          ),
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
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: Translator.translate(
                                          'special_customer',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed:
                                              _applySuggestedFinalTotalForAllRows,
                                          icon: const Icon(Icons.refresh),
                                          label: Text(
                                            Translator.translate(
                                              'use_suggested_total',
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${_saleRows.length} ${Translator.translate('product')}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F2E9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5DCCF),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${Translator.translate('total')}: ${formatCurrency(_totalOrderValue)}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${Translator.translate('customer')}: ${selectedCustomer == null ? Translator.translate('regular_customer') : '${selectedCustomer.customerId} - ${selectedCustomer.name}'}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _submit,
                                        icon: const Icon(Icons.point_of_sale),
                                        label: Text(
                                          Translator.translate('confirm_sale'),
                                        ),
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


class _SalesHistorySection extends StatelessWidget {
  const _SalesHistorySection({required this.sales});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Translator.translate('sales_history'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          Text(Translator.translate('no_sales_saved'))
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
          Text(
            '${Translator.translate('date')}: ${formatDateTime(sale.soldAt)}',
          ),
          Text('${Translator.translate('customer')}: $customerText'),
          Text(
            '${Translator.translate('quantity_in_mm')}: ${formatMillimeters(sale.quantityMm)}',
          ),
          Text(
            '${Translator.translate('unit_price')}: ${formatCurrency(sale.unitPrice)}',
          ),
          Text(
            '${Translator.translate('discount')}: ${formatDiscount(sale.discountPercent)}',
          ),
          Text(
            '${Translator.translate('subtotal')}: ${formatCurrency(sale.subtotal)}',
          ),
          Text(
            '${Translator.translate('final_total')}: ${formatCurrency(sale.finalTotal)}',
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
    return Center(child: Text(Translator.translate('sell_empty_state')),
    );
  }
}

class _SaleRow {
  _SaleRow({
    this.selectedProductId,
    required this.quantityController,
    required this.unitPriceController,
    required this.discountController,
    required this.finalTotalController,
  });

  String? selectedProductId;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController discountController;
  final TextEditingController finalTotalController;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    discountController.dispose();
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
