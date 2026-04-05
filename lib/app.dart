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
  final LocalStore _localStore = LocalStore();

  bool _isAuthenticated = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _products.removeListener(_persistData);
    _customers.removeListener(_persistData);
    _expenses.removeListener(_persistData);
    _products.dispose();
    _customers.dispose();
    _expenses.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final savedProducts = await _localStore.loadProducts();
    final savedCustomers = await _localStore.loadCustomers();
    final savedExpenses = await _localStore.loadExpenses();
    _products.restoreFromJson(savedProducts);
    _customers.restoreFromJson(savedCustomers);
    _expenses.restoreFromJson(savedExpenses);
    _products.addListener(_persistData);
    _customers.addListener(_persistData);
    _expenses.addListener(_persistData);

    if (!mounted) {
      return;
    }

    setState(() {
      _isReady = true;
    });
  }

  Future<void> _persistData() async {
    if (!_isReady) {
      return;
    }

    await Future.wait(<Future<void>>[
      _localStore.saveProducts(_products.toJson()),
      _localStore.saveCustomers(_customers.toJson()),
      _localStore.saveExpenses(_expenses.toJson()),
    ]);
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
                  onLogout: _logout,
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
