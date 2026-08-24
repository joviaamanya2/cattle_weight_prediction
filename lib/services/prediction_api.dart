import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/prediction_record.dart';

class PredictionApiException implements Exception {
  PredictionApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  String get userMessage {
    if (statusCode == null) {
      return 'Unable to reach the prediction backend. Check your internet connection and make sure the API is running.';
    }

    if (statusCode! >= 500) {
      return 'The prediction server returned an error. Please try again in a moment.';
    }

    if (statusCode == 404) {
      return 'The prediction endpoint was not found. Please check the API URL.';
    }

    if (statusCode == 422) {
      return 'The image was not accepted by the prediction API.';
    }

    if (statusCode == 400) {
      return 'The prediction request was invalid. Please check the image and try again.';
    }

    return 'Prediction request failed. Please try again.';
  }
}

class PredictionApiService {
  PredictionApiService._privateConstructor();

  static final PredictionApiService instance =
      PredictionApiService._privateConstructor();

  // ============================================================
  // RENDER API URL
  // ============================================================

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-model-1-dzt0.onrender.com',
  );

  // ============================================================
  // PREDICT WEIGHT
  // ============================================================

  Future<PredictionRecord> predictWeight({
    required String animalId,
    required String animalName,
    required String animalBreed,
    required XFile image,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/predict');

      debugPrint('Prediction API URL: $uri');

      // ----------------------------------------------------------
      // Create multipart request
      // ----------------------------------------------------------

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      // ----------------------------------------------------------
      // Add cattle information
      // ----------------------------------------------------------

      request.fields['animalId'] = animalId;

      request.fields['animalName'] = animalName;

      request.fields['animalBreed'] = animalBreed;

      // ----------------------------------------------------------
      // Read image bytes
      // ----------------------------------------------------------

      final imageBytes = await image.readAsBytes();

      debugPrint(
        'Image selected: ${image.name}',
      );

      debugPrint(
        'Image size: ${imageBytes.length} bytes',
      );

      // ----------------------------------------------------------
      // Add image
      // ----------------------------------------------------------

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: image.name,
        ),
      );

      // ----------------------------------------------------------
      // Send request
      // ----------------------------------------------------------

      debugPrint(
        'Sending prediction request...',
      );

      final streamedResponse = await request
          .send()
          .timeout(
            const Duration(seconds: 60),
          );

      // ----------------------------------------------------------
      // Convert response
      // ----------------------------------------------------------

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'Prediction status: ${response.statusCode}',
      );

      debugPrint(
        'Prediction response: ${response.body}',
      );

      // ----------------------------------------------------------
      // Check response
      // ----------------------------------------------------------

      if (response.statusCode != 200) {
        throw PredictionApiException(
          'Prediction request failed: '
          '${response.statusCode} ${response.body}',
          statusCode: response.statusCode,
        );
      }

      // ----------------------------------------------------------
      // Decode JSON
      // ----------------------------------------------------------

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      // ----------------------------------------------------------
      // Read predicted weight
      // ----------------------------------------------------------

      final predictedWeight =
          _toDouble(
        data['predicted_weight_kg'],
      );

      // Confidence is no longer displayed by your UI,
      // but we keep the field because PredictionRecord
      // currently expects it.

      final confidence =
          _toDouble(
        data['confidence_level_percent'],
      );

      // ----------------------------------------------------------
      // Create PredictionRecord
      // ----------------------------------------------------------

      return PredictionRecord(
        id:
            data['id']?.toString() ??
            'P-${DateTime.now().millisecondsSinceEpoch}',

        animalId:
            data['animalId']?.toString() ??
            animalId,

        animalName:
            data['animalName']?.toString() ??
            animalName,

        animalBreed:
            data['animalBreed']?.toString() ??
            animalBreed,

        predictedWeightKg:
            predictedWeight,

        confidence:
            confidence,

        createdAt:
            DateTime.now(),

        imagePath:
            image.name,

        status:
            data['status']?.toString() ??
            'Completed',

        notes:
            data['notes']?.toString() ??
            'Prediction from FastAPI backend.',
      );
    }

    // ==========================================================
    // TIMEOUT
    // ==========================================================

    on TimeoutException {
      throw PredictionApiException(
        'The prediction request timed out.',
      );
    }

    // ==========================================================
    // OTHER ERRORS
    // ==========================================================

    catch (e) {
      if (e is PredictionApiException) {
        rethrow;
      }

      debugPrint(
        'Prediction API error: $e',
      );

      throw PredictionApiException(
        'An unexpected error occurred: $e',
      );
    }
  }

  // ============================================================
  // CONVERT VALUE TO DOUBLE
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}