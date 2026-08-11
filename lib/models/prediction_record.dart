class PredictionRecord {
  PredictionRecord({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.animalBreed,
    required this.predictedWeightKg,
    required this.confidence,
    required this.createdAt,
    required this.imagePath,
    required this.status,
    required this.notes,
  });

  final String id;
  final String animalId;
  final String animalName;
  final String animalBreed;
  final double predictedWeightKg;
  final double confidence;
  final DateTime createdAt;
  final String imagePath;
  final String status;
  final String notes;
}
