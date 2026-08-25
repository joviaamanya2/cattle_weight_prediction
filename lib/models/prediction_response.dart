class PredictionResponse {
  PredictionResponse({
    required this.valid,
    required this.cattleDetected,
    required this.animal,
    required this.detectionConfidencePercent,
    required this.predictedWeightKg,
    required this.confidenceLevelPercent,
    required this.estimatedAccuracyPercent,
    required this.confidenceInterval,
    required this.expectedErrorKg,
    required this.modelRmseKg,
    required this.filename,
    this.message,
    this.detections = const [],
  });

  // ============================================================
  // BASIC RESPONSE
  // ============================================================

  final bool valid;

  final bool cattleDetected;

  final String animal;

  // ============================================================
  // PREDICTION RESULTS
  // ============================================================

  final double detectionConfidencePercent;

  final double predictedWeightKg;

  final double confidenceLevelPercent;

  final double estimatedAccuracyPercent;

  // ============================================================
  // CONFIDENCE INTERVAL
  // ============================================================

  final ConfidenceInterval confidenceInterval;

  // ============================================================
  // MODEL METRICS
  // ============================================================

  final double expectedErrorKg;

  final double modelRmseKg;

  // ============================================================
  // FILE
  // ============================================================

  final String filename;

  // ============================================================
  // OPTIONAL MESSAGE
  // ============================================================

  final String? message;

  // ============================================================
  // YOLO DETECTIONS
  // ============================================================

  final List<Detection> detections;

  // ============================================================
  // FROM JSON
  // ============================================================

  factory PredictionResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    // ----------------------------------------------------------
    // Parse detections safely
    //
    // The backend only sends "detections" in some responses.
    // Therefore we must not assume it is always present.
    // ----------------------------------------------------------

    final rawDetections = json['detections'];

    final List<Detection> parsedDetections = [];

    if (rawDetections is List) {
      for (final item in rawDetections) {
        if (item is Map<String, dynamic>) {
          parsedDetections.add(
            Detection.fromJson(item),
          );
        }
      }
    }

    // ----------------------------------------------------------
    // Parse confidence interval safely
    // ----------------------------------------------------------

    final rawConfidenceInterval =
        json['confidence_interval_kg'];

    Map<String, dynamic> confidenceIntervalData = {};

    if (rawConfidenceInterval
        is Map<String, dynamic>) {
      confidenceIntervalData =
          rawConfidenceInterval;
    }

    // ----------------------------------------------------------
    // Return response
    // ----------------------------------------------------------

    return PredictionResponse(
      valid: json['valid'] == true,

      cattleDetected:
          json['cattle_detected'] == true,

      animal:
          json['animal']?.toString() ?? '',

      detectionConfidencePercent:
          _toDouble(
            json['detection_confidence_percent'],
          ),

      predictedWeightKg:
          _toDouble(
            json['predicted_weight_kg'],
          ),

      confidenceLevelPercent:
          _toDouble(
            json['confidence_level_percent'],
          ),

      estimatedAccuracyPercent:
          _toDouble(
            json['estimated_accuracy_percent'],
          ),

      confidenceInterval:
          ConfidenceInterval.fromJson(
        confidenceIntervalData,
      ),

      expectedErrorKg:
          _toDouble(
            json['expected_error_kg'],
          ),

      modelRmseKg:
          _toDouble(
            json['model_rmse_kg'],
          ),

      filename:
          json['filename']?.toString() ?? '',

      message:
          json['message']?.toString(),

      detections:
          parsedDetections,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,

      'cattle_detected':
          cattleDetected,

      'animal': animal,

      'detection_confidence_percent':
          detectionConfidencePercent,

      'predicted_weight_kg':
          predictedWeightKg,

      'confidence_level_percent':
          confidenceLevelPercent,

      'estimated_accuracy_percent':
          estimatedAccuracyPercent,

      'confidence_interval_kg':
          confidenceInterval.toJson(),

      'expected_error_kg':
          expectedErrorKg,

      'model_rmse_kg':
          modelRmseKg,

      'filename':
          filename,

      'message':
          message,

      'detections':
          detections
              .map(
                (item) => item.toJson(),
              )
              .toList(),
    };
  }
}


// ============================================================
// HELPER
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


// ============================================================
// CONFIDENCE INTERVAL
// ============================================================

class ConfidenceInterval {
  ConfidenceInterval({
    required this.lower,
    required this.upper,
  });

  final double lower;

  final double upper;

  // ============================================================
  // FROM JSON
  // ============================================================

  factory ConfidenceInterval.fromJson(
    Map<String, dynamic> json,
  ) {
    return ConfidenceInterval(
      lower:
          _toDouble(
            json['lower'],
          ),

      upper:
          _toDouble(
            json['upper'],
          ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'lower': lower,
      'upper': upper,
    };
  }
}


// ============================================================
// YOLO DETECTION
// ============================================================

class Detection {
  Detection({
    required this.className,
    required this.confidence,
  });

  final String className;

  final double confidence;

  // ============================================================
  // FROM JSON
  // ============================================================

  factory Detection.fromJson(
    Map<String, dynamic> json,
  ) {
    return Detection(
      className:
          json['class']?.toString() ?? '',

      confidence:
          _toDouble(
            json['confidence'],
          ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'class': className,
      'confidence': confidence,
    };
  }
}