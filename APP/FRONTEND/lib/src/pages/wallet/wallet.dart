// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../utilities/User_Model/user.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../profile/Account/Transaction_Details/transactionhistory.dart';

class WalletPage extends StatefulWidget {
  final String? username;
  final String? email;
  final int? userId;

  const WalletPage({super.key, this.username, this.email, this.userId});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool isLoading = true;
  bool isLoadingwallet = true;
  bool _isAlertVisible = false;
  double walletBalance = 0.0; // Placeholder for wallet balance
  List<Map<String, dynamic>> transactionDetails = [];
  List<dynamic> transactionData = [];
  bool showAlertLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWallet();
    fetchTransactionDetails();
  }

  void fetchWallet() async {
    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/FetchWalletBalance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['data'] != null) {
          setState(() {
            walletBalance = data['data'].toDouble();
            isLoadingwallet = false; // Data is loaded
          });
        } else {
          print('Error: balance field is null');
        }
      } else {
        throw Exception('Failed to load wallet balance');
      }
    } catch (error) {
      print('Error fetching wallet balance: $error');
    }
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: double.infinity, // Make it fill the available width
        height: 120, // Height of the shimmer effect
        margin: const EdgeInsets.symmetric(vertical: 10),

        color: const Color(0xFF0E0E0E), // Background color of the shimmer
      ),
    );
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const HelpModal(),
        );
      },
    );
  }

  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
      isLoading = false; // Stop loading once data is set
    });
  }

  void fetchTransactionDetails() async {
    String? username = widget.username;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/getTransactionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> transactionData = data['value'];
          List<Map<String, dynamic>> transactionDetailsList =
              transactionData.map((transaction) {
            return {
              'status': transaction['status'] ?? 'Unknown',
              'amount': transaction['amount'] ?? '0.00',
              'time': transaction['time'] ?? 'N/A',
            };
          }).toList();

          // Update the state to reflect the transaction details
          setTransactionDetails(transactionDetailsList);
        } else {
          print('Error: transaction details format is incorrect');
        }
      } else {
        print('Error: Failed to load transaction details');
        throw Exception('Failed to load transaction details');
      }
    } catch (error) {
      print('Error fetching transaction details: $error');
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade700,
      highlightColor: Colors.grey.shade500,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: List.generate(3, (index) => _buildShimmer()),
        ),
      ),
    );
  }

  void _openRightModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.9, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: TransactionHistoryPage(
              username: widget.username ??
                  'Default Username', // Provide a default value
              userId: widget.userId, // Pass the username correctly
            ),
          ),
        );
      },
    );
  }

  void showRechargeModel(double walletBalance, Function fetchWallet, Function fetchTransactionDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full-screen height adjustments
      isDismissible: true, // Allows dismissal by tapping outside
      enableDrag: true, // Allows dragging the bottom sheet
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;

        // Dynamically adjust height based on screen size
        final heightFactor = screenHeight < 600
            ? 0.6 // Use 60% for smaller screens
            : 0.8; // Use 70% for larger screens

        return FractionallySizedBox(
          heightFactor: heightFactor,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // Adjust for keyboard
            ),
            child: RechargeModel(
              walletBalance: walletBalance,
              fetchWallet: fetchWallet, // Pass fetchWallet callback directly
              fetchTransactionDetails: fetchTransactionDetails,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Set font size and button width based on screen size
    double headingFontSize = screenWidth > 600 ? 32 : 24;
    double subHeadingFontSize = screenWidth > 600 ? 20 : 16;
    double padding = screenWidth > 600 ? 20 : 15;
    bool sss = showAlertLoading;
    print(" showAlertLoading $sss");
    return LoadingOverlay(
      showAlertLoading: showAlertLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showHelpModal(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Stack(
            // Wrap the body with a Stack to position the help icon
            children: [
              // Main content
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  children: [
                    // Adjusted spacing from the top dynamically
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Power up, drive on.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize:
                                headingFontSize, // Dynamically adjusted font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                            width:
                                8), // Add some spacing between the text and the icon
                        const Icon(
                          Icons.speed, // Choose the relevant icon
                          color: Colors.white,
                          size: 30, // Adjust the size of the icon
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 3), // Spacing between heading and subheading
                    Text(
                      "Charge your wallet, power your journey!!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize:
                            subHeadingFontSize, // Dynamically adjusted font size
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20), // Spacing before the container

                    isLoadingwallet
                        ? _buildShimmerCard()
                        : Container(
                            padding: EdgeInsets.all(screenWidth > 400
                                ? 15
                                : 10), // Adjust padding dynamically
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(
                                  screenWidth > 400 ? 15 : 10), // Adjust radius
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: screenWidth > 400
                                      ? 10
                                      : 5, // Adjust blur for smaller screens
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: screenWidth > 400
                                      ? 1
                                      : 0.5, // Adjust spread
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // First Column: Wallet Icon in a Rounded Container
                                Container(
                                  width: screenWidth > 600
                                      ? 60
                                      : screenWidth > 400
                                          ? 50
                                          : 40,
                                  height: screenWidth > 600
                                      ? 60
                                      : screenWidth > 400
                                          ? 50
                                          : 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Colors.blueAccent.shade700
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: screenWidth > 600
                                        ? 40
                                        : screenWidth > 400
                                            ? 30
                                            : 25, // Adjust size
                                  ),
                                ),

                                // Second Column: Balance Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Total Balance",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: screenWidth > 400
                                              ? (screenWidth > 600
                                                  ? 16
                                                  : 14) // Adjust for larger screens
                                              : 12, // Smaller font for very small screens
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(
                                          height: screenWidth > 400
                                              ? 5
                                              : 3), // Adjust spacing for smaller screens
                                      Text(
                                        "₹ ${walletBalance.toStringAsFixed(2)}", // Display the balance
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: screenWidth > 400
                                              ? (screenWidth > 600
                                                  ? 24
                                                  : 20) // Adjust for larger screens
                                              : 18, // Smaller font for very small screens
                                          fontWeight: FontWeight.bold,
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Third Column: Add Credits Button
                                // Third Column: Add Credits Button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        showRechargeModel(
                                          walletBalance,
                                          fetchWallet, 
                                          fetchTransactionDetails,// Pass the callback function here
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth > 400
                                              ? 20
                                              : 15, // Adjust padding
                                          vertical: screenWidth > 400
                                              ? 12
                                              : 10, // Adjust padding
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              screenWidth > 400 ? 25 : 20),
                                        ),
                                        elevation: screenWidth > 400
                                            ? 8
                                            : 5, // Adjust elevation
                                        backgroundColor: Colors.transparent,
                                      ).copyWith(
                                        foregroundColor:
                                            WidgetStateProperty.all(
                                                Colors.white),
                                        shadowColor: WidgetStateProperty.all(
                                            Colors.transparent),
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.green,
                                              Colors.lightGreen
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: screenWidth > 600
                                                ? 200
                                                : 100, // Adjust width
                                            minHeight: screenWidth > 600
                                                ? 55
                                                : 45, // Adjust height
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Recharge now",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: screenWidth > 600
                                                  ? 16
                                                  : screenWidth > 400
                                                      ? 12
                                                      : 12, // Adjust font size
                                              fontWeight: FontWeight.bold,
                                              color: Colors
                                                  .white, // Ensure contrast with the background gradient
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),

                    // Display alert if balance is less than 100
                    if (_isAlertVisible && walletBalance < 100)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(top: 10),
                        color: Colors.redAccent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Warning: Your balance is below ₹100. Please add credits to continue!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _isAlertVisible =
                                      false; // Hide the alert when the button is clicked
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 15),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Payment history text with responsive font size
                              Row(
                                children: [
                                  Text(
                                    'Payment history',
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width >
                                              600
                                          ? 24
                                          : 22, // Adjust font size based on screen width
                                      fontWeight: FontWeight.normal,
                                      color: Colors
                                          .white, // Set text color for better visibility on dark background
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 8), // Space between text and icon
                                  Icon(
                                    Icons.history_outlined, // History icon
                                    size: MediaQuery.of(context).size.width >
                                            600
                                        ? 26
                                        : 22, // Adjust icon size based on screen width
                                    color: Colors.white, // Icon color
                                  ),
                                ],
                              ),
                              const Spacer(), // View all section with responsive font size and icon size
                              GestureDetector(
                                onTap: () => _openRightModal(context),
                                child: Row(
                                  children: [
                                    Text(
                                      'View all',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width >
                                                600
                                            ? 16
                                            : 14, // Adjust font size based on screen width
                                        color: Colors
                                            .blue, // Set text color for better visibility
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            4), // Space between text and icon
                                    Icon(
                                      Icons
                                          .arrow_forward_ios, // Arrow icon for 'view all'
                                      size: MediaQuery.of(context).size.width >
                                              600
                                          ? 18
                                          : 14, // Adjust icon size based on screen width
                                      color: Colors.blue, // Icon color
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.5),
                            child: isLoading
                                ? _buildShimmerCard()
                                : transactionDetails.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(20.0),
                                              child: Image.asset(
                                                'assets/Image/search.png', // Use the correct path to your asset
                                                width:
                                                    300, // Optional: Adjust image size
                                              ),
                                            ),
                                            const SizedBox(
                                                height:
                                                    10), // Add some space between the image and the text
                                            const Text(
                                              'No Payment History Found!', // Add your desired text
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors
                                                    .white70, // Optional: Adjust text color
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E1E),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            for (int index = 0;
                                                index <
                                                        transactionDetails
                                                            .length &&
                                                    index < 7;
                                                index++) // Limit to 6 items
                                              Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                transactionDetails[
                                                                            index]
                                                                        [
                                                                        'status'] ??
                                                                    'Unknown',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 20,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 5),
                                                              Text(
                                                                (() {
                                                                  final timeString =
                                                                      transactionDetails[
                                                                              index]
                                                                          [
                                                                          'time'];
                                                                  if (timeString !=
                                                                          null &&
                                                                      timeString
                                                                          .isNotEmpty) {
                                                                    try {
                                                                      final dateTime =
                                                                          DateTime.parse(timeString)
                                                                              .toLocal();
                                                                      return DateFormat(
                                                                              'MM/dd/yyyy, hh:mm:ss a')
                                                                          .format(
                                                                              dateTime);
                                                                    } catch (e) {
                                                                      print(
                                                                          'Error parsing date: $e');
                                                                    }
                                                                  }
                                                                  return 'N/A';
                                                                })(),
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .white60,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Text(
                                                          '${transactionDetails[index]['status'] == 'Credited' ? '+ ₹' : '- ₹'}${transactionDetails[index]['amount']}',
                                                          style: TextStyle(
                                                            fontSize: 19,
                                                            color: transactionDetails[
                                                                            index]
                                                                        [
                                                                        'status'] ==
                                                                    'Credited'
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (index !=
                                                          transactionDetails
                                                                  .length -
                                                              1 &&
                                                      index <
                                                          6) // Ensure divider is shown only for the first 5
                                                    CustomGradientDivider(),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Help icon at the top-right corner
            ],
          ),
        ),
      ),
    );
  }
}

