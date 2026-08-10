import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leafy_path/models/plant_model.dart';

class JournalEntry {
  final String id;
  final String photoUrl;
  final String? note;
  final DateTime date;

  JournalEntry({required this.id, required this.photoUrl, this.note, required this.date});

  factory JournalEntry.fromMap(Map<String, dynamic> data, String id) {
    return JournalEntry(
      id: id,
      photoUrl: data['photoUrl'] ?? '',
      note: data['note'],
      date: data['date'] != null ? (data['date'] as dynamic).toDate() : DateTime.now(),
    );
  }
}

class PlantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Plant>> getUserPlants(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Plant.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<DocumentReference> addPlant(String userId, Plant plant) async {
    return await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .add(plant.toMap());
  }

  Future<void> markAsWatered(String userId, String plantId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .update({'lastWateredDate': DateTime.now()});
  }

  Future<void> updateWindowDirection(String userId, String plantId, String? direction) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .update({'windowDirection': direction});
  }

  Future<void> updateCareInfo({
    required String userId,
    required String plantId,
    required int wateringFrequencyDays,
    required String lightNeed,
    required String temperature,
    required List<String> tips,
    bool petToxic = false,
    String? petToxicityNote,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .update({
      'wateringFrequencyDays': wateringFrequencyDays,
      'lightNeed': lightNeed,
      'temperature': temperature,
      'careTips': tips.join('|||'),
      'petToxic': petToxic,
      'petToxicityNote': petToxicityNote,
    });
  }

  Future<void> deletePlant(String userId, String plantId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .delete();
  }

  Future<void> addJournalEntry(String userId, String plantId, String photoUrl, {String? note}) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .collection('journal')
        .add({'photoUrl': photoUrl, 'note': note, 'date': DateTime.now()});
  }

  Stream<List<JournalEntry>> getJournalEntries(String userId, String plantId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .collection('journal')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromMap(doc.data(), doc.id))
            .toList());
  }
}
