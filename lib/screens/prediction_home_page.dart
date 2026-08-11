import 'package:flutter/material.dart';

class PredictionHomePage extends StatefulWidget {
  const PredictionHomePage({super.key});

  @override
  State<PredictionHomePage> createState() => _PredictionHomePageState();
}

class _PredictionHomePageState extends State<PredictionHomePage> {
  // Stores the selected animal from the dropdown.
  String _selectedAnimal = 'cow';

  // Stores the image state once the user picks a photo.
  String? _imagePath;

  // Stores the placeholder result before the real model is connected.
  String? _predictionResult;

  // Updates the chosen animal type.
  void _onAnimalChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedAnimal = value;
      });
    }
  }

  // Placeholder method for future model integration.
  void _runPrediction() {
    setState(() {
      _predictionResult =
          'The prediction model is not connected yet. This screen is ready to display the result once the model is added.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Weight Predictor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction is the first screen. Use the example workflow here and then continue to login for your dashboard.',
              style: TextStyle(fontSize: 16, color: Colors.green.shade900),
            ),
            const SizedBox(height: 20),
            const Text(
              'Animal type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedAnimal,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'cow', child: Text('Cow')),
                DropdownMenuItem(value: 'bull', child: Text('Bull')),
                DropdownMenuItem(value: 'calf', child: Text('Calf')),
              ],
              onChanged: _onAnimalChanged,
            ),
            const SizedBox(height: 20),
            const Text(
              'Photo input',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('Choose an image from the gallery or camera.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _imagePath = 'placeholder-image';
                      });
                    },
                    child: const Text('Select photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_imagePath != null)
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Image preview will appear here'),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _runPrediction,
                child: const Text('Run prediction'),
              ),
            ),
            const SizedBox(height: 20),
            if (_predictionResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediction result',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Animal: $_selectedAnimal'),
                    const SizedBox(height: 4),
                    Text(_predictionResult!),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth');
                },
                child: const Text('Go to login / register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
