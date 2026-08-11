import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_for_model/services/prediction_api.dart';

void main() {
  test('describes connection errors clearly', () {
    final exception = PredictionApiException('SocketException: Failed host lookup');

    expect(exception.userMessage, contains('backend'));
    expect(exception.userMessage, contains('running'));
  });

  test('describes server errors clearly', () {
    final exception = PredictionApiException('Prediction request failed: 500 Internal Server Error', statusCode: 500);

    expect(exception.userMessage, contains('server'));
  });
}
