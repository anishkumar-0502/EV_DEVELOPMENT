import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;

class EditUserModal extends StatefulWidget {
  final String username;
  final String email;
  final int? userId;

  const EditUserModal({
    super.key,
    required this.username,
    required this.email,
    this.userId,
  });

  @override
  State<EditUserModal> createState() => _EditUserModalState();
}

class _EditUserModalState extends State<EditUserModal> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOldPasswordObscured = true; // For current password visibility
  bool _isNewPasswordObscured = true; // For new password visibility

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;

    if (widget.userId != null) {
      fetchUserDetails();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String value) {
    if (value.isEmpty) {
      return 'Phone number is required';
    } else if (value.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  String? _validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your old password';
    } else if (value.length != 4) {
      return 'Password must be exactly 4 digits';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length != 4 || !RegExp(r'^\d{4}$').hasMatch(value)) {
        return 'New password must be exactly 4 digits';
      }
    }
    return null;
  }

  bool get isFormValid {
    final phoneValid = _validatePhoneNumber(_phoneController.text) == null;
    final oldPasswordValid =
        _validateOldPassword(_oldPasswordController.text) == null;
    final newPasswordValid =
        _validateNewPassword(_newPasswordController.text) == null;
    return phoneValid && oldPasswordValid && newPasswordValid;
  }

  Future<void> fetchUserDetails() async {
    int? userId = widget.userId;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/profile/FetchUserProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          _phoneController.text = data['data']['phone_no'] is int
              ? data['data']['phone_no'].toString()
              : data['data']['phone_no'].toString();
        });
      } else {
        throw Exception('Error fetching user details');
      }
    } catch (error) {
      print('Error fetching user details: $error');
    }
  }

  void _handleUpdate() async {
    if (widget.userId == null) {
      _showAlertBanner('User ID is required');
      return;
    }

    final int userId = widget.userId!;
    final String username = _usernameController.text;
    final String phone = _phoneController.text;
    final String oldPassword = _oldPasswordController.text;
    final String? newPassword = _newPasswordController.text.isNotEmpty
        ? _newPasswordController.text
        : null; // Set newPassword to null if it's empty

    // Check if old and new passwords are the same
    if (oldPassword == newPassword && newPassword != null) {
      _showAlertBanner(
          'Current password and new password should not be the same');
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/profile/UpdateUserProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'username': username,
          'phone_no': phone,
          'current_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(20, 80, 20, 0),
          ),
        );
        Navigator.pop(context, 'refresh');
      } else if (response.statusCode == 401 ||
          response.statusCode == 400 ||
          response.statusCode == 500) {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['error_message'] ??
            "Failed to update! No changes are made";
        _showAlertBanner(errorMessage);
      } else if (response.statusCode == 404) {
        final errorMessage = responseData['error_message'] ??
            "Failed to update! No changes are made";
        _showAlertBanner(errorMessage);
      } else {
        final errorMessage = " No Changes !! Check your credentials";
        _showAlertBanner(errorMessage);
      }
    } catch (e) {
      _showAlertBanner('Something went wrong, try again later');
    }
  }

  void _showAlertBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                CustomGradientDivider(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              child: const CircleAvatar(
                                  radius: 50,
                                  child: Icon(Icons.person_add_outlined,
                                      color: Colors.white, size: 50)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                _usernameController
                                    .text, // Display the current username
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.email, // Display the current email
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _oldPasswordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "Current Password (Required)",
                              hintStyle: const TextStyle(color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isOldPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isOldPasswordObscured =
                                        !_isOldPasswordObscured;
                                  });
                                },
                              ),
                            ),
                            obscureText: _isOldPasswordObscured,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: _validateOldPassword,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText:
                                  "New Password (Only if you want to update)",
                              hintStyle: const TextStyle(color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isNewPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isNewPasswordObscured =
                                        !_isNewPasswordObscured;
                                  });
                                },
                              ),
                              errorText: _validateNewPassword(
                                  _newPasswordController.text),
                            ),
                            obscureText: _isNewPasswordObscured,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: _validateNewPassword,
                          ),
                          const SizedBox(height: 10),
                          IntlPhoneField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "Enter your phone no",
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            initialCountryCode: 'IN',
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // Only allow digits
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomGradientButton(
                            buttonText: 'Save Changes',
                            isEnabled: isFormValid,
                            onPressed: _handleUpdate,
                          ),
                        ],
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

class CustomGradientButton extends StatelessWidget {
  final String buttonText;
  final bool isEnabled;
  final VoidCallback onPressed;

  const CustomGradientButton({
    Key? key,
    required this.buttonText,
    required this.isEnabled,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
            : LinearGradient(colors: [Colors.grey, Colors.grey[400]!]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        onPressed: isEnabled ? onPressed : null,
        child: Text(
          buttonText,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.black54,
            fontSize: 16,
          ),
        ),
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
