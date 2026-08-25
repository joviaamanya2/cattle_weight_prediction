import 'package:flutter/foundation.dart';

import '../models/animal_record.dart';
import '../models/prediction_record.dart';

class AppDataService {
  AppDataService._internal();

  static final AppDataService instance =
      AppDataService._internal();

  // ============================================================
  // LOCAL ANIMAL DATA
  // ============================================================

  final List<AnimalRecord> animals = [
    AnimalRecord(
      id: 'A-001',
      name: 'Mara',
      earTag: 'ET-1001',
      breed: 'Holstein',
      sex: 'Female',
      ageMonths: 26,
      dateOfBirth: DateTime(2023, 5, 12),
      farm: 'North Farm',
      owner: 'A. Smith',
      healthNotes: 'Healthy and active.',
      imagePaths: [
        'front-view',
        'side-view',
      ],
      createdAt: DateTime(2024, 1, 5),
    ),

    AnimalRecord(
      id: 'A-002',
      name: 'Bison',
      earTag: 'ET-1002',
      breed: 'Angus',
      sex: 'Male',
      ageMonths: 34,
      dateOfBirth: DateTime(2022, 8, 21),
      farm: 'West Farm',
      owner: 'K. Brown',
      healthNotes: 'Routine check completed.',
      imagePaths: [
        'profile',
      ],
      createdAt: DateTime(2024, 2, 2),
    ),
  ];

  // ============================================================
  // LOCAL PREDICTION DATA
  // ============================================================

  final List<PredictionRecord> predictions = [
    PredictionRecord(
      id: 'P-001',
      animalId: 'A-001',
      animalName: 'Mara',
      animalBreed: 'Holstein',
      predictedWeightKg: 520,

      detectionConfidencePercent: 90.0,
      confidenceLevelPercent: 87.0,
      estimatedAccuracyPercent: 95.2,

      createdAt: DateTime(2024, 3, 10, 9, 20),
      imagePath: 'front-view',
      status: 'Completed',
      notes: 'Model output pending confirmation.',
    ),

    PredictionRecord(
      id: 'P-002',
      animalId: 'A-002',
      animalName: 'Bison',
      animalBreed: 'Angus',
      predictedWeightKg: 650,

      detectionConfidencePercent: 94.0,
      confidenceLevelPercent: 82.0,
      estimatedAccuracyPercent: 96.2,

      createdAt: DateTime(2024, 3, 12, 10, 5),
      imagePath: 'profile',
      status: 'Completed',
      notes: 'Good visibility in image.',
    ),
  ];

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  final List<String> notifications = [
    'Prediction completed for Mara.',
    'New cattle record added.',
    'Image quality warning for one upload.',
  ];

  // ============================================================
  // AUDIT TRAIL
  // ============================================================

  final List<String> auditTrail = [
    'User entered dashboard.',
    'Prediction history viewed.',
    'Settings updated.',
  ];

  // ============================================================
  // APP SETTINGS
  // ============================================================

  String currentUserRole = 'Farmer';

  String currentTheme = 'Light';

  bool notificationsEnabled = true;

  bool unitsKg = true;

  String language = 'English';

  String profileName = 'Sample User';

  // ============================================================
  // STATISTICS
  // ============================================================

  int get totalCattle => animals.length;

  int get totalPredictions => predictions.length;

  double get averagePredictedWeight {
    if (predictions.isEmpty) {
      return 0.0;
    }

    final total = predictions.fold<double>(
      0.0,
      (sum, item) => sum + item.predictedWeightKg,
    );

    return total / predictions.length;
  }

  List<PredictionRecord> get recentPredictions {
    final sorted = List<PredictionRecord>.from(predictions);

    sorted.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return sorted.take(5).toList();
  }

  // ============================================================
  // ADD ANIMAL
  // ============================================================

  void addAnimal(AnimalRecord animal) {
    animals.add(animal);

    notifications.insert(
      0,
      'New cattle added: ${animal.name}.',
    );

    auditTrail.add(
      'Added animal ${animal.name}.',
    );

    debugPrint(
      'Animal added: ${animal.name}',
    );
  }

  // ============================================================
  // ADD PREDICTION
  // ============================================================

  void addPrediction(PredictionRecord prediction) {
    predictions.add(prediction);

    notifications.insert(
      0,
      'Prediction saved for ${prediction.animalName}.',
    );

    auditTrail.add(
      'Saved prediction for ${prediction.animalName}.',
    );

    debugPrint(
      'Prediction saved for ${prediction.animalName}',
    );
  }

  // ============================================================
  // REMOVE ANIMAL
  // ============================================================

  void removeAnimal(String animalId) {
    animals.removeWhere(
      (animal) => animal.id == animalId,
    );

    notifications.insert(
      0,
      'Cattle record removed.',
    );

    auditTrail.add(
      'Removed animal $animalId.',
    );
  }

  // ============================================================
  // REMOVE PREDICTION
  // ============================================================

  void removePrediction(String predictionId) {
    predictions.removeWhere(
      (prediction) => prediction.id == predictionId,
    );

    notifications.insert(
      0,
      'Prediction removed.',
    );

    auditTrail.add(
      'Removed prediction $predictionId.',
    );
  }

  // ============================================================
  // SEARCH PREDICTIONS
  // ============================================================

  List<PredictionRecord> searchPredictions({
    String query = '',
    String breed = '',
    String farm = '',
    DateTime? date,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final normalizedBreed = breed.trim().toLowerCase();

    final normalizedFarm = farm.trim().toLowerCase();

    return predictions.where((prediction) {
      final animal = animals.firstWhere(
        (item) => item.id == prediction.animalId,
        orElse: () => AnimalRecord(
          id: prediction.animalId,
          name: prediction.animalName,
          earTag: '',
          breed: prediction.animalBreed,
          sex: '',
          ageMonths: 0,
          dateOfBirth: null,
          farm: '',
          owner: '',
          healthNotes: '',
          imagePaths: [
            prediction.imagePath,
          ],
          createdAt: prediction.createdAt,
        ),
      );

      // --------------------------------------------------------
      // SEARCH BY NAME OR PREDICTION ID
      // --------------------------------------------------------

      final matchesQuery =
          normalizedQuery.isEmpty ||
              prediction.animalName
                  .toLowerCase()
                  .contains(normalizedQuery) ||
              prediction.id
                  .toLowerCase()
                  .contains(normalizedQuery);

      // --------------------------------------------------------
      // FILTER BY BREED
      // --------------------------------------------------------

      final matchesBreed =
          normalizedBreed.isEmpty ||
              animal.breed.toLowerCase() ==
                  normalizedBreed;

      // --------------------------------------------------------
      // FILTER BY FARM
      // --------------------------------------------------------

      final matchesFarm =
          normalizedFarm.isEmpty ||
              animal.farm.toLowerCase() ==
                  normalizedFarm;

      // --------------------------------------------------------
      // FILTER BY DATE
      // --------------------------------------------------------

      final matchesDate =
          date == null ||
              (
                prediction.createdAt.year ==
                    date.year &&
                prediction.createdAt.month ==
                    date.month &&
                prediction.createdAt.day ==
                    date.day
              );

      return matchesQuery &&
          matchesBreed &&
          matchesFarm &&
          matchesDate;
    }).toList();
  }

  // ============================================================
  // AVAILABLE BREEDS
  // ============================================================

  List<String> availableBreeds() {
    final breeds = animals
        .map((animal) => animal.breed.trim())
        .where((breed) => breed.isNotEmpty)
        .toSet()
        .toList();

    breeds.sort();

    return breeds;
  }

  // ============================================================
  // AVAILABLE FARMS
  // ============================================================

  List<String> availableFarms() {
    final farms = animals
        .map((animal) => animal.farm.trim())
        .where((farm) => farm.isNotEmpty)
        .toSet()
        .toList();

    farms.sort();

    return farms;
  }

  // ============================================================
  // FIND ANIMAL
  // ============================================================

  AnimalRecord? findAnimalById(String animalId) {
    for (final animal in animals) {
      if (animal.id == animalId) {
        return animal;
      }
    }

    return null;
  }

  // ============================================================
  // FIND PREDICTION
  // ============================================================

  PredictionRecord? findPredictionById(
    String predictionId,
  ) {
    for (final prediction in predictions) {
      if (prediction.id == predictionId) {
        return prediction;
      }
    }

    return null;
  }

  // ============================================================
  // CLEAR ALL LOCAL DATA
  // ============================================================

  void clearAllData() {
    animals.clear();
    predictions.clear();

    notifications.insert(
      0,
      'All local cattle and prediction data cleared.',
    );

    auditTrail.add(
      'Cleared all local application data.',
    );
  }
}