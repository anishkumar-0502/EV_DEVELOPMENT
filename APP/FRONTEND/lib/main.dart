import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cool_alert/cool_alert.dart';
import 'src/pages/Auth/Log_In/login.dart';
import 'src/pages/home.dart';
import 'src/utilities/User_Model/user.dart';
import 'src/utilities/User_Model/ImageProvider.dart';
import 'src/pages/wallet/wallet.dart';
import 'src/pages/profile/Account/Transaction_Details/transaction_details.dart';

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserData()),
        ChangeNotifierProvider(create: (_) => UserImageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class SessionHandler extends StatefulWidget {
  final bool loggedIn;

  const SessionHandler({super.key, this.loggedIn = false});

  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  late Connectivity _connectivity;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _alertIsVisible = false;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _retrieveUserData();
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _retrieveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUser = prefs.getString('user');
    int? storedUserId = prefs.getInt('userId');
    String? storedEmail = prefs.getString('email');
    if (storedUser != null && storedUserId != null && storedEmail != null) {
      Provider.of<UserData>(context, listen: false).updateUserData(storedUser, storedUserId, storedEmail);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool isConnected = result != ConnectivityResult.none;

    if (!isConnected && !_alertIsVisible) {
      _showNoConnectionDialog();
    } else if (isConnected && _alertIsVisible) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
        _alertIsVisible = false;
      }
    }
  }

  Future _showNoConnectionDialog() {
    _alertIsVisible = true;
    return CoolAlert.show(
    context: context,
    type: CoolAlertType.custom, // Changed to custom
    widget: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text(
            'Mobile data required',
            style: TextStyle(
                fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'This app requires internet connection  to function correctly. Please turn on Mobile data',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    confirmBtnText: 'Settings',
    cancelBtnText: 'Cancel',
    showCancelBtn: false,
    confirmBtnColor: Colors.blue,
    barrierDismissible: false,
    onConfirmBtnTap: () {
      _alertIsVisible = false;
        SystemNavigator.pop();
    },
  ); }


  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return userData.username != null
        ? HomePage(username: userData.username ?? '', userId: userData.userId ?? 0, email: userData.email ?? '')
        : const LoginPage();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData customTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
    );

    return MaterialApp(
      title: 'EV',
      debugShowCheckedModeBanner: false,
      theme: customTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SessionHandler(),
        '/home': (context) => const SessionHandler(loggedIn: true),
        '/wallet': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return WalletPage(username: args['username'], userId: args['userId']);
        },
        '/transaction_details': (context) => TransactionDetailsWidget(
          transactionDetails: ModalRoute.of(context)?.settings.arguments as List<Map<String, dynamic>>,
          username: AutofillHints.username,
        ),
      },
    );
  }
}
