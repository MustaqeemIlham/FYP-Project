import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:weather_app/widget/livemap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🔑 Replace with your own API keys
const String openWeatherApiKey = "67871e5f4daba4a75732e8bb84f74c12"; 
const String ambeeApiKey = "40d31519afd573c8a2b4655d4367f24eed431cde4080af5a4fe9cf5487691900";

// Location data class for manual selection
class LocationData {
  final String state;
  final String city;
  final double lat;
  final double lon;

  LocationData({
    required this.state,
    required this.city,
    required this.lat,
    required this.lon,
  });

  String get displayName => "$city, $state";
}

// Malaysia States and Cities Data
final Map<String, List<LocationData>> _malaysiaLocations = {
  "Johor": [
    LocationData(state: "Johor", city: "Johor Bahru", lat: 1.4927, lon: 103.7414),
    LocationData(state: "Johor", city: "Batu Pahat", lat: 1.8492, lon: 102.9284),
    LocationData(state: "Johor", city: "Muar", lat: 2.0442, lon: 102.5689),
    LocationData(state: "Johor", city: "Kluang", lat: 2.0306, lon: 103.3189),
    LocationData(state: "Johor", city: "Kulai", lat: 1.6686, lon: 103.6036),
    LocationData(state: "Johor", city: "Pontian", lat: 1.4877, lon: 103.3896),
    LocationData(state: "Johor", city: "Segamat", lat: 2.5148, lon: 102.8158),
    LocationData(state: "Johor", city: "Tangkak", lat: 2.2679, lon: 102.5456),
  ],
  "Kedah": [
    LocationData(state: "Kedah", city: "Alor Setar", lat: 6.1248, lon: 100.3678),
    LocationData(state: "Kedah", city: "Sungai Petani", lat: 5.6471, lon: 100.4877),
    LocationData(state: "Kedah", city: "Kulim", lat: 5.3647, lon: 100.5618),
    LocationData(state: "Kedah", city: "Langkawi", lat: 6.3500, lon: 99.8000),
    LocationData(state: "Kedah", city: "Jitra", lat: 6.2685, lon: 100.4216),
    LocationData(state: "Kedah", city: "Pokok Sena", lat: 6.1719, lon: 100.5120),
  ],
  "Kelantan": [
    LocationData(state: "Kelantan", city: "Kota Bharu", lat: 6.1254, lon: 102.2386),
    LocationData(state: "Kelantan", city: "Pasir Mas", lat: 6.0493, lon: 102.1394),
    LocationData(state: "Kelantan", city: "Tanah Merah", lat: 5.8087, lon: 102.1472),
    LocationData(state: "Kelantan", city: "Kuala Krai", lat: 5.5307, lon: 102.2017),
    LocationData(state: "Kelantan", city: "Gua Musang", lat: 4.8844, lon: 101.9686),
  ],
  "Melaka": [
    LocationData(state: "Melaka", city: "Melaka City", lat: 2.1896, lon: 102.2501),
    LocationData(state: "Melaka", city: "Alor Gajah", lat: 2.3844, lon: 102.2089),
    LocationData(state: "Melaka", city: "Jasin", lat: 2.3097, lon: 102.4300),
    LocationData(state: "Melaka", city: "Masjid Tanah", lat: 2.3504, lon: 102.1094),
  ],
  "Negeri Sembilan": [
    LocationData(state: "Negeri Sembilan", city: "Seremban", lat: 2.7259, lon: 101.9378),
    LocationData(state: "Negeri Sembilan", city: "Port Dickson", lat: 2.5225, lon: 101.7964),
    LocationData(state: "Negeri Sembilan", city: "Nilai", lat: 2.8033, lon: 101.7903),
    LocationData(state: "Negeri Sembilan", city: "Rembau", lat: 2.5897, lon: 102.0911),
    LocationData(state: "Negeri Sembilan", city: "Jelebu", lat: 2.9375, lon: 102.0722),
    LocationData(state: "Negeri Sembilan", city: "Kuala Pilah", lat: 2.7389, lon: 102.2483),
  ],
  "Pahang": [
    LocationData(state: "Pahang", city: "Kuantan", lat: 3.8167, lon: 103.3333),
    LocationData(state: "Pahang", city: "Bentong", lat: 3.5228, lon: 101.9086),
    LocationData(state: "Pahang", city: "Temerloh", lat: 3.4506, lon: 102.4175),
    LocationData(state: "Pahang", city: "Raub", lat: 3.7906, lon: 101.8572),
    LocationData(state: "Pahang", city: "Jerantut", lat: 3.9361, lon: 102.3622),
    LocationData(state: "Pahang", city: "Cameron Highlands", lat: 4.4675, lon: 101.3767),
    LocationData(state: "Pahang", city: "Pekan", lat: 3.4944, lon: 103.3897),
  ],
  "Perak": [
    LocationData(state: "Perak", city: "Ipoh", lat: 4.5975, lon: 101.0901),
    LocationData(state: "Perak", city: "Taiping", lat: 4.8510, lon: 100.7410),
    LocationData(state: "Perak", city: "Teluk Intan", lat: 4.0251, lon: 101.0213),
    LocationData(state: "Perak", city: "Sitiawan", lat: 4.2167, lon: 100.7000),
    LocationData(state: "Perak", city: "Kuala Kangsar", lat: 4.7727, lon: 100.9373),
    LocationData(state: "Perak", city: "Kampar", lat: 4.3000, lon: 101.1500),
    LocationData(state: "Perak", city: "Batu Gajah", lat: 4.4694, lon: 101.0411),
    LocationData(state: "Perak", city: "Tapah", lat: 4.1975, lon: 101.2636),
  ],
  "Perlis": [
    LocationData(state: "Perlis", city: "Kangar", lat: 6.4414, lon: 100.1986),
    LocationData(state: "Perlis", city: "Arau", lat: 6.4294, lon: 100.2692),
    LocationData(state: "Perlis", city: "Padang Besar", lat: 6.6633, lon: 100.3217),
  ],
  "Penang": [
    LocationData(state: "Penang", city: "George Town", lat: 5.4149, lon: 100.3298),
    LocationData(state: "Penang", city: "Butterworth", lat: 5.3992, lon: 100.3639),
    LocationData(state: "Penang", city: "Bukit Mertajam", lat: 5.3631, lon: 100.4667),
    LocationData(state: "Penang", city: "Bayan Lepas", lat: 5.2833, lon: 100.2667),
    LocationData(state: "Penang", city: "Nibong Tebal", lat: 5.1659, lon: 100.4779),
  ],
  "Sabah": [
    LocationData(state: "Sabah", city: "Kota Kinabalu", lat: 5.9804, lon: 116.0735),
    LocationData(state: "Sabah", city: "Sandakan", lat: 5.8388, lon: 118.1173),
    LocationData(state: "Sabah", city: "Tawau", lat: 4.2447, lon: 117.8912),
    LocationData(state: "Sabah", city: "Lahad Datu", lat: 5.0333, lon: 118.3167),
    LocationData(state: "Sabah", city: "Keningau", lat: 5.3378, lon: 116.1603),
    LocationData(state: "Sabah", city: "Semporna", lat: 4.4811, lon: 118.6158),
    LocationData(state: "Sabah", city: "Kudat", lat: 6.8833, lon: 116.8333),
  ],
  "Sarawak": [
    LocationData(state: "Sarawak", city: "Kuching", lat: 1.5535, lon: 110.3593),
    LocationData(state: "Sarawak", city: "Miri", lat: 4.3995, lon: 113.9914),
    LocationData(state: "Sarawak", city: "Sibu", lat: 2.2870, lon: 111.8305),
    LocationData(state: "Sarawak", city: "Bintulu", lat: 3.1713, lon: 113.0419),
    LocationData(state: "Sarawak", city: "Limbang", lat: 4.7500, lon: 115.0000),
    LocationData(state: "Sarawak", city: "Sri Aman", lat: 1.2372, lon: 111.4625),
    LocationData(state: "Sarawak", city: "Sarikei", lat: 2.1167, lon: 111.5167),
    LocationData(state: "Sarawak", city: "Kapit", lat: 2.0167, lon: 112.9333),
  ],
  "Selangor": [
    LocationData(state: "Selangor", city: "Shah Alam", lat: 3.0738, lon: 101.5183),
    LocationData(state: "Selangor", city: "Petaling Jaya", lat: 3.1073, lon: 101.6067),
    LocationData(state: "Selangor", city: "Klang", lat: 3.0449, lon: 101.4456),
    LocationData(state: "Selangor", city: "Subang Jaya", lat: 3.0656, lon: 101.5871),
    LocationData(state: "Selangor", city: "Kajang", lat: 2.9935, lon: 101.7903),
    LocationData(state: "Selangor", city: "Selayang", lat: 3.2381, lon: 101.6542),
    LocationData(state: "Selangor", city: "Rawang", lat: 3.3213, lon: 101.5767),
    LocationData(state: "Selangor", city: "Semenyih", lat: 2.9526, lon: 101.8430),
    LocationData(state: "Selangor", city: "Sepang", lat: 2.6914, lon: 101.7500),
  ],
  "Terengganu": [
    LocationData(state: "Terengganu", city: "Kuala Terengganu", lat: 5.3296, lon: 103.1370),
    LocationData(state: "Terengganu", city: "Kemaman", lat: 4.2333, lon: 103.4167),
    LocationData(state: "Terengganu", city: "Dungun", lat: 4.7667, lon: 103.4167),
    LocationData(state: "Terengganu", city: "Besut", lat: 5.8333, lon: 102.5500),
    LocationData(state: "Terengganu", city: "Marang", lat: 5.2056, lon: 103.2058),
    LocationData(state: "Terengganu", city: "Setiu", lat: 5.4167, lon: 102.8333),
  ],
  "Kuala Lumpur": [
    LocationData(state: "Kuala Lumpur", city: "Kuala Lumpur", lat: 3.1390, lon: 101.6869),
    LocationData(state: "Kuala Lumpur", city: "Cheras", lat: 3.0700, lon: 101.7600),
    LocationData(state: "Kuala Lumpur", city: "Batu", lat: 3.2308, lon: 101.6842),
    LocationData(state: "Kuala Lumpur", city: "Wangsa Maju", lat: 3.1989, lon: 101.7414),
    LocationData(state: "Kuala Lumpur", city: "Setapak", lat: 3.2011, lon: 101.7150),
  ],
  "Putrajaya": [
    LocationData(state: "Putrajaya", city: "Putrajaya", lat: 2.9264, lon: 101.6964),
  ],
  "Labuan": [
    LocationData(state: "Labuan", city: "Labuan", lat: 5.2831, lon: 115.2308),
    LocationData(state: "Labuan", city: "Victoria", lat: 5.2767, lon: 115.2417),
  ],
};

