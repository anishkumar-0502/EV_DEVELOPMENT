import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
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
class HomeContent extends StatefulWidget {
  final String username;
  final int? userId;
    final String email;


  const HomeContent({super.key, required this.username, required this.userId, required this.email});

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
  double? _previousBearing;
  bool _isCheckingPermission = false; // Flag to prevent repeated permission checks
  bool _isMapLoading = true; // Track if map is still loading
  bool _isMapIdle = false;  // Track if the map is idle (tiles loaded)

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission(); // Check permissions on initialization
    _updateMarkers();
    activeFilter = 'All Chargers';
    fetchAllChargers();
    _startLiveTracking(); // Start live tracking
}


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }


  Future<void> _checkLocationPermission() async {
    if (_isCheckingPermission) return; // Prevent multiple permission checks

    _isCheckingPermission = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Prompt user to enable location services
      // await _showLocationServicesDialog();
      _isCheckingPermission = false;
      return;
    }

    PermissionStatus permission = await Permission.location.request();
    if (permission.isGranted) {
      await _getCurrentLocation();
    }

    _isCheckingPermission = false;
  }

// This method is already present, but you should keep this logic to handle camera animation
  Future<void> _getCurrentLocation() async {
    // Check if the location permission is granted before attempting to fetch the location
    PermissionStatus permission = await Permission.location.status;
    if (permission.isDenied) {
      // If permission is denied, show the permission denied dialog
      await _showPermissionDeniedDialog();
      return;
    } else if (permission.isPermanentlyDenied) {
      // If permission is permanently denied, show the permanently denied dialog
      await _showPermanentlyDeniedDialog();
      return;
    }

    // If the permission is granted, proceed to fetch the location
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      LatLng? currentLocation = await LocationService.instance.getCurrentLocation();

      if (currentLocation != null) {
        // Update the current position
        setState(() {
          _currentPosition = currentLocation;
        });

        if (mapController != null) {
          // Smoothly animate the camera to the new position
          await mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: 18.0,
                tilt: 45.0,
                bearing: _previousBearing ?? 0,
              ),
            ),
          );
        }

        // Update the map markers with the new position
        await _updateCurrentLocationMarker(_previousBearing ?? 0);
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
      // Only reload the map if the current position has changed
      if (_currentPosition != null && _hasSignificantChange(_currentPosition!, _previousBearing ?? 0)) {
        _reloadPage(); // Reload your content or update the UI only if position changed
      }
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
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Expanded( // Add this to prevent the overflow issue
                    child: Text(
                      "Enable Location", // The heading text
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Optional: add ellipsis if text overflows
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: Text(
            'Location services are required to use this feature. Please enable location services in your phone settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70), // Adjusted text color for contrast
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
                await Geolocator.openLocationSettings(); // Open the location settings
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
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Expanded( // Prevent text overflow
                    child: Text(
                      "Permission Denied",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Optional: add ellipsis if text overflows
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: Text(
            'This app requires location permissions to function correctly. Please grant location permissions in settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70), // Adjusted text color for contrast
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
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Expanded( // Prevent text overflow
                    child: Text(
                      "Permission Denied",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Optional: add ellipsis if text overflows
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: Text(
            'Location permissions are permanently denied. Please enable them in the app settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70), // Adjusted text color for contrast
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



void _reloadPage() {
  setState(() {
    // Update the state to trigger a reload of the HomeContent
    initState(); // Fetch chargers again if necessary
  });
}



  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    rootBundle.loadString('assets/Map/map.json').then((String mapStyle) {
      mapController?.setMapStyle(mapStyle);
    });

    // Ensure map is ready
    setState(() {
      _isMapLoading = false; // Hide the loading spinner
    });

    if (_currentPosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
      _updateMarkers();
    }
  }

  void _onCameraIdle() {
    setState(() {
      _isMapIdle = true; // Set when the map camera stops moving, meaning tiles are loaded
    });
  }

Future<void> _onMarkerTapped(MarkerId markerId, LatLng position) async {
  setState(() {
    _selectedPosition = position;
    areMapButtonsEnabled = true;
  });

  // Smoothly animate the camera to the selected marker
  await _smoothlyMoveCamera(position);

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
          (endPosition.longitude - startPosition.longitude) * (i / totalSteps);
      LatLng intermediatePosition = LatLng(latitude, longitude);

      await mapController!.animateCamera(
        CameraUpdate.newLatLng(intermediatePosition),
      );

      await Future.delayed(Duration(milliseconds: stepDuration.toInt()));
    }
  }
}
Future<void> _smoothlyMoveCameraForChargerMarker(LatLng startPosition, LatLng endPosition) async {
  if (mapController != null) {
    double totalSteps = 25; // Number of animation steps for smooth movement
    double stepDuration = 80; // Duration between steps in milliseconds

    for (int i = 1; i <= totalSteps; i++) {
      double latitude = startPosition.latitude +
          (endPosition.latitude - startPosition.latitude) * (i / totalSteps);
      double longitude = startPosition.longitude +
          (endPosition.longitude - startPosition.longitude) * (i / totalSteps);
      LatLng intermediatePosition = LatLng(latitude, longitude);

      await mapController!.animateCamera(
        CameraUpdate.newLatLng(intermediatePosition),
      );

      await Future.delayed(Duration(milliseconds: stepDuration.toInt()));
    }

    // Once the camera reaches the destination, rotate the camera first
    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: endPosition,
          zoom: 16.0, // Set an initial zoom level before zooming in further
          bearing: 90.0, // Rotate the camera to 90 degrees
          tilt: 0, // Keep the tilt at 0 initially
        ),
      ),
    );

    // Small delay to simulate the effect of rotating the camera
    await Future.delayed(const Duration(milliseconds: 300));

    // After rotating the camera, now zoom in and tilt for the final effect
    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: endPosition,
          zoom: 18.0, // Final zoom level
          tilt: 45.0, // Tilt for a 3D effect
          bearing: 90.0, // Keep the same bearing after rotation
        ),
      ),
    );
  }
}



