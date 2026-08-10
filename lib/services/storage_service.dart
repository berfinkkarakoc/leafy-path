import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  Future<String?> uploadPlantPhoto(File imageFile, String userId) async {
    final apiKey = dotenv.env['IMGBB_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("IMGBB HATASI: IMGBB_API_KEY bulunamadı.");
      return null;
    }

    try {
      print("IMGBB: fotoğraf okunuyor...");
      final bytes = await imageFile.readAsBytes();
      print("IMGBB: fotoğraf boyutu ${bytes.length} byte");

      final base64Image = base64Encode(bytes);
      print("IMGBB: base64 hazır, yükleme başlıyor...");

      final response = await http
          .post(
            Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
            body: {'image': base64Image},
          )
          .timeout(const Duration(seconds: 20));

      print("IMGBB: yanıt geldi, statusCode=${response.statusCode}");

      if (response.statusCode != 200) {
        print("IMGBB HATASI: body=${response.body}");
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        print("IMGBB: başarılı, url=${data['data']['url']}");
        return data['data']['url'] as String;
      } else {
        print("IMGBB HATASI: $data");
        return null;
      }
    } catch (e) {
      print("IMGBB HATASI: $e");
      return null;
    }
  }
}
