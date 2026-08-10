import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leafy_path/services/plantnet_service.dart';
import 'package:leafy_path/services/gemini_service.dart';
import 'package:leafy_path/services/storage_service.dart';
import 'package:leafy_path/services/plant_service.dart';
import 'package:leafy_path/services/notification_service.dart';
import 'package:leafy_path/models/plant_model.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final ImagePicker _picker = ImagePicker();
  final PlantNetService _plantNetService = PlantNetService();
  final GeminiService _geminiService = GeminiService();
  final StorageService _storageService = StorageService();
  final PlantService _plantService = PlantService();

  File? _selectedImage;
  bool _isIdentifying = false;
  bool _isSaving = false;

  String? _identifiedName;
  PlantCareInfo? _careInfo;
  String? _errorMessage;
  String? _windowDirection;

  final List<String> _directions = ['Kuzey', 'Güney', 'Doğu', 'Batı', 'Bilmiyorum'];

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 60, maxWidth: 1024);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _identifiedName = null;
      _careInfo = null;
      _errorMessage = null;
    });

    await _identifyPlant();
  }

  Future<void> _identifyPlant() async {
    if (_selectedImage == null) return;

    setState(() {
      _isIdentifying = true;
      _errorMessage = null;
    });

    final result = await _plantNetService.identify(_selectedImage!);

    if (result == null) {
      setState(() {
        _isIdentifying = false;
        _errorMessage = "Bitki tanınamadı. Farklı bir fotoğraf deneyin.";
      });
      return;
    }

    final displayName = result.commonName ?? result.scientificName;
    final info = await _geminiService.getCareInfo(displayName);

    setState(() {
      _identifiedName = displayName;
      _careInfo = info;
      _isIdentifying = false;
      if (info == null) {
        _errorMessage = "Bakım bilgisi alınamadı, yine de kaydedebilirsin.";
      }
    });
  }

  Future<void> _savePlant() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _selectedImage == null || _identifiedName == null) {
      return;
    }

    setState(() => _isSaving = true);

    final photoUrl = await _storageService.uploadPlantPhoto(_selectedImage!, user.uid);

    if (photoUrl == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = "Fotoğraf yüklenemedi, tekrar deneyin.";
      });
      return;
    }

    final wateringDays = _careInfo?.wateringDays ?? 7;

    final plant = Plant(
      id: '',
      name: _identifiedName!,
      species: _identifiedName,
      photoUrl: photoUrl,
      careTips: _careInfo?.tips.join('|||'),
      wateringFrequencyDays: wateringDays,
      lightNeed: _careInfo?.light ?? 'Bilinmiyor',
      temperature: _careInfo?.temperature ?? 'Bilinmiyor',
      windowDirection: (_windowDirection == null || _windowDirection == 'Bilmiyorum') ? null : _windowDirection,
      petToxic: _careInfo?.petToxic ?? false,
      petToxicityNote: _careInfo?.petToxicityNote,
      createdAt: DateTime.now(),
    );

    _plantService.addPlant(user.uid, plant).then((docRef) {
      NotificationService().scheduleWateringReminder(
        plantId: docRef.id,
        plantName: plant.name,
        wateringFrequencyDays: wateringDays,
      );
    }).catchError((e) {
      print("KAYIT HATASI (arka planda): $e");
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _infoChip(String label, String value, Color dotColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tips = _careInfo?.tips ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFECEFEF),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF84A98C).withOpacity(0.3),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showImageSourceSheet(context),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _selectedImage == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.black38),
                                    SizedBox(height: 8),
                                    Text("Bitki fotoğrafı ekle", style: TextStyle(color: Colors.black45)),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isIdentifying)
                    const Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF84A98C)),
                        SizedBox(height: 12),
                        Text("Bitki tanınıyor ve bakım bilgisi hazırlanıyor..."),
                      ],
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (_identifiedName != null && !_isIdentifying) ...[
                    Text(
                      _identifiedName!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E7D68),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_careInfo != null)
                      Row(
                        children: [
                          _infoChip("Sulama sıklığı", "${_careInfo!.wateringDays} GÜN", Colors.blue.shade200),
                          const SizedBox(width: 10),
                          _infoChip("Sıcaklık", _careInfo!.temperature, Colors.orange.shade300),
                          const SizedBox(width: 10),
                          _infoChip("Güneş ihtiyacı", _careInfo!.light, Colors.yellow.shade600),
                        ],
                      ),
                    if (_careInfo?.petToxic == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.pets, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _careInfo!.petToxicityNote ?? "Bu bitki evcil hayvanlar için zehirli olabilir.",
                                style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    const Text(
                      "PENCEREN HANGİ YÖNE BAKIYOR?",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _directions.map((dir) {
                        final selected = _windowDirection == dir;
                        return ChoiceChip(
                          label: Text(dir),
                          selected: selected,
                          onSelected: (_) => setState(() => _windowDirection = dir),
                          selectedColor: const Color(0xFF84A98C),
                          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    if (tips.isNotEmpty) ...[
                      const Text(
                        "BAKIM İPUÇLARI",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      for (final tip in tips)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF84A98C).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.5)),
                        ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84A98C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "BİTKİMİ KAYDET",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
