import 'package:flutter/material.dart';
import 'package:leafy_path/services/gemini_service.dart';
import 'package:leafy_path/services/sun_service.dart';

class PlantCompatibilityScreen extends StatefulWidget {
  const PlantCompatibilityScreen({super.key});

  @override
  State<PlantCompatibilityScreen> createState() => _PlantCompatibilityScreenState();
}

class _PlantCompatibilityScreenState extends State<PlantCompatibilityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _directions = ['Kuzey', 'Güney', 'Doğu', 'Batı'];
  String? _selectedDirection;
  bool _isChecking = false;
  String? _result;
  bool? _petToxic;
  String? _petNote;

  Future<void> _check() async {
    final plantName = _nameController.text.trim();
    if (plantName.isEmpty || _selectedDirection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitki adını yaz ve pencere yönünü seç.")),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _result = null;
    });

    final careInfo = await GeminiService().getCareInfo(plantName);

    if (careInfo == null) {
      setState(() {
        _isChecking = false;
        _result = "Bu bitki hakkında bilgi alınamadı, tekrar dener misin?";
      });
      return;
    }

    final advice = await SunService().getPlacementAdvice(
      windowDirection: _selectedDirection,
      lightNeed: careInfo.light,
    );

    setState(() {
      _isChecking = false;
      _result = "Işık ihtiyacı: ${careInfo.light} • Sulama: ${careInfo.wateringDays} günde bir • Sıcaklık: ${careInfo.temperature}\n\n$advice";
      _petToxic = careInfo.petToxic;
      _petNote = careInfo.petToxicityNote;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Eve Uyar mı?", style: TextStyle(color: Color(0xFF5E7D68), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Almayı düşündüğün bitkinin adını yaz, eve uyup uymayacağını kontrol edelim.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "örn. Monstera, Kaktüs, Orkide...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "PENCEREN HANGİ YÖNE BAKIYOR?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _directions.map((dir) {
                final selected = _selectedDirection == dir;
                return ChoiceChip(
                  label: Text(dir),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDirection = dir),
                  selectedColor: const Color(0xFF84A98C),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84A98C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _isChecking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("KONTROL ET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(_result!, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            if (_petToxic == true) ...[
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
                        _petNote ?? "Bu bitki evcil hayvanlar için zehirli olabilir.",
                        style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
