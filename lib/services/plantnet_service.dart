import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantNetResult {
  final String scientificName;
  final String? commonName;
  final double score;

  PlantNetResult({
    required this.scientificName,
    this.commonName,
    required this.score,
  });
}

class PlantNetService {
  static const String _baseUrl = 'https://my-api.plantnet.org/v2/identify/all';

  /// Fotoğrafı PlantNet API'sine gönderir, en olası türü döner.
  /// Tanıma başarısız olursa null döner.
  Future<PlantNetResult?> identify(File imageFile) async {
    final apiKey = dotenv.env['PLANTNET_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('PLANTNET_API_KEY bulunamadı. .env dosyanı kontrol et.');
    }

    final uri = Uri.parse('$_baseUrl?api-key=$apiKey&lang=tr');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('images', imageFile.path),
    );
    request.fields['organs'] = 'auto';

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final results = data['results'] as List?;

      if (results == null || results.isEmpty) {
        return null;
      }

      final best = results.first;
      final species = best['species'];
      final scientificName = species['scientificNameWithoutAuthor'] ?? 'Bilinmeyen tür';
      final commonNames = species['commonNames'] as List?;
      final commonName = (commonNames != null && commonNames.isNotEmpty)
          ? commonNames.first as String
          : null;
      final score = (best['score'] as num?)?.toDouble() ?? 0.0;

      return PlantNetResult(
        scientificName: scientificName,
        commonName: commonName,
        score: score,
      );
    } catch (e) {
      return null;
    }
  }
}