class HelpModal extends StatelessWidget {
  const HelpModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simulate data loading condition
    bool isDataLoaded = true; // Change this to false to test shimmer loading

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wallet Help',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomGradientDivider(),
          const SizedBox(height: 16),

          // Conditional rendering: shimmer or content
          if (!isDataLoaded) ...[
          ] else ...[
            _buildSection(
              'How to use the Wallet',
              '1. Add Money: Use the "Add Money" section to recharge your wallet. Enter the amount and click "Add ₹".\n'
                  '2. Balance: View your current wallet balance and its level (Low, Medium, Full).\n'
                  '3. Transaction History: Check your recent transactions and their status (Credited, Debited).\n'
                  '4. Payment Methods: Use Razorpay for secure and quick transactions.\n'
                  '5. Max Limit: The wallet has a maximum limit of ₹10,000.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Need More Help?',
              'For further assistance, contact our support team at support@outdidtech.com.',
            ),
          ],
        ],
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
        height: screenHeight * 0.12, // Reduced height to make it smaller
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

  // Reusable method to build a section
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }
}

class RechargeModel extends StatefulWidget {
  final double walletBalance;
  final Function
      fetchWallet; // Change this to fetchWallet instead of onRechargeComplete
  final Function fetchTransactionDetails;

  RechargeModel(
      {required this.walletBalance,
      required this.fetchWallet,
      required this.fetchTransactionDetails}); // Update constructor

