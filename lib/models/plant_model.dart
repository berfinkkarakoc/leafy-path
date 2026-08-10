class Plant {
  final String id;
  final String name;
  final String? species;
  final String photoUrl;
  final String? careTips;
  final int wateringFrequencyDays;
  final String lightNeed;
  final String temperature;
  final String? windowDirection;
  final bool petToxic;
  final String? petToxicityNote;
  final DateTime? lastWateredDate;
  final DateTime createdAt;

  Plant({
    required this.id,
    required this.name,
    this.species,
    required this.photoUrl,
    this.careTips,
    this.wateringFrequencyDays = 7,
    this.lightNeed = "Bilinmiyor",
    this.temperature = "Bilinmiyor",
    this.windowDirection,
    this.petToxic = false,
    this.petToxicityNote,
    this.lastWateredDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'photoUrl': photoUrl,
      'careTips': careTips,
      'wateringFrequencyDays': wateringFrequencyDays,
      'lightNeed': lightNeed,
      'temperature': temperature,
      'windowDirection': windowDirection,
      'petToxic': petToxic,
      'petToxicityNote': petToxicityNote,
      'lastWateredDate': lastWateredDate,
      'createdAt': createdAt,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> data, String id) {
    return Plant(
      id: id,
      name: data['name'] ?? '',
      species: data['species'],
      photoUrl: data['photoUrl'] ?? '',
      careTips: data['careTips'],
      wateringFrequencyDays: data['wateringFrequencyDays'] ?? 7,
      lightNeed: data['lightNeed'] ?? 'Bilinmiyor',
      temperature: data['temperature'] ?? 'Bilinmiyor',
      windowDirection: data['windowDirection'],
      petToxic: data['petToxic'] ?? false,
      petToxicityNote: data['petToxicityNote'],
      lastWateredDate: data['lastWateredDate'] != null
          ? (data['lastWateredDate'] as dynamic).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
