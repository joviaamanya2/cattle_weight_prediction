import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Lets the signed-in user view and edit their locally-stored profile: name,
/// role and photo, sign out, or delete the profile entirely.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  UserProfile? _profile;
  String _selectedRole = 'Farmer';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUpdatingPhoto = false;

  static const List<String> _roles = [
    'Farmer',
    'Veterinarian',
    'Livestock Agent',
    'Student',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.instance.load();
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _nameController.text = profile?.name ?? '';
      _selectedRole = _roles.contains(profile?.role) ? profile!.role : 'Farmer';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SAVE DETAILS
  // ------------------------------------------------------------

  Future<void> _saveDetails() async {
    final profile = _profile;
    if (profile == null) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updated = profile.copyWith(name: trimmedName, role: _selectedRole);
    await UserProfileService.instance.save(updated);

    if (!mounted) return;

    setState(() {
      _profile = updated;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
  }

  // ------------------------------------------------------------
  // PHOTO
  // ------------------------------------------------------------

  Future<void> _showPhotoOptions() async {
    final profile = _profile;
    if (profile == null) return;

    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.gallery),
            ),
            if (profile.avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    if (action == _PhotoAction.remove) {
      await _removePhoto();
    } else {
      await _pickPhoto(
        action == _PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final profile = _profile;
    if (profile == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null || !mounted) return;

      setState(() => _isUpdatingPhoto = true);

      final dir = await getApplicationDocumentsDirectory();
      final dotIndex = picked.path.lastIndexOf('.');
      final ext = dotIndex == -1 ? '.jpg' : picked.path.substring(dotIndex);
      final savedPath =
          '${dir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}$ext';

      await File(picked.path).copy(savedPath);

      // Clean up the previous photo file now that a new one is saved.
      final oldPath = profile.avatarPath;
      if (oldPath != null) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      final updated = profile.copyWith(avatarPath: savedPath);
      await UserProfileService.instance.save(updated);

      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isUpdatingPhoto = false;
      });
    } catch (e) {
      debugPrint('Profile photo update error: $e');
      if (!mounted) return;
      setState(() => _isUpdatingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the photo. Try again.')),
      );
    }
  }

  Future<void> _removePhoto() async {
    final profile = _profile;
    if (profile == null || profile.avatarPath == null) return;

    setState(() => _isUpdatingPhoto = true);

    final file = File(profile.avatarPath!);
    if (await file.exists()) {
      await file.delete();
    }

    final updated = profile.copyWith(clearAvatar: true);
    await UserProfileService.instance.save(updated);

    if (!mounted) return;
    setState(() {
      _profile = updated;
      _isUpdatingPhoto = false;
    });
  }

  // ------------------------------------------------------------
  // LOG OUT
  // ------------------------------------------------------------

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Log out?'),
        content: const Text(
          'Your profile stays on this device — you can sign back in with '
          'the same email any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await UserProfileService.instance.setLoggedIn(false);

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  // ------------------------------------------------------------
  // DELETE PROFILE
  // ------------------------------------------------------------

  Future<void> _confirmDeleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Delete profile?'),
        content: const Text(
          'This removes your name, photo and role from this device. Your '
          'saved cattle predictions are not affected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await UserProfileService.instance.clear();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? SafeArea(
                  child: EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'No profile found',
                    message: 'Sign in or create an account to set up a profile.',
                    action: FilledButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/auth', (route) => false),
                      child: const Text('Go to sign in'),
                    ),
                  ),
                )
              : _buildProfileBody(),
    );
  }

  Widget _buildProfileBody() {
    final profile = _profile!;

    return Stack(
      children: [
        // Gradient header banner behind everything, matching the dashboard
        // hero card's brand gradient.
        Container(
          height: 210,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.section,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAvatar(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            profile.name.isEmpty ? 'Unnamed user' : profile.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: StatusChip(
                              label: _selectedRole,
                              foreground: AppColors.primaryDark,
                              background: AppColors.primarySoft,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),

                          const SectionHeader(title: 'Account details'),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            child: Column(
                              children: [
                                AppTextField(
                                  label: 'Name',
                                  controller: _nameController,
                                  required: true,
                                  enabled: !_isSaving,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FieldShell(
                                  label: 'Email',
                                  helper: 'Email cannot be changed here.',
                                  child: Text(
                                    profile.email,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppDropdownField<String>(
                                  label: 'Role',
                                  value: _selectedRole,
                                  items: _roles
                                      .map((role) => DropdownMenuItem(
                                            value: role,
                                            child: Text(role),
                                          ))
                                      .toList(),
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(() => _selectedRole = value);
                                        },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: _isSaving ? null : _saveDetails,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save changes'),
                          ),

                          const SizedBox(height: AppSpacing.section),
                          const SectionHeader(title: 'Session'),
                          const SizedBox(height: AppSpacing.lg),
                          _buildActionCard(
                            icon: Icons.logout_rounded,
                            accent: AppColors.primary,
                            accentSoft: AppColors.primarySoft,
                            title: 'Log out',
                            subtitle: 'Sign out of this device.',
                            onTap: _confirmLogout,
                          ),

                          const SizedBox(height: AppSpacing.section),
                          Text(
                            'Danger zone',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.danger),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            color: AppColors.dangerSoft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Delete profile',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(color: AppColors.danger),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Removes your name, photo and role from '
                                            'this device. Saved predictions are kept. '
                                            'This cannot be undone.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _confirmDeleteProfile,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Delete profile'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A tappable row card used for the Log out action — same shape as the
  /// icon-badge rows on the Tips tab, for a consistent feel across screens.
  Widget _buildActionCard({
    required IconData icon,
    required Color accent,
    required Color accentSoft,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Row(
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
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarPath = _profile?.avatarPath;

    return Center(
      child: GestureDetector(
        onTap: _isUpdatingPhoto ? null : _showPhotoOptions,
        child: Stack(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: AppShadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: _isUpdatingPhoto
                  ? const Center(child: CircularProgressIndicator())
                  : avatarPath != null
                      ? Image.file(
                          File(avatarPath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: AppColors.primary,
                        ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }
