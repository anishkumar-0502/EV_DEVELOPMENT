
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  LatLng? _currentLocation;

  LocationService._internal();

  static LocationService get instance => _instance;

  Future<LatLng?> getCurrentLocation() async {
    if (_currentLocation == null) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLocation = LatLng(position.latitude, position.longitude);
    }
    return _currentLocation;
  }

  void updateCurrentLocation(LatLng newLocation) {
    _currentLocation = newLocation;
  }
}
