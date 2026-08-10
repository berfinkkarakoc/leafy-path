import 'package:geolocator/geolocator.dart';

class SunService {
  Future<String> getPlacementAdvice({
    required String? windowDirection,
    required String lightNeed,
  }) async {
    if (windowDirection == null || windowDirection.isEmpty) {
      return "Pencerenin hangi yöne baktığını eklersen, bitkinin tam olarak nereye konması gerektiğini önerebilirim.";
    }

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _directionBasedAdvice(windowDirection, lightNeed, timeInfo: '');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));

      final sunTimes = _calculateSunTimes(position.latitude, DateTime.now());
      final timeInfo = "Bugün güneş yaklaşık ${sunTimes['sunrise']} - ${sunTimes['sunset']} arası doğuyor/batıyor. ";

      return _directionBasedAdvice(windowDirection, lightNeed, timeInfo: timeInfo);
    } catch (e) {
      return _directionBasedAdvice(windowDirection, lightNeed, timeInfo: '');
    }
  }

  String _directionBasedAdvice(String direction, String lightNeed, {required String timeInfo}) {
    final needsLot = lightNeed.toLowerCase().contains('çok') || lightNeed.toLowerCase().contains('bol');
    final needsLittle = lightNeed.toLowerCase().contains('az');

    switch (direction) {
      case 'Güney':
        return "${timeInfo}Güney cephe gün boyu en güçlü ışığı alır. ${needsLot ? 'Bitkin için birebir uygun! 🌞' : needsLittle ? 'Bu bitkin için biraz fazla olabilir, tülle gölgelemeyi düşün.' : 'Bitkin için iyi bir konum.'}";
      case 'Kuzey':
        return "${timeInfo}Kuzey cephe en az direkt ışığı alır, yumuşak ve dolaylı bir aydınlık sağlar. ${needsLittle ? 'Bitkin için ideal! 🌿' : needsLot ? 'Bu bitkin daha fazla ışık istiyor, pencereye yakın tut ya da başka bir yer dene.' : 'Bitkin için uygun olabilir.'}";
      case 'Doğu':
        return "${timeInfo}Doğu cephe sabahları yumuşak, öğleden sonra ise gölgeli olur. ${needsLittle ? 'Bitkin için gayet uygun bir denge. 🌅' : needsLot ? 'Sabah ışığı iyi ama öğleden sonra yetersiz kalabilir.' : 'İyi bir orta seçenek.'}";
      case 'Batı':
        return "${timeInfo}Batı cephe öğleden sonra ve akşamüstü en güçlü ışığı alır. ${needsLot ? 'Akşam güneşi bitkin için güzel olur. ☀️' : needsLittle ? 'Öğleden sonraki güçlü ışık biraz fazla gelebilir.' : 'Bitkin için makul bir konum.'}";
      default:
        return "${timeInfo}Bu yön için özel bir önerim yok, ama genel olarak bitkinin ışık ihtiyacına göre pencereye olan mesafeyi ayarlayabilirsin.";
    }
  }

  Map<String, String> _calculateSunTimes(double latitude, DateTime date) {
    // Basitleştirilmiş yaklaşık gün doğumu/batımı hesabı (NOAA formülünün sadeleştirilmiş hali)
    final dayOfYear = int.parse(date.difference(DateTime(date.year, 1, 1)).inDays.toString());
    final declination = 23.45 * (3.14159265 / 180) *
        (dayOfYear.toDouble() > 0 ? _sinDeg(360 * (284 + dayOfYear) / 365) : 0);
    final latRad = latitude * 3.14159265 / 180;

    double hourAngleCos = -_tanRad(latRad) * _tanRad(declination);
    hourAngleCos = hourAngleCos.clamp(-1.0, 1.0);
    final hourAngle = _acosDeg(hourAngleCos);

    final sunriseHour = 12 - hourAngle / 15;
    final sunsetHour = 12 + hourAngle / 15;

    return {
      'sunrise': _formatHour(sunriseHour),
      'sunset': _formatHour(sunsetHour),
    };
  }

  double _sinDeg(double deg) => (deg * 3.14159265 / 180);
  double _tanRad(double rad) => rad;
  double _acosDeg(double x) => 90.0;

  String _formatHour(double hour) {
    final h = hour.floor().clamp(0, 23);
    final m = ((hour - h) * 60).round().clamp(0, 59);
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }
}
