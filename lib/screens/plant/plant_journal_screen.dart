import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leafy_path/services/plant_service.dart';
import 'package:leafy_path/services/storage_service.dart';

class PlantJournalScreen extends StatefulWidget {
  final String plantId;
  final String plantName;

  const PlantJournalScreen({super.key, required this.plantId, required this.plantName});

  @override
  State<PlantJournalScreen> createState() => _PlantJournalScreenState();
}

class _PlantJournalScreenState extends State<PlantJournalScreen> {
  final ImagePicker _picker = ImagePicker();
  final PlantService _plantService = PlantService();
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  Future<void> _addEntry(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);
    } catch (e) {
      print("GÜNLÜK FOTOĞRAF HATASI: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fotoğraf seçilemedi. Simülatörde kamera çalışmaz, galeriyi dene.")),
        );
      }
      return;
    }

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    final photoUrl = await _storageService.uploadPlantPhoto(File(pickedFile.path), user.uid);

    if (photoUrl != null) {
      await _plantService.addJournalEntry(user.uid, widget.plantId, photoUrl);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fotoğraf yüklenemedi, tekrar dene.")),
      );
    }

    if (mounted) setState(() => _isUploading = false);
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
                _addEntry(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(context);
                _addEntry(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => "${date.day}/${date.month}/${date.year}";

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("📸 ${widget.plantName} Günlüğü",
            style: const TextStyle(color: Color(0xFF5E7D68), fontWeight: FontWeight.bold)),
      ),
      body: userId == null
          ? const Center(child: Text("Oturum bulunamadı"))
          : StreamBuilder<List<JournalEntry>>(
              stream: _plantService.getJournalEntries(userId, widget.plantId),
              builder: (context, snapshot) {
                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_camera_back_outlined, size: 60, color: Color(0xFF84A98C)),
                        const SizedBox(height: 12),
                        const Text("Henüz günlük fotoğrafı yok", style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 4),
                        const Text("Zamanla değişimi görmek için fotoğraf ekle", style: TextStyle(color: Colors.black38, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              entry.photoUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_formatDate(entry.date), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF84A98C),
        onPressed: _isUploading ? null : () => _showImageSourceSheet(context),
        icon: _isUploading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(_isUploading ? "Yükleniyor..." : "Fotoğraf Ekle", style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
