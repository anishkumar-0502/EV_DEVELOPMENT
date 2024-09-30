import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../Charging/charging.dart';
import '../../utilities/QR/qrscanner.dart';
import '../../utilities/Alert/alert_banner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../../service/location.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:math' as math;

class HomeContent extends StatefulWidget {
  final String username;
  final int? userId;
  final String email;

  const HomeContent(
      {super.key,
      required this.username,
      required this.userId,
      required this.email});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
  final GlobalKey _mapKey = GlobalKey(); // Global key for map widget
  final TextEditingController _searchController = TextEditingController();
  String searchChargerID = '';
  List availableChargers = [];
  List recentSessions = [];
  String activeFilter = 'All Chargers';
  bool isLoading = true;
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition; // To store the selected marker's position
  final LatLng _center = const LatLng(12.909746, 77.606360);
  Set<Marker> _markers = {};
  bool isSearching = false;
  bool areMapButtonsEnabled = false;
  MarkerId? _previousMarkerId; // To track the previously selected marker
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFetchingLocation = false; // Ensure initialization
  LatLng? _previousPosition;
  // double? _previousBearing;
  bool _isCheckingPermission =
      false; // Flag to prevent repeated permission checks
  bool LocationEnabled = false;
  final PageController _pageController = PageController(
      viewportFraction: 0.85); // Page controller for scrolling cards
  static const String apiKey = 'AIzaSyDezbZNhVuBMXMGUWqZTOtjegyNexKWosA';
  Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // Check permissions on initialization
    _updateMarkers();
    activeFilter = 'All Chargers';
    fetchAllChargers();
    _startLiveTracking(); // Start live tracking
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

// Define the method to check and request location permissions
  Future<void> _checkLocationPermission() async {
    if (_isCheckingPermission) return; // Prevent multiple permission checks

    _isCheckingPermission = true;

    // Load the saved flag from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool locationPromptClosed = prefs.getBool('LocationPromptClosed') ?? false;

    // If the user has closed the dialog before, don't show it again
    if (locationPromptClosed) {
      _isCheckingPermission = false;
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show the location services dialog
      await _showLocationServicesDialog();
      _isCheckingPermission = false;
      return;
    }

    // Request location permission
    PermissionStatus permission = await Permission.location.request();
    if (permission.isGranted) {
      await _getCurrentLocation();
      // Reset the flag, because location is now enabled
      await prefs.setBool('LocationPromptClosed', false);
    }

    // Do nothing if permission is denied; no alert is shown
    _isCheckingPermission = false;
  }

  Future<void> _getCurrentLocation() async {
    // If a location fetch is already in progress, don't start a new one
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      // Ensure location services are enabled and permission is granted before fetching location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServicesDialog();
        return;
      }

      PermissionStatus permission = await Permission.location.status;
      if (permission.isDenied) {
        await _showPermissionDeniedDialog();
        return;
      } else if (permission.isPermanentlyDenied) {
        await _showPermanentlyDeniedDialog();
        return;
      }

      // Fetch the current location if permission is granted
      LatLng? currentLocation =
          await LocationService.instance.getCurrentLocation();
      print("_onMapCreated currentLocation $currentLocation");

