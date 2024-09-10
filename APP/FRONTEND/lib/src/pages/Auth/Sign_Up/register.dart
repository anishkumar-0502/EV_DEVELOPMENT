import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import '../Log_In/login.dart';
import '../../../utilities/Alert/alert_banner.dart'; // Import the alert banner
import 'package:connectivity_plus/connectivity_plus.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  bool _isUsernameInteracted = false;
  bool _isEmailInteracted = false;
  bool _isPasswordInteracted = false;
  bool _isPasswordVisible = false;
  String? _alertMessage;
  String? SussessMsg;
  late Connectivity _connectivity;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateAndUpdate);
    _emailController.addListener(_validateAndUpdate);
    _phoneController.addListener(_validateAndUpdate);
    _passwordController.addListener(_validateAndUpdate);
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }


  Future<void> _checkInitialConnection() async {
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }
  void _updateConnectionStatus(ConnectivityResult result) {

    // Check for specific connection types (Wi-Fi or Mobile Data)
    if (result == ConnectivityResult.mobile) {
      // Connected to mobile data
      _dismissConnectionDialog(); // Close any dialog if mobile data is connected
    } else if (result == ConnectivityResult.wifi) {
      // Connected to Wi-Fi
      _dismissConnectionDialog(); // Close any dialog if Wi-Fi is connected
    } else if (result == ConnectivityResult.none) {
      // No internet connection
      if (!_isDialogOpen) {
        _showNoConnectionDialog(result); // Show dialog with specific message
      }
    }
  }

  void _showNoConnectionDialog(ConnectivityResult result) {
    String message;

    if (result == ConnectivityResult.none) {
      message = 'Mobile data is off. Please turn it on or connect to Wi-Fi.';
    } else {
      message = 'No Internet Connection. Please check your connection.';
    }

    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Text(
                    "Connection Error",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                _checkInitialConnection(); // Retry connection check
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                SystemNavigator.pop(); // Close the app
              },
              child: const Text("Close App", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogOpen = false; // Update state when dialog is dismissed
      });
    });
  }



  void _dismissConnectionDialog() {
    if (_isDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss the alert
      _isDialogOpen = false;
    }
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _validateAndUpdate() {
    // Truncate email input if it contains anything after `.com`
    final emailValue = _emailController.text;
    if (emailValue.contains('.com')) {
      final index = emailValue.indexOf('.com');
      if (index + 4 < emailValue.length) {
        _emailController.text = emailValue.substring(0, index + 4);
        _emailController.selection = TextSelection.fromPosition(
            TextPosition(offset: _emailController.text.length));
      }
    }

    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  bool _validateEmail(String value) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }

  bool _validateUsername(String value) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');  // Allows letters and numbers
    return usernameRegex.hasMatch(value);
  }

  void _handleRegister() async {
    final String username = _usernameController.text;
    final String email = _emailController.text;
    final String phone = _phoneController.text;
    final String password = _passwordController.text;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/profile/RegisterNewUser'),
        headers: {'Content-Type': 'application/json'}, // Ensure content type is set
        body: jsonEncode({
          'username': username,
          'email_id': email,
          'phone_no': phone,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        _showAlertBannerSussess("User successfully registered");
        // Handle successful registration
        await Future.delayed(const Duration(seconds: 3)); // Wait for 3 seconds
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        final data = json.decode(response.body);
        _showAlertBanner(data['message']);
      }
    } catch (e) {
      _showAlertBanner('Internal server error');
    }
  }

  void _showAlertBanner(String message) {
    setState(() {
      _alertMessage = message;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _alertMessage = null;
      });
    });
  }

  void _showAlertBannerSussess(String message) async {
    setState(() {
      SussessMsg = message;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        SussessMsg = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0, // Hide the AppBar
      ),
      body: Column(
        children: [
          if (_alertMessage != null)
            AlertBanner(message: _alertMessage!),
          if (SussessMsg != null)
            SussessBanner(message: SussessMsg!),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Create your Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Fill in the details below to get started.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Username',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1ED760), // Cursor color
                      validator: (value) {
                        if (!_isUsernameInteracted) return null; // Show error only if interacted
                        if (value == null || value.isEmpty) {
                          return 'Enter your username';
                        }
                        if (!_validateUsername(value)) {
                          return 'Username must be alphabets & numbers only';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validateAndUpdate();
                      },
                      onTap: () {
                        setState(() {
                          _isUsernameInteracted = true;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: const Color(0xFF1ED760), // Cursor color
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9@._]'), // Allow alphanumeric, @, ., _
                        ),
                      ],
                      validator: (value) {
                        if (!_isEmailInteracted) return null; // Show error only if interacted
                        if (value == null || value.isEmpty) {
                          return 'Enter your email';
                        }
                        if (!_validateEmail(value)) {
                          return 'Enter a valid email address (e.g., username@gmail.com)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validateAndUpdate();
                      },
                      onTap: () {
                        setState(() {
                          _isEmailInteracted = true;
                        });
                      },
                    ),            
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible, // Control password visibility
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1ED760), // Cursor color
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4), // Limit to 4 digits
                        FilteringTextInputFormatter.digitsOnly, // Allow only digits
                      ],
                      validator: (value) {
                        if (!_isPasswordInteracted) return null; // Show error only if interacted
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length != 4) {
                          return 'Password must be 4 digits';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validateAndUpdate();
                      },
                      onTap: () {
                        setState(() {
                          _isPasswordInteracted = true;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    IntlPhoneField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(200, 58, 58, 60),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Phone Number',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1ED760),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        print(phone.completeNumber);  // Print complete number to check
                      },
                      onTap: () {
                        // Handle tap if necessary
                      },
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isButtonEnabled ? _handleRegister : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled ? const Color(0xFF1C8B39) : Colors.transparent, // Dark green when enabled
                        minimumSize: const Size(double.infinity, 50), // Set the width to be full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: _isButtonEnabled ? Colors.transparent : Colors.transparent, // No border color when disabled
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.green.withOpacity(0.2); // Light green gradient
                            }
                            return const Color(0xFF1C8B40); // Dark green color
                          },
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isButtonEnabled ? Colors.white : Colors.green[700], // Text color for button
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between button and text link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text(
                          'Already a user? Sign In ?',
                          style: TextStyle(fontSize: 15, color: Colors.green[700]),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      child: CustomPaint(
        painter: GradientPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        colors: [
          Color.fromRGBO(0, 0, 0, 0.75),
          Color.fromRGBO(0, 128, 0, 0.75),
          Colors.green,
        ],
        end: Alignment.center,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.0)
      ..quadraticBezierTo(size.width / 3, 0, size.width, size.height * 0.99)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}