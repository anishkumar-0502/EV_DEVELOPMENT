import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StopCharger extends StatefulWidget {
  final int? userId;

  const StopCharger({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _StopChargerState createState() => _StopChargerState();
}

class _StopChargerState extends State<StopCharger> {
  bool lightTime = false;
  bool lightUnit = false;
  bool lightPrice = false;
  String? UserTimeVal;
  String? UserUnitVal;
  String? UserPriceVal;
  final List<TextEditingController> _controllers =
      List.generate(3, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  void fetchUserDetails() async {
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/profile/FetchUserProfile'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        print('API Response: ${response.body}');

        setState(() {
          lightTime = data['data']['autostop_time_isChecked'] ?? false;
          lightUnit = data['data']['autostop_unit_isChecked'] ?? false;
          lightPrice = data['data']['autostop_price_isChecked'] ?? false;

          UserTimeVal = data['data']['autostop_time']?.toString() ?? '';
          UserUnitVal = data['data']['autostop_unit']?.toString() ?? '';
          UserPriceVal = data['data']['autostop_price']?.toString() ?? '';

          _controllers[0].text = UserTimeVal ?? "0";
          _controllers[1].text = UserUnitVal ?? "0";
          _controllers[2].text = UserPriceVal ?? "0";
        });
      } else {
        _showAlertBanner('Error fetching user details');
      }
    } catch (error) {
      print('Error fetching user details: $error');
      _showAlertBanner('Something went wrong, try again later ');
    }
  }

  void handleUpdate() async {
    // Assign default value of "0" if the field is empty
    UserTimeVal = UserTimeVal?.isEmpty ?? true ? '0' : UserTimeVal;
    UserUnitVal = UserUnitVal?.isEmpty ?? true ? '0' : UserUnitVal;
    UserPriceVal = UserPriceVal?.isEmpty ?? true ? '0' : UserPriceVal;

    Map<String, dynamic> updatedData = {
      'updateUserTimeVal': UserTimeVal ?? "0",
      'updateUserUnitVal': UserUnitVal ?? "0",
      'updateUserPriceVal': UserPriceVal ?? "0",
      'updateUserTime_isChecked': lightTime,
      'updateUserUnit_isChecked': lightUnit,
      'updateUserPrice_isChecked': lightPrice,
      "user_id": widget.userId,
    };

    try {
      final response = await http.post(
        Uri.parse(
            'http://122.166.210.142:4444/charging/UpdateAutoStopSettings'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedData),
      );

      print('Update Response: ${response.body}');

      if (response.statusCode == 200) {
        _showAlertBanner('AutoStop settings updated successfully.',
            backgroundColor: Colors.green);
        Navigator.pop(context);
      } else {
        _showAlertBanner(
            'No Changes! ,Error updating settings, please check the credentials.');
      }
    } catch (error) {
      print('Error:\n$error');
      _showAlertBanner('Something went wrong, try again later ');
    }
  }

  void _showAlertBanner(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust based on screen size
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(isSmallScreen
                      ? 8.0
                      : 16.0), // Adjust padding for small screens
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen
                                ? 4.0
                                : 8.0), // Adjust horizontal padding
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen
                                ? 20
                                : 25, // Adjust font size for small screens
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
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen
                    ? 8.0
                    : 16.0), // Adjust padding for small screens
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Auto Stop Based on:',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    settingContainer(
                      lightTime,
                      'Time',
                      _controllers[0],
                      UserTimeVal,
                      (value) {
                        setState(() {
                          UserTimeVal = value;
                        });
                      },
                      (newValue) {
                        setState(() {
                          lightTime = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    settingContainer(
                      lightUnit,
                      'Unit',
                      _controllers[1],
                      UserUnitVal,
                      (value) {
                        setState(() {
                          UserUnitVal = value;
                        });
                      },
                      (newValue) {
                        setState(() {
                          lightUnit = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    settingContainer(
                      lightPrice,
                      'Price',
                      _controllers[2],
                      UserPriceVal,
                      (value) {
                        setState(() {
                          UserPriceVal = value;
                        });
                      },
                      (newValue) {
                        setState(() {
                          lightPrice = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomGradientButton(
                      buttonText: 'Save Changes',
                      onPressed: handleUpdate,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container settingContainer(
      bool lightValue,
      String label,
      TextEditingController controller,
      String? value,
      ValueChanged<String> onChanged,
      ValueChanged<bool> onSwitchChanged) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(
          isSmallScreen ? 12.0 : 16.0), // Adjust padding for small screens
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal:
                isSmallScreen ? 12.0 : 16.0), // Adjust horizontal padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Switch(
              value: lightValue,
              onChanged: onSwitchChanged,
              activeTrackColor: Colors.green,
              activeColor: Colors.white,
              inactiveTrackColor: const Color.fromARGB(255, 39, 39, 39),
              inactiveThumbColor: Colors.white,
            ),
            Text(
              '$label      ',
              style: TextStyle(
                fontSize: isSmallScreen
                    ? 20
                    : 25, // Adjust font size for small screens
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: isSmallScreen
                  ? 50
                  : 60, // Adjust input field width for small screens
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: label == 'Unit'
                    ? TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  if (label == 'Time') ...[
                    FilteringTextInputFormatter
                        .digitsOnly, // Only digits allowed
                    LengthLimitingTextInputFormatter(5), // Max length for Time
                  ],
                  if (label == 'Unit')
                    FilteringTextInputFormatter.allow(RegExp(
                        r'^\d{0,4}(\.\d{0,2})?$')), // Decimal with up to 4 digits before and 2 digits after the decimal
                  if (label == 'Price')
                    FilteringTextInputFormatter.allow(RegExp(
                        r'^\d{0,4}(\.\d{0,2})?$')), // Decimal with up to 4 digits before and 2 digits after the decimal
                ],
                onChanged: (val) {
                  onChanged(val);
                  if (label == 'Price' &&
                      int.tryParse(val) != null &&
                      int.parse(val) > 10000) {
                    controller.text = '10000';
                    controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length));
                  }
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ),
            Text(
              label == 'Price' ? 'INR' : (label == 'Time' ? "min's" : 'unit'),
              style: TextStyle(
                fontSize: isSmallScreen
                    ? 15
                    : 17, // Adjust font size for small screens
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.2, // Adjust this to change the overall height of the divider
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
          Color.fromRGBO(0, 0, 0, 0.75), // Darker black shade
          Color.fromRGBO(0, 128, 0, 0.75), // Darker green for blending
          Colors.green, // Green color in the middle
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

class CustomGradientButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const CustomGradientButton({
    Key? key,
    required this.buttonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ).copyWith(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.resolveWith(
          (states) => Colors.transparent,
        ),
      ),
      onPressed: onPressed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 200, maxHeight: 50),
          alignment: Alignment.center,
          child: Text(
            buttonText,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