void _onMapTapped(LatLng position) async {
  setState(() {
    areMapButtonsEnabled = false;
  });

  if (_previousMarkerId != null) {
    // Load the custom red icon
    BitmapDescriptor defaultIcon = await _getIconFromAssetred('assets/icons/EV_location_red.png');

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

  Future<BitmapDescriptor> _getCustomMarkerWithDirection(double bearing) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    const double radius = 50.0;
    final Paint fillPaint = Paint()..color = Colors.blue;
    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw the circle for location
    canvas.drawCircle(Offset(radius, radius), radius, fillPaint);
    canvas.drawCircle(Offset(radius, radius), radius, strokePaint);

    // Draw the directional pointer
    final Path arrowPath = Path()
      ..moveTo(radius, radius * 0.5) // Top of the arrow
      ..lineTo(radius * 0.7, radius * 1.5) // Left side
      ..lineTo(radius * 1.3, radius * 1.5) // Right side
      ..close();

    final Paint arrowPaint = Paint()..color = Colors.white;
    canvas.save();
    canvas.translate(radius, radius); // Move origin to the center
    canvas.rotate(bearing * 3.1415927 / 180); // Rotate according to bearing
    canvas.translate(-radius, -radius); // Move back origin
    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();

    final picture = pictureRecorder.endRecording();
    final img =
        await picture.toImage((radius * 2).toInt(), (radius * 2).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(buffer);
  }
  
  Future<BitmapDescriptor> _createCurrentLocationMarkerIcon(double bearing) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  const double size = 150.0; // Adjust size as needed
  print("_createCurrentLocationMarkerIcon: $bearing");
  // Create the custom marker using CurrentLocationMarkerPainter
  final CurrentLocationMarkerPainter painter = CurrentLocationMarkerPainter(
    bearing: bearing,
    animatedRadius: 80.0 , // Provide a fixed value for animatedRadius
  );
  
  painter.paint(canvas, Size(size, size));

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
      final currentLocationIcon = await _createCurrentLocationMarkerIcon(bearing);

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition!,
            icon: currentLocationIcon,
            infoWindow: const InfoWindow(title: 'Your Location'),
            onTap: () {
              _showCustomInfoWindow(
                'Your Location',
                '',
                _currentPosition!,
              );
            },
          ),
        );
      });
    }


  // Continue updating charger markers only if the position has changed
  for (var charger in availableChargers) {
    final chargerId = charger['charger_id'] ?? 'Unknown Charger ID';
    final lat = charger['lat'] != null ? double.tryParse(charger['lat']) : null;
    final lng = charger['long'] != null ? double.tryParse(charger['long']) : null;

    if (lat != null && lng != null) {
      // Check if the charger location has changed
      if (_previousPosition != null && lat == _previousPosition!.latitude && lng == _previousPosition!.longitude) {
        continue; // Skip if position hasn't changed
      }

      BitmapDescriptor chargerIcon = await _getIconFromAssetred('assets/icons/EV_location_red.png');
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

  void _showCustomInfoWindow(String title, String snippet, LatLng position) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade800, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight:
                  Radius.circular(20), // Adjust the radius value as needed
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.ev_station, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                snippet,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the modal
                      // Add your action here, like navigating to the location
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Navigate',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<BitmapDescriptor> _getIconFromFlutterIcon(
      IconData iconData, Color color, double size) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: iconData.fontFamily,
          color: color,
        ),
      )
      ..layout();

    textPainter.paint(canvas, Offset(0, 0));
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(buffer);
  }

