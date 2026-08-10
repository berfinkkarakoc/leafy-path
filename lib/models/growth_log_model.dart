class GrowthLog {
  final String id;
  final String photoUrl;
  final String? note;
  final DateTime createdAt;

  GrowthLog({
    required this.id,
    required this.photoUrl,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'photoUrl': photoUrl,
      'note': note,
      'createdAt': createdAt,
    };
  }

  factory GrowthLog.fromMap(Map<String, dynamic> data, String id) {
    return GrowthLog(
      id: id,
      photoUrl: data['photoUrl'] ?? '',
      note: data['note'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
