import 'dart:convert';
import 'package:ev_app/src/pages/Charging/charging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package for launching URLs
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;

class ChargerConnectorPage extends StatefulWidget {
  final String address;
  final int? userId;
  final LatLng position;
  final String username; // Make the username parameter nullable
  final String email;

  const ChargerConnectorPage({
    required this.address,
    super.key,
    required this.position,
    this.userId,
    required this.username,
    required this.email,
  });

  @override
  _ChargerConnectorPageState createState() => _ChargerConnectorPageState();
}

class _ChargerConnectorPageState extends State<ChargerConnectorPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late String mapStyle; // Declare the mapStyle variable
  List<Map<String, dynamic>> availableChargers =
      []; // List to store multiple chargers
  bool isLoading = true;
  String searchChargerID = '';
  List recentSessions = [];
  GoogleMapController? mapController;
  bool isSearching = false;
  bool areMapButtonsEnabled = false;
  bool isChargerAvailable = false; // Flag to track if any charger is available
  static const String apiKey = 'AIzaSyCwyCo-jhRnxEo55neAZI8cCbVbdwLtmJ8';
  Map<String, String> _addressCache = {};
  List<String> chargerIdsList = [];
  // Declare charger at the class level
  Map<String, dynamic> charger = {
    'charger_id': '',
    'charger_type': '',
    'last_used_time': '',
    'unit_price': 0.0,
    "status": '',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Set the initial index to 0 for the "Charger" tab
    _currentIndex = 0; // Active state for the first tab
    fetchAllChargers();
    _loadMapStyle(); // Load the map style when the page is initialized
  }

  Future<void> _loadMapStyle() async {
    mapStyle = await rootBundle.loadString('assets/Map/map.json');
    setState(() {}); // Call setState to update the UI after loading the style
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void showErrorDialog(BuildContext context, String message) {
    setState(() {
      isSearching = false;
      isLoading = false; // Set loading to false on error
    });
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

  Future<String> _getPlaceName(LatLng position, String chargerId) async {
    // Check if the address is already cached
    if (_addressCache.containsKey(chargerId)) {
      return _addressCache[chargerId]!;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        String fetchedAddress = data['results'][0]['formatted_address'];
        // Store the fetched address in the cache
        _addressCache[chargerId] = fetchedAddress;
        return fetchedAddress;
      } else {
        return "Unknown Location";
      }
    } else {
      throw Exception('Failed to fetch place name');
    }
  }

  Future<void> fetchAllChargers() async {
    setState(() {
      isLoading = true;
      availableChargers.clear(); // Clear previous chargers if needed
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://122.166.210.142:4444/getAllChargersWithStatusAndPrice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      final data = json.decode(response.body);
      print("Filtered Charger Data Position: $data");

      if (response.statusCode == 200) {
        final List<dynamic> chargerData = data['data'] ?? [];

        // Filter chargers based on latitude and longitude
        List<dynamic> filteredChargerData = chargerData.where((charger) {
          final lat = double.tryParse(charger['lat'] ?? '0');
          final long = double.tryParse(charger['long'] ?? '0');
          return lat == widget.position.latitude &&
              long == widget.position.longitude;
        }).toList();
        print("filteredChargerData $filteredChargerData");

        // Create a list to hold unique chargers with addresses
        List<Map<String, dynamic>> uniqueChargers = [];
        final Set<String> chargerIds = {}; // To track unique charger IDs

        for (var charger in filteredChargerData) {
          final chargerId = charger['charger_id'] ?? 'Unknown ID';

          if (!chargerIds.contains(chargerId)) {
            chargerIds.add(chargerId);

            String lastUsedTime = 'Not yet received';
            if (charger['status'] != null &&
                charger['status'] is List &&
                charger['status'].isNotEmpty) {
              final status = charger['status'].firstWhere(
                (status) => status['timestamp'] != null,
                orElse: () => null,
              );
              if (status != null) {
                lastUsedTime = formatTimestamp(status['timestamp']);
              }
            }

            final isPrivate = charger['charger_accessibility'] == 2;

            String chargerStatus = '-';
            if (charger['status'] != null &&
                charger['status'] is List &&
                charger['status'].isNotEmpty) {
              // Collect all statuses that have a 'charger_status' key
              final allStatuses = charger['status']
                  .where((status) => status['charger_status'] != null)
                  .map((status) => status['charger_status'])
                  .toList();

              if (allStatuses.isNotEmpty) {
                chargerStatus =
                    allStatuses.join(', '); // Concatenate statuses with a comma
              }
            }
            print("chargerStatus: $chargerStatus");
            final gunConnector = charger['gun_connector'] ?? 0;
            final socketCount = charger['socket_count'] ?? 0;

            // Determine the display text for gun and socket
            String gunSocketDisplay = '';

            if (gunConnector > 0 && socketCount > 0) {
              gunSocketDisplay = 'Gun and Socket';
            } else if (gunConnector > 0 && socketCount == 0) {
              gunSocketDisplay = 'Gun ';
            } else if (gunConnector == 0 && socketCount > 0) {
              gunSocketDisplay = 'Socket ';
            }

            uniqueChargers.add({
              'charger_id': chargerId,
              'charger_type': charger['charger_type'] ?? 'Unknown Type',
              'last_used_time': lastUsedTime,
              'unit_price': charger['unit_price'] ?? 0.0,
              'address': charger['address'] ?? 'Unknown address',
              'is_private': isPrivate,
              'status': chargerStatus,
              'gun_connector': gunConnector,
              'socket_count': socketCount,
              'gun_socket_display': gunSocketDisplay, // Store the display text
              'charger_model': charger['charger_model'] ?? 'Unknown Model',
              'bluetooth_module': charger['bluetooth_module'] ?? false,
              'wifi_module':
                  charger['wifi_module'] ?? false, // Include Wi-Fi status
            });
          }
        }

        setState(() {
          availableChargers = uniqueChargers;
          isLoading = false;

          if (uniqueChargers.isNotEmpty) {
            final firstCharger = uniqueChargers.first;
            print("firstCharger $uniqueChargers[0]");
            charger = {
              'charger_id': firstCharger['charger_id'] ?? 'Unknown ID',
              'charger_type': firstCharger['charger_type'] ?? 'Unknown Type',
              'last_used_time': firstCharger['last_used_time'] ?? ' - ',
              'unit_price': firstCharger['unit_price'] ?? 0.0,
              'status': firstCharger['status'] ?? 'Unknown',
              'gun_connector': firstCharger['gun_connector'] ?? 0,
              'socket_count': firstCharger['socket_count'] ?? 0,
              'charger_model': firstCharger['charger_model'] ?? 'Unknown Model',
              'bluetooth_module': firstCharger['bluetooth_module'] ?? false,
              'wifi_module': firstCharger['wifi_module'] ?? false,
            };
          }
        });
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Something went wrong, try again later: $error');
      showErrorDialog(
          context, 'An unexpected error occurred. Please try again.');
      setState(() {
        isLoading = false;
      });
    }
  }

// Function to format the timestamp
  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A'; // Handle null case

    // Define date format patterns
    final rawFormat = DateTime.tryParse(timestamp);
    final formatter = intl.DateFormat('MM/dd/yyyy, hh:mm:ss a');
    // final formatter = intl.DateFormat('MM/dd/yyyy');

    if (rawFormat != null) {
      // If the timestamp is in ISO format, parse and format
      final parsedDate = rawFormat.toLocal();
      return formatter.format(parsedDate);
    } else {
      // Otherwise, assume it's already in the desired format and return it
      return timestamp; // Or 'Invalid date' if you want to handle improperly formatted strings
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final String location = widget.address;
    final LatLng position = widget.position;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image (fixed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.3, // Scalable height for image
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Image.asset(
                'assets/Image/Connecter_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Content
          Positioned(
            top:
                screenHeight * 0.3, // Position the main content below the image
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          "Open Now",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "24 Hours",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildNavigationBar(screenWidth),
                    const SizedBox(height: 10),
                    CustomGradientDivider(),
                    _buildContent(screenWidth),
                  ],
                ),
              ),
            ),
          ),

          // Share button
          Positioned(
            top: 30,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              onPressed: () {
                double latitude = position.latitude;
                double longitude = position.longitude;

                String message =
                    "Explore the ion Hive for seamless EV charging experience!\n\n"
                    "Location: $location\n\n"
                    "Charge your EV now!\n"
                    "Check the location on the map: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

                Share.share(message);
              },
            ),
          ),

          // Back button
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Conditionally render the loading overlay if `isSearching` is true
          if (isSearching)
            Container(
              color:
                  Colors.black.withOpacity(0.5), // Semi-transparent background
              child: Center(
                child: _AnimatedChargingIcon(), // Loading indicator
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth) {
    // Calculate the available height
    final availableHeight = MediaQuery.of(context).size.height;

    return Container(
      height:
          availableHeight, // Set height dynamically based on available space
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildChargerSessionsContent(screenWidth),
          _buildLocationSessionsContent(screenWidth),
        ],
      ),
    );
  }

  Widget _buildChargerSessionsContent(double screenWidth) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(5.0),
        margin: const EdgeInsets.only(bottom: 430),
        child: Column(
          children: availableChargers.isNotEmpty
              ? availableChargers.map((charger) {
                  return _buildChargerDetails(screenWidth, charger);
                }).toList()
              : List.generate(
                  4, // Number of shimmer cards to show
                  (index) => _buildShimmerCard(context),
                ),
        ),
      ),
    );
  }

  Future<void> updateConnectorUser(
      String searchChargerID, int connectorId, int connectorType) async {
    setState(() {
      isSearching = false;
    });
    print("response: updateConnectorUser");

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/updateConnectorUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
          'connector_id': connectorId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Charging(
              searchChargerID: searchChargerID,
              username: widget.username,
              userId: widget.userId,
              connector_id: connectorId,
              connector_type: connectorType,
              email: widget.email,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      showErrorDialog(context, 'Something went wrong, try again later ');
    }
  }

  void showloadingpage() {
    setState(() {
      isSearching = false;
    });

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            child: _AnimatedChargingIcon(),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> handleSearchRequest(
      String searchChargerID) async {
    if (isSearching) return null;

    print("response: handleSearchRequest");

    if (searchChargerID.isEmpty) {
      showErrorDialog(context, 'Please enter a charger ID.');
      return {'error': true, 'message': 'Charger ID is empty'};
    }

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/SearchCharger'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
        }),
      );
      // Optional: Delay to show the loading animation for a bit longer if needed
      await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          this.searchChargerID = searchChargerID;
          isSearching = false;
        });

        // Dismiss the loading animation
        // if (mounted) Navigator.of(context).pop();

        // Return the successful response data
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorDatas = errorData['message'];
        print("ododod 2: $errorDatas");

        showErrorDialog(context, errorData['message']);

        // Dismiss the loading animation
        // if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      showErrorDialog(context, 'Something went wrong, try again later');

      // Dismiss the loading animation
      if (mounted) Navigator.of(context).pop();

      return {
        'error': true,
        'message': 'Something went wrong, try again later'
      };
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
    return null;
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Preparing':
        return Colors.orange;
      case 'Charging':
        return Colors.orange;
      case 'Finishing':
        return Colors.orange;
      case 'Unavailable':
        return Colors.red;
      case 'Faulted':
        return Colors.red;
      default:
        return Colors
            .white54; // Default color for other statuses or if not updated
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case 'Available':
        return 'Available';
      case 'Faulted':
        return 'Faulted';
      case 'Preparing':
        return 'Busy';
      case 'Charging':
        return 'Busy';
      case 'Finishing':
        return 'Busy';
      case 'Unavailable':
        return 'Unavailable';
      default:
        return '-';
    }
  }

  Widget _buildChargerDetails(
      double screenWidth, Map<String, dynamic> charger) {
    return GestureDetector(
      onTap: () async {
        final data = await handleSearchRequest(charger['charger_id']);
        print("connectorIdconnectorId data $data");
        if (data != null && !data.containsKey('error')) {
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              backgroundColor: Colors.black,
              builder: (BuildContext context) {
                return Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: ConnectorSelectionDialog(
                    chargerData: data['socketGunConfig'] ?? {},
                    onConnectorSelected: (connectorId, connectorType) {
                      updateConnectorUser(
                          charger['charger_id'], connectorId, connectorType);
                    },
                    username: widget.username,
                    email: widget.email,
                    userId: widget.userId,
                  ),
                );
              },
            );
          }
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.grey[900],
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left section: Centered image with border
              Column(
                children: [
                  Container(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.22,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color.fromARGB(255, 54, 54, 54),
                        width: 2.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/Image/Gunsocket.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Right section for details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Charger ID, Wi-Fi, and Bluetooth buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          charger['charger_id'] ?? 'Unknown Charger ID',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 221, 219, 219),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.wifi,
                              color: charger['wifi_module'] == true
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              size: screenWidth * 0.05,
                            ),
                            const SizedBox(
                                width: 8), // Add spacing between icons
                            Icon(
                              Icons.bluetooth,
                              color: charger['bluetooth_module'] == true
                                  ? Colors.lightBlueAccent
                                  : Colors.grey,
                              size: screenWidth * 0.05,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Row 2: Socket/Gun, AC/DC, and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment:
                          CrossAxisAlignment.end, // Aligns items vertically
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${charger['gun_socket_display'] ?? 'Unknown'} | ${charger['charger_type'] ?? 'AC/DC'}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        if (charger['status'] != null &&
                            charger['status'].contains(','))
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .end, // Align text to the right
                                children: charger['status']
                                    .split(',')
                                    .asMap() // Use asMap() to include index if needed for specific labels
                                    .entries
                                    .map<Widget>(
                                  (entry) {
                                    final status = entry.value.trim();
                                    final index = entry.key;
                                    final label = index % 2 == 0
                                        ? "S"
                                        : "G"; // Alternate label logic
                                    return RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$label : ', // Label text
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              color: Colors
                                                  .grey, // Grey color for label
                                            ),
                                          ),
                                          TextSpan(
                                            text: status, // Status text
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              color: getStatusColor(
                                                  status), // Dynamic color for status
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                getStatusText(charger['status']),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: getStatusColor(charger['status']),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    // Row 3: Price per unit and Charger Model
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price container with border
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                                color: const Color.fromARGB(179, 48, 47, 47),
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                color: Colors.yellowAccent,
                                size: screenWidth * 0.04,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${charger['unit_price'] ?? 'N/A'} / unit',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035, // Reduced size
                                  fontWeight: FontWeight.bold, // Make bold
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // kWh container with border
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                                color: const Color.fromARGB(179, 40, 39, 39),
                                width: 1.5),
                          ),
                          child: Text(
                            "${charger['charger_model'] ?? 'Unknown Model'} kWh",
                            style: TextStyle(
                              fontSize: screenWidth * 0.035, // Reduced size
                              fontWeight: FontWeight.bold, // Make bold
                              // color: Colors.grey[400],
                              color: const Color.fromARGB(255, 181, 40, 50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                  ],
                ),
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

  Widget _buildNavigationBar(double screenWidth) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly, // Distributes space evenly
      children: [
        Expanded(child: _buildNavItem("Charger", 0, screenWidth)),
        Expanded(child: _buildNavItem("Location", 1, screenWidth)),
      ],
    );
  }

  Widget _buildNavItem(String title, int index, double screenWidth) {
    // Determine if the current index is active
    bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      },
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center the text vertically
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.green : Colors.white70,
              fontSize: screenWidth < 600
                  ? 16
                  : 20, // Adjust font size based on screen width
            ),
            textAlign: TextAlign.center, // Center the text horizontally
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            width: isActive ? 50 : 0,
            height: 3,
            color: Colors.green,
            curve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSessionsContent(double screenWidth) {
    return SizedBox(
      child: Padding(
        padding:
            const EdgeInsets.only(top: 15.0, left: 5, right: 5, bottom: 450),
        child: Container(
          height: 100, // Set a fixed height for the map container
          width: double
              .infinity, // Set the width to match the parent width (full width)
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(15), // Optional: Add rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset:
                    const Offset(0, 3), // Optional: Add a shadow for styling
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
                10), // Same as above to clip the map's corners
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.position,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('chargerLocation'),
                  position: widget.position,
                  infoWindow: const InfoWindow(
                    title: 'Charger Location',
                    snippet: "landmark", // Show landmark in the snippet
                  ),
                  onTap: () {
                    _launchMapsUrl(
                        widget.position.latitude, widget.position.longitude);
                  },
                ),
              },
              onMapCreated: (GoogleMapController controller) async {
                String mapStyle =
                    await rootBundle.loadString('assets/Map/map.json');
                controller.setMapStyle(mapStyle);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _launchMapsUrl(double latitude, double longitude) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
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

class ConnectorSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> chargerData;
  final Function(int, int) onConnectorSelected;
  final String username;
  final int? userId;
  final String email;
  final Map<String, dynamic>? selectedLocation; // Accept the selected location

  const ConnectorSelectionDialog({
    super.key,
    required this.chargerData,
    required this.onConnectorSelected,
    required this.username,
    this.userId,
    required this.email,
    this.selectedLocation,
  });

  @override
  _ConnectorSelectionDialogState createState() =>
      _ConnectorSelectionDialogState();
}

class _ConnectorSelectionDialogState extends State<ConnectorSelectionDialog> {
  int? selectedConnector;
  int? selectedConnectorType;

  bool _isFormValid() {
    return selectedConnector != null && selectedConnectorType != null;
  }

  String _getConnectorTypeName(int connectorType) {
    if (connectorType == 1) {
      return 'Socket';
    } else if (connectorType == 2) {
      return 'Gun';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: isSmallScreen ? 12.0 : 16.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensures it takes minimum space
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Connector',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomGradientDivider(),
          const SizedBox(height: 20),

          // Connector Grid
          GridView.builder(
            shrinkWrap: true, // Prevents unnecessary space
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.chargerData.keys
                .where((key) =>
                    key.startsWith('connector_') && key.endsWith('_type'))
                .length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemBuilder: (BuildContext context, int index) {
              // Fetch the available connector keys dynamically
              List<String> connectorKeys = widget.chargerData.keys
                  .where((key) =>
                      key.startsWith('connector_') && key.endsWith('_type'))
                  .toList();

              String connectorKey =
                  connectorKeys[index]; // Use the key directly
              int connectorId =
                  index + 1; // Still keep the numbering for display purposes
              int? connectorType = widget.chargerData[connectorKey];

              if (connectorType == null) {
                return const SizedBox
                    .shrink(); // Skip if there's no valid connector
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedConnector = connectorId;
                    selectedConnectorType = connectorType;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedConnector == connectorId
                        ? Colors.green
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          connectorType == 1 ? Icons.power : Icons.ev_station,
                          color: connectorType == 1 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getConnectorTypeName(connectorType),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ' - [ $connectorId ]',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10), // Adjust this spacing as needed

          // Continue Button
          ElevatedButton(
            onPressed: _isFormValid()
                ? () {
                    if (selectedConnector != null &&
                        selectedConnectorType != null) {
                      widget.onConnectorSelected(
                          selectedConnector!, selectedConnectorType!);
                      Navigator.of(context).pop();
                    }
                  }
                : null,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.green.withOpacity(0.2);
                  }
                  return const Color(0xFF1C8B40);
                },
              ),
              minimumSize: MaterialStateProperty.all(
                Size(double.infinity, isSmallScreen ? 45 : 50),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
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
                  // Navigate to HomePage without disrupting other content
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => HomePage(
                  //       selectedLocation: selectedLocation,
                  //       username: username,
                  //       userId: userId,
                  //       email: email,
                  //     ),
                  //   ),
                  // );
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