Future<Map<String, dynamic>?> handleSearchRequest(String searchChargerID) async {
  if (isSearching) return null;
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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        this.searchChargerID = searchChargerID;
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
      print(errorData['message'] );
      return {'error': true, 'message': errorData['message']};
    }
  } catch (error) {
    showErrorDialog(context, 'Internal server error ');
    return {'error': true, 'message': 'Internal server error'};
  } finally {
    setState(() {
      isSearching = false;
    });
  }
}

  Future<void> updateConnectorUser(
      String searchChargerID, int connectorId, int connectorType) async {
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
        });
      }
    } else {
      // Show a custom dialog if permission is not granted
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing by tapping outside
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E), // Dark theme background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue, size: 35),
                    SizedBox(width: 10),
                    Text(
                      "Permission Denied",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                CustomGradientDivider(), // Inserted Custom Gradient Divider
              ],
            ),
            content: Column(
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
                  openAppSettings(); // Open app settings
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("Settings", style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
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
    ).then((_) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
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
        body: json.encode({
          'user_id': widget.userId,
        }),
      );
        final data = json.decode(response.body);
        print("datas: $data");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableChargers = data['data'] ?? [];
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

  Future<BitmapDescriptor> _getRotatedIcon({
    required IconData iconData,
    required Color color,
    required double size,
    required double rotation,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: iconData.fontFamily,
          color: color,
        ),
      )
      ..layout();

    canvas.save();
    canvas.translate(
        size / 2, size / 2); // Move the canvas origin to the center
    canvas.rotate(
        rotation * 3.1415927 / 180); // Rotate the canvas to the given bearing
    canvas.translate(-size / 2, -size / 2); // Move back the origin

    textPainter.paint(canvas, Offset(0, 0));
    canvas.restore();

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(buffer);
  }
  Future<BitmapDescriptor> _getDirectionMarker(double bearing) async {
  const double size = 100.0; // Size of the icon
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);

  // Load the image from assets
  final ByteData imageData = await rootBundle.load('assets/arrow.png');
  final ui.Image image = await loadImageFromBytes(imageData.buffer.asUint8List());

  // Adjust the center point based on the arrow's orientation
  final double offsetX = size * 0.25; // 25% from the left
  final double offsetY = size * 0.75; // 75% from the top

  // Draw the image on the canvas
  canvas.save();
  canvas.translate(offsetX, offsetY); // Move origin to the adjusted center
  canvas.rotate(bearing * 3.1415927 / 180); // Rotate according to bearing
  canvas.translate(-offsetX, -offsetY); // Move back origin

  // Draw the image with the same size as the canvas
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, size, size),
    Paint(),
  );

  canvas.restore();

  final picture = pictureRecorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(buffer);
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
  ).listen((Position position) async {
    final LatLng newPosition = LatLng(position.latitude, position.longitude);
    final double newBearing = position.heading;

    // Update the current position and marker if there's a significant change
    if (_hasSignificantChange(newPosition, newBearing)) {
      _currentPosition = newPosition;
      _previousPosition = newPosition;
      _previousBearing = newBearing;

      await _updateCurrentLocationMarker(newBearing);

      // **Remove the automatic camera update** here
      // if (mapController != null) {
      //   mapController!.animateCamera(
      //     CameraUpdate.newCameraPosition(
      //       CameraPosition(
      //         target: _currentPosition!,
      //         zoom: 18.0,
      //         bearing: newBearing,
      //         tilt: 45.0,
      //       ),
      //     ),
      //   );
      // }
    }
  }, onError: (error) {
    print('Error in live tracking: $error');
  });
}


