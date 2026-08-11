import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/animal_record.dart';
import '../models/prediction_record.dart';

class AppDataService {
  AppDataService._internal();

  static final AppDataService instance = AppDataService._internal();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000',
  );

  final http.Client _client = http.Client();

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
      imagePaths: ['front-view', 'side-view'],
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
      imagePaths: ['profile'],
      createdAt: DateTime(2024, 2, 2),
    ),
  ];

  final List<PredictionRecord> predictions = [
    PredictionRecord(
      id: 'P-001',
      animalId: 'A-001',
      animalName: 'Mara',
      animalBreed: 'Holstein',
      predictedWeightKg: 520,
      confidence: 0.87,
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
      confidence: 0.82,
      createdAt: DateTime(2024, 3, 12, 10, 5),
      imagePath: 'profile',
      status: 'Completed',
      notes: 'Good visibility in image.',
    ),
  ];

  final List<String> notifications = [
    'Prediction completed for Mara.',
    'New cattle record added.',
    'Image quality warning for one upload.',
  ];

  final List<String> auditTrail = [
    'User entered dashboard.',
    'Prediction history viewed.',
    'Settings updated.',
  ];

  String currentUserRole = 'Farmer';
  String currentTheme = 'Light';
  bool notificationsEnabled = true;
  bool unitsKg = true;
  String language = 'English';
  String profileName = 'Sample User';

  int get totalCattle => animals.length;

  int get totalPredictions => predictions.length;

  double get averagePredictedWeight {
    if (predictions.isEmpty) {
      return 0;
    }
    final total = predictions.fold<double>(0, (sum, item) => sum + item.predictedWeightKg);
    return total / predictions.length;
  }

  List<PredictionRecord> get recentPredictions => predictions.take(5).toList();

  Future<void> loadFromBackend() async {
    final animalsResponse = await _client.get(Uri.parse('$_baseUrl/animals')).timeout(const Duration(seconds: 10));
    if (animalsResponse.statusCode != 200) {
      throw Exception('Unable to load animals from backend: ${animalsResponse.statusCode}');
    }

    final predictionsResponse = await _client.get(Uri.parse('$_baseUrl/predictions')).timeout(const Duration(seconds: 10));
    if (predictionsResponse.statusCode != 200) {
      throw Exception('Unable to load predictions from backend: ${predictionsResponse.statusCode}');
    }

    final animalsData = jsonDecode(animalsResponse.body) as List<dynamic>;
    final predictionsData = jsonDecode(predictionsResponse.body) as List<dynamic>;

    animals
      ..clear()
      ..addAll(animalsData.map((item) => _animalFromJson(item as Map<String, dynamic>)).toList());

    predictions
      ..clear()
      ..addAll(predictionsData.map((item) => _predictionFromJson(item as Map<String, dynamic>)).toList());

    notifications.insert(0, 'Synced ${animals.length} animals and ${predictions.length} predictions from backend.');
    auditTrail.add('Loaded data from backend.');
  }

  Future<void> syncAnimalToBackend(AnimalRecord animal) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/animals'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': animal.id,
            'name': animal.name,
            'earTag': animal.earTag,
            'breed': animal.breed,
            'sex': animal.sex,
            'ageMonths': animal.ageMonths,
            'dateOfBirth': animal.dateOfBirth?.toIso8601String(),
            'farm': animal.farm,
            'owner': animal.owner,
            'healthNotes': animal.healthNotes,
            'imagePaths': animal.imagePaths,
            'createdAt': animal.createdAt.toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('Unable to save animal to backend: ${response.statusCode}');
    }
  }

  void addAnimal(AnimalRecord animal) {
    animals.add(animal);
    notifications.insert(0, 'New cattle added: ${animal.name}.');
    auditTrail.add('Added animal ${animal.name}.');
  }

  void addPrediction(PredictionRecord prediction) {
    predictions.add(prediction);
    notifications.insert(0, 'Prediction saved for ${prediction.animalName}.');
    auditTrail.add('Saved prediction for ${prediction.animalName}.');
  }

  AnimalRecord _animalFromJson(Map<String, dynamic> data) {
    return AnimalRecord(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      earTag: data['earTag']?.toString() ?? '',
      breed: data['breed']?.toString() ?? '',
      sex: data['sex']?.toString() ?? '',
      ageMonths: int.tryParse(data['ageMonths']?.toString() ?? '') ?? 0,
      dateOfBirth: data['dateOfBirth'] == null ? null : DateTime.tryParse(data['dateOfBirth'].toString()),
      farm: data['farm']?.toString() ?? '',
      owner: data['owner']?.toString() ?? '',
      healthNotes: data['healthNotes']?.toString() ?? '',
      imagePaths: (data['imagePaths'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? <String>[],
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  PredictionRecord _predictionFromJson(Map<String, dynamic> data) {
    return PredictionRecord(
      id: data['id']?.toString() ?? '',
      animalId: data['animalId']?.toString() ?? '',
      animalName: data['animalName']?.toString() ?? '',
      animalBreed: data['animalBreed']?.toString() ?? '',
      predictedWeightKg: double.tryParse(data['predictedWeightKg']?.toString() ?? '') ?? 0,
      confidence: double.tryParse(data['confidence']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      imagePath: data['imagePath']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Completed',
      notes: data['notes']?.toString() ?? '',
    );
  }

  List<PredictionRecord> searchPredictions({
    String query = '',
    String breed = '',
    String farm = '',
    DateTime? date,
  }) {
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
          farm: farm,
          owner: '',
          healthNotes: '',
          imagePaths: [prediction.imagePath],
          createdAt: prediction.createdAt,
        ),
      );
      final matchesQuery = query.isEmpty ||
          prediction.animalName.toLowerCase().contains(query.toLowerCase()) ||
          prediction.id.toLowerCase().contains(query.toLowerCase());
      final matchesBreed = breed.isEmpty || animal.breed.toLowerCase() == breed.toLowerCase();
      final matchesFarm = farm.isEmpty || animal.farm.toLowerCase() == farm.toLowerCase();
      final matchesDate = date == null ||
          prediction.createdAt.year == date.year &&
              prediction.createdAt.month == date.month &&
              prediction.createdAt.day == date.day;
      return matchesQuery && matchesBreed && matchesFarm && matchesDate;
    }).toList();
  }

  List<String> availableBreeds() {
    return animals.map((animal) => animal.breed).toSet().toList();
  }

  List<String> availableFarms() {
    return animals.map((animal) => animal.farm).toSet().toList();
  }
}