      if (currentLocation != null) {
        // Update the current position
        setState(() {
          _currentPosition = currentLocation;
        });

        // Smoothly animate the camera to the new position if the mapController is available
        if (mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: 18.0, // Adjust zoom level as needed
                tilt: 45.0, // Add a tilt for a 3D effect
                // bearing:
                //     _previousBearing ?? 0, // Use previous bearing if available
              ),
            ),
          );
        }

        // Update the current location marker on the map
        // await _updateCurrentLocationMarker(_previousBearing ?? 0);
      } else {
        print('Current location could not be determined.');
      }
    } catch (e) {
      print('Error occurred while fetching the current location: $e');
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && !_isCheckingPermission) {
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (isLocationEnabled) {
        _checkLocationPermission(); // Ensure permission is checked again
      } else {
        _showLocationServicesDialog();
      }
    }
  }

  Future<void> _showLocationServicesDialog() async {
    return showDialog(
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
                  Icon(Icons.location_on, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Expanded(
                    // Add this to prevent the overflow issue
                    child: Text(
                      "Enable Location", // The heading text
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Optional: add ellipsis if text overflows
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: const Text(
            'Location services are required to use this feature. Please enable location services in your phone settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Save the flag to not show the dialog again
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('LocationPromptClosed', true);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator
                    .openLocationSettings(); // Open the location settings
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Settings",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }   

  Future<void> _showPermissionDeniedDialog() async {
    return showDialog(
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
                  Icon(Icons.location_on, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Expanded(
                    // Prevent text overflow
                    child: Text(
                      "Permission Denied",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Optional: add ellipsis if text overflows
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: const Text(
            'This app requires location permissions to function correctly. Please grant location permissions in settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                openAppSettings(); // Open app settings
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Settings",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermanentlyDeniedDialog() async {
    return showDialog(
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
                  Icon(Icons.warning, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Expanded(
                    // Prevent text overflow
                    child: Text(
                      "Permission Denied",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Optional: add ellipsis if text overflows
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: const Text(
            'Location permissions are permanently denied. Please enable them in the app settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                openAppSettings(); // Open app settings
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Settings",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

// Updated _onMapCreated function
  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // Load and set the map style
    String mapStyle = await rootBundle.loadString('assets/Map/map.json');
    mapController?.setMapStyle(mapStyle);
    await Future.delayed(const Duration(seconds: 1));

    // Check if the current position is available
    if (_currentPosition != null) {
      print("_onMapCreated $_currentPosition");
      // Zoom to 100km radius around the current location
      _animateTo100kmRadius();
      _updateMarkers(); // Update markers if needed
    } else {
      print("_onMapCreated $_currentPosition");
      // Optionally handle the case where the current position is not available
      _animateTo100kmRadius();
    }
  }

  Future<void> _onMarkerTapped(MarkerId markerId, LatLng position) async {
    setState(() {
      _selectedPosition = position;
      areMapButtonsEnabled = true;
    });

    // // Smoothly animate the camera to the selected marker
    // await _smoothlyMoveCamera(position);

    // Change the marker icon to the selected icon
    BitmapDescriptor newIcon =
        await _getIconFromAsset('assets/icons/EV_location_green.png');
    BitmapDescriptor defaultIcon =
        await _getIconFromAssetred('assets/icons/EV_location_red.png');

    setState(() {
      // Revert the previous marker icon to default if it exists
      if (_previousMarkerId != null) {
        _markers = _markers.map((marker) {
          if (marker.markerId == _previousMarkerId) {
            return marker.copyWith(iconParam: defaultIcon);
          }
          return marker;
        }).toSet();
      }

      // Update the icon for the newly selected marker
      _markers = _markers.map((marker) {
        if (marker.markerId == markerId) {
          _previousMarkerId = marker.markerId;
          return marker.copyWith(iconParam: newIcon);
        }
        return marker;
      }).toSet();
    });
  }

  /// Function to move the camera smoothly to a new position
  Future<void> _smoothlyMoveCamera(LatLng newPosition) async {
    if (mapController != null && _currentPosition != null) {
      LatLng startPosition = _currentPosition!;
      LatLng endPosition = newPosition;

      double totalSteps = 50; // The number of steps for smooth movement
      double stepDuration = 100; // Duration in milliseconds between each step

      for (int i = 1; i <= totalSteps; i++) {
        double latitude = startPosition.latitude +
            (endPosition.latitude - startPosition.latitude) * (i / totalSteps);
        double longitude = startPosition.longitude +
            (endPosition.longitude - startPosition.longitude) *
                (i / totalSteps);
        LatLng intermediatePosition = LatLng(latitude, longitude);

        await mapController!.animateCamera(
          CameraUpdate.newLatLng(intermediatePosition),
        );

        await Future.delayed(Duration(milliseconds: stepDuration.toInt()));
      }
    }
  }

  Future<void> _smoothlyMoveCameraForChargerMarker(
      LatLng startPosition, LatLng endPosition) async {
    if (mapController != null) {
      const int totalSteps =
          25; // Number of animation steps for smooth movement
      const int stepDuration = 120; // Duration between steps in milliseconds

      for (int i = 1; i <= totalSteps; i++) {
        double latitude = startPosition.latitude +
            (endPosition.latitude - startPosition.latitude) * (i / totalSteps);
        double longitude = startPosition.longitude +
            (endPosition.longitude - startPosition.longitude) *
                (i / totalSteps);
        LatLng intermediatePosition = LatLng(latitude, longitude);

        // Smoothly animate to intermediate positions
        await mapController!.animateCamera(
          CameraUpdate.newLatLng(intermediatePosition),
        );

        await Future.delayed(const Duration(milliseconds: stepDuration));
      }

      // Rotate the camera and set an initial zoom and bearing
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: endPosition,
            zoom: 16.0, // Set an initial zoom level
            bearing: 90.0, // Rotate the camera 90 degrees
            tilt: 0, // Set tilt to 0 initially
          ),
        ),
      );

      // Delay to simulate rotation effect
      await Future.delayed(const Duration(milliseconds: 300));

      // Final zoom and tilt for 3D effect
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: endPosition,
            zoom: 18.0, // Final zoom level for close-up view
            tilt: 45.0, // Tilt the camera for a 3D effect
            bearing: 90.0, // Keep the same bearing
          ),
        ),
      );
    } else {
      // Log or handle cases when the map controller is not initialized
      print("Map controller is not initialized.");
    }
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      areMapButtonsEnabled = false;
    });

    if (_previousMarkerId != null) {
      // Load the custom red icon
      BitmapDescriptor defaultIcon =
          await _getIconFromAssetred('assets/icons/EV_location_red.png');

      setState(() {
        // Update the marker with the red icon
        _markers = _markers.map((marker) {
          if (marker.markerId == _previousMarkerId) {
            return marker.copyWith(
              iconParam: defaultIcon,
            );
          }
          return marker;
        }).toSet();

        // Reset the previous marker ID
        _previousMarkerId = null;
      });
    }
  }

  Future<BitmapDescriptor> _getIconWithOutline(
      IconData iconData,
      Color iconColor,
      double size,
      Color outlineColor,
      double outlineWidth) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final paint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    final outlineRadius = size / 2 + outlineWidth;

    // Draw the outline (a circle with the specified outline color)
    canvas.drawCircle(
      Offset(outlineRadius, outlineRadius),
      outlineRadius,
      paint,
    );

    // Draw the icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: iconData.fontFamily,
          color: iconColor,
        ),
      )
      ..layout();

    textPainter.paint(
      canvas,
      Offset(outlineWidth, outlineWidth),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(
        (outlineRadius * 2).toInt(), (outlineRadius * 2).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(buffer);
  }

  Future<BitmapDescriptor> _getIconFromAsset(String assetPath,
      {int width = 300, int height = 300}) async {
    final byteData = await rootBundle.load(assetPath);
    final Uint8List bytes = byteData.buffer.asUint8List();

    // Decode the image from bytes
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width,
      targetHeight: height,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    // Convert the image to bytes
    final ByteData? resizedByteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<BitmapDescriptor> _getIconFromAssetred(String assetPath,
      {int width = 230, int height = 230}) async {
    final byteData = await rootBundle.load(assetPath);
    final Uint8List bytes = byteData.buffer.asUint8List();

    // Decode the image from bytes
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width,
      targetHeight: height,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    // Convert the image to bytes
    final ByteData? resizedByteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<BitmapDescriptor> _createCurrentLocationMarkerIcon(
      double bearing) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 150.0; // Adjust size as needed
    print("_createCurrentLocationMarkerIcon: $bearing");
    // Create the custom marker using CurrentLocationMarkerPainter
    final CurrentLocationMarkerPainter painter = CurrentLocationMarkerPainter(
      // bearing: bearing,
      animatedRadius: 80.0, // Provide a fixed value for animatedRadius
    );

    painter.paint(canvas, const Size(size, size));

    final ui.Image image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageData = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(imageData);
  }

  // Update the markers function
  void _updateMarkers() async {
    if (_currentPosition != null) {
      // Fetch the dynamic bearing
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      final double bearing = position.heading; // Get the current bearing

      // Update the current location marker with the custom marker icon and bearing
      final currentLocationIcon =
          await _createCurrentLocationMarkerIcon(bearing);

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition!,
            icon: currentLocationIcon,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
    }

    // Continue updating charger markers only if the position has changed
    for (var charger in availableChargers) {
      final chargerId = charger['charger_id'] ?? 'Unknown Charger ID';
      final lat =
          charger['lat'] != null ? double.tryParse(charger['lat']) : null;
      final lng =
          charger['long'] != null ? double.tryParse(charger['long']) : null;

      if (lat != null && lng != null) {
        // Check if the charger location has changed
        if (_previousPosition != null &&
            lat == _previousPosition!.latitude &&
            lng == _previousPosition!.longitude) {
          continue; // Skip if position hasn't changed
        }

        BitmapDescriptor chargerIcon =
            await _getIconFromAssetred('assets/icons/EV_location_red.png');
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(chargerId),
              position: LatLng(lat, lng),
              icon: chargerIcon,
              infoWindow: InfoWindow(
                title: charger['model'] ?? 'Unknown Model',
                snippet: chargerId,
              ),
              onTap: () {
                _onMarkerTapped(MarkerId(chargerId), LatLng(lat, lng));
              },
            ),
          );
        });
      }
    }
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
        Uri.parse('http://122.166.210.142:4444/searchCharger'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
        }),
      );

      // Delay to keep the loading indicator visible
      await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          this.searchChargerID = searchChargerID;
          isSearching = false;
        });

        await showModalBottomSheet(
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
                      searchChargerID, connectorId, connectorType);
                },
              ),
            );
          },
        );
        return data; // Return the successful response data
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isSearching = false;
        });
        return {'error': true, 'message': errorData['message']};
      }
    } catch (error) {
      showErrorDialog(context, 'Internal server error');
      return {'error': true, 'message': 'Internal server error'};
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  Future<void> updateConnectorUser(
      String searchChargerID, int connectorId, int connectorType) async {
    setState(() {
      isSearching = false;
    });

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
      showErrorDialog(context, 'Internal server error ');
    }
  }

  void navigateToQRViewExample() async {
    // Check camera permission
    bool hasPermission = await Permission.camera.isGranted;

    if (hasPermission) {
      // Navigate to the QR scanner screen if permission is granted
      final scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => QRViewExample(
            handleSearchRequestCallback: handleSearchRequest,
            username: widget.username,
            userId: widget.userId,
          ),
        ),
      );

      if (scannedCode != null) {
        setState(() {
          searchChargerID = scannedCode;
          isSearching = false;
        });
      }
    } else {
      // Show a custom dialog if permission is not granted
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue, size: 35),
                    SizedBox(width: 10),
                    Text(
                      "Permission Denied",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomGradientDivider(),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To Scan QR codes, allow this app access to your camera. Tap Settings > Permissions, and turn Camera on.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text("Settings",
                    style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
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
          child: ErrorDetails(errorData: message),
        );
      },
    ).then((_) {});
  }

  Future<void> fetchRecentSessionDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/getRecentSessionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
        }),
      );
      final data = json.decode(response.body);
      print("Prev: $data");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentSessions = data['data'] ?? [];

          activeFilter = 'Previously Used';
          isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isLoading = false;
        });
        setState(() {
          activeFilter = 'All Chargers';
          isLoading = false;
        });
      }
    } catch (error) {
      showErrorDialog(context, 'Internal server error ');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAllChargers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://122.166.210.142:4444/getAllChargersWithStatusAndPrice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> chargerData = data['data'] ?? [];

        // Fetch addresses for each charger and store in a new field
        for (var charger in chargerData) {
          final lat = double.parse(charger['lat'] ?? '0');
          final long = double.parse(charger['long'] ?? '0');
          final chargerId = charger['charger_id'] ?? 'Unknown ID';

          // Fetch address only if it's not already fetched
          if (charger['address'] == null) {
            String address = await _getPlaceName(LatLng(lat, long), chargerId);
            charger['address'] = address; // Store the fetched address
          }
        }

        setState(() {
          availableChargers = chargerData;
          activeFilter = 'All Chargers';
          isLoading = false;
        });

        _updateMarkers();
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Internal server error $error ');
      setState(() {
        isLoading = false;
      });
    }
  }

