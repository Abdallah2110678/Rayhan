import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../pages/add_product_page.dart';
import '../pages/customers_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/finances_page.dart';
import '../pages/products_page.dart';
import '../pages/sell_product_page.dart';
import '../state/customer_controller.dart';
import '../state/expense_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/brand_mark.dart';

class RayhanShell extends StatefulWidget {
  const RayhanShell({
    super.key,
    required this.products,
    required this.customers,
    required this.expenses,
    required this.onLogout,
  });

  final ProductCatalogController products;
  final CustomerController customers;
  final ExpenseController expenses;
  final VoidCallback onLogout;

  @override
  State<RayhanShell> createState() => _RayhanShellState();
}

class _RayhanShellState extends State<RayhanShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
        products: widget.products,
        customers: widget.customers,
        expenses: widget.expenses,
      ),
      ProductsPage(catalog: widget.products),
      AddProductPage(catalog: widget.products),
      SellProductPage(products: widget.products, customers: widget.customers),
      CustomersPage(customers: widget.customers),
      FinancesPage(expenses: widget.expenses),
    ];

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: Translator.translate('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: Translator.translate('products'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.add_box_outlined),
        selectedIcon: const Icon(Icons.add_box),
        label: Translator.translate('add'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.sell_outlined),
        selectedIcon: const Icon(Icons.sell),
        label: Translator.translate('sell'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.groups_2_outlined),
        selectedIcon: const Icon(Icons.groups_2),
        label: Translator.translate('customers'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet),
        label: Translator.translate('finance'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 980;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFFF8F3EA),
                Color(0xFFE9F1EB),
                Color(0xFFF4EFE6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 88,
              title: const BrandMark(),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.language),
                        tooltip: Translator.translate('toggle_language_tooltip'),
                        onPressed: () {
                          setState(() {
                            Translator.toggleLocale();
                          });
                        },
                      ),
                      AnimatedBuilder(
                        animation: Listenable.merge(<Listenable>[
                          widget.products,
                          widget.customers,
                        ]),
                        builder: (context, _) {
                          final lowStockItems = widget.products.products
                              .where((product) => product.quantityMm <= 110)
                              .toList();

                          return Row(
                            children: [
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      final selected = await showMenu<String>(
                                        context: context,
                                        position: const RelativeRect.fromLTRB(
                                          1000,
                                          100,
                                          16,
                                          0,
                                        ),
                                        items: lowStockItems.isEmpty
                                            ? [
                                                PopupMenuItem<String>(
                                                  value: '',
                                                  child: Text(
                                                    Translator.translate('no_low_stock_items'),
                                                  ),
                                                ),
                                              ]
                                            : lowStockItems.map((product) {
                                                return PopupMenuItem<String>(
                                                  value: product.id,
                                                  child: Text(
                                                    '${product.name} - ${formatMillimeters(product.quantityMm)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                      );

                                      if (!mounted) return;

                                      if (selected != null &&
                                          selected.isNotEmpty) {
                                        final productName = widget
                                            .products
                                            .products
                                            .firstWhere((p) => p.id == selected)
                                            .name;

                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                Translator.translate(
                                                  'check_product_stock',
                                                  {'product': productName},
                                                ),
                                              ),
                                            ),
                                          );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                    ),
                                    tooltip: Translator.translate(
                                      'low_stock_notifications_tooltip',
                                    ),
                                  ),
                                  if (lowStockItems.isNotEmpty)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          '${lowStockItems.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              _ShellSummary(
                                productCount: widget.products.productCount,
                                customerCount: widget.customers.customerCount,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton.outlined(
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.logout),
                        tooltip: Translator.translate('logout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: useRail
                  ? Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 0, 18),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: NavigationRail(
                              selectedIndex: _currentIndex,
                              labelType: NavigationRailLabelType.all,
                              minWidth: 96,
                              backgroundColor: Colors.white.withOpacity(0.75),
                              onDestinationSelected: (value) {
                                setState(() {
                                  _currentIndex = value;
                                });
                              },
                              destinations: <NavigationRailDestination>[
                                NavigationRailDestination(
                                  icon: const Icon(Icons.dashboard_outlined),
                                  selectedIcon: const Icon(Icons.dashboard),
                                  label: Text(Translator.translate('home')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.inventory_2_outlined),
                                  selectedIcon: const Icon(Icons.inventory_2),
                                  label: Text(Translator.translate('products')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.add_box_outlined),
                                  selectedIcon: const Icon(Icons.add_box),
                                  label: Text(Translator.translate('add')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.sell_outlined),
                                  selectedIcon: const Icon(Icons.sell),
                                  label: Text(Translator.translate('sell')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.groups_2_outlined),
                                  selectedIcon: const Icon(Icons.groups_2),
                                  label: Text(Translator.translate('customers')),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.account_balance_wallet_outlined),
                                  selectedIcon: const Icon(Icons.account_balance_wallet),
                                  label: Text(Translator.translate('finance')),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: pages,
                          ),
                        ),
                      ],
                    )
                  : IndexedStack(index: _currentIndex, children: pages),
            ),
            bottomNavigationBar: useRail
                ? null
                : NavigationBar(
                    selectedIndex: _currentIndex,
                    destinations: destinations,
                    onDestinationSelected: (value) {
                      setState(() {
                        _currentIndex = value;
                      });
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _ShellSummary extends StatelessWidget {
  const _ShellSummary({
    required this.productCount,
    required this.customerCount,
  });

  final int productCount;
  final int customerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DDCF)),
      ),
      child: Text(
        '$productCount products • $customerCount customers',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D403B),
            ),
      ),
    );
  }
}
