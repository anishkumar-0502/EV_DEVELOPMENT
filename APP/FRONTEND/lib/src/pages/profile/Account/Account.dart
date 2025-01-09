import 'package:flutter/material.dart';
import 'Transaction_Details/transactionhistory.dart';
import '../../Auth/Log_In/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../utilities/User_Model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  final String username;
  final int? userId;
  final String? email;

  const AccountPage(
      {super.key, required this.username, this.userId, this.email});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoading = false;

  void _showTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.7, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: TransactionHistoryPage(
              username: widget.username, // Pass the username correctly
            ),
          ),
        );
      },
    );
  }

  void _showrfidmodel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.8, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Rfidpage(
              username: widget.username,
              email: widget.email, // Pass the username correctly
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccount() {
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
                  const Icon(Icons.warning, color: Colors.yellow, size: 25),
                  const SizedBox(width: 10),
                  const Text(
                    "Are You Sure?",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: const Text(
            "Once deleted, you won't be able to recover your account. Confirm to delete?",
            style: TextStyle(
                color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                deleteAccount();
                Navigator.of(context).pop(); // Call the deleteAccount function
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    Provider.of<UserData>(context, listen: false).clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void deleteAccount() async {
    String? username = widget.username;
    int? userId = widget.userId;

    if (userId == null) {
      _showAlertBanner('User ID is required');
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true; // Show loading overlay
    });

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.32:4444/profile/DeleteAccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'username': username,
          'status': false,
        }),
      );

      if (response.statusCode == 200) {
        // Show loading overlay for 3 seconds
        await Future.delayed(Duration(seconds: 3));

        // Show success dialog
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
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 25),
                      const SizedBox(width: 10),
                      const Text(
                        "Account Deleted",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomGradientDivider(), // Custom gradient divider
                ],
              ),
              content: const Text(
                "Your account has been successfully deleted.",
                style: TextStyle(
                    color: Colors.white70), // Adjusted text color for contrast
              ),
            );
          },
        );

        // Call the logout function after closing the dialog
        Future.delayed(Duration(seconds: 2), () {
          _logout();
        });
      } else if (response.statusCode == 401 ||
          response.statusCode == 400 ||
          response.statusCode == 500) {
        final responseData = jsonDecode(response.body);
        final errorMessage =
            responseData['error_message'] ?? "Failed to delete account!";
        if (mounted) _showAlertBanner(errorMessage);
      } else {
        final errorMessage = "Unexpected error occurred. Please try again.";
        if (mounted) _showAlertBanner(errorMessage);
      }
    } catch (e) {
      if (mounted) _showAlertBanner('Something went wrong, try again later');
      print(e);
    } finally {
      // Hide loading overlay regardless of success or error
      setState(() {
        _isLoading = false;
      });
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
    return LoadingOverlay(
      showAlertLoading: _isLoading,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.green.shade700.withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomLeft,
              stops: [0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                CustomGradientDivider(),
                GestureDetector(
                  onTap: _showTransactionModal, // Use function reference
                  child: Container(
                    margin: const EdgeInsets.only(
                        top: 20.0, left: 15, right: 15, bottom: 10),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E).withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.currency_rupee, color: Colors.white70),
                        SizedBox(width: 20),
                        Text(
                          'Payment Details',
                          style: TextStyle(color: Colors.white70, fontSize: 17),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showrfidmodel, // Use function reference
                  child: Container(
                    margin:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E).withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.account_circle_outlined,
                            color: Colors.white70),
                        SizedBox(width: 20),
                        Text(
                          'Manage RFID',
                          style: TextStyle(color: Colors.white70, fontSize: 17),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showDeleteAccount, // Use function reference
                  child: Container(
                    margin:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E).withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 20),
                        Text(
                          'Delete account',
                          style: TextStyle(color: Colors.red, fontSize: 17),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Rfidpage extends StatefulWidget {
  final String username;
  final String? email;

  const Rfidpage({Key? key, required this.username, this.email})
      : super(key: key);

  @override
  _RfidpageState createState() => _RfidpageState();
}

class _RfidpageState extends State<Rfidpage> {
  String? tagId;
  String? tagIdExpiryDate;
  bool? tagIdAssigned;
  bool? status;
  bool isLoading = true; // To track loading state
  String errorMessage = ''; // To show any error messages

  @override
  void initState() {
    super.initState();
    fetchrfid(); // Call the fetchrfid method on init
  }

  Future<void> fetchrfid() async {
    print('Fetching RFID details for email ID: ${widget.email}');

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.32:4444/profile/fetchRFID'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_id': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);

        setState(() {
          // Update the state with the response data
          tagId = data['data']['tag_id'];
          tagIdExpiryDate = data['data']['tag_id_expiry_date'];
          status = data['data']['status'];
          isLoading = false; // Set loading to false after data is fetched
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Not yet assigned';
          isLoading = false; // Set loading to false even on error
        });
        print('Not yet assigned');
      } else {
        throw Exception('Error fetching user details');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error fetching user details';
        isLoading = false; // Set loading to false on error
      });
      print('Error fetching user details catch: $error');
    }
  }

  // Function to format the date with AM/PM
  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    // Parse the input date string
    DateTime dateTime = DateTime.parse(dateString);

    // Convert to IST by adding 5 hours and 30 minutes
    DateTime istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));

    // Format the date in the desired format: dd/MM/yyyy, hh:mm:ss a
    return DateFormat('dd/MM/yyyy, hh:mm:ss a').format(istDateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage RFID', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomGradientDivider(),
              SizedBox(height: screenHeight * 0.02), // Responsive space
              Center(
                child: Text(
                  "Let’s take a look at your RFID card details!",
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // Responsive font size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Responsive space
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04), // Respo

                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                        1, // Maintain square aspect ratio (512x512 image)
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10), // Optional rounded corners
                      child: Image.asset(
                        'assets/Image/rfidcard.png', // Use the correct path to your asset
                        fit: BoxFit.contain, // Dynamically scale the image
                      ),
                    ),
                  ),
                ),
              ),
              // Space between image and other content

              // Show shimmer effect while fetching data
              if (isLoading)
                Center(child: _buildShimmerCard(context))
              else if (errorMessage.isNotEmpty)
                Center(
                  child: Container(
                    width: screenWidth * 0.8, // Responsive width
                    padding: EdgeInsets.all(
                        screenWidth * 0.04), // Responsive padding
                    margin: EdgeInsets.only(
                        bottom: screenHeight * 0.02), // Responsive margin
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E).withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenWidth * 0.05, // Responsive font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                Center(
                  child: Container(
                    padding: EdgeInsets.all(
                        screenWidth * 0.04), // Responsive padding
                    margin: EdgeInsets.only(
                        bottom: screenHeight * 0.02), // Responsive margin
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E).withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            '📋 RFID Information',
                            style: TextStyle(
                              fontSize:
                                  screenWidth * 0.045, // Responsive font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: screenHeight * 0.02), // Responsive space
                        CustomGradientDivider(),
                        SizedBox(
                            height: screenHeight * 0.02), // Responsive space
                        Padding(
                          padding: EdgeInsets.only(
                              left: screenWidth * 0.04,
                              top: screenHeight * 0.02,
                              bottom: screenHeight * 0.01),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'RFID Name: ',
                                    style: TextStyle(
                                      fontSize: screenWidth *
                                          0.045, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    '$tagId',
                                    style: TextStyle(
                                        fontSize: screenWidth *
                                            0.045), // Responsive font size
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Row(
                                children: [
                                  Text(
                                    'Expiry Date: ',
                                    style: TextStyle(
                                      fontSize: screenWidth *
                                          0.045, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    '${formatDate(tagIdExpiryDate)}',
                                    style: TextStyle(
                                        fontSize: screenWidth *
                                            0.045), // Responsive font size
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.045, // Responsive font size
                                    color: Colors.white,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: status == true
                                          ? 'Active'
                                          : 'Inactive',
                                      style: TextStyle(
                                        color: status == true
                                            ? Colors.green
                                            : Colors.red, // Status color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align the text and icon
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        right: screenWidth *
                            0.02), // Responsive space between icon and text
                    child: Icon(Icons.lightbulb_outline,
                        color: Colors.yellow, size: screenWidth * 0.05),
                  ),
                  Expanded(
                    // Ensure the text wraps correctly
                    child: Text(
                      'Minimum wallet balance should be maintained to access RFID card',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04, // Responsive font size
                        color: Colors.white70,
                        height: 1.5, // Better readability
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Shimmer loading card widget
  Widget _buildShimmerCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: screenWidth * 0.9, // Reduced width to make it smaller
        height: screenHeight * 0.9, // Reduced height to make it smaller
        margin: EdgeInsets.only(
          left:
              screenWidth * 0.05, // Move the shimmer card slightly to the right
          right: screenWidth * 0.02,
          top: screenHeight * 0.01,
        ),
        color: const Color(0xFF0E0E0E), // Background color of the shimmer
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
