import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/Charging/charging.dart';
import '../pages/Home_contents/home_content.dart';
import '../utilities/QR/qrscanner.dart';
import 'package:http/http.dart' as http;

class Footer extends StatefulWidget {
  final Function(int) onTabChanged;
  final String username;
  final int? userId;
  final String email;

  const Footer({
    required this.onTabChanged,
    super.key,
    required this.username,
    this.userId,
    required this.email,
  });

  @override
  FooterState createState() => FooterState();
}

class FooterState extends State<Footer> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<int> _navigationStack = []; // Navigation stack to track history
  bool isSearching = false;
  String searchChargerID = '';

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Define screen size categories
    bool isSmallScreen = screenWidth <= 400; // For small devices like phones
    bool isMediumScreen =
        screenWidth > 400 && screenWidth <= 800; // For tablets
    bool isLargeScreen = screenWidth > 800; // For large devices like desktops

    return SafeArea(top: false,
      child: Container(
        padding: const EdgeInsets.only(top:8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: "Home",
              index: 0,
              isSelected: _currentIndex == 0,
              onTap: _onTabTapped,
              screenWidth: screenWidth,
              screenCategory:
                  _getScreenCategory(isSmallScreen, isMediumScreen),
            ),
            _buildNavItem(
              icon: Icons.wallet_outlined,
              label: "Wallet",
              index: 1,
              isSelected: _currentIndex == 1,
              onTap: _onTabTapped,
              screenWidth: screenWidth,
              screenCategory:
                  _getScreenCategory(isSmallScreen, isMediumScreen),
            ),
            FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: navigateToQRViewExample,
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: isLargeScreen
                    ? 40
                    : isMediumScreen
                        ? 35
                        : 28, // Adjust size for small screens
              ),
            ),
            _buildNavItem(
              icon: Icons.history,
              label: "History",
              index: 2,
              isSelected: _currentIndex == 2,
              onTap: _onTabTapped,
              screenWidth: screenWidth,
              screenCategory:
                  _getScreenCategory(isSmallScreen, isMediumScreen),
            ),
            _buildNavItem(
              icon: Icons.account_circle,
              label: "Profile",
              index: 3,
              isSelected: _currentIndex == 3,
              onTap: _onTabTapped,
              screenWidth: screenWidth,
              screenCategory:
                  _getScreenCategory(isSmallScreen, isMediumScreen),
            ),
          ],
        ),
      ),
    );
  }

// Helper function for determining screen category
  String _getScreenCategory(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) {
      return "small";
    } else if (isMediumScreen) {
      return "medium";
    } else {
      return "large";
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required ValueChanged<int> onTap,
    required double screenWidth,
    required String screenCategory,
  }) {
    double iconSize = 0;
    double fontSize = 0;

    // Adjust icon size and font size based on screen category
    if (screenCategory == "large") {
      iconSize = 36;
      fontSize = 16;
    } else if (screenCategory == "medium") {
      iconSize = 30;
      fontSize = 14;
    } else {
      iconSize = 24;
      fontSize = 12;
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: isSelected
                ? const Color.fromARGB(255, 104, 251, 109)
                : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromARGB(255, 104, 251, 109)
                  : Colors.grey,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _navigationStack.add(_currentIndex); // Add current index to the stack
      _currentIndex = index;
    });
    widget.onTabChanged(index);
  }

  /// Handle back button press to navigate backward in the stack
  bool handleBackPress() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _currentIndex =
            _navigationStack.removeLast(); // Go back to the previous tab
      });
      widget.onTabChanged(_currentIndex);
      return false; // Prevent exiting the app
    }
    return true; // Allow exiting the app
  }

  Future<void> navigateToQRViewExample() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTimeQR') ?? true;

    if (Platform.isIOS) {
      if (isFirstTime) {
        // Navigate without checking permission for the first time
        await _navigateToQRView();
        prefs.setBool(
            'isFirstTimeQR', false); // Set to false after the first navigation
      } else {
        var status = await Permission.camera.status;
        debugPrint("camera status: $status ");
        if (status == PermissionStatus.denied) {
          await Permission.camera.request();
        }

        if (status.isGranted) {
          await _navigateToQRView();
        } else {
          _navigateToPermissionErrorPage();
        }
      }
    } else if (Platform.isAndroid) {
      // For Android, always check permissions
      PermissionStatus permissionStatus = await Permission.camera.request();

      if (permissionStatus.isGranted) {
        await _navigateToQRView();
      } else {
        // Show a dialog if permission is denied
        _navigateToPermissionErrorPage();
      }
    }
  }

  void _navigateToPermissionErrorPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PermissionErrorPage(), // Custom page like the image
      ),
    );
  }

  Future<void> _navigateToQRView() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRViewExample(
          handleSearchRequestCallback: handleSearchRequest,
          username: widget.username,
          userId: widget.userId,
        ),
      ),
    );

    if (scannedCode != null) {
      setState(() {
        searchChargerID = scannedCode;
        isSearching = false;
      });
    }
  }

  Future<Map<String, dynamic>?> handleSearchRequest(
      String searchChargerID) async {
    if (isSearching) return null;

    if (searchChargerID.isEmpty) {
      showErrorDialog(context, 'Please enter a charger ID.');
      return {'error': true, 'message': 'Charger ID is empty'};
    }

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/searchCharger'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
        }),
      );

      // Delay to keep the loading indicator visible
      await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          this.searchChargerID = searchChargerID;
          isSearching = false;
        });

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.black,
          builder: (BuildContext context) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: ConnectorSelectionDialog(
                chargerData: data['socketGunConfig'] ?? {},
                onConnectorSelected: (connectorId, connectorType) {
                  updateConnectorUser(
                      searchChargerID, connectorId, connectorType);
                },
                username: widget.username,
                email: widget.email,
                userId: widget.userId,
              ),
            );
          },
        );
        return data; // Return the successful response data
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isSearching = false;
        });
        return {'error': true, 'message': errorData['message']};
      }
    } catch (error) {
      showErrorDialog(context, 'Something went wrong, try again later');
      return {
        'error': true,
        'message': 'Something went wrong, try again later'
      };
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: ErrorDetails(
              errorData: message,
              username: widget.username,
              email: widget.email,
              userId: widget.userId),
        );
      },
    ).then((_) {});
  }

  Future<void> updateConnectorUser(
      String searchChargerID, int connectorId, int connectorType) async {
    setState(() {
      isSearching = false;
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/updateConnectorUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
          'connector_id': connectorId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Charging(
              searchChargerID: searchChargerID,
              username: widget.username,
              userId: widget.userId,
              connector_id: connectorId,
              connector_type: connectorType,
              email: widget.email,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      showErrorDialog(context, 'Something went wrong, try again later ');
    }
  }
}