// Helper function to load an image from bytes
  Future<ui.Image> loadImageFromBytes(Uint8List imgBytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imgBytes, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  void _startLiveTracking() {
    // Cancel any existing subscription to prevent memory leaks
    _positionStreamSubscription?.cancel();

    // Set up the position stream subscription
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Receive updates for any movement
      ),
    ).listen((Position position) async {}, onError: (error) {
      print('Error in live tracking: $error');
    });
  }

  Future<void> _updateCurrentLocationMarker(double bearing) async {
    // Create a custom icon that reflects the current bearing
    final currentLocationIcon = await _createCurrentLocationMarkerIcon(bearing);
    print("_updateCurrentLocationMarker: $currentLocationIcon ");
    setState(() {
      // Remove any previous marker for the current location
      _markers
          .removeWhere((marker) => marker.markerId.value == 'current_location');

      // Add a new marker with the updated location and rotation
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          icon: currentLocationIcon,
          rotation: bearing,
          anchor: const Offset(0.5, 0.5), // Center the icon
        ),
      );
    });
  }

  void _animateTo100kmRadius() {
    if (_currentPosition == null) return;

    // Calculate bounds for a 100km radius
    double radiusInKm = 10.0;
    double kmInLat = 0.009; // Approximate value for 1 km in latitude
    double kmInLng = 0.009 /
        cos(_currentPosition!.latitude *
            pi /
            180.0); // Adjust based on current latitude

    final LatLng southWest = LatLng(
      _currentPosition!.latitude - (radiusInKm * kmInLat),
      _currentPosition!.longitude - (radiusInKm * kmInLng),
    );

    final LatLng northEast = LatLng(
      _currentPosition!.latitude + (radiusInKm * kmInLat),
      _currentPosition!.longitude + (radiusInKm * kmInLng),
    );

    // Create the LatLngBounds
    LatLngBounds bounds =
        LatLngBounds(southwest: southWest, northeast: northEast);

    // Animate the camera to fit the bounds
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return LoadingOverlay(
      showAlertLoading: isSearching,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                key: _mapKey,
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? _center,
                  zoom: 15.0,
                ),
                markers: _markers,
                zoomControlsEnabled: false,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onTap: _onMapTapped,
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight *
                        0.05, // Adjust padding based on screen height
                    left: screenWidth *
                        0.04, // Adjust padding based on screen width
                    right: screenWidth * 0.04,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (value) {
                            handleSearchRequest(value);
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0E0E0E),
                            hintText: 'Search ChargerId...',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            FilteringTextInputFormatter.deny(
                              RegExp(r'\s'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                          width: screenWidth *
                              0.03), // Adjust spacing based on screen width
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E0E0E),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            navigateToQRViewExample();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, // Adjust horizontal padding
                    vertical: screenHeight * 0.01, // Adjust vertical padding
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeFilter == 'All Chargers'
                                ? Colors.blue
                                : const Color(0xFF0E0E0E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              activeFilter = 'All Chargers';
                            });
                            fetchAllChargers();
                          },
                          icon:
                              const Icon(Icons.ev_station, color: Colors.white),
                          label: const Text('All Chargers',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(
                            width: screenWidth *
                                0.03), // Adjust spacing between buttons
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeFilter == 'Previously Used'
                                ? Colors.blue
                                : const Color(0xFF0E0E0E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              activeFilter = 'Previously Used';
                            });
                            fetchRecentSessionDetails();
                          },
                          icon: const Icon(Icons.history, color: Colors.white),
                          label: const Text('Previously Used',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                    height: screenHeight *
                        0.42), // Adjust height based on screen size
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: Column(
                      children: [
                        Expanded(
                          child:
                              _buildChargerList(), // Place the charger list here
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: screenHeight *
                  0.2, // Adjust positioning based on screen height
              right: screenWidth *
                  0.03, // Adjust positioning based on screen width
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'zoom_in',
                    backgroundColor: Colors.black,
                    onPressed: () {
                      mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    child: const Icon(Icons.zoom_in_map_rounded,
                        color: Colors.white),
                  ),
                  SizedBox(
                      height: screenHeight *
                          0.01), // Adjust spacing between buttons
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    backgroundColor: Colors.black,
                    onPressed: () {
                      mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    child: const Icon(Icons.zoom_out_map_rounded,
                        color: Colors.red),
                  ),
                ],
              ),
            ),
            // Keep the FloatingActionButton outside the Column to prevent it from moving
            Positioned(
              top: screenHeight * 0.53, // Pin to the bottom
              right: screenWidth * 0.03,
              child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(227, 76, 175, 79),
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A'; // Handle null case

    // Define date format patterns
    final rawFormat = DateTime.tryParse(timestamp);
    final formatter = intl.DateFormat('MM/dd/yyyy, hh:mm:ss a');

    if (rawFormat != null) {
      // If the timestamp is in ISO format, parse and format
      final parsedDate = rawFormat.toLocal();
      return formatter.format(parsedDate);
    } else {
      // Otherwise, assume it's already in the desired format and return it
      return timestamp; // Or 'Invalid date' if you want to handle improperly formatted strings
    }
  }

