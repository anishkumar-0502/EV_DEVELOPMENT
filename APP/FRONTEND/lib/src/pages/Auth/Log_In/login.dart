// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../utilities/User_Model/user.dart';
import '../../home.dart';
import '../Sign_Up/register.dart';
import '../../../utilities/Alert/alert_banner.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isEmailInteracted = false;
  bool _isPasswordInteracted = false;
  bool _isPasswordVisible = false;

  String? storedUser;
  String? _alertMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_emailListener);
    _passwordController.addListener(_updateButtonState);
    _retrieveUserData();
  }

  @override
  void dispose() {
    _emailController.removeListener(_emailListener);
    _passwordController.removeListener(_updateButtonState);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _retrieveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedUser = prefs.getString('user');
    });
  }

  void _emailListener() {
    String text = _emailController.text;
    int index = text.indexOf('.com');

    if (index != -1 && text.length > index + 4) {
      // If the length exceeds '.com', truncate any characters after '.com'
      _emailController.text = text.substring(0, index + 4);
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }
    _updateButtonState();
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@gmail\.com$');
    return emailRegex.hasMatch(value);
  }

  bool _isFormValid() {
    final form = _formKey.currentState;
    return form?.validate() ?? false;
  }

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/CheckLoginCredentials'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_id': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String username = responseData['data']['username'];
        int userId = responseData['data']['user_id'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', username);
        await prefs.setInt('userId', userId);
        await prefs.setString('email', email);

        Provider.of<UserData>(context, listen: false)
            .updateUserData(username, userId, email);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              username: username,
              userId: userId,
              email: email,
            ),
          ),
        );
      } else {
        final data = json.decode(response.body);
        _showAlertBanner(data['message'] ?? 'Login failed');
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

  void _updateButtonState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return storedUser != null
        ? HomePage(
      username: storedUser!,
      email: '',
    )
        : Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Welcome Back! Sign In to dive in?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enter your email and password to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
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
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: const Color(0xFF1ED760),
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
                  onTap: () {
                    setState(() {
                      _isEmailInteracted = true;
                    });
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
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
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  cursorColor: const Color(0xFF1ED760),
                  validator: (value) {
                    if (!_isPasswordInteracted) return null;
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length != 4) {
                      return 'Password must be exactly 4 digits';
                    }
                    return null;
                  },
                  onTap: () {
                    setState(() {
                      _isPasswordInteracted = true;
                    });
                  },
                ),
                const SizedBox(height:15),
                ElevatedButton(
                  onPressed: _isFormValid() ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid()
                        ? const Color(0xFF1C8B39)
                        : Colors.transparent, // Dark green when enabled
                    minimumSize: const Size(double.infinity, 50), // Full width button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ).copyWith(
                    backgroundColor:
                    MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.green
                              .withOpacity(0.2); // Light green gradient
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
                      color: _isFormValid()
                          ? Colors.white
                          : Colors.green[700], // Text color
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        "New User? Sign Up",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 20), // Extra margin at the bottom
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _alertMessage != null
          ? AlertBanner(
        message: _alertMessage!,
      )
          : null,
    );
  }
}