// Get all locations as a flat list
List<LocationData> get _allLocations {
  List<LocationData> all = [];
  _malaysiaLocations.forEach((state, locations) {
    all.addAll(locations);
  });
  return all;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentLocation = "Fetching...";
  Position? _currentPosition;
  LocationData? _selectedLocation;
  String? _selectedStateFilter;
  final TextEditingController _searchController = TextEditingController();

  Map<String, String> _weatherData = {};
  bool _isLoading = true;

  // ADDED: Variable for planting date selection
  DateTime? _selectedPlantingDate;
  
  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.recommend), label: 'Recommendation'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    
    // Initialize planting date with current date
    _selectedPlantingDate = DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper function to get week of year from date
  int _getWeekOfYear(DateTime date) {
    // Simple calculation: week number based on days passed
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(firstDayOfYear).inDays;
    return ((daysPassed + firstDayOfYear.weekday + 6) / 7).floor();
  }

  // Method to show location selection dialog
  void _showLocationSelectionDialog() {
    // Create local state for the dialog
    String? dialogSelectedState = _selectedStateFilter;
    TextEditingController dialogSearchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Select Location'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    // Current location option
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.my_location, color: Colors.blue),
                        title: const Text('Use Current Location'),
                        subtitle: const Text('Get your exact GPS location'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          _useCurrentLocation();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Search field
                    // TextField(
                    //   controller: dialogSearchController,
                    //   decoration: InputDecoration(
                    //     hintText: 'Search city or state...',
                    //     prefixIcon: const Icon(Icons.search),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    //     suffixIcon: dialogSearchController.text.isNotEmpty
                    //         ? IconButton(
                    //             icon: const Icon(Icons.clear),
                    //             onPressed: () {
                    //               dialogSearchController.clear();
                    //               setDialogState(() {});
                    //             },
                    //           )
                    //         : null,
                    //   ),
                    //   onChanged: (value) {
                    //     setDialogState(() {});
                    //   },
                    // ),
                    
                    const SizedBox(height: 10),
                    
                    // State filter chips
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // All states chip
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: dialogSelectedState == null,
                              onSelected: (selected) {
                                setDialogState(() {
                                  dialogSelectedState = null;
                                });
                              },
                              backgroundColor: dialogSelectedState == null ? Colors.green[100] : null,
                              selectedColor: Colors.green[200],
                            ),
                          ),
                          
                          // State chips
                          ..._malaysiaLocations.keys.map((state) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: FilterChip(
                                label: Text(state),
                                selected: dialogSelectedState == state,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    dialogSelectedState = selected ? state : null;
                                  });
                                },
                                backgroundColor: dialogSelectedState == state ? Colors.green[100] : null,
                                selectedColor: Colors.green[200],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    const Divider(),
                    
                    // Location count
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Locations (${_getFilteredLocationsForDialog(dialogSelectedState, dialogSearchController.text).length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          // if (dialogSelectedState != null)
                          //   Chip(
                          //     label: Text(dialogSelectedState!),
                          //     backgroundColor: Colors.green[50],
                          //     side: BorderSide(color: Colors.green[300]!),
                          //   ),
                        ],
                      ),
                    ),
                    
                    // List of available locations
                    Expanded(
                      child: _buildLocationsList(dialogSelectedState, dialogSearchController.text),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocationsList(String? stateFilter, String searchText) {
    final filteredLocations = _getFilteredLocationsForDialog(stateFilter, searchText);
    
    if (filteredLocations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('No locations found'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.location_city, color: Colors.green),
            title: Text(
              location.city,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(location.state),
            trailing: _selectedLocation == location
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _useManualLocation(location);
            },
          ),
        );
      },
    );
  }

  // Helper method to get filtered locations for dialog
  List<LocationData> _getFilteredLocationsForDialog(String? stateFilter, String searchText) {
    List<LocationData> locations = _allLocations;
    
    // Filter by state if selected
    if (stateFilter != null && _malaysiaLocations.containsKey(stateFilter)) {
      locations = _malaysiaLocations[stateFilter]!;
    }
    
    // Filter by search text
    final searchTextLower = searchText.toLowerCase();
    if (searchTextLower.isNotEmpty) {
      locations = locations.where((location) {
        return location.city.toLowerCase().contains(searchTextLower) ||
               location.state.toLowerCase().contains(searchTextLower);
      }).toList();
    }
    
    // Sort by city name
    locations.sort((a, b) => a.city.compareTo(b.city));
    
    return locations;
  }

  // Method to use current GPS location
  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _currentLocation = "Getting location...";
      _selectedLocation = null;
    });

    await _checkLocationPermission();
  }

  // Method to use manually selected location
  Future<void> _useManualLocation(LocationData location) async {
    setState(() {
      _isLoading = true;
      _currentLocation = location.displayName;
      _selectedLocation = location;
      _currentPosition = Position(
        latitude: location.lat,
        longitude: location.lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    });

    try {
      // Clear existing weather data first
      _weatherData.clear();
      
      // Fetch weather data for manual location
      await _fetchWeatherData(location.lat, location.lon);
      
      // Also fetch soil data after manual location change
      await _fetchSoilData();
      
    } catch (e) {
      print("Error using manual location: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check location permission
  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog("Location services are disabled. Please enable them in settings.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog("Location permission denied. Please allow access.");
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog("Location permission is permanently denied. Please enable it in settings.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      Placemark place = placemarks.first;

      setState(() {
        _currentPosition = pos;
        _currentLocation = "${place.locality ?? ''}, ${place.country ?? ''}";
        _selectedLocation = null;
      });

      // Clear existing data first
      _weatherData.clear();
      
      // Fetch both weather and soil data
      await Future.wait([
        _fetchWeatherData(pos.latitude, pos.longitude),
        _fetchSoilData(),
      ]);
      
    } catch (e) {
      print("Error fetching location: $e");
      setState(() {
        _currentLocation = "Unable to fetch location";
        _isLoading = false;
      });
    }
  }

Future<void> _fetchWeatherData(double lat, double lon) async {
  try {
    final url =
        "https://api.weatherapi.com/v1/forecast.json?key=6151a8c29de54bfb8ba24520250109&q=$lat,$lon&days=3&aqi=no&alerts=no";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final forecast = data['forecast']['forecastday'];

      double avgTemp = 0;
      double avgHumidity = 0;
      double totalRain = 0;
      int count = forecast.length;

      for (var day in forecast) {
        avgTemp += day['day']['avgtemp_c'];
        avgHumidity += day['day']['avghumidity'];
        totalRain += (day['day']['totalprecip_mm'] ?? 0).toDouble();
      }

      avgTemp /= count;
      avgHumidity /= count;

      // Scale 3-day data to monthly
      double monthlyAvgTemp = avgTemp;
      double monthlyAvgHumidity = avgHumidity;
      double monthlyTotalRain = totalRain * 10; // Scale to monthly

      // Adjust for seasonality
      final now = DateTime.now();
      final month = now.month;
      
      if (month >= 11 || month <= 2) {
        // Monsoon season
        monthlyTotalRain *= 1.3;
        monthlyAvgHumidity *= 1.1;
      } else if (month >= 3 && month <= 9) {
        // Drier months
        monthlyTotalRain *= 0.7;
        monthlyAvgHumidity *= 0.9;
      }

      setState(() {
        _weatherData["Temperature"] = "${monthlyAvgTemp.toStringAsFixed(1)}°C";
        _weatherData["Humidity"] = "${monthlyAvgHumidity.toStringAsFixed(1)}%";
        _weatherData["Rainfall"] = "${monthlyTotalRain.toStringAsFixed(1)} mm";
      });
    } else {
      setState(() {
        _weatherData["Weather Error"] = "Failed to fetch weather";
      });
    }
  } catch (e) {
    print("Error fetching weather data: $e");
    setState(() {
      _weatherData["Weather Error"] = "Network error";
    });
  }
}

Future<void> _fetchSoilData() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _weatherData["Soil pH (0-5cm)"] = "No user";
        _weatherData["Nitrogen"] = "No user";
        _weatherData["Phosphorus"] = "No user";
        _weatherData["Potassium"] = "No user";
        _isLoading = false;
      });
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userid', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data();

      setState(() {
        _weatherData["Soil pH (0-5cm)"] = data["phsoil"]?.toString() ?? "N/A";
        _weatherData["Nitrogen"] = data["nitrogen"]?.toString() ?? "N/A";
        _weatherData["Phosphorus"] = data["phosphorus"]?.toString() ?? "N/A";
        _weatherData["Potassium"] = data["potassium"]?.toString() ?? "N/A";
        _isLoading = false;
      });
    } else {
      setState(() {
        _weatherData["Soil pH (0-5cm)"] = "No data";
        _weatherData["Nitrogen"] = "No data";
        _weatherData["Phosphorus"] = "No data";
        _weatherData["Potassium"] = "No data";
        _isLoading = false;
      });
    }
  } catch (e) {
    print("Error fetching soil data: $e");
    setState(() {
      _weatherData["Soil pH (0-5cm)"] = "Error";
      _weatherData["Nitrogen"] = "Error";
      _weatherData["Phosphorus"] = "Error";
      _weatherData["Potassium"] = "Error";
      _isLoading = false;
    });
  }
}

  void _showLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showMissingValuesDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Missing Soil Data"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/reco')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  // Widget for planting date selection
  Widget _buildPlantingDateSelection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  "Planting Date Selection",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Select when you want to plant:",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Date picker button
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _selectedPlantingDate != null
                    ? DateFormat('dd MMMM yyyy').format(_selectedPlantingDate!)
                    : "Pick a planting date",
              ),
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedPlantingDate = pickedDate;
                  });
                }
              },
            ),
            
            // Show selected date info
            if (_selectedPlantingDate != null) ...[
              const SizedBox(height: 12),
              Text(
                "Selected: ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedPlantingDate!)}",
                style: TextStyle(color: Colors.green[700]),
              ),
              Text(
                "Week ${((_selectedPlantingDate!.day - 1) ~/ 7) + 1} of ${DateFormat('MMMM').format(_selectedPlantingDate!)}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: const [
            Icon(Icons.home, color: Colors.white),
            SizedBox(width: 6),
            Text(
              "Home",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _checkLocationPermission(),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/noti'),
            color: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location header with change icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📍 $_currentLocation",
                                style: const TextStyle(fontSize: 20),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedLocation != null)
                                Text(
                                  'Tap to change location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Change location button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_location_alt, color: Colors.green),
                      onPressed: _showLocationSelectionDialog,
                      tooltip: 'Change Location',
                    ),
                  ),
                ],
              ),
              
              // Current location indicator
              if (_selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Using manual location: ${_selectedLocation!.displayName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // Map container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : LiveMap(
                        latitude: _currentPosition!.latitude,
                        longitude: _currentPosition!.longitude,
                      ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Current Conditions',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _weatherData.isEmpty
                      ? const Center(child: Text('No data available'))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _weatherData.length,
                          itemBuilder: (context, index) {
                            String key = _weatherData.keys.elementAt(index);
                            String value = _weatherData[key]!;
                            return MetricCard(
                              icon: _getIconForMetric(key),
                              title: key,
                              value: value,
                              color: Colors.green,
                            );
                          },
                        ),

              // ADDED: Planting date selection section
              _buildPlantingDateSelection(),

              const SizedBox(height: 8),

SizedBox(
  width: double.infinity,
  height: 53,
  child: ElevatedButton.icon(
    onPressed: () async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showMissingValuesDialog("Please fill your soil values first in your profile.");
        return;
      }

      final data = querySnapshot.docs.first.data();

      final ph = data["phsoil"];
      final nitrogen = data["nitrogen"];
      final phosphorus = data["phosphorus"];
      final potassium = data["potassium"];
      final now = DateTime.now();
      final time = FieldValue.serverTimestamp();
      
      // Use selected planting date or current date
      final plantingDate = _selectedPlantingDate ?? now;
      final year = plantingDate.year;
      final month = plantingDate.month;
      final weekOfMonth = ((plantingDate.day - 1) ~/ 7) + 1;
      final weekOfYear = _getWeekOfYear(plantingDate);
      
      // Extract weather values
      double avgTemp, humidity, rainfall;
      
      final tempStr = _weatherData["Temperature"] ?? 
                     _weatherData["Avg Temp (14d)"] ?? "28.0";
      final humidityStr = _weatherData["Humidity"] ?? 
                         _weatherData["Avg Humidity (14d)"] ?? "85.0";
      final rainfallStr = _weatherData["Rainfall"] ?? 
                         _weatherData["Total Rainfall (14d)"] ?? "200.0";
      
      avgTemp = double.tryParse(tempStr.replaceAll("°C", "").trim()) ?? 28.0;
      humidity = double.tryParse(humidityStr.replaceAll("%", "").trim()) ?? 85.0;
      rainfall = double.tryParse(rainfallStr.replaceAll(" mm", "").trim()) ?? 200.0;
      
      // Log what we're sending
      print("📤 Sending to API:");
      print("  Temperature: $avgTemp°C");
      print("  Humidity: $humidity%");
      print("  Rainfall: ${rainfall}mm");
      print("  Soil: pH=$ph, N=$nitrogen, P=$phosphorus, K=$potassium");
      print("  Planting Date: ${DateFormat('dd/MM/yyyy').format(plantingDate)}");
      print("  Planting Time: Year=$year, Month=$month, Week=$weekOfMonth (Week $weekOfYear of year)");
      
      if (ph == null || nitrogen == null || phosphorus == null || potassium == null) {
        _showMissingValuesDialog(
          "Please fill in Soil pH, Nitrogen, Phosphorus, and Potassium values first.",
        );
      } else {
        try {
          print("🔹 Step 1: Sending request to API...");
          final url = Uri.parse("https://smilacaceous-retha-vespine.ngrok-free.dev/recommend");
          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "ph": double.tryParse(ph.toString()) ?? 0.0,
              "nitrogen": double.tryParse(nitrogen.toString()) ?? 0.0,
              "phosphorus": double.tryParse(phosphorus.toString()) ?? 0.0,
              "potassium": double.tryParse(potassium.toString()) ?? 0.0,
              "avg_temp": avgTemp,
              "humidity": humidity,
              "rainfall": rainfall,
              
              // Send exact planting date (Option 3)
              "planting_date": DateFormat('yyyy-MM-dd').format(plantingDate),
              
              // For backward compatibility
              "year": year,
              "month": month,
              "week_of_month": weekOfMonth,
              "current_week": _getWeekOfYear(now),
            }),
          );

          print("🔹 Step 2: Got response with status: ${response.statusCode}");
          print("🔹 Response body: ${response.body}");

          if (response.statusCode == 200) {
            print("✅ API Success, parsing JSON...");
            final result = json.decode(response.body);
            print("🔹 API Response: $result");

            final recommendation = result["recommendation"];

            if (recommendation == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result["message"] ?? "No crop recommendation found"))
              );
              return;
            }

          final price = (recommendation["price"] as num).toDouble();
          final priceFixed = double.parse(price.toStringAsFixed(2));
          final cropName = recommendation["cropname"].toString();
          final desc = recommendation["description"];
          final growthCycleWeeks = recommendation["growth_cycle_weeks"] ?? 12;

          // Calculate harvest date
          DateTime harvestDate;
          
          // Try to get harvest date from API first
          if (recommendation["harvest_date"] != null) {
            harvestDate = DateFormat('yyyy-MM-dd').parse(recommendation["harvest_date"]);
          } else {
            // Calculate harvest date in Flutter
            harvestDate = plantingDate.add(Duration(days: growthCycleWeeks * 7));
          }

          print("🔹 Step 3: Parsed values → crop=$cropName, price=$priceFixed");
          print("🔹 Growth Cycle: $growthCycleWeeks weeks");
          print("🔹 Planting: ${DateFormat('dd/MM/yyyy').format(plantingDate)}");
          print("🔹 Harvest: ${DateFormat('dd/MM/yyyy').format(harvestDate)}");

          // Save to Firestore
          print("🔹 Step 4: Saving to Firestore...");
          await FirebaseFirestore.instance.collection("history").add({
            "userid": currentUser.uid,
            "date": time,
            "cropname": cropName,
            "price": priceFixed,
            "description": desc,
            "growth_cycle_weeks": growthCycleWeeks,
            
            // Planting information
            "planting_date": Timestamp.fromDate(plantingDate),
            "planting_year": plantingDate.year,
            "planting_month": plantingDate.month,
            "planting_week_of_month": weekOfMonth,
            "planting_week_of_year": weekOfYear,
            
            // Harvest information
            "harvest_date": Timestamp.fromDate(harvestDate),
            "harvest_year": harvestDate.year,
            "harvest_month": harvestDate.month,
            "harvest_week_of_month": ((harvestDate.day - 1) ~/ 7) + 1,
            "harvest_week_of_year": _getWeekOfYear(harvestDate),
            
            // For backward compatibility
            "recommended_planting_week": weekOfYear,
            "expected_harvest_week": _getWeekOfYear(harvestDate),
            
            // Store API response
            "api_response": recommendation,
          });
          
          print("✅ Firestore save done");

          // Navigate to recommendations page
          print("🔹 Step 5: Navigating to /recom2...");
          context.go('/recom2');
          
          } else {
            print("❌ API Error: ${response.body}");
            _showMissingValuesDialog("Error fetching recommendation.");
          }
        } catch (e) {
          print("🔥 Exception caught: $e");
          _showMissingValuesDialog("Unexpected error: $e");
        }
      }
    },
    icon: const Icon(Icons.eco, color: Colors.white, size: 35),
    label: const Text(
      'Get Recommendation',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green[600],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
)
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/recom2');
              break;
            case 2:
              context.go('/community');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: _bottomNavItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

IconData _getIconForMetric(String metric) {
  switch (metric) {
    case "Avg Temp (14d)":
    case "Temperature":
      return Icons.thermostat;
    case "Avg Humidity (14d)":
    case "Humidity":
      return Icons.water_drop;
    case "Total Rainfall (14d)":
    case "Rainfall":
      return Icons.umbrella;
    case "Weather Error":
      return Icons.error;
    case "Soil pH (0-5cm)":
      return Icons.science;
    case "Nitrogen":
      return Icons.grass;
    case "Phosphorus":
      return Icons.eco;
    case "Potassium":
      return Icons.energy_savings_leaf;
    default:
      return Icons.eco;
  }
}
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.09),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

