import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../utilities/Seperater/gradientPainter.dart';
import 'package:shimmer/shimmer.dart';

class HistoryPage extends StatefulWidget {
  final String? username;
  final int? userId;

  const HistoryPage({super.key, this.username, this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String activeTab = 'history'; // Initial active tab
  List<Map<String, dynamic>> sessionDetails = [];
  bool isLoading = true; // Variable to track loading state

  @override
  void initState() {
    super.initState();
    fetchChargingSessionDetails();
  }

  // Function to set session details
  void setSessionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      sessionDetails = value;
      isLoading = false; // Set loading to false once data is loaded
    });
  }

  // Function to fetch charging session details
  void fetchChargingSessionDetails() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String? username = widget.username;

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.32:4444/session/getChargingSessionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> chargingSessionData = data['value'];
          List<Map<String, dynamic>> sessionDetails =
              chargingSessionData.cast<Map<String, dynamic>>();
          setState(() {
            this.sessionDetails = sessionDetails; // Update sessionDetails
            isLoading = false; // Stop loading
          });
        } else {
          throw Exception('Session details format is incorrect');
        }
      } else {
        throw Exception('Failed to load session details');
      }
    } catch (error) {
      print('Error fetching session details: $error');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }

  void _showSessionDetailsModal(
      BuildContext context, Map<String, dynamic> sessionData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow dynamic resizing for content
      isDismissible: true, // Allow dismissing by tapping outside
      enableDrag: true, // Allow dismissing by dragging
      backgroundColor: Colors.black, // Set modal background color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ), // Optional: Adds rounded corners for a modern look
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Handle keyboard overlap
          child: SessionDetailsModal(sessionData: sessionData),
        );
      },
    );
  }

// Function to show help modal
  void _showsessionhelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Ensures the modal height can be dynamically adjusted
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context)
              .viewInsets, // Padding for the keyboard (if needed)
          child: const HelpModal(), // Displaying the HelpModal widget
        );
      },
    );
  }

  double _calculateTotalEnergyUsage() {
    double totalEnergy = 0.0;

    for (var session in sessionDetails) {
      totalEnergy +=
          double.tryParse(session['unit_consummed'].toString()) ?? 0.0;
    }

    // Returning the total energy with 3 decimal places
    return double.parse(totalEnergy.toStringAsFixed(3));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showsessionhelp(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 15.5, top: 15.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Sessions',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Explore the details of your charging session',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          isLoading
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildShimmerCard(
                      context), // Display shimmer card while loading
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.all(23.0),
                      child: Column(
                        children: [
                          const Text(
                            'Total sessions',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            sessionDetails.length.toString(),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white70),
                          ), // Display total count of sessions
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Total energy usage',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${_calculateTotalEnergyUsage().toString()}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color:
                                          Colors.green), // The value in green
                                ),
                                const TextSpan(
                                  text: ' kWh',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          Colors.white70), // 'kWh' in white70
                                ),
                              ],
                            ),
                          ), // Display the total energy consumed with 'kWh' added, and the value in green
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Scrollbar(
                child: Column(
                  children: [
                    isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: _buildShimmerCard(
                                context), // Display shimmer card while loading
                          )
                        : sessionDetails.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
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
                                      'No Session History Found!', // Add your desired text
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors
                                            .white70, // Optional: Adjust text color
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 15.0, right: 20, bottom: 50),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        for (int index = 0;
                                            index < sessionDetails.length;
                                            index++)
                                          InkWell(
                                            onTap: () {
                                              _showSessionDetailsModal(context,
                                                  sessionDetails[index]);
                                            },
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
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
                                                              sessionDetails[
                                                                          index]
                                                                      [
                                                                      'charger_id']
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 17,
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
                                                              sessionDetails[index]
                                                                          [
                                                                          'start_time'] !=
                                                                      null
                                                                  ? DateFormat(
                                                                          'MM/dd/yyyy, hh:mm:ss a')
                                                                      .format(
                                                                      DateTime.parse(sessionDetails[index]
                                                                              [
                                                                              'start_time'])
                                                                          .toLocal(),
                                                                    )
                                                                  : "-",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .white60,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            ' Rs. ${sessionDetails[index]['price']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 19,
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Text(
                                                            '${sessionDetails[index]['unit_consummed']} kWh',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              color: Colors
                                                                  .white60,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (index !=
                                                    sessionDetails.length - 1)
                                                  CustomGradientDivider(),
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
              ),
            ),
          ),
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
}

