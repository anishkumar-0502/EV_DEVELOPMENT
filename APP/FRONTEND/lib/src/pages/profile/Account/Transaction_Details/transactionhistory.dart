import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart'; // Import shimmer package

class TransactionHistoryPage extends StatefulWidget {
  final String username;
  final int? userId;

  const TransactionHistoryPage(
      {super.key, required this.username, this.userId});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<Map<String, dynamic>> transactionDetails = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
      isLoading = false; // Stop loading once data is set
    });
  }

  // Function to fetch transaction details
  void fetchTransactionDetails() async {
    String? username = widget.username;
    print(username);

    if (username.isEmpty) {
      print('Error: Username is null or empty');
      return;
    }

    print('Fetching transaction details for username: $username');

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.32:4444/wallet/getTransactionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> transactionData = data['value'];
          List<Map<String, dynamic>> transactions =
              transactionData.map((transaction) {
            return {
              'status': transaction['status'] ?? 'Unknown',
              'amount': transaction['amount'] ?? '0.00',
              'time': transaction['time'] ?? 'N/A',
            };
          }).toList();
          setTransactionDetails(transactions);
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

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedFilter == 'All') return transactionDetails;
    return transactionDetails
        .where((txn) => txn['status'] == selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // The main scrollable content below the fixed filter row
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width *
                  0.04), // Adjust padding based on screen size
              child: Column(
                children: [
                  const SizedBox(
                      height: 90), // Add space for the fixed filter row
                  // Transaction Details Widget wrapped inside a scrollable widget
                  isLoading
                      ? _buildShimmerCard()
                      : filteredTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05),
                                    child: Image.asset(
                                      'assets/Image/search.png', // Use the correct path to your asset
                                      width: MediaQuery.of(context).size.width *
                                          0.6, // Adjust image size based on screen width
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width *
                                      0.05), // Adjust padding
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    for (int index = 0;
                                        index < filteredTransactions.length;
                                        index++)
                                      Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
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
                                                        filteredTransactions[
                                                                    index]
                                                                ['status'] ??
                                                            'Unknown',
                                                        style: TextStyle(
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.05, // Adjust font size based on screen width
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        (() {
                                                          final timeString =
                                                              filteredTransactions[
                                                                      index]
                                                                  ['time'];
                                                          if (timeString !=
                                                                  null &&
                                                              timeString
                                                                  .isNotEmpty) {
                                                            try {
                                                              final dateTime =
                                                                  DateTime.parse(
                                                                          timeString)
                                                                      .toLocal();
                                                              return '${dateTime.day}-${dateTime.month}-${dateTime.year} at ${dateTime.hour}:${dateTime.minute}';
                                                            } catch (e) {
                                                              return 'Invalid date format';
                                                            }
                                                          } else {
                                                            return 'No Date Available';
                                                          }
                                                        })(),
                                                        style: TextStyle(
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.04, // Adjust font size based on screen width
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Conditional color for amount based on status
                                                Text(
                                                  '₹${filteredTransactions[index]['amount'] ?? '0.00'}',
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width *
                                                        0.05, // Adjust font size based on screen width
                                                    color: filteredTransactions[
                                                                    index]
                                                                ['status'] ==
                                                            'Deducted'
                                                        ? Colors
                                                            .red // Red color for debited transactions
                                                        : Colors
                                                            .green, // Green for other transactions
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (index !=
                                              filteredTransactions.length -
                                                  1) // Ensure divider is shown only for the first 5
                                            CustomGradientDivider(),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                ],
              ),
            ),
          ),
          // Fixed filter buttons row
          Positioned(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height *
                    0.02, // Adjust top padding based on screen height
                bottom: MediaQuery.of(context).size.height *
                    0.02, // Adjust bottom padding based on screen height
                left: MediaQuery.of(context).size.width *
                    0.05, // Adjust left padding based on screen width
                right: MediaQuery.of(context).size.width *
                    0.05, // Adjust right padding based on screen width
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double buttonWidth = constraints.maxWidth *
                      0.3; // Each filter takes 30% of the available width
                  double lineWidth = buttonWidth *
                      0.4; // Set the line width to be 60% of the button width
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(
                          16.0), // Set the border radius here
                    ),
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width *
                        0.04), // Adjust padding based on screen width
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 'All' Filter
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = 'All'; // Show all transactions
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'All',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.05, // Adjust font size based on screen width
                                  fontWeight: FontWeight.bold,
                                  color: selectedFilter == 'All'
                                      ? Colors.blueAccent
                                      : Colors
                                          .white70, // Change color if selected
                                ),
                              ),
                              // Line under the selected filter
                              if (selectedFilter == 'All')
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: lineWidth, // Smaller line width
                                  height: 2,
                                  color: Colors
                                      .blueAccent, // Color for the underline
                                ),
                            ],
                          ),
                        ),
                        // 'Credited' Filter
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter =
                                  'Credited'; // Show credited transactions
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Credited',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.05, // Adjust font size based on screen width
                                  fontWeight: FontWeight.bold,
                                  color: selectedFilter == 'Credited'
                                      ? Colors.green
                                      : Colors
                                          .white70, // Change color if selected
                                ),
                              ),
                              // Line under the selected filter
                              if (selectedFilter == 'Credited')
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: lineWidth, // Smaller line width
                                  height: 2,
                                  color:
                                      Colors.green, // Color for the underline
                                ),
                            ],
                          ),
                        ),
                        // 'Debited' Filter
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter =
                                  'Deducted'; // Show debited transactions
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Debited',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.05, // Adjust font size based on screen width
                                  fontWeight: FontWeight.bold,
                                  color: selectedFilter == 'Deducted'
                                      ? Colors.red
                                      : Colors
                                          .white70, // Change color if selected
                                ),
                              ),
                              // Line under the selected filter
                              if (selectedFilter == 'Deducted')
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: lineWidth, // Smaller line width
                                  height: 2,
                                  color: Colors.red, // Color for the underline
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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
