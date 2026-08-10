import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  /// Bugün yağmur bekleniyor mu kontrol eder. Konum alınamazsa null döner.
  Future<bool?> isRainExpectedToday() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}&longitude=${position.longitude}'
        '&daily=precipitation_sum&timezone=auto&forecast_days=1',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final precipitation = (data['daily']?['precipitation_sum']?[0] as num?)?.toDouble() ?? 0;

      return precipitation > 1.0; // 1mm üstü yağış varsa "yağmur bekleniyor" say
    } catch (e) {
      print("HAVA DURUMU HATASI: $e");
      return null;
    }
  }
}
