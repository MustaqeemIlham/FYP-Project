import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const LiveMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(latitude, longitude),
        initialZoom: 14.0,
      ),
      children: [

        TileLayer(
  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  userAgentPackageName: "com.example.weather_app", 
),

        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(latitude, longitude),
              width: 50,
              height: 50,
              child: const Icon(Icons.location_pin,
                  size: 40, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}