// Function to calculate the distance between two points (in km)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in km
    final double dLat = (lat2 - lat1) * math.pi / 180.0;
    final double dLon = (lon2 - lon1) * math.pi / 180.0;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c; // Distance in km
  }

  void _onChargerCardChanged(int index) async {
    if (index < availableChargers.length) {
      var charger = availableChargers[index];
      double? lat = double.tryParse(charger['lat']);
      double? lng = double.tryParse(charger['long']);

      if (lat != null && lng != null) {
        LatLng chargerPosition = LatLng(lat, lng);

        if (mapController != null) {
          LatLng startPosition =
              _selectedPosition ?? _currentPosition ?? _center;

          // Smoothly move the camera to the charger position
          await _smoothlyMoveCameraForChargerMarker(
              startPosition, chargerPosition);

          // Update selected position and enable map buttons
          setState(() {
            _selectedPosition = chargerPosition;
            areMapButtonsEnabled = true; // Enable map buttons

            // Update marker icons
            _updateMarkerIcons(charger[
                'charger_id']); // Assuming charger['id'] holds the unique ID of the charger
          });
        }
      }
    }
  }

  Future<void> _updateMarkerIcons(String chargerId) async {
    BitmapDescriptor newIcon =
        await _getIconFromAsset('assets/icons/EV_location_green.png');
    BitmapDescriptor defaultIcon =
        await _getIconFromAsset('assets/icons/EV_location_red.png');

    setState(() {
      // Change the icon of the previously selected marker back to default
      if (_previousMarkerId != null) {
        _markers = _markers.map((marker) {
          if (marker.markerId == _previousMarkerId) {
            return marker.copyWith(iconParam: defaultIcon);
          }
          return marker;
        }).toSet();
      }

      // Update the icon for the currently selected charger marker
      _markers = _markers.map((marker) {
        if (marker.markerId.value == chargerId) {
          _previousMarkerId = marker.markerId;
          return marker.copyWith(iconParam: newIcon);
        }
        return marker;
      }).toSet();
    });
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

  // Build Charger List
  Widget _buildChargerList() {
    List<Widget> chargerCards = [];

    // Add "Previously Used" charger cards
    if (activeFilter == 'Previously Used') {
      for (var session in recentSessions) {
        chargerCards.add(
          _buildChargerCard(
            context,
            session['details']['landmark'] ?? 'Unknown location',
            session['details']['charger_id'] ?? 'Unknown ID',
            session['details']['model'] ?? 'Unknown Model',
            session['status']['charger_status'] ?? 'Unknown Status',
            formatTimestamp(session['status']['timestamp']),
            session['unit_price']?.toString() ?? 'Unknown Price',
            session['status']['connector_id'] ?? 0,
            session['details']['charger_accessibility']?.toString() ??
                'Unknown',
            session['details']['charger_type'] ?? 'Unknown Type',
            LatLng(
              double.parse(session['details']['lat'] ?? '0'),
              double.parse(session['details']['long'] ?? '0'),
            ),
          ),
        );
      }
    }
    // Add "All Chargers" based on distance (within 100 km)
    else if (activeFilter == 'All Chargers') {
      for (var charger in availableChargers) {
        if (_currentPosition != null &&
            _calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  double.parse(charger['lat'] ?? '0'),
                  double.parse(charger['long'] ?? '0'),
                ) <=
                100.0) {
          for (var status in charger['status'] ?? [null]) {
            chargerCards.add(
              _buildChargerCard(
                context,
                charger['landmark'] ?? 'Unknown location',
                charger['charger_id'] ?? 'Unknown ID',
                charger['model'] ?? 'Unknown Model',
                status == null
                    ? "Not yet received"
                    : status['charger_status'] ?? 'Unknown Status',
                status == null
                    ? "Not yet received"
                    : formatTimestamp(status['timestamp']),
                charger['unit_price']?.toString() ?? 'Unknown Price',
                status == null
                    ? 0
                    : status['connector_id'] ?? 'Unknown Last Updated',
                charger['charger_accessibility']?.toString() ?? 'Unknown',
                charger['charger_type'] ?? 'Unknown Type',
                LatLng(
                  double.parse(charger['lat'] ?? '0'),
                  double.parse(charger['long'] ?? '0'),
                ),
              ),
            );
          }
        }
      }
    }

    // Wrap the charger cards in a PageView.builder for horizontal scrolling
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: chargerCards.length,
        onPageChanged: (index) {
          _onChargerCardChanged(index); // Handle page change event
        },
        itemBuilder: (context, index) {
          return chargerCards[index];
        },
      ),
    );
  }

  Widget _buildChargerCard(
    BuildContext context,
    String landmark,
    String chargerId,
    String model,
    String status,
    String time,
    String price,
    int connectorId,
    String accessType,
    String chargerType,
    LatLng position,
  ) {
    // Get screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case "Available":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "Unavailable":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case "Preparing":
        statusColor = Colors.yellow;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    // Get the charger from the list based on chargerId
    final charger = availableChargers.firstWhere(
      (c) => c['charger_id'] == chargerId,
      orElse: () => null,
    );

    // Get the address directly from the charger object (fetched once)
    String placeName = charger?['address'] ?? 'Unknown Address';
    placeName = truncateText(placeName, 35);
    landmark = truncateText(landmark, 20);

    return GestureDetector(
      onTap: () async {
        if (charger != null) {
          final lat = double.tryParse(charger['lat']);
          final lng = double.tryParse(charger['long']);
          if (lat != null && lng != null) {
            final destinationPosition = LatLng(lat, lng);
            LatLng startPosition =
                _selectedPosition ?? _currentPosition ?? _center;

            await _smoothlyMoveCameraForChargerMarker(
                startPosition, destinationPosition);

            setState(() {
              _selectedPosition = destinationPosition;
              areMapButtonsEnabled = true;
            });

            BitmapDescriptor newIcon =
                await _getIconFromAsset('assets/icons/EV_location_green.png');
            BitmapDescriptor defaultIcon =
                await _getIconFromAsset('assets/icons/EV_location_red.png');

            setState(() {
              if (_previousMarkerId != null) {
                _markers = _markers.map((marker) {
                  if (marker.markerId == _previousMarkerId) {
                    return marker.copyWith(iconParam: defaultIcon);
                  }
                  return marker;
                }).toSet();
              }

              _markers = _markers.map((marker) {
                if (marker.markerId.value == chargerId) {
                  _previousMarkerId = marker.markerId;
                  return marker.copyWith(iconParam: newIcon);
                }
                return marker;
              }).toSet();
            });
          }
        }
      },
      child: Stack(
        children: [
          Container(
            width: screenWidth * 0.9,
            height: screenHeight * 0.2,
            margin: EdgeInsets.only(
                right: screenWidth * 0.05,
                top: screenHeight * 0.03,
                bottom: screenHeight * 0.05),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '📍 $landmark...',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.037,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              placeName,
                              style: TextStyle(
                                fontSize: screenWidth * 0.033,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  "$chargerId - ",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "[$connectorId] ",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          color: statusColor,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        statusIcon,
                                        color: statusColor,
                                        size: screenWidth * 0.035,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.currency_rupee,
                                      color: Colors.orange,
                                      size: screenWidth * 0.035,
                                    ),
                                    Text(
                                      "$price per unit",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Container(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    chargerType,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavigationButton(context), // Navigation Button
                                        const SizedBox(width: 5),
                      _buildUseChargerButton(
                          context, chargerId), // Use Charger Button
                    ],
                  )
                ],
              ),
            ),
          ),
          SlantedLabel(accessType: accessType),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: GestureDetector(
        onTap: areMapButtonsEnabled
            ? () async {
                if (_selectedPosition != null) {
                  final googleMapsUrl =
                      "https://www.google.com/maps/dir/?api=1&destination=${_selectedPosition!.latitude},${_selectedPosition!.longitude}&travelmode=driving";
                  if (await canLaunch(googleMapsUrl)) {
                    await launch(googleMapsUrl);
                  } else {
                    showErrorDialog(context, 'Could not open the map.');
                  }
                }
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.directions, color: Colors.red),
                onPressed: null,
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: Text(
                  'Navigate',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUseChargerButton(BuildContext context, String chargerId) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          handleSearchRequest(chargerId);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.bolt, color: Colors.yellow),
                onPressed: null,
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.01),
                child: Text(
                  'UseCharger',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Truncate text if it's longer than the max length
  String truncateText(String text, int maxLength) {
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    }
    return text;
  }
}

class ConnectorSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> chargerData;
  final Function(int, int) onConnectorSelected;

  const ConnectorSelectionDialog({
    super.key,
    required this.chargerData,
    required this.onConnectorSelected,
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Connector',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
            shrinkWrap: true,
            itemCount: widget.chargerData.keys
                .where((key) => key.startsWith('connector_'))
                .length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemBuilder: (BuildContext context, int index) {
              int connectorId = index + 1;
              String connectorKey = 'connector_${connectorId}_type';

              if (!widget.chargerData.containsKey(connectorKey) ||
                  widget.chargerData[connectorKey] == null) {
                return const SizedBox.shrink();
              }

              int connectorType = widget.chargerData[connectorKey];

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
                          connectorType == 1
                              ? Icons.power // socket icon
                              : Icons.ev_station, // gun connector icon
                          color: connectorType == 1
                              ? Colors.green // Socket icon color
                              : Colors.red, // Gun connector icon color
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getConnectorTypeName(connectorType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ' - [ $connectorId ]',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
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
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.green.withOpacity(0.2);
                  }
                  return const Color(0xFF1C8B40);
                },
              ),
              minimumSize:
                  WidgetStateProperty.all(const Size(double.infinity, 50)),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: WidgetStateProperty.all(0),
            ),
            child:
                const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SlantedLabel extends StatelessWidget {
  final String accessType;

  const SlantedLabel({required this.accessType, super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: screenHeight * 0.01, // Adjusted for screen height
      right: screenWidth * 0.05, // Adjusted for screen width
      child: Stack(
        children: [
          ClipPath(
            clipper: SlantClipper(),
            child: Container(
              color: accessType == '1'
                  ? const Color(0xFF0E0E0E)
                  : const Color(0xFF0E0E0E),
              height: screenHeight * 0.05, // Adjusted for screen height
              width: screenWidth * 0.25, // Adjusted for screen width
            ),
          ),
          Positioned(
            right: screenWidth * 0.04, // Adjusted for screen width
            top: screenHeight * 0.005, // Adjusted for screen height
            child: Text(
              accessType == '1' ? 'Public' : 'Private',
              style: TextStyle(
                color: accessType == '1' ? Colors.green : Colors.yellow,
                fontWeight: FontWeight.normal,
                fontSize: screenWidth * 0.04, // Adjusted for screen width
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(20, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(20, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8E8E8E)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Calculate offsets for top and bottom reduction
    final offset =
        size.height * 0.1; // Adjust this factor to change the reduction

    // Draw the diagonal line from top-right to bottom-left with equal reduction
    canvas.drawLine(
      Offset(size.width - offset,
          offset), // Starting point (inward from top-right)
      Offset(offset,
          size.height - offset), // Ending point (inward from bottom-left)
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class CurrentLocationMarkerPainter extends CustomPainter {
  final double animatedRadius; // Dynamic radius for animation

  CurrentLocationMarkerPainter({
    required this.animatedRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double outerCircleRadius = animatedRadius; // Use the animated radius
    final double dotRadius = size.width / 8; // Adjusted size for the inner dot
    final double borderThickness = size.width / 24;

    // Draw the translucent outer circle
    final Paint circlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        outerCircleRadius, circlePaint);

    // Draw the solid blue dot without rotation
    final Paint dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), dotRadius, dotPaint);

    // Save the current state of the canvas before rotation
    canvas.save();

    // Translate the canvas to the center of the marker
    canvas.translate(size.width / 2, size.height / 2);

    // Draw the white border with rotation
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness;

    canvas.drawCircle(const Offset(0, 0), dotRadius, borderPaint);

    // Restore the canvas state after drawing the rotated elements
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CurrentLocationMarker extends StatefulWidget {
  const CurrentLocationMarker({super.key});

  @override
  _CurrentLocationMarkerState createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<CurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a slightly longer duration
    _controller = AnimationController(
      duration:
          const Duration(seconds: 2), // Longer duration for smoother animation
      vsync: this,
    )..repeat(reverse: true); // Loop the animation

    // Define the animation for the circle's radius with smoother transitions
    _animation = Tween<double>(begin: 50.0, end: 100.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: CurrentLocationMarkerPainter(
            animatedRadius: _animation.value, // Pass the animated radius
          ),
          child: Container(), // Empty container just to hold the CustomPainter
        );
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool showAlertLoading;
  final Widget child;

  LoadingOverlay(
      {super.key, required this.showAlertLoading, required this.child});

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
