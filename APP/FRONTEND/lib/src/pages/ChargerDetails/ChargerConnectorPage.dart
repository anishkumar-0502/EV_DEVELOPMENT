import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package for launching URLs
import 'package:share_plus/share_plus.dart';

class ChargerConnectorPage extends StatefulWidget {
  final String address;
  final String landmark;
  final String accessType;
  final String chargerId;
  final String unitPrice;
  final String chargerType;
  final String time;
  final LatLng position;

  const ChargerConnectorPage({
    required this.address,
    required this.landmark,
    required this.accessType,
    required this.chargerId,
    required this.unitPrice,
    required this.chargerType,
    required this.time,
    super.key, required this.position,
  });

  @override
  _ChargerConnectorPageState createState() => _ChargerConnectorPageState();
}

class _ChargerConnectorPageState extends State<ChargerConnectorPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late String mapStyle; // Declare the mapStyle variable

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Set the initial index to 0 for the "Charger" tab
    _currentIndex = 0; // Active state for the first tab
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  final String location = widget.address;

    // Truncate the address if it's longer than 30 characters
    String truncatedAddress = widget.address.length > 30
        ? widget.address.substring(0, 30) + '...'
        : widget.address;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.landmark,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    truncatedAddress,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        '4.77',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        ' (43)',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Image.asset(
                'assets/Image/Connecter_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.black),
                onPressed: () {
                  // Bookmark action
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {
                        // Create the shareable message
                        String message = "Explore the EV POWER for seamless EV charging experience!\n\n"
                                        "Location: $location\n\n"
                                        "Charge your EV now!";     
                    // Share the message
                    Share.share(message);
                  },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.landmark,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.address,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white54,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 47, 49, 50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white54, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '4.77',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (widget.accessType == "private") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Access type is private. Contact admin.'),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  widget.accessType == "private" ? Icons.lock : Icons.lock_open,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildNavigationBar(screenWidth),
                      const SizedBox(height: 20),
                      _buildContent(screenWidth),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargerDetails(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.chargerId,
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              widget.chargerType,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              "Last used on ${widget.time}",
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.currency_rupee,
              color: Colors.orange,
              size: screenWidth * 0.04,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.unitPrice}/kWh',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20), // Add space below the charger details
      ],
    );
  }

  Widget _buildNavigationBar(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavItem("Charger", 0),
        _buildNavItem("Location", 1),
        _buildNavItem("Reviews", 2),
      ],
    );
  }
Widget _buildNavItem(String title, int index) {
  // Define a variable to determine if the current index is active
  bool isActive = _currentIndex == index;

  return GestureDetector(
    onTap: () {
      setState(() {
        _currentIndex = index;
      });
      _pageController.jumpToPage(index);
    },
    child: Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.white70, // Change color if active
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4), // Space between text and line
        // AnimatedContainer for the line effect
        AnimatedContainer(
          duration: const Duration(milliseconds: 700), // Duration for the animation
          width: isActive ? 50 : 0, // Width changes based on active state
          height: 3, // Line height
          color: Colors.green, // Line color
          curve: Curves.easeInOut, // Animation curve
        ),
      ],
    ),
  );
}

  Widget _buildContent(double screenWidth) {
    return SizedBox(
      height: 200, // Fixed height for the content area
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
          _buildReviewSessionsContent(screenWidth),
        ],
      ),
    );
  }
Widget _buildChargerSessionsContent(double screenWidth) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    color: Colors.grey[850],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChargerDetails(screenWidth), // Add charger details here
      ],
    ),
  );
}

Widget _buildLocationSessionsContent(double screenWidth) {
  return SizedBox(
    height: 200, // Set a height for the map container
    child: GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.position,
        zoom: 14, // Adjust the zoom level as needed
      ),
      markers: {
        Marker(
          markerId: const MarkerId('chargerLocation'),
          position: widget.position,
          infoWindow: InfoWindow(
            title: 'Charger Location',
            snippet: widget.landmark, // Show landmark in the snippet
          ),
          onTap: () {
            // Navigate to Google Maps when the marker is tapped
            _launchMapsUrl(widget.position.latitude, widget.position.longitude);
          },
        ),
      },
      onMapCreated: (GoogleMapController controller) async {
        // Set the map style here
        String mapStyle = await rootBundle.loadString('assets/Map/map.json');
        controller.setMapStyle(mapStyle);
      },
    ),
  );
}


  // Function to launch Google Maps
  void _launchMapsUrl(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }


  Widget _buildReviewSessionsContent(double screenWidth) {
    // Implement review sessions content
    return Container(); // Placeholder
  }
}
