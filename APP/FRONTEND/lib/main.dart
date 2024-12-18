import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // Tile caching
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import custom widgets and utility files
import 'src/pages/Auth/Log_In/login.dart';
import 'src/pages/home.dart';
import 'src/utilities/User_Model/user.dart';
import 'src/utilities/User_Model/ImageProvider.dart';
import 'src/pages/wallet/wallet.dart';


void main() async {
  // Ensure Flutter bindings are initialized before calling any asynchronous methods
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI overlay styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize the tile caching
  Object? initErr;
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (err) {
    initErr = err;
  }
  // Now run the app with providers
  runApp(MyApp(initialisationError: initErr));
}

// SessionHandler to manage user session and connection status
class SessionHandler extends StatefulWidget {
  final bool loggedIn;

  const SessionHandler({super.key, this.loggedIn = false});

  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _retrieveUserData();
  }

  // Retrieve stored user data from SharedPreferences
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
  // Check for internet connection
  if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
    _dismissNoConnectionPage(); // Dismiss the error page if internet is restored
  } else if (result == ConnectivityResult.none) {
    _showNoConnectionPage(context); // Show the no internet error page
  }
}
void _showNoConnectionPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const InternetErrorPage(),
    ),
  );
}



void _dismissNoConnectionPage() {
  if (Navigator.canPop(context)) {
    Navigator.pop(context); // Pop the InternetErrorPage if it is active
  }
}
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return userData.username != null
        ? HomePage(username: userData.username ?? '', userId: userData.userId ?? 0, email: userData.email ?? '')
        : const LoginPage();
  }
}


// App Container to manage initialization error and app state
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialisationError});

  final Object? initialisationError;

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

if (initialisationError case final err?) {
  return MaterialApp(
    title: 'FMTC Demo (Initialisation Error)',
    theme: customTheme,
    home: InitialisationError(error: err), // Provide a default message
  );
}


    // Return main app with multiple providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserData()),
        ChangeNotifierProvider(create: (_) => UserImageProvider()),
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => RegionSelectionProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ConfigureDownloadProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DownloadingProvider(), lazy: true),
      ],
      child: MaterialApp(
        title: 'ion Hive',
        debugShowCheckedModeBanner: false,
        theme: customTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SessionHandler(),
          '/home': (context) => const SessionHandler(loggedIn: true),
          '/wallet': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
            return WalletPage(username: args['username'], userId: args['userId'], email: args['email_id'],);
          },
  
        },
      ),
    );
  }
}



class GeneralProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


class MapProvider with ChangeNotifier {
  double _zoomLevel = 12.0;
  String _currentRegion = "Default Region";

  double get zoomLevel => _zoomLevel;
  String get currentRegion => _currentRegion;

  void setZoomLevel(double zoom) {
    _zoomLevel = zoom;
    notifyListeners();
  }

  void setCurrentRegion(String region) {
    _currentRegion = region;
    notifyListeners();
  }
}

class DownloadingProvider with ChangeNotifier {
  double _progress = 0.0;
  bool _isDownloading = false;

  double get progress => _progress;
  bool get isDownloading => _isDownloading;

  void startDownload() {
    _isDownloading = true;
    _progress = 0.0;
    notifyListeners();
  }

  void updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void completeDownload() {
    _isDownloading = false;
    _progress = 100.0;
    notifyListeners();
  }
}

class ConfigureDownloadProvider with ChangeNotifier {
  String _region = "Default Region";
  bool _isConfigured = false;

  String get region => _region;
  bool get isConfigured => _isConfigured;

  void configureDownload(String newRegion) {
    _region = newRegion;
    _isConfigured = true;
    notifyListeners();
  }

  void resetConfiguration() {
    _isConfigured = false;
    notifyListeners();
  }
}


class RegionSelectionProvider with ChangeNotifier {
  String _selectedRegion = "Default Region";

  String get selectedRegion => _selectedRegion;

  void selectRegion(String region) {
    _selectedRegion = region;
    notifyListeners();
  }
}


class InitialisationError extends StatelessWidget {
  final Object error;

  const InitialisationError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            const Text(
              'An error occurred during initialization:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // You can add a retry mechanism or go back to the previous screen
                Navigator.of(context).pop();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


class InternetErrorPage extends StatelessWidget {
  const InternetErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch screen size
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // No Internet Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.wifi,
                    size: screenWidth * 0.30, // Adjust size dynamically
                    color: Colors.blueGrey,
                  ),
                  Icon(
                    Icons.close,
                    size: screenWidth * 0.17, // Adjust size dynamically
                    color: Colors.red,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05), // Adjust spacing
              // Title
              Text(
                "Ooops!",
                style: TextStyle(
                  fontSize: screenWidth * 0.07, // Adjust font size dynamically
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  "It seems you are offline. Please check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // Adjust font size dynamically
                    color: Colors.white70,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              // Retry Button
              ElevatedButton(
                onPressed: () async {
                  // Check the internet connection status
                  var connectivityResult = await Connectivity().checkConnectivity();

                  if (connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi) {
                    // Internet is available, close the page
                    Navigator.of(context).pop(); // Close the current page
                  } else {
                    // Internet is still not available, retry the connection check
                    _showRetryMessage(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1, // Adjust padding dynamically
                    vertical: screenHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Try Again",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // Adjust font size dynamically
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Close App Button
              TextButton(
                onPressed: () {
                  // Close the app (pop the current page)
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Back to App",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045, // Adjust font size dynamically
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
void _showRetryMessage(BuildContext context) {
  // Dismiss any existing snack bars before showing a new one
  ScaffoldMessenger.of(context).clearSnackBars();
  
  // Show the new retry message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No internet connection. Please try again later.'),
      duration: Duration(seconds: 2),
    ),
  );
}

}
