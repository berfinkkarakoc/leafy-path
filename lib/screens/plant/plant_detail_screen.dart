import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leafy_path/models/plant_model.dart';
import 'package:leafy_path/services/plant_service.dart';
import 'package:leafy_path/services/notification_service.dart';
import 'package:leafy_path/services/sun_service.dart';
import 'package:leafy_path/services/gemini_service.dart';
import 'package:leafy_path/screens/plant/plant_doctor_screen.dart';
import 'package:leafy_path/screens/plant/plant_journal_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final List<String> _directions = ['Kuzey', 'Güney', 'Doğu', 'Batı'];
  bool _isRetryingCareInfo = false;

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

  Widget _actionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _retryCareInfo(String userId, Plant currentPlant) async {
    setState(() => _isRetryingCareInfo = true);

    final info = await GeminiService().getCareInfo(currentPlant.species ?? currentPlant.name);

    if (info != null) {
      await PlantService().updateCareInfo(
        userId: userId,
        plantId: currentPlant.id,
        wateringFrequencyDays: info.wateringDays,
        lightNeed: info.light,
        temperature: info.temperature,
        tips: info.tips,
        petToxic: info.petToxic,
        petToxicityNote: info.petToxicityNote,
      );
    }

    if (mounted) {
      setState(() => _isRetryingCareInfo = false);
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bakım bilgisi yine alınamadı, birazdan tekrar dene.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlantService plantService = PlantService();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Oturum bulunamadı")));
    }

    final docStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(widget.plant.id)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFECEFEF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF84A98C)));
          }

          final currentPlant = Plant.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          final tips = (currentPlant.careTips ?? '').split('|||').where((t) => t.trim().isNotEmpty).toList();
          final missingCareInfo = currentPlant.temperature == 'Bilinmiyor' && currentPlant.lightNeed == 'Bilinmiyor';

          int? daysUntilNext;
          bool overdue = true;
          if (currentPlant.lastWateredDate != null) {
            final daysSince = DateTime.now().difference(currentPlant.lastWateredDate!).inDays;
            daysUntilNext = currentPlant.wateringFrequencyDays - daysSince;
            overdue = daysUntilNext <= 0;
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFF84A98C).withOpacity(0.3),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_back, size: 20),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Bitkiyi sil"),
                                    content: Text("${currentPlant.name} kalıcı olarak silinecek. Emin misin?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Vazgeç"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await NotificationService().cancelReminder(currentPlant.id);
                                  await plantService.deletePlant(userId, currentPlant.id);
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            currentPlant.photoUrl,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 240,
                              color: Colors.black12,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentPlant.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5E7D68),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: overdue ? const Color(0xFFD98C6B) : const Color(0xFF84A98C),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                overdue ? "SULAMA BEKLİYOR" : "SULANDI",
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: overdue
                                ? const Color(0xFFD98C6B).withOpacity(0.12)
                                : const Color(0xFF84A98C).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                overdue ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                size: 18,
                                color: overdue ? const Color(0xFFD98C6B) : const Color(0xFF5E7D68),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentPlant.lastWateredDate == null
                                      ? "Henüz sulanmadı"
                                      : overdue
                                          ? "Son sulama: ${_formatDate(currentPlant.lastWateredDate!)} • Sulama zamanı geldi!"
                                          : "Son sulama: ${_formatDate(currentPlant.lastWateredDate!)} • $daysUntilNext gün sonra tekrar sula",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: overdue ? const Color(0xFFB05B36) : const Color(0xFF4E6E5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            _actionCard(
                              emoji: "🩺",
                              title: "Bitki Doktoru",
                              subtitle: "Sorunu analiz et",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlantDoctorScreen(plantName: currentPlant.species ?? currentPlant.name),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _actionCard(
                              emoji: "📸",
                              title: "Büyüme Günlüğü",
                              subtitle: "Zaman içindeki hali",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlantJournalScreen(plantId: currentPlant.id, plantName: currentPlant.name),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            _infoChip("Sulama", "${currentPlant.wateringFrequencyDays} GÜN", Colors.blue.shade200),
                            const SizedBox(width: 10),
                            _infoChip("Sıcaklık", currentPlant.temperature, Colors.orange.shade300),
                            const SizedBox(width: 10),
                            _infoChip("Güneş", currentPlant.lightNeed, Colors.yellow.shade600),
                          ],
                        ),

                        if (currentPlant.petToxic) ...[
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
                                    currentPlant.petToxicityNote ?? "Bu bitki evcil hayvanlar için zehirli olabilir.",
                                    style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (missingCareInfo) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isRetryingCareInfo ? null : () => _retryCareInfo(userId, currentPlant),
                              icon: _isRetryingCareInfo
                                  ? const SizedBox(
                                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.refresh, size: 18),
                              label: Text(_isRetryingCareInfo ? "Deneniyor..." : "Bakım bilgisini yeniden dene"),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF5E7D68)),
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
                            final selected = currentPlant.windowDirection == dir;
                            return ChoiceChip(
                              label: Text(dir),
                              selected: selected,
                              onSelected: (_) async {
                                await plantService.updateWindowDirection(userId, currentPlant.id, dir);
                              },
                              selectedColor: const Color(0xFF84A98C),
                              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        FutureBuilder<String>(
                          future: SunService().getPlacementAdvice(
                            windowDirection: currentPlant.windowDirection,
                            lightNeed: currentPlant.lightNeed,
                          ),
                          builder: (context, sunSnapshot) {
                            if (!sunSnapshot.hasData) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "KONUM ÖNERİSİ",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          sunSnapshot.data!,
                                          style: const TextStyle(fontSize: 13.5, height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

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
                                color: const Color(0xFF84A98C).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.5)),
                            ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await plantService.markAsWatered(userId, currentPlant.id);
                              await NotificationService().scheduleWateringReminder(
                                plantId: currentPlant.id,
                                plantName: currentPlant.name,
                                wateringFrequencyDays: currentPlant.wateringFrequencyDays,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Sulandı olarak işaretlendi 💧")),
                                );
                              }
                            },
                            icon: const Icon(Icons.water_drop_outlined, color: Colors.white),
                            label: const Text(
                              "BUGÜN SULANDI OLARAK İŞARETLE",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E7D68),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
