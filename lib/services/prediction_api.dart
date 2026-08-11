import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/prediction_record.dart';

class PredictionApiException implements Exception {
  PredictionApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  String get userMessage {
    if (statusCode == null) {
      return 'Unable to reach the prediction backend. Make sure the Flask server is running and reachable.';
    }

    if (statusCode! >= 500) {
      return 'The prediction server returned an error. Please try again in a moment.';
    }

    if (statusCode == 404) {
      return 'The prediction endpoint was not found. Please check the backend configuration.';
    }

    return 'Prediction request failed. Please check the backend and try again.';
  }
}

class PredictionApiService {
  PredictionApiService._privateConstructor();

  static final PredictionApiService instance = PredictionApiService._privateConstructor();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000',
  );

  Future<PredictionRecord> predictWeight({
    required String animalId,
    required String animalName,
    required String animalBreed,
    required String imagePath,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'animalId': animalId,
            'animalName': animalName,
            'animalBreed': animalBreed,
            'imagePath': imagePath,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw PredictionApiException(
        'Prediction request failed: ${response.statusCode} ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return PredictionRecord(
      id: data['id']?.toString() ?? 'P-${DateTime.now().millisecondsSinceEpoch}',
      animalId: data['animalId']?.toString() ?? animalId,
      animalName: data['animalName']?.toString() ?? animalName,
      animalBreed: data['animalBreed']?.toString() ?? animalBreed,
      predictedWeightKg: (data['predictedWeightKg'] ?? 0).toDouble(),
      confidence: (data['confidence'] ?? 0).toDouble(),
      createdAt: DateTime.parse(data['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      imagePath: data['imagePath']?.toString() ?? imagePath,
      status: data['status']?.toString() ?? 'Completed',
      notes: data['notes']?.toString() ?? 'Prediction from Flask backend.',
    );
  }
}
