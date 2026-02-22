import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'YOUR_API_KEY'; // Gantikan dengan API anda
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    final response = await http.get(Uri.parse(
        '$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mendapatkan data cuaca');
    }
  }
}
