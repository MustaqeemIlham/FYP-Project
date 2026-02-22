import 'package:geolocator/geolocator.dart';

class LocationService {
  // Request location permission
  static Future<bool> handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // User denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // Permissions permanently denied
    }

    return true;
  }

  // Get current user position
  static Future<Position?> getCurrentLocation() async {
    // ✅ Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled.");
    }

    // ✅ Check permission
    bool hasPermission = await handlePermission();
    if (!hasPermission) return null;

    // ✅ Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
