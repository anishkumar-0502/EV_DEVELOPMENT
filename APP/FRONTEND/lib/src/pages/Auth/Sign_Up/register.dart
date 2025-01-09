import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import '../Log_In/login.dart';
import '../../../utilities/Alert/alert_banner.dart'; // Import the alert banner

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
  bool _isLoading = false;
  String? successMsg;

  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateAndUpdate);
    _emailController.addListener(_validateAndUpdate);
    _phoneController.addListener(_validateAndUpdate);
    _passwordController.addListener(_validateAndUpdate);
    // _connectivity = Connectivity();
    // _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // _checkInitialConnection();
  }

// Future<void> _checkInitialConnection() async {
//   var result = await _connectivity.checkConnectivity();
//   _updateConnectionStatus(result);
// }

//   void _updateConnectionStatus(ConnectivityResult result) {
//   // Check for internet connection
//   if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
//     _dismissNoConnectionPage(); // Dismiss the error page if internet is restored
//   } else if (result == ConnectivityResult.none) {
//     _showNoConnectionPage(context); // Show the no internet error page
//   }
// }
// void _showNoConnectionPage(BuildContext context) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => InternetErrorPage(),
//     ),
//   );
// }

// void _dismissNoConnectionPage() {
//   if (Navigator.canPop(context)) {
//     Navigator.pop(context); // Pop the InternetErrorPage if it is active
//   }
// }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    // _connectivitySubscription.cancel();
    super.dispose();
  }

  void _validateAndUpdate() {
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
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return usernameRegex.hasMatch(value);
  }

  void _handleRegister() async {
    if (isSearching) return;
    final String username = _usernameController.text;
    final String email = _emailController.text;
    final String phone = _phoneController.text;
    final String password = _passwordController.text;

    setState(() {
      isSearching = true;
    });

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.32:4444/profile/RegisterNewUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email_id': email,
          'phone_no': phone,
          'password': password,
        }),
      );

      await Future.delayed(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _showAlertBannerSuccess("User successfully registered");
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          isSearching = false;
        });
        final data = json.decode(response.body);
        _showAlertBanner(data['message']);
      }
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      print('register $e');
      _showAlertBanner('Something went wrong, try again later');
    }
  }

  void _showAlertBanner(String message) {
    setState(() {
      _alertMessage = message;
      isSearching = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _alertMessage = null;
      });
    });
  }

  void _showAlertBannerSuccess(String message) async {
    setState(() {
      successMsg = message;
      isSearching = false;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        successMsg = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      showAlertLoading: isSearching,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: SingleChildScrollView(
          // Allows scrolling
          child: ConstrainedBox(
            // Ensures the content takes minimum space
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Center(
              // Center the content initially
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center content within Column
                    children: [
                      if (_alertMessage != null)
                        AlertBanner(
                            message: _alertMessage!), // Conditional rendering
                      if (successMsg != null)
                        SuccessBanner(
                            message: successMsg!), // Conditional rendering
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
                      _buildUsernameField(),
                      const SizedBox(height: 20),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 20),
                      _buildPhoneField(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                          child: Text(
                            'Already a user? Sign In ?',
                            style: TextStyle(
                                fontSize: 15, color: Colors.green[700]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(200, 58, 58, 60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        hintText: 'Username',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF1ED760),
      validator: (value) {
        if (!_isUsernameInteracted) return null;
        if (value == null || value.isEmpty) return 'Enter your username';
        if (!_validateUsername(value)) {
          return 'Username must be alphabets, numbers only & \nSpace not alowed';
        }
        return null;
      },
      onChanged: (value) => _validateAndUpdate(),
      onTap: () {
        setState(() {
          _isUsernameInteracted = true;
        });
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(200, 58, 58, 60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        hintText: 'Email',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF1ED760),
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(
            r'[a-z0-9@.]')), // Allows only lowercase letters, numbers, @, and .
      ],
      validator: (value) {
        if (!_isEmailInteracted) return null;
        if (value == null || value.isEmpty) {
          return 'Please enter email';
        }
        if (!_validateEmail(value)) {
          return 'Enter a valid Gmail address ending with .com';
        }
        return null;
      },
      onChanged: (value) => _validateAndUpdate(),
      onTap: () {
        setState(() {
          _isEmailInteracted = true;
        });
      },
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
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
      validator: (value) {
        if (value == null || value.number.isEmpty)
          return 'Enter your phone number';
        return null;
      },
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly, // Allows only numbers
      ],
      onChanged: (value) => _validateAndUpdate(),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(200, 58, 58, 60),
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
      cursorColor: const Color(0xFF1ED760),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4)
      ],
      validator: (value) {
        if (!_isPasswordInteracted) return null;
        if (value == null || value.isEmpty) return 'Enter your password';
        if (value.length != 4) return 'Password must be exactly 4 digits long';
        return null;
      },
      onChanged: (value) => _validateAndUpdate(),
      onTap: () {
        setState(() {
          _isPasswordInteracted = true;
        });
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isButtonEnabled
          ? () {
              // Close the keyboard when the button is pressed
              FocusScope.of(context).unfocus();

              // Call the register function
              _handleRegister();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isButtonEnabled
            ? const Color(0xFF1C8B39)
            : Colors.transparent, // Dark green when enabled
        minimumSize:
            const Size(double.infinity, 50), // Set the width to be full width
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: _isButtonEnabled
              ? Colors.transparent
              : Colors.transparent, // No border color when disabled
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
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class SuccessBanner extends StatelessWidget {
  final String message;

  const SuccessBanner({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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

class LoadingOverlay extends StatelessWidget {
  final bool showAlertLoading;
  final Widget child;

  LoadingOverlay({required this.showAlertLoading, required this.child});

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // color: Colors.black.withOpacity(0.75), // Transparent black background
      color: Colors.black.withOpacity(0.90), // Transparent black background
      child: Center(
        child: _AnimatedChargingIcon(), // Use the animated charging icon
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // The main content
        if (showAlertLoading)
          _buildLoadingIndicator(), // Use the animated loading indicator
      ],
    );
  }
}

class _AnimatedChargingIcon extends StatefulWidget {
  @override
  __AnimatedChargingIconState createState() => __AnimatedChargingIconState();
}

class __AnimatedChargingIconState extends State<_AnimatedChargingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward(); // Start the animation

    // Slide animation for moving the bolt icon vertically downwards
    _slideAnimation = Tween<double>(begin: -130.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Opacity animation for smooth fading in and out
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the animation to start from the top when it reaches the bottom
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value), // Move vertically
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.bolt_sharp, // Charging icon
        color: Colors.green, // Set the icon color
        size: 200, // Adjust the size as needed
      ),
    );
  }
}



// class InternetErrorPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // Fetch screen size
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // No Internet Icon
//               Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Icon(
//                     Icons.wifi,
//                     size: screenWidth * 0.30, // Adjust size dynamically
//                     color: Colors.blueGrey,
//                   ),
//                   Icon(
//                     Icons.close,
//                     size: screenWidth * 0.17, // Adjust size dynamically
//                     color: Colors.red,
//                   ),
//                 ],
//               ),
//               SizedBox(height: screenHeight * 0.05), // Adjust spacing
//               // Title
//               Text(
//                 "Ooops!",
//                 style: TextStyle(
//                   fontSize: screenWidth * 0.07, // Adjust font size dynamically
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white70,
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.02),
//               // Description
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
//                 child: Text(
//                   "It seems you are offline. Please check your internet connection and try again.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: screenWidth * 0.045, // Adjust font size dynamically
//                     color: Colors.white70,
//                   ),
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.06),
//               // Retry Button
//               ElevatedButton(
//                 onPressed: () async {
//                   // Check the internet connection status
//                   var connectivityResult = await Connectivity().checkConnectivity();

//                   if (connectivityResult == ConnectivityResult.mobile ||
//                       connectivityResult == ConnectivityResult.wifi) {
//                     // Internet is available, close the page
//                     Navigator.of(context).pop(); // Close the current page
//                   } else {
//                     // Internet is still not available, retry the connection check
//                     _showRetryMessage(context);
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: EdgeInsets.symmetric(
//                     horizontal: screenWidth * 0.1, // Adjust padding dynamically
//                     vertical: screenHeight * 0.02,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: Text(
//                   "Try Again",
//                   style: TextStyle(
//                     fontSize: screenWidth * 0.045, // Adjust font size dynamically
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.03),
//               // Close App Button
//               TextButton(
//                 onPressed: () {
//                   // Close the app (pop the current page)
//                   Navigator.of(context).pop();
//                 },
//                 child: Text(
//                   "Back to App",
//                   style: TextStyle(
//                     fontSize: screenWidth * 0.045, // Adjust font size dynamically
//                     color: Colors.green,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// void _showRetryMessage(BuildContext context) {
//   // Dismiss any existing snack bars before showing a new one
//   ScaffoldMessenger.of(context).clearSnackBars();
  
//   // Show the new retry message
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text('No internet connection. Please try again later.'),
//       duration: Duration(seconds: 2),
//     ),
//   );
// }

// }
