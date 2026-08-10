import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leafy_path/models/growth_log_model.dart';

class GrowthLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<GrowthLog>> getLogs(String userId, String plantId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .collection('growth_logs')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GrowthLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addLog(String userId, String plantId, String photoUrl, String? note) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('plants')
        .doc(plantId)
        .collection('growth_logs')
        .add({
      'photoUrl': photoUrl,
      'note': note,
      'createdAt': DateTime.now(),
    });
  }
}