// Function to check if there's a significant change
bool _hasSignificantChange(LatLng newPosition, double newBearing) {
  const double bearingThreshold = 5.0; // Minimum change in degrees to update
  const double distanceThreshold = 0.0001; // Minimum change in distance (in degrees) to update

  final double bearingChange = (_previousBearing != null)
      ? (newBearing - _previousBearing!).abs()
      : double.infinity;
  final double distanceChange = (_previousPosition != null)
      ? Geolocator.distanceBetween(
              _previousPosition!.latitude,
              _previousPosition!.longitude,
              newPosition.latitude,
              newPosition.longitude) /
          1000
      : double.infinity;

  return bearingChange > bearingThreshold || distanceChange > distanceThreshold;
}

Future<void> _updateCurrentLocationMarker(double bearing) async {
  // Create a custom icon that reflects the current bearing
  final currentLocationIcon = await _createCurrentLocationMarkerIcon(bearing);
  print("_updateCurrentLocationMarker: $currentLocationIcon ");
  setState(() {
    // Remove any previous marker for the current location
    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              key: _mapKey, // Assign GlobalKey to GoogleMap
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? _center,
                zoom: 16.0,
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

          // Loading indicator while the map is loading
          if (_isMapLoading || !_isMapIdle)
            Center(
              child: CircularProgressIndicator(), // Show spinner
            ),

          if (!_isMapLoading && _isMapIdle) ...[
          Positioned(
            bottom: 250,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(227, 76, 175, 79),
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
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
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'), // Allow only alphabets and numbers
                        ),
                        FilteringTextInputFormatter.deny(
                          RegExp(r'\s'), // Disallow spaces
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(width: 10),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
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
                        icon: const Icon(Icons.ev_station, color: Colors.white),
                        label: const Text('All Chargers',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
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
              const Spacer(),
              _buildChargerList(),
              // SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
              //   child: Row(
              //     children: <Widget>[
              //       const SizedBox(width: 15),
              //       if (isLoading)
              //         for (var i = 0; i < 3; i++) _buildShimmerCard(),
              //       if (!isLoading && activeFilter == 'Previously Used')
              //         for (var session in recentSessions)
              //           _buildChargerCard(
              //             context,
              //             session['details']['charger_id'] ?? 'Unknown ID',
              //             session['details']['model'] ?? 'Unknown Model',
              //             session['status']['charger_status'] ??
              //                 'Unknown Status',
              //             "1.3 Km",
              //             session['unit_price']?.toString() ?? 'Unknown Price',
              //             session['status']['connector_id'] ?? 0,
              //             session['details']['charger_accessibility']
              //                     ?.toString() ??
              //                 'Unknown',
              //           ),
              //       if (!isLoading && activeFilter == 'All Chargers')
              //       for (var charger in availableChargers)
              //         for (var status in charger['status'] ?? [null])  // If status is null, use [null]
              //           _buildChargerCard(
              //             context,
              //             charger['charger_id'] ?? 'Unknown ID',
              //             charger['model'] ?? 'Unknown Model',
              //             status == null
              //                 ? "Not yet received"  // When status is null
              //                 : status['charger_status'] ?? 'Unknown Status',
              //             "1.3 Km",
              //             charger['unit_price']?.toString() ?? 'Unknown Price',
              //             status == null
              //                 ? 0  // Default connector ID when status is null
              //                 : status['connector_id'] ?? 'Unknown Last Updated',
              //             charger['charger_accessibility']?.toString() ?? 'Unknown',
              //           )
              //     ],
              //   ),
              // ),
              const SizedBox(height: 28),
            ],
          ),
          Positioned(
            bottom: 250,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(227, 76, 175, 79),
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            top: 170,
            right: 10,
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
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.black,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  child:
                      const Icon(Icons.zoom_out_map_rounded, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
        ]
      ),
    );
  }

  Widget _buildChargerList() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 15),
            if (isLoading)
              for (var i = 0; i < 3; i++) _buildShimmerCard(),
            if (!isLoading && activeFilter == 'Previously Used')
              for (var session in recentSessions)
                _buildChargerCard(
                  context,
                  session['details']['charger_id'] ?? 'Unknown ID',
                  session['details']['model'] ?? 'Unknown Model',
                  session['status']['charger_status'] ??
                      'Unknown Status',
                  "1.3 Km",
                  session['unit_price']?.toString() ?? 'Unknown Price',
                  session['status']['connector_id'] ?? 0,
                  session['details']['charger_accessibility']
                          ?.toString() ??
                      'Unknown',
                ),
            if (!isLoading && activeFilter == 'All Chargers')
            for (var charger in availableChargers)
              for (var status in charger['status'] ?? [null])  // If status is null, use [null]
                _buildChargerCard(
                  context,
                  charger['charger_id'] ?? 'Unknown ID',
                  charger['model'] ?? 'Unknown Model',
                  status == null
                      ? "Not yet received"  // When status is null
                      : status['charger_status'] ?? 'Unknown Status',
                  "1.3 Km",
                  charger['unit_price']?.toString() ?? 'Unknown Price',
                  status == null
                      ? 0  // Default connector ID when status is null
                      : status['connector_id'] ?? 'Unknown Last Updated',
                  charger['charger_accessibility']?.toString() ?? 'Unknown',
                )
          ],
        ),
      );
  }

  Widget _buildChargerCard(
    BuildContext context,
    String chargerId,
    String model,
    String status,
    String meter,
    String price,
    int connectorId,
    String accessType,
  ) {
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

    final charger = availableChargers.firstWhere(
      (c) => c['charger_id'] == chargerId,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () async {
        if (charger != null) {
          final lat = double.tryParse(charger['lat']);
          final lng = double.tryParse(charger['long']);
          if (lat != null && lng != null) {
            final destinationPosition = LatLng(lat, lng);

            // Use the current charger position as the start position
            LatLng startPosition = _selectedPosition ?? _currentPosition ?? _center;

            // Smoothly move the camera from the current position to the destination charger position
            await _smoothlyMoveCameraForChargerMarker(startPosition, destinationPosition);

            // Set the new selected position and enable map buttons
            setState(() {
              _selectedPosition = destinationPosition;
              areMapButtonsEnabled = true;
            });


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
            width: 315,
            margin: const EdgeInsets.only(right: 28, top: 20),
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
            child: Padding(
              padding: const EdgeInsets.all(10.0),
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
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "$chargerId - ",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "[$connectorId]",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              model,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 14,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  meter,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.currency_rupee,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    Text(
                                      "$price per unit",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                        onTap: areMapButtonsEnabled
                                  ? () async {
                                      if (_selectedPosition != null) {
                                        final googleMapsUrl =
                                            "https://www.google.com/maps/dir/?api=1&destination=${_selectedPosition!.latitude},${_selectedPosition!.longitude}&travelmode=driving";
                                        if (await canLaunch(googleMapsUrl)) {
                                          await launch(googleMapsUrl);
                                        } else {
                                          showErrorDialog(context,
                                              'Could not open the map. Please check your internet connection or try again later.');
                                        }
                                      }
                                    }
                                  : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.directions, color: Colors.red),
                                  onPressed: areMapButtonsEnabled
                                  ? () async {
                                      if (_selectedPosition != null) {
                                        final googleMapsUrl =
                                            "https://www.google.com/maps/dir/?api=1&destination=${_selectedPosition!.latitude},${_selectedPosition!.longitude}&travelmode=driving";
                                        if (await canLaunch(googleMapsUrl)) {
                                          await launch(googleMapsUrl);
                                        } else {
                                          showErrorDialog(context,
                                              'Could not open the map. Please check your internet connection or try again later.');
                                        }
                                      }
                                    }
                                  : null,
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Navigate',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            handleSearchRequest(chargerId);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.bolt, color: Colors.yellow),
                                  onPressed: null, // Remove the redundant onPressed
                                ),
                                const Text(
                                  ' Use Charger',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SlantedLabel(accessType: accessType),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 15.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 20,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Container(
                width: 80,
                height: 20,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class ConnectorSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> chargerData;
  final Function(int, int) onConnectorSelected;

  const ConnectorSelectionDialog({
    Key? key,
    required this.chargerData,
    required this.onConnectorSelected,
  }) : super(key: key);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Connector',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst); // Close the QR code scanner page and return to the Home Page
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomGradientDivider(),
          const SizedBox(height: 20),
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
                    child: Text(
                      'Connector $connectorId',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
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
              minimumSize:
                  MaterialStateProperty.all(const Size(double.infinity, 50)),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
              side: MaterialStateProperty.resolveWith<BorderSide>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return const BorderSide(color: Colors.transparent);
                  }
                  return const BorderSide(color: Colors.transparent);
                },
              ),
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

  const SlantedLabel({required this.accessType, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 28,
      child: Stack(
        children: [
          ClipPath(
            clipper: SlantClipper(),
            child: Container(
              color: accessType == '1'
                  ? const Color(0xFF0E0E0E)
                  : const Color(0xFF0E0E0E),
              height: 40,
              width: 100,
            ),
          ),
          Positioned(
            right: 18,
            top: 5,
            child: Text(
              accessType == '1' ? 'Public' : 'Private',
              style: TextStyle(
                color: accessType == '1' ? Colors.green : Colors.yellow,
                fontWeight: FontWeight.normal,
                fontSize: 15,
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
  final double bearing; // Direction bearing
  final double animatedRadius; // Dynamic radius for animation

  CurrentLocationMarkerPainter({
    required this.bearing,
    required this.animatedRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double outerCircleRadius = animatedRadius; // Use the animated radius
    final double dotRadius = size.width / 5; // Adjusted size for the inner dot
    final double borderThickness = size.width / 20;

    // Draw the translucent outer circle
    final Paint circlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), outerCircleRadius, circlePaint);

    // Draw the solid blue dot without rotation
    final Paint dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), dotRadius, dotPaint);

    // Save the current state of the canvas before rotation
    canvas.save();

    // Translate the canvas to the center of the marker
    canvas.translate(size.width / 2, size.height / 2);

    // Rotate the canvas based on the bearing
    canvas.rotate(bearing * 3.1415927 / 180);

    // Draw the white border with rotation
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness;

    canvas.drawCircle(Offset(0, 0), dotRadius, borderPaint);

    // Draw the arrow pointing in the bearing direction
    final Path arrowPath = Path()
      ..moveTo(0, -outerCircleRadius) // Start at the top point
      ..lineTo(-outerCircleRadius / 3, -outerCircleRadius / 2) // Left side of arrow
      ..lineTo(outerCircleRadius / 3, -outerCircleRadius / 2) // Right side of arrow
      ..close(); // Connect to the starting point

    final Paint arrowPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);

    // Restore the canvas state after drawing the rotated elements
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CurrentLocationMarker extends StatefulWidget {
  final double bearing;

  CurrentLocationMarker({required this.bearing});

  @override
  _CurrentLocationMarkerState createState() => _CurrentLocationMarkerState();
}
class _CurrentLocationMarkerState extends State<CurrentLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a slightly longer duration
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Longer duration for smoother animation
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
            bearing: widget.bearing,
            animatedRadius: _animation.value, // Pass the animated radius
          ),
          child: Container(), // Empty container just to hold the CustomPainter
        );
      },
    );
  }
}

