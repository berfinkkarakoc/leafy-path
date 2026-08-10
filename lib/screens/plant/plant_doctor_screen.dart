import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leafy_path/services/gemini_service.dart';

class PlantDoctorScreen extends StatefulWidget {
  final String plantName;

  const PlantDoctorScreen({super.key, required this.plantName});

  @override
  State<PlantDoctorScreen> createState() => _PlantDoctorScreenState();
}

class _PlantDoctorScreenState extends State<PlantDoctorScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _diagnosis;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _diagnosis = null;
    });

    await _analyze();
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    final result = await _geminiService.diagnosePlantIssue(_selectedImage!, widget.plantName);

    setState(() {
      _diagnosis = result ?? "Analiz yapılamadı, tekrar dene.";
      _isAnalyzing = false;
    });
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera ile çek'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("🩺 Bitki Doktoru", style: TextStyle(color: Color(0xFF5E7D68), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sorunlu görünen yaprak, gövde ya da toprağın fotoğrafını çek, senin için inceleyelim.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showImageSourceSheet(context),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.black38),
                            SizedBox(height: 8),
                            Text("Sorunlu bölgenin fotoğrafını ekle", style: TextStyle(color: Colors.black45)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF84A98C)),
                  SizedBox(height: 12),
                  Text("İnceleniyor..."),
                ],
              ),
            if (_diagnosis != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(_diagnosis!, style: const TextStyle(fontSize: 14, height: 1.6)),
              ),
          ],
        ),
      ),
    );
  }
}
