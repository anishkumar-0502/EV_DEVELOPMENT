import 'dart:convert';
import 'package:ev_app/src/utilities/Alert/alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../utilities/Seperater/gradientPainter.dart';

class WalletPage extends StatefulWidget {
  final String username;
  final int? userId;
    final String email;

  const WalletPage({super.key, required this.username, this.userId, required this.email});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Razorpay _razorpay;
  double? walletBalance;
  bool isLoading = true;
  bool showAlertLoading = false;

  double? _lastPaymentAmount; // Store the last payment amount
  final TextEditingController _amountController = TextEditingController(text: '500');
  String? _alertMessage; // Variable to hold the alert message
  String? _errorMessage;

  List<Map<String, dynamic>> transactionDetails = []; // Define transactionDetails

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchWallet(); // Fetch wallet balance when the page is initialized
    fetchTransactionDetails(); // Fetch transaction details
    _amountController.addListener(() {
      _validateAmount(); // Validate the amount and update the error message
    });
  }

  void _validateAmount() {
    setState(() {
      // Trigger the custom formatter to handle validation
      final formatter = CustomTextInputFormatter(
        _calculateRemainingBalance(),
            (String? error) {
          setState(() {
            _errorMessage = error;
          });
        },
      );
      formatter.formatEditUpdate(
        _amountController.value,
        TextEditingValue(text: _amountController.text),
      );
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.removeListener(_validateAmount);
    super.dispose();
  }

  // Method to set wallet balance
  void setWalletBalance(double balance) {
    setState(() {
      walletBalance = balance.toDouble(); // Convert integer to double
    });
  }

  // Function to fetch wallet balance
  void fetchWallet() async {
    int? userId = widget.userId;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/FetchWalletBalance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("dataaaa $data");
        if (data['data'] != null) {
          setState(() {
            walletBalance = data['data'].toDouble(); // Set wallet balance
            isLoading = false; // Data is loaded
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

  // Function to set transaction details
  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
    });
  }

  // Function to fetch transaction details
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
          List<Map<String, dynamic>> transactions = transactionData.map((transaction) {
            return {
              'status': transaction['status'],
              'amount': transaction['amount'],
              'time': transaction['time'],
            };
          }).toList();
          setTransactionDetails(transactions);
        } else {
          print('Error: transaction details format is incorrect');
        }
      } else {
        throw Exception('Failed to load transaction details');
      }
    } catch (error) {
      print('Error fetching transaction details: $error');
    }
  }

  void handlePayment(double amount) async {
    String? username = widget.username;
    const String currency = 'INR';
    int? user_Id= widget.userId;

    setState(() {
      showAlertLoading = true; // Show loading overlay
    });

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/createOrder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount, 'currency': currency , 'userId' : user_Id }),
      );
      await Future.delayed(const Duration(seconds: 2));
        var data = json.decode(response.body);
        print("dataa: $data");

        print("WalletResponse: $data");
      // Check if the response is successful
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("dataa: $data");
        ////LIVE
        // Map<String, dynamic> options = {
        //   'key': 'rzp_live_TFodb8l3ihW2nM',
        //   'amount': data['amount'],
        //   'currency': data['currency'],
        //   'name': 'EV Power',
        //   'description': 'Wallet Recharge',
        //   'order_id': data['id'],
        //   'prefill': {'name': username},
        //   'theme': {'color': '#3399cc'},
        // };
        
        //TEST
        Map<String, dynamic> options = {
          'key': 'rzp_test_dcep4q6wzcVYmr',
          'amount': data['amount'],
          'currency': data['currency'],
          'name': 'Anish kumar A',
          'description': 'Wallet Recharge',
          'order_id': data['id'],
          'prefill': {'name': username},
          'theme': {'color': '#3399cc'},
        };
        _lastPaymentAmount = amount; // Store the amount

        // Open the Razorpay payment gateway
        _razorpay.open(options);
      }else {
        // Handle non-200 responses here
        final errorData = json.decode(response.body);
        final errorDatas =  errorData['message'];
         print("WalletResponse ododod 2: $errorDatas");

        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      print('Error during payment: $error');
    } finally {
      setState(() {
        showAlertLoading = false; // Hide loading overlay after payment process
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
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    String? username = widget.username;

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      Map<String, dynamic> result = {
        'user': username,
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
        _showPaymentSuccessModal(result);

        setState(() {
          fetchWallet(); // Fetch wallet balance after successful payment
          fetchTransactionDetails(); // Fetch transaction details after successful payment
        });
      } else {
        print('Payment details not saved!');
      }
    } catch (error) {
      print('Error saving payment details: $error');
    } finally {
      setState(() {
        isLoading = false; // End loading
      });
    }
  }

void _showAlertBanner(String message) {
  setState(() {
    _alertMessage = message; // Set the alert message
  });

  // Clear the alert message after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    setState(() {
      _alertMessage = null; // Clear the alert message
    });
  });
}
  void _handlePaymentError(PaymentFailureResponse response) {
    String? username = widget.username;
    Map<String, dynamic> paymentError = {
      'user': username,
      'RechargeAmt': _lastPaymentAmount, // Use the stored amount
      'message': response.message,
      'date_time': DateTime.now().toString(),
    };

    setState(() {
      isLoading = true; // Start loading
    });

    // Simulate a delay or asynchronous operation if needed
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false; // End loading
      });
      _showPaymentFailureModal(paymentError);
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
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
          child: isLoading
              ? _buildShimmerCard(context) // Show shimmer effect while loading
              : PaymentSuccessModal(paymentResult: paymentResult),
        );
      },
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
        left: screenWidth * 0.05, // Move the shimmer card slightly to the right
        right: screenWidth * 0.02,
        top: screenHeight * 0.01,
      ),
      color: const Color(0xFF0E0E0E), // Background color of the shimmer
    ),
  );
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
          child: isLoading
              ? _buildShimmerCard(context) // Show shimmer effect while loading
              : PaymentFailureModal(paymentError: paymentError),
        );
      },
    );
  }

  double _calculateProgress() {
    const double maxLimit = 10000.0; // Updated max limit
    if (walletBalance != null && walletBalance! > 0) {
      return walletBalance! / maxLimit;
    }
    return 0.0;
  }

  String _getBalanceLevel() {
    double progress = _calculateProgress();
    if (progress < 0.33) {
      return 'Low';
    } else if (progress < 0.66) {
      return 'Medium';
    } else {
      return 'Full';
    }
  }

  Color _getBalanceColor() {
    double progress = _calculateProgress();
    if (progress < 0.33) {
      return Colors.red;
    } else if (progress < 0.66) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
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

  double _calculateRemainingBalance() {
    const double maxLimit = 10000.0; // Maximum wallet balance
    if (walletBalance != null) {
      return maxLimit - walletBalance!; // Remaining balance that can be added
    }
    return maxLimit;
  }
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return LoadingOverlay(
    showAlertLoading: showAlertLoading,
    child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHelpModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, // Adjust padding based on screen width
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Wallet',
              style: TextStyle(
                fontSize: screenWidth * 0.06, // Responsive font size
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Fast, one-click payments\nSeamless charging',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: screenHeight * 0.02,
                            width: screenWidth * 0.3,
                            color: Colors.white,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            children: [
                              Container(
                                height: screenHeight * 0.04,
                                width: screenWidth * 0.5,
                                color: Colors.white,
                              ),
                              const Spacer(),
                              Container(
                                height: screenHeight * 0.025,
                                width: screenWidth * 0.15,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Container(
                            height: screenHeight * 0.02,
                            width: screenWidth * 0.2,
                            color: Colors.white,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Container(
                            height: screenHeight * 0.01,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Text(
                              '₹${walletBalance?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenHeight * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: _getBalanceColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getBalanceLevel(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Max ₹10,000',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        if (walletBalance != null && walletBalance! < 100)
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Maintain min balance of ₹100 for optimal charging.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: screenHeight * 0.02),
                        LinearProgressIndicator(
                          value: walletBalance != null ? _calculateProgress() : 0,
                          color: Colors.orange,
                          backgroundColor: Colors.white12,
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),
              
const Text(
  'Add money',
  style: TextStyle(fontSize: 18, color: Colors.white),
),
SizedBox(height: screenHeight * 0.02), // Adjust height proportionally
Container(
  padding: EdgeInsets.symmetric(
    horizontal: screenWidth * 0.04, // Dynamic horizontal padding
    vertical: screenHeight * 0.015, // Dynamic vertical padding
  ),
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(screenWidth * 0.03), // Adjust radius proportionally
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter amount',
                hintStyle: const TextStyle(color: Colors.white54),
                errorText: _errorMessage,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                CustomTextInputFormatter(
                  _calculateRemainingBalance(),
                      (String? error) {
                    setState(() {
                      _errorMessage = error;
                    });
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white54),
            onPressed: () {
              _amountController.clear();
            },
          ),
        ],
      ),
      if (_alertMessage != null)
        Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.01), // Add some space above the banner
          child: AlertBanner(message: _alertMessage!),
        ),
    ],
  ),
),
              const SizedBox(height: 16),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08, // Adjust horizontal padding
          vertical: screenHeight * 0.02, // Adjust vertical padding
        ),
        backgroundColor: Colors.white12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02), // Adjust radius
        ),
      ),
      onPressed: () {
        _amountController.text = '100';
      },
      child: Text('₹ 100', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08, // Adjust horizontal padding
          vertical: screenHeight * 0.02, // Adjust vertical padding
        ),
        backgroundColor: Colors.white12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02), // Adjust radius
        ),
      ),
      onPressed: () {
        _amountController.text = '500';
      },
      child: Text('₹ 500', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08, // Adjust horizontal padding
          vertical: screenHeight * 0.02, // Adjust vertical padding
        ),
        backgroundColor: Colors.white12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02), // Adjust radius
        ),
      ),
      onPressed: () {
        _amountController.text = '1000';
      },
      child: Text('₹ 1000', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
    ),
  ],
),          const SizedBox(height: 16),
 
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.08, // Adjust horizontal padding
      vertical: screenHeight * 0.02, // Adjust vertical padding
    ),
    backgroundColor: Colors.white12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(screenWidth * 0.02), // Adjust radius
    ),
  ),
  onPressed: () {
    double remainingBalance = _calculateRemainingBalance(); // Calculate remaining balance
    _amountController.text = remainingBalance.toStringAsFixed(2); // Set the text to the remaining balance
  },
  child: Text(
    'Maximum',
    style: TextStyle(
      color: Colors.white,
      fontSize: screenWidth * 0.045, // Adjust font size
    ),
  ),
),

              const SizedBox(height: 24),

