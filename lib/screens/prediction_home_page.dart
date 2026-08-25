import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/prediction_record.dart';
import '../services/prediction_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

class PredictionHomePage extends StatefulWidget {
  const PredictionHomePage({super.key});

  @override
  State<PredictionHomePage> createState() => _PredictionHomePageState();
}

class _PredictionHomePageState extends State<PredictionHomePage> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();

  XFile? _selectedImage;

  String _selectedAnimal = 'cow';
  String _selectedBreed = 'Holstein';

  PredictionRecord? _prediction;

  String? _errorMessage;

  bool _isPredicting = false;

  /// Whether the result on screen has been written to history yet. The name
  /// is only collected once a result exists, so both live here rather than
  /// in the prediction form.
  bool _resultSaved = false;
  String? _savedName;

  // ------------------------------------------------------------
  // LOCAL HISTORY
  // ------------------------------------------------------------

  final List<_PredictionHistoryItem> _history = [];

  /// History tab filter: 0 = all, 1 = today.
  int _historyFilter = 0;

  // ------------------------------------------------------------
  // TAB CONTROLLER
  // ------------------------------------------------------------

  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // IMAGE PICKING
  // ------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _prediction = null;
        _errorMessage = null;
        _resultSaved = false;
        _savedName = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to select the image. Please try again.';
      });

      debugPrint('Image picker error: $e');
    }
  }

  // ------------------------------------------------------------
  // CLEAR IMAGE
  // ------------------------------------------------------------

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _prediction = null;
      _errorMessage = null;
      _resultSaved = false;
      _savedName = null;
    });
  }

  // ------------------------------------------------------------
  // RUN PREDICTION
  // ------------------------------------------------------------

  Future<void> _runPrediction() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage =
            'Please select a cattle image before running prediction.';
      });
      return;
    }

    setState(() {
      _isPredicting = true;
      _prediction = null;
      _errorMessage = null;
      _resultSaved = false;
      _savedName = null;
    });

    try {
      // The animal is still unnamed at this point — naming happens in the
      // save prompt once a result comes back.
      final result = await PredictionApiService.instance.predictWeight(
        animalId: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        animalName: 'Unnamed cattle',
        animalBreed: _selectedBreed,
        image: _selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        _prediction = result;
        _isPredicting = false;
      });

      // Nothing is written to history until the farmer confirms.
      await _promptSaveResult();
    } on PredictionApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.userMessage;
        _isPredicting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Something went wrong while making the prediction.';
        _isPredicting = false;
      });

      debugPrint('Prediction error: $e');
    }
  }

  // ------------------------------------------------------------
  // SAVE PROMPT
  // ------------------------------------------------------------

  /// Asks whether to keep the result, collecting the cattle name at the same
  /// time. Declining leaves the result on screen but out of history.
  Future<void> _promptSaveResult() async {
    final record = _prediction;
    if (record == null) return;

    _nameController.clear();

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
          0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          0,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
        ),
        title: const Text('Save this result?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.predictedWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_animalTypeLabel • $_selectedBreed',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Cattle name',
              controller: _nameController,
              hint: 'e.g. Nakato',
              helper: 'Leave blank to save as “Unnamed cattle”.',
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.inkMuted,
              minimumSize: const Size(88, 46),
            ),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(112, 46),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (save == true) {
      _saveCurrentResult(_nameController.text.trim());
    }
  }

  void _saveCurrentResult(String rawName) {
    final record = _prediction;
    if (record == null) return;

    final String name = rawName.isEmpty ? 'Unnamed cattle' : rawName;

    setState(() {
      _history.insert(
        0,
        _PredictionHistoryItem(
          name: name,
          animalType: _animalTypeLabel,
          breed: _selectedBreed,
          weight: record.predictedWeightKg,
          date: DateTime.now(),
        ),
      );
      _resultSaved = true;
      _savedName = name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved “$name” to history.')),
    );
  }

  // ------------------------------------------------------------
  // ANIMAL TYPE LABEL
  // ------------------------------------------------------------

  String get _animalTypeLabel {
    switch (_selectedAnimal) {
      case 'bull':
        return 'Bull';
      case 'calf':
        return 'Calf';
      default:
        return 'Cow';
    }
  }

  // ------------------------------------------------------------
  // DERIVED STATS
  // ------------------------------------------------------------

  int get _todayCount {
    final now = DateTime.now();
    return _history
        .where((h) =>
            h.date.year == now.year &&
            h.date.month == now.month &&
            h.date.day == now.day)
        .length;
  }

  double get _averageWeight {
    if (_history.isEmpty) return 0;
    final total = _history.fold<double>(0, (sum, h) => sum + h.weight);
    return total / _history.length;
  }

  double get _heaviestWeight {
    if (_history.isEmpty) return 0;
    return _history.map((h) => h.weight).reduce((a, b) => a > b ? a : b);
  }

  List<_PredictionHistoryItem> get _visibleHistory {
    if (_historyFilter == 0) return _history;
    final now = DateTime.now();
    return _history
        .where((h) =>
            h.date.year == now.year &&
            h.date.month == now.month &&
            h.date.day == now.day)
        .toList();
  }

  // ------------------------------------------------------------
  // IMAGE PREVIEW
  // ------------------------------------------------------------

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No cattle photo yet',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Add a clear side-on photo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        children: [
          SizedBox(
            height: 240,
            width: double.infinity,
            child: FutureBuilder(
              future: _selectedImage!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ColoredBox(
                    color: AppColors.field,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const ColoredBox(
                    color: AppColors.field,
                    child: Center(child: Text('Unable to preview image')),
                  );
                }

                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: CircleIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Remove photo',
              size: 36,
              background: Colors.black54,
              foreground: Colors.white,
              onPressed: _isPredicting ? null : _clearImage,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PREDICTION RESULT
  // ------------------------------------------------------------

  Widget _buildPredictionResult() {
    if (_prediction == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prediction result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_resultSaved)
                const StatusChip(
                  label: 'Saved',
                  icon: Icons.check_rounded,
                  foreground: AppColors.success,
                  background: AppColors.successSoft,
                )
              else
                const StatusChip(
                  label: 'Not saved',
                  icon: Icons.bookmark_border_rounded,
                  foreground: AppColors.warning,
                  background: AppColors.warningSoft,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '${_prediction!.predictedWeightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Estimated from the submitted photo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _resultRow('Animal type', _animalTypeLabel),
          _resultRow('Breed', _selectedBreed),
          if (_savedName != null) _resultRow('Cattle name', _savedName!),
          const SizedBox(height: AppSpacing.md),
          const AppBanner(
            message:
                'This is an estimate. Use a calibrated scale for sales, '
                'treatment or dosing decisions.',
            icon: Icons.info_outline_rounded,
            foreground: AppColors.inkMuted,
            background: AppColors.field,
          ),
          // Declining the prompt should not strand the result.
          if (!_resultSaved) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _promptSaveResult,
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Save to history'),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RESULT ROW
  // ------------------------------------------------------------

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD PREDICT TAB CONTENT
  // ------------------------------------------------------------

  Widget _buildPredictTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.section,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HERO
                // ------------------------------------------------
                _buildHero(),
                const SizedBox(height: AppSpacing.xl),

                // ------------------------------------------------
                // STAT GRID
                // ------------------------------------------------
                _buildStatGrid(),
                const SizedBox(height: AppSpacing.section),

                // ------------------------------------------------
                // CATTLE INFORMATION
                // ------------------------------------------------
                const SectionHeader(
                  title: 'Cattle details',
                  subtitle: 'Tell us what we are weighing',
                ),
                const SizedBox(height: AppSpacing.lg),

                AppCard(
                  child: Column(
                    children: [
                      AppDropdownField<String>(
                        label: 'Animal type',
                        required: true,
                        value: _selectedAnimal,
                        items: const [
                          DropdownMenuItem(value: 'cow', child: Text('Cow')),
                          DropdownMenuItem(value: 'bull', child: Text('Bull')),
                          DropdownMenuItem(value: 'calf', child: Text('Calf')),
                        ],
                        onChanged: _isPredicting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedAnimal = value);
                              },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField<String>(
                        label: 'Breed',
                        required: true,
                        value: _selectedBreed,
                        items: const [
                          DropdownMenuItem(
                            value: 'Holstein',
                            child: Text('Holstein'),
                          ),
                         
                          DropdownMenuItem(
                            value: 'Angus',
                            child: Text('Angus'),
                          ),
                          DropdownMenuItem(
                            value: 'Jersey',
                            child: Text('Jersey'),
                          ),
                          DropdownMenuItem(
                            value: 'Friesian',
                            child: Text('Friesian'),
                          ),
                          DropdownMenuItem(
                            value: 'Ankole',
                            child: Text('Ankole'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: _isPredicting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedBreed = value);
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),

                // ------------------------------------------------
                // PHOTO
                // ------------------------------------------------
                const SectionHeader(
                  title: 'Cattle photo',
                  subtitle: 'A clear side view gives the best estimate',
                ),
                const SizedBox(height: AppSpacing.lg),

                AppCard(
                  child: Column(
                    children: [
                      _buildImagePreview(),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPredicting
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPredicting
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                              ),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------
                if (_errorMessage != null) ...[
                  AppBanner(
                    message: _errorMessage!,
                    icon: Icons.error_outline_rounded,
                    foreground: AppColors.danger,
                    background: AppColors.dangerSoft,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ------------------------------------------------
                // PREDICT BUTTON
                // ------------------------------------------------
                FilledButton(
                  onPressed: _isPredicting ? null : _runPrediction,
                  child: _isPredicting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Text('Calculating weight...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Predict Weight'),
                            SizedBox(width: AppSpacing.sm),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),

                if (_prediction != null) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _buildPredictionResult(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HERO
  // ------------------------------------------------------------

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Know your cattle’s weight',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Snap a photo and get an instant estimate — no scale needed.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STAT GRID
  // ------------------------------------------------------------

  Widget _buildStatGrid() {
    final tiles = [
      StatTile(
        icon: Icons.insights_rounded,
        value: '${_history.length}',
        label: 'Total\nsaved',
        accent: AppColors.peach,
        accentSoft: AppColors.peachSoft,
      ),
      StatTile(
        icon: Icons.today_rounded,
        value: '$_todayCount',
        label: 'Done\ntoday',
        accent: AppColors.leaf,
        accentSoft: AppColors.leafSoft,
      ),
      StatTile(
        icon: Icons.speed_rounded,
        value: _history.isEmpty ? '—' : _averageWeight.toStringAsFixed(0),
        label: 'Avg\nkg',
        accent: AppColors.periwinkle,
        accentSoft: AppColors.periwinkleSoft,
      ),
      StatTile(
        icon: Icons.trending_up_rounded,
        value: _history.isEmpty ? '—' : _heaviestWeight.toStringAsFixed(0),
        label: 'Max\nkg',
        accent: AppColors.rose,
        accentSoft: AppColors.roseSoft,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD HISTORY TAB
  // ------------------------------------------------------------

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return SafeArea(
        bottom: false,
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'No predictions yet',
          message: 'Your cattle weight estimates will appear here.',
          action: FilledButton(
            onPressed: () => setState(() => _selectedTabIndex = 0),
            child: const Text('Make a prediction'),
          ),
        ),
      );
    }

    final visible = _visibleHistory;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.section,
        ),
        children: [
          SectionHeader(
            title: 'Prediction history',
            subtitle: '${_history.length} saved on this device',
            trailing: CircleIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Clear all history',
              onPressed: _confirmClearHistory,
              foreground: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedToggle(
            segments: const ['All', 'Today'],
            selectedIndex: _historyFilter,
            onChanged: (i) => setState(() => _historyFilter = i),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.section),
              child: Text(
                'Nothing recorded today yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...visible.map(_buildHistoryCard),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Clear history?'),
        content: const Text(
          'This removes every saved prediction from this device. '
          'It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(_history.clear);
    }
  }

  Widget _buildHistoryCard(_PredictionHistoryItem item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const StatusChip(
                      label: 'Estimated',
                      foreground: AppColors.success,
                      background: AppColors.successSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.animalType} • ${item.breed}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(item.date),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${item.weight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD TIPS TAB
  // ------------------------------------------------------------

  Widget _buildTipsTab() {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.section,
        ),
        children: [
          const SectionHeader(
            title: 'Tips & guidelines',
            subtitle: 'Get the most accurate estimate every time',
          ),
          const SizedBox(height: AppSpacing.xl),
          _tipCard(
            icon: Icons.photo_camera_outlined,
            title: 'Take clear side photos',
            description:
                'Keep the whole animal visible. Shoot from the side of the '
                'cattle for the most accurate estimate.',
            accent: AppColors.periwinkle,
            accentSoft: AppColors.periwinkleSoft,
          ),
          _tipCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Use good lighting',
            description:
                'Daylight gives the best visibility. Avoid strong shadows '
                'that hide the animal’s body shape.',
            accent: AppColors.peach,
            accentSoft: AppColors.peachSoft,
          ),
          _tipCard(
            icon: Icons.straighten_rounded,
            title: 'Stand on level ground',
            description:
                'Make sure the animal is standing naturally on level ground '
                'for consistent results.',
            accent: AppColors.leaf,
            accentSoft: AppColors.leafSoft,
          ),
          _tipCard(
            icon: Icons.repeat_rounded,
            title: 'Keep angle & distance consistent',
            description:
                'Shoot from the same distance and angle each time so your '
                'weight history stays comparable.',
            accent: AppColors.rose,
            accentSoft: AppColors.roseSoft,
          ),
          _tipCard(
            icon: Icons.scale_rounded,
            title: 'Confirm important decisions',
            description:
                'The prediction is an estimate. Always use a reliable scale '
                'for sales, treatment or dosing.',
            accent: AppColors.danger,
            accentSoft: AppColors.dangerSoft,
          ),
          _tipCard(
            icon: Icons.timeline_rounded,
            title: 'Track weight trends',
            description:
                'Repeat predictions over time to see whether your cattle are '
                'gaining or losing weight.',
            accent: AppColors.primary,
            accentSoft: AppColors.primarySoft,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro tip',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Build a routine — photograph at the same time of '
                        'day, in the same spot, for the most comparable '
                        'results.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.inkMuted,
                        ),
                      ),
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

  Widget _tipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required Color accentSoft,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: accentSoft, shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const titles = ['Cattle Weight', 'History', 'Tips'];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: AppSpacing.xl,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titles[_selectedTabIndex]),
            Text('By Jaguza', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: CircleIconButton(
              icon: Icons.person_outline_rounded,
              tooltip: 'Profile',
              onPressed: () => Navigator.pushNamed(context, '/auth'),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildPredictTab(),
          _buildHistoryTab(),
          _buildTipsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (index) => setState(() => _selectedTabIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_weight_outlined),
                activeIcon: Icon(Icons.monitor_weight_rounded),
                label: 'Predict',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb_outline_rounded),
                activeIcon: Icon(Icons.lightbulb_rounded),
                label: 'Tips',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FORMAT DATE
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }
}

// ============================================================
// HISTORY MODEL
// ============================================================

class _PredictionHistoryItem {
  final String name;
  final String animalType;
  final String breed;
  final double weight;
  final DateTime date;

  _PredictionHistoryItem({
    required this.name,
    required this.animalType,
    required this.breed,
    required this.weight,
    required this.date,
  });
}