  @override
  _RechargeModelState createState() => _RechargeModelState();
}

class _RechargeModelState extends State<RechargeModel>
    with SingleTickerProviderStateMixin {
  TextEditingController _amountController = TextEditingController();
  String _errorMessage = '';
  bool showAlertLoading = false;
  late Animation<double> _scaleAnimation;
  bool _isPageVisible = false;
  late Razorpay _razorpay;
  double? _lastPaymentAmount; // To display error message
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize TextEditingController
    _amountController = TextEditingController();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Fade-in animation for the screen content
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isPageVisible = true;
      });
    });

    // Start the button scaling animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void showErrorDialog(BuildContext context, String message) {
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
              const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Text(
                    "Something went wrong",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
                color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Fetch username from the UserData provider
    UserData userData = Provider.of<UserData>(context, listen: false);
    String username =
        userData.username ?? 'Guest'; // Default to 'Guest' if username is null

    try {
      Map<String, dynamic> result = {
        'user': username, // Using the fetched username
        'RechargeAmt': _lastPaymentAmount, // Use the stored amount
        'transactionId': response.orderId,
        'responseCode': 'SUCCESS',
        'date_time': DateTime.now().toString(),
      };

      var output = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/savePayments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(result),
      );

      var responseData = json.decode(output.body);
      if (responseData == 1) {
        print('Payment successful!');
        widget.fetchWallet(); // Call the fetchWallet() method passed from the parent 
        widget.fetchTransactionDetails(); 
        _showPaymentSuccessModal(result);
      } else {
        print('Payment details not saved!');
      }
    } catch (error) {
      print('Error saving payment details: $error');
    }
  }

  void _showPaymentSuccessModal(Map<String, dynamic> paymentResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: PaymentSuccessModal(paymentResult: paymentResult),
        );
      },
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    UserData userData = Provider.of<UserData>(context, listen: false);
    String username = userData.username ?? 'Guest';
    Map<String, dynamic> paymentError = {
      'user': username,
      'RechargeAmt': _lastPaymentAmount, // Use the stored amount
      'message': response.message,
      'date_time': DateTime.now().toString(),
    };

    // setState(() {
    //   isLoading = true; // Start loading
    // });

    // Simulate a delay or asynchronous operation if needed
    Future.delayed(const Duration(milliseconds: 500), () {
      // setState(() {
      //   isLoading = false; // End loading
      // });
      widget.fetchWallet(); // Call the fetchWallet() method passed from the parent
      widget.fetchTransactionDetails(); 
      _showPaymentFailureModal(paymentError);
    });
  }

  void _showPaymentFailureModal(Map<String, dynamic> paymentError) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: PaymentFailureModal(paymentError: paymentError),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double maxAmount =
        10000 - widget.walletBalance; // Calculate max allowed balance
    maxAmount = double.parse(maxAmount.toStringAsFixed(2));


    // Handle payment process
    void handlePayment(double amount) async {
      // Get the user ID dynamically from UserData provider
      UserData userData = Provider.of<UserData>(context, listen: false);
      String username = userData.username ??
          'Guest'; // Fallback to 'Guest' if username is null
      const String currency = 'INR';
      int? userId = userData
          .userId; // Assuming userId is available in your UserData provider

      if (userId == null) {
        showErrorDialog(context, "User ID is missing.");
        return;
      }

      setState(() {
        showAlertLoading = true; // Show loading overlay
      });

      try {
        var response = await http.post(
          Uri.parse('http://122.166.210.142:4444/wallet/createOrder'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(
              {'amount': amount, 'currency': currency, 'userId': userId}),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          print("WalletResponse: $data");

          Map<String, dynamic> options = {
            'key': 'rzp_test_dcep4q6wzcVYmr',
            'amount': data['amount'],
            'currency': data['currency'],
            'name': "Charger Express",
            'description': 'Wallet Recharge',
            'order_id': data['id'],
            'prefill': {'name': username},
            'theme': {'color': '#3399cc'},
          };

          _lastPaymentAmount = amount;

          // Open the Razorpay payment gateway
          _razorpay.open(options);
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'];
          print("WalletResponse Error: $errorMessage");

          showErrorDialog(context, errorMessage);
        }
      } catch (error) {
        print('Error during payment: $error');
      } finally {
        setState(() {
          showAlertLoading = false;
        });
      }
    }

// Submit button action
    void onSubmit() {
      double amount = double.tryParse(_amountController.text) ?? 0.0;

      // Check if the entered amount is valid and does not exceed the wallet balance + 10,000
      if (amount > 0) {
        double totalAmount = widget.walletBalance +
            amount; // Add the entered amount to the wallet balance

        // Check if the total amount exceeds the maximum allowed limit (10,000)
        if (totalAmount <= 10000) {
          handlePayment(amount); // Call handlePayment on valid amount
        } else {
          setState(() {
            _errorMessage = "Maximum limit exceeded. Cannot exceed ₹10,000.";
          });
          // showErrorDialog(context, "Maximum limit exceeded. Cannot exceed ₹10,000.");
        }
      } else {
        setState(() {
          _errorMessage = "Please enter a valid amount";
        });
        // showErrorDialog(context, "Please enter a valid amount.");
      }
    }
return Scaffold(
  resizeToAvoidBottomInset: false, // Prevent resizing when the keyboard appears
  appBar: AppBar(
    backgroundColor: Colors.black,
    title: Text(
      'Recharge Wallet',
      style: TextStyle(
        color: Colors.white,
        fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 22,
        fontWeight: FontWeight.normal,
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  ),
  body: AnimatedOpacity(
    opacity: _isPageVisible ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 500),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomGradientDivider(), // Custom gradient divider
            const SizedBox(height: 16),
            const Text(
              'Your Current Balance:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              '₹${widget.walletBalance}',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Now you can recharge your wallet by entering an amount below:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
  TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Enter Amount',
              labelStyle: const TextStyle(color: Colors.white54),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              errorText: _errorMessage.isEmpty ? null : _errorMessage,
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal input
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Allow digits and decimal point
              LengthLimitingTextInputFormatter(7), // Limit input to 7 characters (4 digits + decimal + 2 digits)
            ],
            onChanged: (value) {
              setState(() {
                _errorMessage = ''; // Clear error message on input change
              });

              // Check if the value is empty or invalid
              if (value.isEmpty || value == '.' || value == '-') {
                return;
              }

              // Regex for validating the format: 4 digits before the decimal and 2 digits after
              RegExp regExp = RegExp(r'^\d{1,4}(\.\d{0,2})?$');
              if (!regExp.hasMatch(value)) {
                setState(() {
                  _errorMessage = 'Amount cannot exceed ₹$maxAmount. \nThe total wallet balance cannot exceed ₹10,000.';
                });
                return;
              }

              // Try parsing the input as a double
              double? enteredAmount = double.tryParse(value);

              // If valid, check if it's greater than the maximum allowed amount
              if (enteredAmount != null) {
                if (enteredAmount > maxAmount) {
                  setState(() {
                    _errorMessage = 'Amount cannot exceed ₹$maxAmount.';
                  });

                  // Reset to max allowed amount if the value exceeds the limit
                  _amountController.text = maxAmount.toStringAsFixed(2);
                  _amountController.selection = TextSelection.collapsed(offset: _amountController.text.length);
                }
              } else {
                setState(() {
                  _errorMessage = 'Invalid amount format.';
                });
              }
            },
            onEditingComplete: () {
              // Ensure proper formatting when editing is complete
              String currentValue = _amountController.text;
              if (currentValue.isNotEmpty && !currentValue.contains('.')) {
                // If no decimal point, add ".00"
                _amountController.text = '$currentValue.00';
                _amountController.selection = TextSelection.collapsed(offset: _amountController.text.length); // Move cursor to the end
              }
            },
          ),   const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedAmountButton(500.00),
                _buildAnimatedAmountButton(1000.00),
                _buildAnimatedAmountButton('Maximum'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.height * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                  backgroundColor: Colors.transparent,
                ).copyWith(
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      minHeight: 45,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Continue",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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

  // Method to build the animated amount buttons
  Widget _buildAnimatedAmountButton(dynamic amount) {
    String amountText =
        amount is double ? amount.toStringAsFixed(2) : amount.toString();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _errorMessage = "";

            if (amount == 'Maximum') {
              double maxAmount = 10000 - widget.walletBalance;
              _amountController.text = maxAmount.toStringAsFixed(2);
            } else {
              _amountController.text = amountText;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            amountText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessModal extends StatelessWidget {
  final Map<String, dynamic> paymentResult;

  const PaymentSuccessModal({super.key, required this.paymentResult});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if the data is available
    bool isDataLoaded = paymentResult.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Success',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                  Navigator.pop(context); // Close the modal
                },
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          CustomGradientDivider(),
          SizedBox(height: screenHeight * 0.02),

          // Shimmer effect or content
          if (!isDataLoaded) ...[
            _buildShimmer(screenHeight),
          ] else ...[
            Center(
              child: Text(
                '₹${(paymentResult['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: screenWidth * 0.12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green, size: screenWidth * 0.08),
                SizedBox(width: screenWidth * 0.02),
                const Text(
                  'Completed',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Payment should now be in ${paymentResult['user'] ?? ''}'s wallet.",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: screenHeight * 0.03),
            _buildListTile(
              Icons.account_circle,
              paymentResult['user'] ?? '',
              DateFormat('dd MMM yyyy, hh:mm a').format(
                DateTime.parse(
                    paymentResult['date_time'] ?? DateTime.now().toString()),
              ),
              screenWidth,
            ),
            SizedBox(height: screenHeight * 0.03),
            _buildListTile(
              Icons.receipt_long,
              'Transaction ID',
              paymentResult['transactionId'] ?? '',
              screenWidth,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer(double screenHeight) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade700,
            highlightColor: Colors.grey.shade500,
            child: Container(
              height: screenHeight * 0.06,
              width: double.infinity,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
      IconData icon, String title, String subtitle, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade600,
          radius: screenWidth * 0.06,
          child: Icon(icon, color: Colors.white, size: screenWidth * 0.07),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.white70),
        ),
      ),
    );
  }
}

class PaymentFailureModal extends StatelessWidget {
  final Map<String, dynamic> paymentError;

  const PaymentFailureModal({Key? key, required this.paymentError})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the data is available
    bool isDataLoaded = paymentError.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Failure',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                  Navigator.pop(context); // Close the modal
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomGradientDivider(),
          const SizedBox(height: 16),

          // Shimmer effect or loaded content
          if (!isDataLoaded) ...[
            _buildShimmer(),
          ] else ...[
            Center(
              child: Text(
                '₹${(paymentError['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 32),
                SizedBox(width: 8),
                Text(
                  'Failed',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Transaction failed unexpectedly',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _buildListTile(
              Icons.account_circle,
              paymentError['user'] ?? '',
              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(
                  paymentError['date_time'] ?? DateTime.now().toString())),
            ),
            const SizedBox(height: 24),
            _buildListTile(
              Icons.receipt_long,
              'Transaction ID',
              '${paymentError['transactionId'] ?? ' - '}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            height: 48,
            width: double.infinity,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            height: 48,
            width: double.infinity,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            height: 48,
            width: double.infinity,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800, // Background color for the ListTile
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade600,
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
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

class LoadingOverlay extends StatelessWidget {
  final bool showAlertLoading;
  final Widget child;

  const LoadingOverlay({required this.showAlertLoading, required this.child});

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
