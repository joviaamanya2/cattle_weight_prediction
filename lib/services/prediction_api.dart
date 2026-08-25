import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/prediction_record.dart';
import '../models/prediction_response.dart';

class PredictionApiException implements Exception {
  PredictionApiException(
    this.message, {
    this.statusCode,
    this.isFriendlyMessage = false,
  });

  final String message;
  final int? statusCode;
  final bool isFriendlyMessage;

  String get userMessage {
    if (isFriendlyMessage) {
      return message;
    }

    if (statusCode == null) {
      return 'Unable to reach the prediction backend. '
          'Check your internet connection and try again.';
    }

    if (statusCode! >= 500) {
      return 'The prediction server returned an error. '
          'Please try again in a moment.';
    }

    if (statusCode == 404) {
      return 'The prediction endpoint was not found. '
          'Please check the API URL.';
    }

    if (statusCode == 422) {
      return 'The image was not accepted by the prediction API.';
    }

    if (statusCode == 400) {
      return 'The prediction request was invalid. '
          'Please check the image and try again.';
    }

    return 'Prediction request failed. Please try again.';
  }

  @override
  String toString() => message;
}

class PredictionApiService {
  PredictionApiService._privateConstructor();

  static final PredictionApiService instance =
      PredictionApiService._privateConstructor();