ElevatedButton(
  onPressed: walletBalance != null && walletBalance! >= 10000
      ? null
      : () {
          double amount = double.tryParse(_amountController.text) ?? 0.0;
          double totalBalance = (walletBalance ?? 0.0) + amount;
          double remainingBalance = 10000 - (walletBalance ?? 0.0);

          if (amount <= 0 || totalBalance > 10000) {
            showDialog(
              context: context,
              barrierDismissible: false, // Prevent dismissing by tapping outside
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 25),
                          SizedBox(width: 10),
                          Text(
                            "Error",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomGradientDivider(), // Custom gradient divider
                    ],
                  ),
                  content: Text(
                    _amountController.text.isEmpty
                        ? 'Your field is empty! Kindly enter a valid amount.'
                        : 'The total balance after adding this amount exceeds the maximum limit of ₹10,000. You can only add up to ₹${remainingBalance.toStringAsFixed(2)}.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
          } else {
            handlePayment(amount);
          }
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: walletBalance != null && walletBalance! >= 10000
        ? Colors.transparent
        : const Color(0xFF1C8B39),
    minimumSize: Size(screenWidth * 0.9, screenHeight * 0.07), // Full width button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
    ),
    elevation: 0,
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.green.withOpacity(0.2);
        }
        return walletBalance != null && walletBalance! >= 10000
            ? Colors.grey
            : const Color(0xFF1C8B39);
      },
    ),
  ),
  child: Text(
    walletBalance != null && walletBalance! >= 10000
        ? 'Limit Reached'
        : 'Add ₹${_amountController.text}',
    style: TextStyle(
      fontSize: screenWidth * 0.045,
      fontWeight: FontWeight.bold,
      color: walletBalance != null && walletBalance! >= 10000
          ? Colors.grey
          : Colors.white,
    ),
  ),
),
              const SizedBox(height: 24),
            ],
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
                onPressed: () => Navigator.of(context).pop(),
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
                Icon(Icons.check_circle, color: Colors.green, size: screenWidth * 0.08),
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
                DateTime.parse(paymentResult['date_time'] ?? DateTime.now().toString()),
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

  Widget _buildListTile(IconData icon, String title, String subtitle, double screenWidth) {
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

  const PaymentFailureModal({Key? key, required this.paymentError}) : super(key: key);

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
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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

          // Shimmer effect or loaded content
          if (!isDataLoaded) ...[
            _buildShimmer(),
          ] else ...[
            Center(
              child: Text(
                '₹${(paymentError['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
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
              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(paymentError['date_time'] ?? DateTime.now().toString())),
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
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
            _buildShimmerCard(context),
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
        left: screenWidth * 0.05, // Move the shimmer card slightly to the right
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
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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



class LimitRangeTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  LimitRangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    // Remove any commas
    newText = newText.replaceAll(',', '');

    // Check if the input is a valid double
    double? newValueAsDouble = double.tryParse(newText);

    if (newValueAsDouble == null) {
      // Return oldValue if the new value is not a valid double
      return oldValue;
    }

    // Check if the new value is within the specified range
    if (newValueAsDouble < min || newValueAsDouble > max) {
      return oldValue;
    }

    // Return the new value if it's within the range
    return newValue.copyWith(text: newText);
  }
}


class CustomTextInputFormatter extends TextInputFormatter {
  final double remainingBalance;
  final void Function(String?) onValidationError;

  CustomTextInputFormatter(this.remainingBalance, this.onValidationError);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Allow empty input
    if (newText.isEmpty) {
      onValidationError(null);
      return newValue;
    }

    // Allow only valid input with up to two decimal places
    final RegExp regex = RegExp(r'^\d*\.?\d{0,2}$');
    if (!regex.hasMatch(newText)) {
      return oldValue; // Revert to old value if the input is invalid
    }

    // Parse the new value as double
    double? newValueDouble = double.tryParse(newText);

    // If new value exceeds the remaining balance, show error and revert to old value
    if (newValueDouble != null && newValueDouble > remainingBalance) {
      onValidationError("Enter a value up to ₹${remainingBalance.toStringAsFixed(2)}.Total Limit is \n₹10,000.");
      return oldValue;
    } else {
      // Clear error if valid
      onValidationError(null);
    }

    return newValue; // Return the new value if all validations pass
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

class ErrorDetails extends StatelessWidget {
  final String? errorData;
  final String username;
  final int? userId;
  final String email;
  final Map<String, dynamic>? selectedLocation; // Accept the selected location

  const ErrorDetails(
      {Key? key,
      required this.errorData,
      required this.username,
      this.userId,
      required this.email,
      this.selectedLocation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Error Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  // Use Navigator.push to add the new page without disrupting other content
                  Navigator.pop(context);
                  // Close the QR code scanner page and return to the Home Page
                },
              ),
            ],
          ),
          const SizedBox(
              height: 10), // Add spacing between the header and the green line
          CustomGradientDivider(),
          const SizedBox(
              height: 20), // Add spacing between the green line and the icon
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 70,
          ),
          const SizedBox(height: 20),
          Text(
            errorData ?? 'An unknown error occurred.',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
