import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/animal_record.dart';
import '../models/prediction_record.dart';
import '../services/app_data.dart';
import '../services/prediction_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AppDataService _data = AppDataService.instance;
  bool _isLoading = true;
  String? _syncError;

  @override
  void initState() {
    super.initState();
    _loadBackendData();
  }

  Future<void> _loadBackendData() async {
    try {
      await _data.loadFromBackend();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _syncError = 'Unable to sync with backend. Showing local data.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardView(data: _data),
      CattleView(data: _data),
      PredictionView(data: _data),
      HistoryView(data: _data),
      ReportsView(data: _data),
      ImagesView(data: _data),
      NotificationsView(data: _data),
      AdministrationView(data: _data),
      ModelInfoView(data: _data),
      SettingsView(data: _data),
    ];

    final titles = <String>[
      'Dashboard',
      'Cattle Management',
      'Weight Prediction',
      'Prediction History',
      'Reports',
      'Image Management',
      'Notifications',
      'Administration',
      'Model Information',
      'Settings',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final mainItems = <_NavItem>[
          _NavItem('Dashboard', 0),
          _NavItem('Cattle', 1),
          _NavItem('Predict', 2),
          _NavItem('History', 3),
          _NavItem('Reports', 4),
        ];
        final extraItems = <_NavItem>[
          _NavItem('Images', 5),
          _NavItem('Alerts', 6),
          _NavItem('Admin', 7),
          _NavItem('Model', 8),
          _NavItem('Settings', 9),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_selectedIndex]),
            centerTitle: false,
          ),
          drawer: isWide
              ? null
              : Drawer(
                  child: ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text(
                          'Navigation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...mainItems.map(
                        (item) => ListTile(
                          title: Text(item.label),
                          onTap: () {
                            setState(() => _selectedIndex = item.index);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const Divider(),
                      ...extraItems.map(
                        (item) => ListTile(
                          title: Text(item.label),
                          onTap: () {
                            setState(() => _selectedIndex = item.index);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_syncError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_syncError!),
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          if (isWide)
                            NavigationRail(
                              selectedIndex: _selectedIndex,
                              onDestinationSelected: (index) =>
                                  setState(() => _selectedIndex = index),
                              labelType: NavigationRailLabelType.all,
                              destinations: [
                                ...mainItems.map(
                                  (item) => NavigationRailDestination(
                                    label: Text(item.label),
                                    icon: SizedBox.shrink(),
                                  ),
                                ),
                                ...extraItems.map(
                                  (item) => NavigationRailDestination(
                                    label: Text(item.label),
                                    icon: SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          Expanded(child: pages[_selectedIndex]),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  type: BottomNavigationBarType.fixed,
                  items: mainItems
                      .map(
                        (item) => BottomNavigationBarItem(
                          label: item.label,
                          icon: const SizedBox.shrink(),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.index);

  final String label;
  final int index;
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.data});

  final AppDataService data;

  @override
  Widget build(BuildContext context) {
    final summaryCards = [
      _SummaryCard(
        title: 'Total cattle registered',
        value: data.totalCattle.toString(),
      ),
      _SummaryCard(
        title: 'Predictions made',
        value: data.totalPredictions.toString(),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'A compact summary of cattle activity and prediction trends.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: summaryCards.map((card) => card).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          _PanelCard(
            title: 'Recent predictions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.recentPredictions.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${item.animalName}: ${item.predictedWeightKg.toStringAsFixed(0)} kg on ${item.createdAt.toLocal().toString().split(' ')[0]}',
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          _PanelCard(
            title: 'Prediction activity',
            child: Column(
              children: [
                for (final item in data.predictions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${item.animalName} - ${item.predictedWeightKg.toStringAsFixed(0)} kg - ${item.status}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CattleView extends StatefulWidget {
  const CattleView({super.key, required this.data});

  final AppDataService data;

  @override
  State<CattleView> createState() => _CattleViewState();
}

class _CattleViewState extends State<CattleView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _earTagController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _earTagController.dispose();
    _breedController.dispose();
    _sexController.dispose();
    _ageController.dispose();
    _farmController.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add cattle record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _earTagController,
                  decoration: const InputDecoration(labelText: 'Ear tag'),
                ),
                TextField(
                  controller: _breedController,
                  decoration: const InputDecoration(labelText: 'Breed'),
                ),
                TextField(
                  controller: _sexController,
                  decoration: const InputDecoration(labelText: 'Sex'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age (months)'),
                ),
                TextField(
                  controller: _farmController,
                  decoration: const InputDecoration(labelText: 'Farm'),
                ),
                TextField(
                  controller: _ownerController,
                  decoration: const InputDecoration(labelText: 'Owner'),
                ),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Health notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final animal = AnimalRecord(
                  id: 'A-${widget.data.animals.length + 1}',
                  name: _nameController.text.trim().isEmpty
                      ? 'Unnamed'
                      : _nameController.text.trim(),
                  earTag: _earTagController.text.trim(),
                  breed: _breedController.text.trim(),
                  sex: _sexController.text.trim(),
                  ageMonths: int.tryParse(_ageController.text.trim()) ?? 0,
                  dateOfBirth: null,
                  farm: _farmController.text.trim(),
                  owner: _ownerController.text.trim(),
                  healthNotes: _notesController.text.trim(),
                  imagePaths: ['new-image'],
                  createdAt: DateTime.now(),
                );
                widget.data.addAnimal(animal);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Cattle records',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _showAddDialog,
                child: const Text('Add animal'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Maintain animal records and support future image history.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.data.animals.length,
              itemBuilder: (context, index) {
                final animal = widget.data.animals[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${animal.id} | Ear tag: ${animal.earTag}'),
                      Text(
                        'Breed: ${animal.breed} | Sex: ${animal.sex} | Age: ${animal.ageMonths} months',
                      ),
                      Text('Farm: ${animal.farm} | Owner: ${animal.owner}'),
                      Text('Health: ${animal.healthNotes}'),
                      Text('Images: ${animal.imagePaths.join(', ')}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PredictionView extends StatefulWidget {
  const PredictionView({super.key, required this.data});

  final AppDataService data;

  @override
  State<PredictionView> createState() => _PredictionViewState();
}

class _PredictionViewState extends State<PredictionView> {
  final List<XFile> _selectedImages = [];
  bool _isPredicting = false;
  PredictionRecord? _lastPrediction;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _selectImages() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _selectedImages.add(image);
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo == null) {
      return;
    }

    setState(() {
      _selectedImages.add(photo);
      _errorMessage = null;
      _successMessage = null;
    });
  }

  void _removeSelectedImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  Future<void> _runPrediction() async {
    if (_selectedImages.isEmpty) {
      setState(
        () => _errorMessage =
            'Please add at least one image before running prediction.',
      );
      return;
    }

    final animal = widget.data.animals.isNotEmpty
        ? widget.data.animals.first
        : null;
    if (animal == null) {
      setState(
        () => _errorMessage =
            'Please add at least one animal record before predicting.',
      );
      return;
    }

    setState(() {
      _isPredicting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final imagePath = _selectedImages.first.path;
      final prediction = await PredictionApiService.instance.predictWeight(
        animalId: animal.id,
        animalName: animal.name,
        animalBreed: animal.breed,
        imagePath: imagePath,
      );

      setState(() {
        _lastPrediction = prediction;
        _successMessage =
            'Prediction ready: ${prediction.predictedWeightKg.toStringAsFixed(0)} kg with ${(prediction.confidence * 100).toStringAsFixed(0)}% confidence.';
      });
    } catch (error) {
      final message = error is PredictionApiException
          ? error.userMessage
          : 'Prediction failed. Please try again.';

      setState(() {
        _errorMessage = message;
        _successMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediction workflow',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload one or more images, validate quality, and prepare the prediction result for storage.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _selectImages,
                child: const Text('Choose from gallery'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _takePhoto,
                child: const Text('Take photo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade200),
                color: Colors.red.shade50,
              ),
              child: Text(_errorMessage!),
            ),
          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade200),
                color: Colors.green.shade50,
              ),
              child: Text(_successMessage!),
            ),
          if (_isPredicting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Uploaded images',
            child: _selectedImages.isEmpty
                ? const Text('No images selected yet.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages.map((image) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(image.path, fit: BoxFit.cover)
                                  : Image.file(
                                      File(image.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => _removeSelectedImage(image),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'X',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPredicting ? null : _runPrediction,
              child: const Text('Run prediction'),
            ),
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Prediction result',
            child: _lastPrediction == null
                ? const Text('No prediction yet.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Predicted weight: ${_lastPrediction!.predictedWeightKg.toStringAsFixed(0)} kg',
                      ),
                      Text(
                        'Confidence: ${(_lastPrediction!.confidence * 100).toStringAsFixed(0)}%',
                      ),
                      Text(
                        'Prediction date: ${_lastPrediction!.createdAt.toLocal()}',
                      ),
                      Text('Image used: ${_lastPrediction!.imagePath}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.data.addPrediction(_lastPrediction!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Prediction saved to local records.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Save prediction'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Model: ${_lastPrediction!.notes}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key, required this.data});

  final AppDataService data;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _query = '';
  String _breed = '';
  String _farm = '';
  PredictionRecord? _selectedForCompare;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.data.searchPredictions(
      query: _query,
      breed: _breed,
      farm: _farm,
    );
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediction history',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Search and compare prior predictions.'),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              labelText: 'Search by animal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _breed.isEmpty ? null : _breed,
                  decoration: const InputDecoration(
                    labelText: 'Filter breed',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.data
                      .availableBreeds()
                      .map(
                        (breed) =>
                            DropdownMenuItem(value: breed, child: Text(breed)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _breed = value ?? ''),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _farm.isEmpty ? null : _farm,
                  decoration: const InputDecoration(
                    labelText: 'Filter farm',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.data
                      .availableFarms()
                      .map(
                        (farm) =>
                            DropdownMenuItem(value: farm, child: Text(farm)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _farm = value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedForCompare = item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.animalName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item.predictedWeightKg.toStringAsFixed(0)} kg | ${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                        ),
                        Text(item.createdAt.toLocal().toString().split(' ')[0]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedForCompare != null)
            _PanelCard(
              title: 'Compare selection',
              child: Text(
                '${_selectedForCompare!.animalName}: ${_selectedForCompare!.predictedWeightKg.toStringAsFixed(0)} kg',
              ),
            ),
        ],
      ),
    );
  }
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key, required this.data});

  final AppDataService data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Daily, monthly, and breed-based reporting sections are prepared for later export.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SummaryCard(
                    title: 'Daily predictions',
                    value: data.totalPredictions.toString(),
                  ),
                  _SummaryCard(title: 'Average by breed', value: '520 kg'),
                  _SummaryCard(title: 'Heaviest animal', value: 'Bison'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Weight distribution',
            child: Column(
              children: [
                for (final entry in <MapEntry<String, int>>[
                  const MapEntry('Holstein', 2),
                  const MapEntry('Angus', 1),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Expanded(
                          child: Container(height: 10, color: Colors.black12),
                        ),
                        const SizedBox(width: 8),
                        Text(entry.value.toString()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImagesView extends StatelessWidget {
  const ImagesView({super.key, required this.data});

  final AppDataService data;

  @override
  Widget build(BuildContext context) {
    final imageEntries = <String>[
      ...data.animals.expand((animal) => animal.imagePaths),
      ...data.predictions.map((prediction) => prediction.imagePath),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image management',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'View, replace, and review image metadata before prediction.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: imageEntries.length,
              itemBuilder: (context, index) {
                final image = imageEntries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              image,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Upload date: placeholder'),
                            const Text('File size: placeholder'),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Replace'),
                      ),
                      TextButton(onPressed: () {}, child: const Text('Delete')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key, required this.data});

  final AppDataService data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('System messages and pending tasks are listed here.'),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: data.notifications.length,
              itemBuilder: (context, index) {
                final item = data.notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdministrationView extends StatelessWidget {
  const AdministrationView({super.key, required this.data});

  final AppDataService data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Administrative controls and audit trail placeholders.'),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'User roles',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current role: ${data.currentUserRole}'),
                const SizedBox(height: 8),
                const Text('Farmer'),
                const Text('Veterinarian'),
                const Text('Administrator'),
                const Text('Researcher'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Audit trail',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.auditTrail.map((item) => Text(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ModelInfoView extends StatelessWidget {
  const ModelInfoView({super.key, required this.data});

  final AppDataService data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model information',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This screen explains the model structure and deployment status, and it is ready for a real model replacement.',
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Current model',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Model name: placeholder-regression-model'),
                Text('Version: 0.1.0'),
                Text('Integration status: ready-for-model-integration'),
                Text('Expected input: animal metadata and image path'),
                Text('Expected output: predicted weight and confidence'),
                Text('Supported breeds: Cow, Bull, Calf'),
                Text('Supported image types: JPEG and PNG'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Service notes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Model API integration point is ready.'),
                Text(
                  'Replace the placeholder backend logic with your trained model when it is available.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.data});

  final AppDataService data;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust preferences and profile settings for the current user.',
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${widget.data.profileName}'),
                Text('Role: ${widget.data.currentUserRole}'),
                Text('Language: ${widget.data.language}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Preferences',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: widget.data.notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => widget.data.notificationsEnabled = value),
                  title: const Text('Notifications'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: widget.data.unitsKg,
                  onChanged: (value) =>
                      setState(() => widget.data.unitsKg = value),
                  title: const Text('Use kilogram units'),
                  contentPadding: EdgeInsets.zero,
                ),
                DropdownButtonFormField<String>(
                  initialValue: widget.data.language,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'French', child: Text('French')),
                    DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                  ],
                  onChanged: (value) =>
                      setState(() => widget.data.language = value ?? 'English'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