  // ============================================================
  // API BASE URL
  // ============================================================

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-model-1-dzt0.onrender.com',
  );

  // ============================================================
  // SERVER CONNECTION TEST
  //
  // This tests GET /
  // It does NOT test /predict.
  //
  // Useful for diagnosing the Android phone connection.
  // ============================================================

  Future<void> testConnection() async {
    final uri = Uri.parse(_baseUrl);

    debugPrint('');
    debugPrint('========================================');
    debugPrint('PREDICTION SERVER CONNECTION TEST');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('Platform: ${defaultTargetPlatform.name}');
    debugPrint('Is Web: $kIsWeb');
    debugPrint('Sending GET request...');
    debugPrint('');

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 30),
          );

      stopwatch.stop();

      debugPrint('========================================');
      debugPrint('SERVER CONNECTION TEST RESULT');
      debugPrint('========================================');
      debugPrint(
        'Response time: ${stopwatch.elapsedMilliseconds} ms',
      );
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      debugPrint('========================================');
      debugPrint('');

      if (response.statusCode != 200) {
        throw PredictionApiException(
          'Prediction server health check failed: '
          '${response.statusCode} ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      stopwatch.stop();

      debugPrint('========================================');
      debugPrint('SERVER CONNECTION TIMEOUT');
      debugPrint('========================================');
      debugPrint(
        'Time elapsed: ${stopwatch.elapsedMilliseconds} ms',
      );
      debugPrint('The server did not respond within 30 seconds.');
      debugPrint('========================================');

      throw PredictionApiException(
        'The prediction server took too long to respond.',
        isFriendlyMessage: true,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      debugPrint('========================================');
      debugPrint('SERVER CONNECTION ERROR');
      debugPrint('========================================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Time elapsed: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      rethrow;
    }
  }

  // ============================================================
  // PREDICT WEIGHT
  // ============================================================

  Future<PredictionRecord> predictWeight({
    required String animalId,
    required String animalName,
    required String animalBreed,
    required XFile image,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$_baseUrl/predict');

      debugPrint('');
      debugPrint('========================================');
      debugPrint('PREDICTION API REQUEST');
      debugPrint('========================================');
      debugPrint('URL: $uri');
      debugPrint('Method: POST');
      debugPrint('Animal ID: $animalId');
      debugPrint('Animal Name: $animalName');
      debugPrint('Animal Breed: $animalBreed');
      debugPrint('Platform: ${defaultTargetPlatform.name}');
      debugPrint('Is Web: $kIsWeb');
      debugPrint('========================================');

      // ----------------------------------------------------------
      // CREATE MULTIPART REQUEST
      // ----------------------------------------------------------

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      // ----------------------------------------------------------
      // READ IMAGE
      // ----------------------------------------------------------

      debugPrint('Reading image...');

      final imageBytes = await image.readAsBytes();

      debugPrint('Image selected: ${image.name}');
      debugPrint('Image size: ${imageBytes.length} bytes');

      if (imageBytes.isEmpty) {
        throw PredictionApiException(
          'The selected image is empty. Please select another image.',
          isFriendlyMessage: true,
        );
      }

      // ----------------------------------------------------------
      // ADD IMAGE
      //
      // IMPORTANT:
      //
      // FastAPI:
      //
      // file: UploadFile = File(...)
      //
      // Therefore this MUST be "file".
      // ----------------------------------------------------------

      debugPrint('Adding image to multipart request...');
      debugPrint('Multipart field name: file');
      debugPrint('Filename: ${image.name}');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: image.name,
        ),
      );

      debugPrint('Multipart request prepared.');
      debugPrint('Number of files: ${request.files.length}');
      debugPrint('');

      // ----------------------------------------------------------
      // SEND REQUEST
      // ----------------------------------------------------------

      debugPrint('========================================');
      debugPrint('SENDING PREDICTION REQUEST');
      debugPrint('========================================');
      debugPrint('POST $uri');
      debugPrint('Waiting for server response...');
      debugPrint('');

      final streamedResponse = await request
          .send()
          .timeout(
            const Duration(seconds: 120),
          );

      final serverResponseTime =
          stopwatch.elapsedMilliseconds;

      debugPrint('========================================');
      debugPrint('SERVER RESPONDED');
      debugPrint('========================================');
      debugPrint(
        'Response time: ${serverResponseTime} ms',
      );
      debugPrint(
        'HTTP status: ${streamedResponse.statusCode}',
      );
      debugPrint('========================================');

      // ----------------------------------------------------------
      // CONVERT STREAMED RESPONSE
      // ----------------------------------------------------------

      debugPrint('Reading response body...');

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      stopwatch.stop();

      debugPrint('========================================');
      debugPrint('PREDICTION API RESPONSE');
      debugPrint('========================================');
      debugPrint('Total time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');
      debugPrint('========================================');

      // ----------------------------------------------------------
      // CHECK HTTP STATUS
      // ----------------------------------------------------------

      if (response.statusCode != 200) {
        debugPrint('========================================');
        debugPrint('PREDICTION SERVER RETURNED ERROR');
        debugPrint('========================================');
        debugPrint('HTTP status: ${response.statusCode}');
        debugPrint('Server body: ${response.body}');
        debugPrint('========================================');

        throw PredictionApiException(
          'Prediction request failed: '
          '${response.statusCode} ${response.body}',
          statusCode: response.statusCode,
        );
      }

      // ----------------------------------------------------------
      // DECODE JSON
      // ----------------------------------------------------------

      dynamic decodedResponse;

      try {
        decodedResponse = jsonDecode(response.body);
      } catch (e) {
        debugPrint('========================================');
        debugPrint('INVALID JSON RESPONSE');
        debugPrint('========================================');
        debugPrint('JSON error: $e');
        debugPrint('Raw response: ${response.body}');
        debugPrint('========================================');

        throw PredictionApiException(
          'The prediction server returned an invalid response.',
        );
      }

      // ----------------------------------------------------------
      // CHECK RESPONSE TYPE
      // ----------------------------------------------------------

      if (decodedResponse is! Map<String, dynamic>) {
        debugPrint('========================================');
        debugPrint('UNEXPECTED RESPONSE FORMAT');
        debugPrint('========================================');
        debugPrint(
          'Response type: ${decodedResponse.runtimeType}',
        );
        debugPrint('Response: $decodedResponse');
        debugPrint('========================================');

        throw PredictionApiException(
          'The prediction server returned an unexpected '
          'response format.',
        );
      }

      final Map<String, dynamic> data = decodedResponse;

      debugPrint('Decoded API response successfully.');
      debugPrint('Valid: ${data['valid']}');
      debugPrint(
        'Cattle detected: ${data['cattle_detected']}',
      );

      // ----------------------------------------------------------
      // CHECK BACKEND VALIDATION
      //
      // FastAPI returns HTTP 200 even when:
      //
      // 1. Image is invalid
      // 2. No cattle is detected
      // ----------------------------------------------------------

      final bool isValid = data['valid'] == true;

      final bool cattleDetected =
          data['cattle_detected'] == true;

      if (!isValid || !cattleDetected) {
        final message = data['message']?.toString();

        debugPrint('========================================');
        debugPrint('BACKEND REJECTED IMAGE');
        debugPrint('========================================');
        debugPrint('Valid: $isValid');
        debugPrint('Cattle detected: $cattleDetected');
        debugPrint('Message: $message');
        debugPrint('Detections: ${data['detections']}');
        debugPrint('========================================');

        throw PredictionApiException(
          message ??
              'No cattle detected. '
                  'Please upload an image containing cattle.',
          statusCode: response.statusCode,
          isFriendlyMessage: true,
        );
      }

      // ----------------------------------------------------------
      // CONVERT API RESPONSE
      // ----------------------------------------------------------

      debugPrint('Converting prediction response...');

      final PredictionResponse predictionResponse =
          PredictionResponse.fromJson(data);

      // ----------------------------------------------------------
      // CREATE PREDICTION RECORD
      // ----------------------------------------------------------

      final predictionRecord = PredictionRecord(
        id: 'P-${DateTime.now().millisecondsSinceEpoch}',

        animalId: animalId,

        animalName: animalName,

        animalBreed: animalBreed,

        predictedWeightKg:
            predictionResponse.predictedWeightKg,

        detectionConfidencePercent:
            predictionResponse.detectionConfidencePercent,

        confidenceLevelPercent:
            predictionResponse.confidenceLevelPercent,

        estimatedAccuracyPercent:
            predictionResponse.estimatedAccuracyPercent,

        createdAt: DateTime.now(),

        imagePath: image.name,

        status: 'Completed',

        notes:
            'Prediction generated by the cattle weight '
            'prediction API.',
      );

      stopwatch.stop();

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('PREDICTION SUCCESS');
      debugPrint('========================================');
      debugPrint(
        'Total request time: '
        '${stopwatch.elapsedMilliseconds} ms',
      );
      debugPrint(
        'Weight: '
        '${predictionRecord.predictedWeightKg} kg',
      );
      debugPrint(
        'Detection confidence: '
        '${predictionRecord.detectionConfidencePercent}%',
      );
      debugPrint(
        'Confidence level: '
        '${predictionRecord.confidenceLevelPercent}%',
      );
      debugPrint(
        'Estimated accuracy: '
        '${predictionRecord.estimatedAccuracyPercent}%',
      );
      debugPrint('========================================');
      debugPrint('');

      return predictionRecord;
    }

    // ==========================================================
    // TIMEOUT
    // ==========================================================

    on TimeoutException {
      stopwatch.stop();

      debugPrint('');
      debugPrint('========================================');
      debugPrint('PREDICTION API TIMEOUT');
      debugPrint('========================================');
      debugPrint(
        'Time elapsed: ${stopwatch.elapsedMilliseconds} ms',
      );
      debugPrint(
        'The server did not respond within 120 seconds.',
      );
      debugPrint('========================================');
      debugPrint('');

      throw PredictionApiException(
        'The prediction request timed out. '
        'The server may be waking up. Please try again.',
        isFriendlyMessage: true,
      );
    }

    // ==========================================================
    // OTHER ERRORS
    // ==========================================================

    catch (e, stackTrace) {
      stopwatch.stop();

      if (e is PredictionApiException) {
        rethrow;
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('PREDICTION API ERROR');
      debugPrint('========================================');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint(
        'Time elapsed: ${stopwatch.elapsedMilliseconds} ms',
      );
      debugPrint('Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('========================================');
      debugPrint('');

      throw PredictionApiException(
        'An unexpected error occurred: $e',
      );
    }
  }
}