import 'package:flutter/material.dart';

import '../pages/add_product_page.dart';
import '../pages/customers_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/products_page.dart';
import '../pages/sell_product_page.dart';
import '../state/customer_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/brand_mark.dart';

class RayhanShell extends StatefulWidget {
  const RayhanShell({
    super.key,
    required this.products,
    required this.customers,
    required this.onLogout,
  });

  final ProductCatalogController products;
  final CustomerController customers;
  final VoidCallback onLogout;

  @override
  State<RayhanShell> createState() => _RayhanShellState();
}

class _RayhanShellState extends State<RayhanShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(products: widget.products, customers: widget.customers),
      ProductsPage(catalog: widget.products),
      AddProductPage(catalog: widget.products),
      SellProductPage(products: widget.products, customers: widget.customers),
      CustomersPage(customers: widget.customers),
    ];

    final destinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Products',
      ),
      NavigationDestination(
        icon: Icon(Icons.add_box_outlined),
        selectedIcon: Icon(Icons.add_box),
        label: 'Add',
      ),
      NavigationDestination(
        icon: Icon(Icons.sell_outlined),
        selectedIcon: Icon(Icons.sell),
        label: 'Sell',
      ),
      NavigationDestination(
        icon: Icon(Icons.groups_2_outlined),
        selectedIcon: Icon(Icons.groups_2),
        label: 'Customers',
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
                      AnimatedBuilder(
                        animation: Listenable.merge(<Listenable>[
                          widget.products,
                          widget.customers,
                        ]),
                        builder: (context, _) {
                          return _ShellSummary(
                            productCount: widget.products.productCount,
                            customerCount: widget.customers.customerCount,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton.outlined(
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
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
                              destinations: const <NavigationRailDestination>[
                                NavigationRailDestination(
                                  icon: Icon(Icons.dashboard_outlined),
                                  selectedIcon: Icon(Icons.dashboard),
                                  label: Text('Home'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.inventory_2_outlined),
                                  selectedIcon: Icon(Icons.inventory_2),
                                  label: Text('Products'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.add_box_outlined),
                                  selectedIcon: Icon(Icons.add_box),
                                  label: Text('Add'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.sell_outlined),
                                  selectedIcon: Icon(Icons.sell),
                                  label: Text('Sell'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.groups_2_outlined),
                                  selectedIcon: Icon(Icons.groups_2),
                                  label: Text('Customers'),
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