class SessionDetailsModal extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionDetailsModal({Key? key, required this.sessionData})
      : super(key: key);

  String _getConnectorTypeName(int? connectorType) {
    switch (connectorType) {
      case 1:
        return 'Socket';
      case 2:
        return 'Gun';
      default:
        return 'Unknown';
    }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Scale functions based on both width and height
    double scaleFont(double fontSize) => fontSize * (screenWidth / 400);
    double scalePadding(double padding) => padding * (screenHeight / 800);
    double scaleIconSize(double size) => size * (screenWidth / 400);

    bool isLoading =
        sessionData.isEmpty; // Example condition, adapt based on your logic

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(scalePadding(16.0)),
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
                Text(
                  'Session Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scaleFont(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white, size: scaleIconSize(24)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: scalePadding(10)),
            CustomGradientDivider(),
            SizedBox(height: scalePadding(10)),

            // Show shimmer placeholders if data is loading
            if (isLoading)
              _buildShimmerCard(context)
            else
              Column(
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.ev_station,
                    title: 'Charger ID',
                    subtitle: '${sessionData['charger_id']}',
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.numbers,
                    title: 'Connector Id',
                    subtitle: '${sessionData['connector_id']}',
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.numbers,
                    title: 'Connector Type',
                    subtitle:
                        _getConnectorTypeName(sessionData['connector_type']),
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.numbers,
                    title: 'Session ID',
                    subtitle: '${sessionData['session_id']}',
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.access_time,
                    title: 'Start Time',
                    subtitle: sessionData['start_time'] != null
                        ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(
                            DateTime.parse(sessionData['start_time']).toLocal())
                        : "-",
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.stop,
                    title: 'Stop Time',
                    subtitle: sessionData['stop_time'] != null
                        ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(
                            DateTime.parse(sessionData['stop_time']).toLocal())
                        : "-",
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.electric_car,
                    title: 'Units Consumed',
                    subtitle: '${sessionData['unit_consummed']} kWh',
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: Icons.error,
                    title: 'Error',
                    subtitle: sessionData['Error'] ??
                        'No Error', // If 'error' is null, display 'No Error'
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                  _buildListTile(
                    context,
                    icon: null, // No icon, as we're using a custom CircleAvatar
                    title: 'Price',
                    subtitle: 'Rs. ${sessionData['price']}',
                    customIcon: CircleAvatar(
                      backgroundColor: Colors.grey.shade600,
                      child: Text(
                        '\u20B9', // Indian Rupee symbol
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: scaleFont(24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    scaleFont: scaleFont,
                    scaleIconSize: scaleIconSize,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

// Helper function to build ListTile
  Widget _buildListTile(
    BuildContext context, {
    required IconData? icon,
    required String title,
    required String subtitle,
    Widget? customIcon,
    required double Function(double) scaleFont,
    required double Function(double) scaleIconSize,
  }) {
    return Column(
      children: [
        ListTile(
          leading: customIcon ??
              CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: Icon(icon, color: Colors.white, size: scaleIconSize(24)),
              ),
          title: Text(
            title,
            style: TextStyle(fontSize: scaleFont(18), color: Colors.white),
          ),
          subtitle: Text(
            subtitle.isEmpty || subtitle == 'null' ? 'No Error' : subtitle,
            style: TextStyle(fontSize: scaleFont(16), color: Colors.white70),
          ),
        ),
        SizedBox(height: scaleFont(8)),
      ],
    );
  }
}

// Help modal widget
class HelpModal extends StatelessWidget {
  const HelpModal({super.key});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Help & Support',
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

          // Session History Section
          _buildHelpSection(
            context,
            title: 'Session History',
            content:
                'This page displays a list of your past charging sessions. You can tap on any session to view detailed information, including charger ID, session ID, start time, end time, units consumed, and price.',
          ),

          // Viewing Session Details Section
          _buildHelpSection(
            context,
            title: 'Viewing Session Details',
            content:
                'To view details of a specific session, tap on the session entry in the list. This will open a modal at the bottom of the screen displaying detailed information about the session.',
          ),

          // Help & Support Section
          _buildHelpSection(
            context,
            title: 'Help & Support',
            content:
                'For any further assistance or issues, please contact our support team @ support@outdidtech.com. You can find contact details in the app settings or visit our website for more help.',
          ),
        ],
      ),
    );
  }

  // Helper method to build each section
  Widget _buildHelpSection(BuildContext context,
      {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
