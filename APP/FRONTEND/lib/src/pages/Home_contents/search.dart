
import 'dart:convert';
import 'package:ev_app/src/pages/home.dart';
import 'package:ev_app/src/service/location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SearchResultsPage extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function(String) handleSearchRequest;
  final Function(Map<String, dynamic>)
      onLocationSelected; // Callback to handle selected location
  final String username;
  final int? userId;
  final String email;

  const SearchResultsPage(
      {super.key,
      required this.handleSearchRequest,
      required this.onLocationSelected,
      required this.username,
      this.userId,
      required this.email});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _chargerIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Sample recent locations
  List<Map<String, String>> recentLocations = [];
  List<Map<String, Object>> filteredLocations = [];
  LatLng? _currentPosition;
bool _isLoading = false; // Add this variable to manage loading state

  // Initialize recent locations from SharedPreferences
  @override
  void initState() {
    super.initState();
    _loadRecentLocations();
  }

  void _searchChargerId(String chargerId) async {
    if (chargerId.isEmpty) {
      // Handle empty charger ID input
      return;
    }

    final result = await widget.handleSearchRequest(chargerId);

    if (result != null && result.containsKey('error') && !result['error']) {
      // If search is successful, prepare location data
      final location = {
        'name': result['chargerName']?.toString() ??
            'Unknown Charger', // Ensure value is a String
        'address': result['chargerAddress']?.toString() ??
            '', // Ensure value is a String
      };

      // Call the onLocationSelected method to locate the charger on the map
      _onLocationSelected(location);
    } else {
      // Handle error cases
      print('Error in search: ${result?['message']}');
    }
  }

