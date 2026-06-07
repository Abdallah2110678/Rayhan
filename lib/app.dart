import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/storage/local_store.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/translator.dart';
import 'pages/login_page.dart';
import 'pages/product_details_page.dart';
import 'pages/rayhan_shell.dart';
import 'pages/sell_product_page.dart';
import 'state/customer_controller.dart';
import 'state/expense_controller.dart';
import 'state/packaging_controller.dart';
import 'state/product_catalog_controller.dart';

class RayhanApp extends StatefulWidget {
  const RayhanApp({super.key});

  @override
  State<RayhanApp> createState() => _RayhanAppState();
}

class _RayhanAppState extends State<RayhanApp> {
  static const String _username = 'Dr Mohamed sabie';
  static const String _password = '21012002';

  final ProductCatalogController _products = ProductCatalogController();
  final CustomerController _customers = CustomerController();
  final ExpenseController _expenses = ExpenseController();
  final PackagingController _packaging = PackagingController();
  final LocalStore _localStore = LocalStore();

  bool _isAuthenticated = false;
  bool _isReady = false;

  // Per-controller debounce timers — avoids write storms on rapid changes.
  Timer? _productsSaveTimer;
  Timer? _customersSaveTimer;
  Timer? _expensesSaveTimer;
  Timer? _packagingSaveTimer;

  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _productsSaveTimer?.cancel();
    _customersSaveTimer?.cancel();
    _expensesSaveTimer?.cancel();
    _packagingSaveTimer?.cancel();
    _products.removeListener(_onProductsChanged);
    _customers.removeListener(_onCustomersChanged);
    _expenses.removeListener(_onExpensesChanged);
    _packaging.removeListener(_onPackagingChanged);
    _products.dispose();
    _customers.dispose();
    _expenses.dispose();
    _packaging.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final savedProducts = await _localStore.loadProducts();
    final savedCustomers = await _localStore.loadCustomers();
    final savedExpenses = await _localStore.loadExpenses();
    final savedPackaging = await _localStore.loadPackaging();
    _products.restoreFromJson(savedProducts);
    _customers.restoreFromJson(savedCustomers);
    _expenses.restoreFromJson(savedExpenses);
    _packaging.restoreFromJson(savedPackaging);
    _products.addListener(_onProductsChanged);
    _customers.addListener(_onCustomersChanged);
    _expenses.addListener(_onExpensesChanged);
    _packaging.addListener(_onPackagingChanged);

    if (!mounted) {
      return;
    }

    setState(() {
      _isReady = true;
    });
  }

  void _onProductsChanged() {
    if (!_isReady) return;
    _productsSaveTimer?.cancel();
    _productsSaveTimer = Timer(_debounceDuration, () {
      _localStore.saveProducts(_products.toJson());
    });
  }

  void _onCustomersChanged() {
    if (!_isReady) return;
    _customersSaveTimer?.cancel();
    _customersSaveTimer = Timer(_debounceDuration, () {
      _localStore.saveCustomers(_customers.toJson());
    });
  }

  void _onExpensesChanged() {
    if (!_isReady) return;
    _expensesSaveTimer?.cancel();
    _expensesSaveTimer = Timer(_debounceDuration, () {
      _localStore.saveExpenses(_expenses.toJson());
    });
  }

  void _onPackagingChanged() {
    if (!_isReady) return;
    _packagingSaveTimer?.cancel();
    _packagingSaveTimer = Timer(_debounceDuration, () {
      _localStore.savePackaging(_packaging.toJson());
    });
  }

  void _login(String username, String password) {
    if (username == _username && password == _password) {
      setState(() {
        _isAuthenticated = true;
      });
      return;
    }

    throw ArgumentError('Invalid username or password.');
  }

  void _logout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == ProductDetailsPage.routeName) {
      final productId = settings.arguments as String;
      return MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(
          catalog: _products,
          productId: productId,
          customers: _customers,
        ),
      );
    }

    if (settings.name == SellProductPage.routeName) {
      final productId = settings.arguments is String ? settings.arguments as String : null;
      return MaterialPageRoute<void>(
        builder: (_) => SellProductPage(
          products: _products,
          customers: _customers,
          packaging: _packaging,
          initialProductId: productId,
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Translator.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: Translator.translate('app_name'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: !_isReady
          ? const _SplashPage()
          : _isAuthenticated
              ? RayhanShell(
                  products: _products,
                  customers: _customers,
                  expenses: _expenses,
                  packaging: _packaging,
                  onLogout: _logout,
                  onLocaleChanged: () => setState(() {}),
                )
              : LoginPage(onLogin: _login),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
