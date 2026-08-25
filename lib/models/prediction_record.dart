class PredictionRecord {
  PredictionRecord({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.animalBreed,
    required this.predictedWeightKg,
    required this.detectionConfidencePercent,
    required this.confidenceLevelPercent,
    required this.estimatedAccuracyPercent,
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

  final double detectionConfidencePercent;
  final double confidenceLevelPercent;
  final double estimatedAccuracyPercent;

  final DateTime createdAt;

  final String imagePath;

  final String status;
  final String notes;

  factory PredictionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return PredictionRecord(
      id: json['id']?.toString() ?? '',

      animalId:
          json['animal_id']?.toString() ?? '',

      animalName:
          json['animal_name']?.toString() ?? '',

      animalBreed:
          json['animal_breed']?.toString() ?? '',

      predictedWeightKg:
          (json['predicted_weight_kg'] as num?)
                  ?.toDouble() ??
              0.0,

      detectionConfidencePercent:
          (json['detection_confidence_percent'] as num?)
                  ?.toDouble() ??
              0.0,

      confidenceLevelPercent:
          (json['confidence_level_percent'] as num?)
                  ?.toDouble() ??
              0.0,

      estimatedAccuracyPercent:
          (json['estimated_accuracy_percent'] as num?)
                  ?.toDouble() ??
              0.0,

      createdAt:
          DateTime.tryParse(
                json['created_at']?.toString() ?? '',
              ) ??
              DateTime.now(),

      imagePath:
          json['image_path']?.toString() ?? '',

      status:
          json['status']?.toString() ?? 'completed',

      notes:
          json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'animal_name': animalName,
      'animal_breed': animalBreed,
      'predicted_weight_kg': predictedWeightKg,
      'detection_confidence_percent':
          detectionConfidencePercent,
      'confidence_level_percent':
          confidenceLevelPercent,
      'estimated_accuracy_percent':
          estimatedAccuracyPercent,
      'created_at':
          createdAt.toIso8601String(),
      'image_path': imagePath,
      'status': status,
      'notes': notes,
    };
  }
}