void _oncurrentLocationSelected(Map<String, dynamic> location) {
  // Convert latitude and longitude to strings to ensure consistency
  final selectedLocation = {
    'name': location['name'],
    'address': location['address'],
    'latitude': location['latitude'].toString(), // Ensure it's a string
    'longitude': location['longitude'].toString(), // Ensure it's a string
  };

  // Pass the selected location to the callback
  widget.onLocationSelected(selectedLocation);

  print("_currentSelectedLocation $selectedLocation");

  // Use Navigator.push to add the new page without disrupting other content
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HomePage(
        selectedLocation: selectedLocation, // Pass the consistent selectedLocation
        username: widget.username,
        userId: widget.userId,
        email: widget.email,
      ),
    ),
  );
}
void _onLocationSelected(Map<String, dynamic> location) {
  // Convert latitude and longitude to strings to ensure consistency
  final selectedLocation = {
    'name': location['name'],
    'address': location['address'],
    'latitude': location['latitude'].toString(), // Ensure it's a string
    'longitude': location['longitude'].toString(), // Ensure it's a string
  };

  // Pass the selected location to the callback
  widget.onLocationSelected(selectedLocation);

  _saveRecentLocation(location); // Save selected location to recent
  print("_currentSelectedLocation $selectedLocation");

  // Use Navigator.push to add the new page without disrupting other content
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HomePage(
        selectedLocation: selectedLocation, // Pass the consistent selectedLocation
        username: widget.username,
        userId: widget.userId,
        email: widget.email,
      ),
    ),
  );
}


  Future<void> _loadRecentLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedLocations = prefs.getStringList('recentLocations');

    if (storedLocations != null) {
      recentLocations = storedLocations.map((location) {
        var parts = location.split('|');
        return {
          'name': parts[0],
          'address': parts[1],
          'latitude': parts[2],
          'longitude': parts[3],
        };
      }).toList();

      setState(() {});
    }
  }

  Future<void> _saveRecentLocation(Map<String, dynamic> location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("location: $location");

    // Ensure all values in location are Strings
    final locationAsStringMap = {
      'name': location['name'].toString(),
      'address': location['address'].toString(),
      'latitude': location['latitude'].toString(),
      'longitude': location['longitude'].toString(),
    };

    // Check if the location already exists in recentLocations
    if (!recentLocations.any((loc) =>
        loc['name'] == locationAsStringMap['name'] &&
        loc['address'] == locationAsStringMap['address'])) {
      // Add to the top of the list
      recentLocations.insert(0, locationAsStringMap);

      // Convert the recentLocations list to a List<String> for storage, including latitude and longitude
      List<String> storedLocations = recentLocations.map((loc) {
        return '${loc['name']}|${loc['address']}|${loc['latitude']}|${loc['longitude']}';
      }).toList();

      // Save the recent locations list to SharedPreferences
      await prefs.setStringList('recentLocations', storedLocations);

      // Update the UI
      setState(() {});
    }
  }

  Future<void> _clearRecentLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentLocations'); // Clear from SharedPreferences
    setState(() {
      recentLocations.clear(); // Clear the local list
    });
  }

  Future<void> _deleteRecentLocation(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    recentLocations.removeAt(index); // Remove the location from the local list
    List<String> storedLocations = recentLocations
        .map((loc) => '${loc['name']}|${loc['address']}')
        .toList();
    await prefs.setStringList(
        'recentLocations', storedLocations); // Update SharedPreferences
    setState(() {}); // Update the UI
  }

  Future<List<Map<String, dynamic>>> fetchLocations(String query) async {
    const String apiKey =
        'AIzaSyDezbZNhVuBMXMGUWqZTOtjegyNexKWosA'; // Replace with your actual API key
    final String apiUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Decode the JSON response
        Map<String, dynamic> data = json.decode(response.body);

        // Extract the predictions
        List<dynamic> predictions = data['predictions'] ?? [];

        // Create a list to store locations with additional details
        List<Map<String, dynamic>> locations = [];

        // Fetch details for each prediction
        for (var item in predictions) {
          String placeId = item['place_id'];
          String name = item['description'];

          // Fetch Place Details
          final detailsResponse = await http.get(Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey'));

          if (detailsResponse.statusCode == 200) {
            Map<String, dynamic> detailsData =
                json.decode(detailsResponse.body);
            var locationData = detailsData['result']['geometry']['location'];

            // Extract latitude and longitude
            double latitude = locationData['lat'];
            double longitude = locationData['lng'];

            // Extract address
            String address =
                item['structured_formatting']['secondary_text'] ?? '';

            // Add location data to the list
            locations.add({
              'name': name,
              'address': address,
              'latitude': latitude,
              'longitude': longitude,
            });
          } else {
            print(
                'Failed to load place details for $placeId, status code: ${detailsResponse.statusCode}');
          }
        }

        // Filter to only include locations in India
        return locations
            .where((location) => location['address']!.contains('India'))
            .toList();
      } else {
        throw Exception(
            'Failed to load locations, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      return []; // Return an empty list in case of an error
    }
  }


void _filterLocations(String query) async {
  // Clear previous filtered locations when query is empty
  if (query.isEmpty) {
    setState(() {
      filteredLocations = [];
      _isLoading = false; // Set loading to false if no query
    });
    return; // Exit early
  }

  // Set loading to true before fetching locations
  setState(() {
    _isLoading = true;
  });

  // Fetch locations based on the query
  List<Map<String, dynamic>> locations = await fetchLocations(query);

  setState(() {
    // Print the filtered locations
    for (var location in locations) {
      print('Name: ${location['name']}');
      print('Address: ${location['address']}');
      print('Latitude: ${location['latitude']}');
      print('Longitude: ${location['longitude']}');
      print(''); // Just for better formatting
    }

    // Update the filtered locations
    filteredLocations = locations.map((location) {
      return {
        'name': location['name'] as String,
        'address': location['address'] as String,
        'latitude': location['latitude'] as double,
        'longitude': location['longitude'] as double,
      };
    }).toList();

    // Set loading to false after fetching locations
    _isLoading = false;
  });
}

  
Future<void> _getCurrentLocation() async {
  try {
 
    // Fetch the current location if permission is granted
    LatLng? currentLocation = await LocationService.instance.getCurrentLocation();
    print("_onMapCreated currentLocation $currentLocation");

    if (currentLocation != null) {
      // Update the current position
      setState(() {
        _currentPosition = currentLocation;
      });

      // Call the _onLocationSelected function with the current location data
      _oncurrentLocationSelected({
        'name': 'Current Location',
        'address': 'Your Current Address', // You can customize this as needed
        'latitude': currentLocation.latitude.toString(),
        'longitude': currentLocation.longitude.toString(),
      });

  
    } else {
      print('Current location could not be determined.');
    }
  } catch (e) {
    print('Error occurred while fetching the current location: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isSmallScreen ? 8.0 : 16.0),

              // Charger ID Search Field
              TextField(
                controller: _chargerIdController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(200, 58, 58, 60),
                  prefixIcon: const Icon(Icons.ev_station, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white70,
                      size: 23,
                    ),
                    onPressed: () {
                      _chargerIdController.clear();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Search by ChargerID...',
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                onSubmitted: _searchChargerId,
                cursorColor: const Color(0xFF1ED760),
              ),
              SizedBox(height: isSmallScreen ? 8.0 : 16.0),

              // Custom Gradient Divider with 'or' Text
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 1.0,
                      width: isSmallScreen ? 100 : 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.greenAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      height: 1.0,
                      width: isSmallScreen ? 100 : 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.greenAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 8.0 : 16.0),
              TextField(
                controller: _locationController,
                onChanged: _filterLocations,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(200, 58, 58, 60),
                  prefixIcon:
                      const Icon(Icons.location_on, color: Colors.redAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Search by Location...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white70, size: 23),
                    onPressed: () {
                      _locationController.clear();
                      setState(() {
                        filteredLocations = [];
                      });
                    },
                  ),
                ),
                cursorColor: const Color(0xFF1ED760),
              ),
              // Show loading indicator with message if _isLoading is true
              if (_isLoading)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 13), // Space between the indicator and text
                      Text('Fetching locations...', style: TextStyle(fontSize: 16,  color: Colors.orangeAccent)),
                      SizedBox(height: 10), // Space between the indicator and text
                    ],
                  ),
                ),

              if (filteredLocations.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = filteredLocations[index];
                    return ListTile(
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📍 ', style: TextStyle(fontSize: 20)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location['name']
                                      as String, // Explicitly cast to String
                                  style: const TextStyle(color: Colors.green),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  location['address']
                                      as String, // Explicitly cast to String
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _locationController.text =
                            location['name'] as String; // Cast to String
                        _saveRecentLocation(location);
                        _onLocationSelected(location);
                        setState(() {
                          filteredLocations = [];
                          _isLoading = false;
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 10),
             ElevatedButton.icon(
              onPressed: _getCurrentLocation, // Call the function here
              icon: const Icon(Icons.my_location,color: Colors.white,), // Icon for current location
              label: const Text('Current location',style: TextStyle(color: Colors.white,fontSize: 18),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Set the button color to green
                minimumSize: const Size(double.infinity, 50), // Full width button and set height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
                ),
              ),
),  

                 const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 4.0 : 8.0, horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: Colors.grey, size: 20.0),
                        SizedBox(width: 8.0),
                        Text(
                          'Recent Locations',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _clearRecentLocations();
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Container(
                  height: 0.5,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.greenAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLocations.length,
                itemBuilder: (context, index) {
                  final location = recentLocations[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 4.0 : 8.0),
                    child: Card(
                      color: const Color.fromARGB(200, 58, 58, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          _onLocationSelected(location);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location['name']!,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location['address']!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteRecentLocation(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
