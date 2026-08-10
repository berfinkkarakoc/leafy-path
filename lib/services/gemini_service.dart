import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantCareInfo {
  final int wateringDays;
  final String temperature;
  final String light;
  final List<String> tips;
  final bool petToxic;
  final String? petToxicityNote;

  PlantCareInfo({
    required this.wateringDays,
    required this.temperature,
    required this.light,
    required this.tips,
    this.petToxic = false,
    this.petToxicityNote,
  });
}

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY bulunamadı. .env dosyanı kontrol et.');
    }

    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
    );
  }

  Future<PlantCareInfo?> getCareInfo(String plantName) async {
    final prompt = '''
$plantName bitkisi için bakım bilgisi ver. SADECE aşağıdaki JSON formatında
yanıt ver, başka hiçbir açıklama, markdown işareti veya kod bloğu ekleme:

{
  "wateringDays": 7,
  "temperature": "15-20°C",
  "light": "Az Işık",
  "tips": [
    "Bu bitki hakkında 2-3 cümlelik genel bir tanıtım paragrafı, Türkçe.",
    "İpucu: bu bitkiye özel pratik bir bakım tavsiyesi, Türkçe."
  ],
  "petToxic": false,
  "petToxicityNote": "Kısa bir açıklama, Türkçe, örn: Kedi ve köpekler için hafif toksiktir, yenirse kusmaya sebep olabilir."
}

- wateringDays: kaç günde bir sulanmalı (sadece sayı)
- temperature: uygun sıcaklık aralığı, "15-20°C" formatında
- light: "Az Işık", "Orta Işık" veya "Çok Işık" değerlerinden biri
- tips: tam olarak 2 metin içeren liste, ilki genel tanıtım, ikincisi "İpucu:" ile başlayan pratik tavsiye
- petToxic: bu bitki kedi/köpek için zehirliyse true, güvenliyse false
- petToxicityNote: petToxic true ise kısa açıklama, false ise null yaz
''';

    for (int attempt = 1; attempt <= 4; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        String? text = response.text;

        if (text == null) return null;

        text = text.trim();
        if (text.startsWith('```')) {
          text = text.replaceAll(RegExp(r'^```json\s*|^```\s*|```$', multiLine: true), '').trim();
        }

        final data = jsonDecode(text);

        return PlantCareInfo(
          wateringDays: data['wateringDays'] is int
              ? data['wateringDays']
              : int.tryParse(data['wateringDays'].toString()) ?? 7,
          temperature: data['temperature']?.toString() ?? 'Bilinmiyor',
          light: data['light']?.toString() ?? 'Bilinmiyor',
          tips: (data['tips'] as List?)?.map((e) => e.toString()).toList() ?? [],
          petToxic: data['petToxic'] == true,
          petToxicityNote: data['petToxicityNote']?.toString(),
        );
      } catch (e) {
        print("GEMINI HATASI ($attempt/4): $e");
        if (attempt < 4) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    return null;
  }

  Future<String?> diagnosePlantIssue(File image, String plantName) async {
    final bytes = await image.readAsBytes();

    final prompt = '''
Sen deneyimli bir bitki doktorusun. Bu $plantName bitkisinin fotoğrafına bak.

Şunları Türkçe, samimi ve kısa (en fazla 5-6 cümle) şekilde anlat:
- Bitkide görünür bir sorun var mı (sararma, kuruma, leke, zararlı, aşırı/az sulama belirtisi vb.)?
- Sorun varsa muhtemel sebebi ne olabilir?
- Ne yapılması gerektiğini pratik adımlarla söyle.
- Bitki sağlıklı görünüyorsa bunu da açıkça söyle, endişelendirme.

Emoji kullanabilirsin ama markdown başlık/yıldız kullanma, düz metin yaz.
''';

    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);
      return response.text;
    } catch (e) {
      print("BİTKİ DOKTORU HATASI: $e");
      return null;
    }
  }
}
