import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leafy_path/services/auth_service.dart';
import 'package:leafy_path/services/plant_service.dart';
import 'package:leafy_path/models/plant_model.dart';
import 'package:leafy_path/screens/auth/login_screen.dart';
import 'package:leafy_path/screens/plant/add_plant_screen.dart';
import 'package:leafy_path/screens/plant/plant_detail_screen.dart';
import 'package:leafy_path/screens/plant/plant_compatibility_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool _needsWatering(Plant plant) {
    if (plant.lastWateredDate == null) return true;
    final daysSince = DateTime.now().difference(plant.lastWateredDate!).inDays;
    return daysSince >= plant.wateringFrequencyDays;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final PlantService plantService = PlantService();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userId = currentUser?.uid;

    final String displayName = (currentUser?.displayName != null &&
            currentUser!.displayName!.trim().isNotEmpty)
        ? currentUser.displayName!
        : (currentUser?.email?.split('@').first ?? 'Bitki Sever');

    return Scaffold(
      backgroundColor: const Color(0xFFECEFEF),
      body: userId == null
          ? const Center(child: Text("Oturum bulunamadı"))
          : StreamBuilder<List<Plant>>(
              stream: plantService.getUserPlants(userId),
              builder: (context, snapshot) {
                final plants = snapshot.data ?? [];
                final wateringNeeded = plants.where(_needsWatering).length;

                return SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Merhaba,",
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  Text(
                                    displayName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4E6E5D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search, color: Color(0xFF5E7D68)),
                              tooltip: "Eve uyar mı?",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PlantCompatibilityScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Color(0xFF5E7D68)),
                              onPressed: () async {
                                await authService.signOut();
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                }
                              },
                            ),
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF84A98C),
                              child: Text(
                                _getInitials(displayName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (plants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "BUGÜNÜN GÖREVİ:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E7D68),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            wateringNeeded > 0
                                                ? "$wateringNeeded bitki sulama bekliyor!"
                                                : "Tüm bitkilerin mutlu! 🌿",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            wateringNeeded > 0
                                                ? "Hepsini aşağıda görebilirsin"
                                                : "Bugün sulama gerekmiyor",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.85),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.water_drop_outlined,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Row(
                          children: [
                            Text(
                              "BİTKİLERİM",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(
                                child: CircularProgressIndicator(color: Color(0xFF84A98C)),
                              )
                            : plants.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.local_florist,
                                          size: 80,
                                          color: Color(0xFF84A98C),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Henüz bitkin yok",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5E7D68),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "İlk bitkini eklemek için + butonuna bas",
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.72,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                    ),
                                    itemCount: plants.length,
                                    itemBuilder: (context, index) {
                                      final plant = plants[index];
                                      final needsWater = _needsWatering(plant);

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PlantDetailScreen(plant: plant),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.network(
                                                      plant.photoUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Container(
                                                        color: Colors.black12,
                                                        child: const Icon(Icons.image_not_supported),
                                                      ),
                                                    ),
                                                    if (plant.petToxic)
                                                      Positioned(
                                                        top: 6,
                                                        right: 6,
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.pets, size: 14, color: Colors.redAccent),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      plant.name.toUpperCase(),
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: needsWater
                                                            ? () async {
                                                                await plantService.markAsWatered(
                                                                    userId, plant.id);
                                                              }
                                                            : null,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: needsWater
                                                              ? const Color(0xFF84A98C)
                                                              : Colors.black12,
                                                          disabledBackgroundColor: Colors.black12,
                                                          padding:
                                                              const EdgeInsets.symmetric(vertical: 6),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        child: Text(
                                                          needsWater ? "SULA" : "SULANDI",
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: needsWater
                                                                ? Colors.white
                                                                : Colors.black45,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF84A98C),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPlantScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
