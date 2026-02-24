import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../utils/leveling_system.dart';

const Color clubOrange = Color(0xFFF57809);
const Color darkBackground = Color(0xFF0B0B0F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _authService = AuthService();

  Map<String, dynamic>? _profile;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _autoValidate = false;

  File? _pickedImageFile;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;

  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialPhone = '';

  // Système de niveau
  int _totalXp = 0;
  int _currentLevel = 1;
  double _levelProgress = 0.0;
  int _xpToNextLevel = 0;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _authService.getUserProfile();

      if (!mounted) return;

      _profile = data;
      _hydrateControllersFromProfile(data);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de charger le profil"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _hydrateControllersFromProfile(Map<String, dynamic>? data) {
    final firstName = (data?['firstName'] ?? data?['first_name'] ?? '')
        .toString();
    final lastName = (data?['lastName'] ?? data?['last_name'] ?? '').toString();
    final phone = (data?['phone'] ?? '').toString();

    final xpRaw = data?['total_xp'] ?? data?['totalXp'] ?? 0;
    _totalXp = _safeInt(xpRaw);

    _currentLevel = math.max(1, LevelingSystem.getLevel(_totalXp));
    _levelProgress = (LevelingSystem.getProgressToNextLevel(
      _totalXp,
    )).clamp(0.0, 1.0).toDouble();
    _xpToNextLevel = math.max(0, LevelingSystem.getXpToNextLevel(_totalXp));

    _initialFirstName = firstName;
    _initialLastName = lastName;
    _initialPhone = phone;

    _firstNameCtrl.text = firstName;
    _lastNameCtrl.text = lastName;
    _phoneCtrl.text = phone;

    _pickedImageFile = null;
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _autoValidate = false;
    });
  }

  void _cancelEditing() {
    _firstNameCtrl.text = _initialFirstName;
    _lastNameCtrl.text = _initialLastName;
    _phoneCtrl.text = _initialPhone;

    setState(() {
      _isEditing = false;
      _autoValidate = false;
      _pickedImageFile = null;
    });
  }

  bool get _hasChanges {
    final textChanged =
        _firstNameCtrl.text.trim() != _initialFirstName.trim() ||
        _lastNameCtrl.text.trim() != _initialLastName.trim() ||
        _phoneCtrl.text.trim() != _initialPhone.trim();

    final photoChanged = _pickedImageFile != null;

    return textChanged || photoChanged;
  }

  Future<void> _pickProfileImage() async {
    if (!_isEditing) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (file == null) return;

      setState(() {
        _pickedImageFile = File(file.path);
      });
    } catch (e) {
      debugPrint("Erreur sélection image: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de sélectionner l’image"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_isEditing || _isSaving) return;

    FocusScope.of(context).unfocus();

    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanges) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucune modification à enregistrer"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedText = await _authService.updateUserProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (updatedText == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de mettre à jour les informations"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _profile = {...?_profile, ...updatedText};

      if (_pickedImageFile != null) {
        final updatedPhoto = await _authService.uploadProfileImage(
          _pickedImageFile!,
        );

        if (updatedPhoto == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Infos enregistrées, mais photo non mise à jour"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _profile = {...?_profile, ...updatedPhoto};
        }
      }

      _hydrateControllersFromProfile(_profile);

      if (!mounted) return;
      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil mis à jour ✅"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Erreur save profil: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l’enregistrement"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  ImageProvider? _buildAvatarProvider() {
    // Preview local (si utilisateur sélectionne une image)
    if (_pickedImageFile != null) {
      return FileImage(_pickedImageFile!);
    }

    final raw =
        (_profile?['profileImageUrl'] ??
                _profile?['profile_image_url'] ??
                _profile?['avatar'] ??
                '')
            .toString()
            .trim();

    if (raw.isEmpty) return null;

    try {
      // URL distante
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return NetworkImage(raw);
      }

      // Data URL base64 (data:image/...;base64,xxxxx)
      if (raw.startsWith('data:image')) {
        final base64Part = raw.split(',').last;
        return MemoryImage(base64Decode(base64Part));
      }

      // Base64 "brut"
      if (raw.length > 80) {
        return MemoryImage(base64Decode(raw));
      }
    } catch (e) {
      debugPrint("Erreur decode avatar: $e");
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final email = (_profile?['email'] ?? 'Email indisponible').toString();

    final previewName = [
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    final fullName = previewName.isEmpty ? "Athlète" : previewName;
    final progressPercent = (_levelProgress * 100).round();

    return Scaffold(
      backgroundColor: darkBackground,
      extendBody: true,
      body: Stack(
        children: [
          const _ProfileBackgroundDecor(),
          SafeArea(
            bottom: false,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: clubOrange),
                  )
                : Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                      children: [
                        _ProfileEditableHero(
                          isEditing: _isEditing,
                          isSaving: _isSaving,
                          fullName: fullName,
                          email: email,
                          avatarProvider: _buildAvatarProvider(),
                          onBack: () => Navigator.pop(context, true),
                          onEdit: _startEditing,
                          onCancel: _cancelEditing,
                          onPickImage: _pickProfileImage,
                          currentLevel: _currentLevel,
                          totalXp: _totalXp,
                          levelProgress: _levelProgress,
                          xpToNextLevel: _xpToNextLevel,
                          hasChanges: _hasChanges,
                        ),

                        const SizedBox(height: 16),

                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _LocalSectionTitle(
                                "STATISTIQUES DU COMPTE",
                              ),
                              const SizedBox(height: 14),
                              _StatsGrid(
                                items: [
                                  _StatItem(
                                    icon: Icons.star_rounded,
                                    label: "Niveau",
                                    value: "$_currentLevel",
                                    accent: clubOrange,
                                  ),
                                  _StatItem(
                                    icon: Icons.bolt_rounded,
                                    label: "XP total",
                                    value: _totalXp.toString(),
                                    accent: const Color(0xFF6EE7B7),
                                  ),
                                  _StatItem(
                                    icon: Icons.trending_up_rounded,
                                    label: "Progression",
                                    value: "$progressPercent%",
                                    accent: const Color(0xFF60A5FA),
                                  ),
                                  _StatItem(
                                    icon: Icons.flag_rounded,
                                    label: "Prochain niveau",
                                    value: "+$_xpToNextLevel XP",
                                    accent: const Color(0xFFB794F4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _LocalSectionTitle(
                                "INFORMATIONS PERSONNELLES",
                              ),
                              const SizedBox(height: 16),

                              _ModernInputField(
                                controller: _firstNameCtrl,
                                enabled: _isEditing,
                                label: "Prénom",
                                hint: "Ex: Enzo",
                                icon: Icons.person_outline_rounded,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Le prénom est requis";
                                  }
                                  if (v.trim().length < 2) {
                                    return "Prénom trop court";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _ModernInputField(
                                controller: _lastNameCtrl,
                                enabled: _isEditing,
                                label: "Nom",
                                hint: "Ex: Dheilly",
                                icon: Icons.badge_outlined,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Le nom est requis";
                                  }
                                  if (v.trim().length < 2) {
                                    return "Nom trop court";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _ModernInputField(
                                controller: _phoneCtrl,
                                enabled: _isEditing,
                                label: "Téléphone",
                                hint: "Ex: 06 12 34 56 78",
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return null;
                                  if (v.trim().length < 6)
                                    return "Numéro invalide";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _ReadonlyField(
                                label: "Email",
                                value: email,
                                icon: Icons.alternate_email_rounded,
                                helper:
                                    "L’adresse email ne peut pas être modifiée ici.",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        AnimatedOpacity(
                          opacity: _isEditing ? 1.0 : 0.8,
                          duration: const Duration(milliseconds: 250),
                          child: _GlassCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      colors: [
                                        clubOrange.withOpacity(0.22),
                                        clubOrange.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: clubOrange.withOpacity(0.25),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.tips_and_updates_rounded,
                                    color: clubOrange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isEditing
                                            ? "Mode édition activé"
                                            : "Conseil",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isEditing
                                            ? "Tu peux modifier tes informations et ta photo. Les changements ne seront appliqués qu’après validation."
                                            : "Passe en mode édition pour mettre à jour ton profil. L’avatar accepte une image locale puis upload côté API.",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.72),
                                          height: 1.35,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        isEditing: _isEditing,
        isSaving: _isSaving,
        hasChanges: _hasChanges,
        onCancel: _cancelEditing,
        onMainPressed: _isSaving
            ? null
            : (_isEditing ? _saveProfile : _startEditing),
      ),
    );
  }
}

/* =========================
   BACKGROUND DECOR
   ========================= */

class _ProfileBackgroundDecor extends StatelessWidget {
  const _ProfileBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.25,
              colors: [Color(0xFF14141C), Color(0xFF0B0B0F)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _BlurCircle(size: 220, color: clubOrange.withOpacity(0.18)),
        ),
        Positioned(
          top: 180,
          left: -80,
          child: _BlurCircle(
            size: 190,
            color: const Color(0xFF3B82F6).withOpacity(0.10),
          ),
        ),
        Positioned(
          bottom: 90,
          right: -50,
          child: _BlurCircle(
            size: 170,
            color: const Color(0xFFA855F7).withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

/* =========================
   HERO PROFIL
   ========================= */

class _ProfileEditableHero extends StatelessWidget {
  final bool isEditing;
  final bool isSaving;
  final bool hasChanges;
  final String fullName;
  final String email;
  final ImageProvider? avatarProvider;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onPickImage;

  final int currentLevel;
  final int totalXp;
  final double levelProgress;
  final int xpToNextLevel;

  const _ProfileEditableHero({
    required this.isEditing,
    required this.isSaving,
    required this.hasChanges,
    required this.fullName,
    required this.email,
    required this.avatarProvider,
    required this.onBack,
    required this.onEdit,
    required this.onCancel,
    required this.onPickImage,
    required this.currentLevel,
    required this.totalXp,
    required this.levelProgress,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = levelProgress.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

    return _GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      gradientColors: [
        Colors.white.withOpacity(0.07),
        Colors.white.withOpacity(0.02),
      ],
      child: Column(
        children: [
          Row(
            children: [
              _GhostIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isEditing
                    ? _PillButton(
                        key: const ValueKey('cancel'),
                        text: "Annuler",
                        icon: Icons.close_rounded,
                        onTap: isSaving ? () {} : onCancel,
                        danger: true,
                      )
                    : _PillButton(
                        key: const ValueKey('edit'),
                        text: "Éditer",
                        icon: Icons.edit_rounded,
                        onTap: onEdit,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxWidth < 360;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: _AvatarLevelWidget(
                        isEditing: isEditing,
                        avatarProvider: avatarProvider,
                        levelProgress: progress,
                        currentLevel: currentLevel,
                        onPickImage: onPickImage,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _HeroTextBlock(
                      fullName: fullName,
                      email: email,
                      progress: progress,
                      progressPercent: progressPercent,
                      totalXp: totalXp,
                      xpToNextLevel: xpToNextLevel,
                      isEditing: isEditing,
                      hasChanges: hasChanges,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarLevelWidget(
                    isEditing: isEditing,
                    avatarProvider: avatarProvider,
                    levelProgress: progress,
                    currentLevel: currentLevel,
                    onPickImage: onPickImage,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _HeroTextBlock(
                      fullName: fullName,
                      email: email,
                      progress: progress,
                      progressPercent: progressPercent,
                      totalXp: totalXp,
                      xpToNextLevel: xpToNextLevel,
                      isEditing: isEditing,
                      hasChanges: hasChanges,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AvatarLevelWidget extends StatelessWidget {
  final bool isEditing;
  final ImageProvider? avatarProvider;
  final double levelProgress;
  final int currentLevel;
  final VoidCallback onPickImage;

  const _AvatarLevelWidget({
    required this.isEditing,
    required this.avatarProvider,
    required this.levelProgress,
    required this.currentLevel,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: levelProgress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: clubOrange,
                  );
                },
              ),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF121217),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
                image: avatarProvider != null
                    ? DecorationImage(image: avatarProvider!, fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: avatarProvider == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: Colors.white.withOpacity(0.45),
                    )
                  : null,
            ),
            if (isEditing)
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: clubOrange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF111116),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: clubOrange.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                clubOrange.withOpacity(0.22),
                clubOrange.withOpacity(0.08),
              ],
            ),
            border: Border.all(color: clubOrange.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: clubOrange, size: 14),
              const SizedBox(width: 4),
              Text(
                "NIV $currentLevel",
                style: const TextStyle(
                  color: clubOrange,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  final String fullName;
  final String email;
  final double progress;
  final int progressPercent;
  final int totalXp;
  final int xpToNextLevel;
  final bool isEditing;
  final bool hasChanges;

  const _HeroTextBlock({
    required this.fullName,
    required this.email,
    required this.progress,
    required this.progressPercent,
    required this.totalXp,
    required this.xpToNextLevel,
    required this.isEditing,
    required this.hasChanges,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.4,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _MiniInfoBox(
                icon: Icons.bolt_rounded,
                title: "XP total",
                value: "$totalXp XP",
                accent: const Color(0xFF6EE7B7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniInfoBox(
                icon: Icons.flag_rounded,
                title: "Objectif",
                value: "+$xpToNextLevel XP",
                accent: const Color(0xFF60A5FA),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Text(
              "Progression",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const Spacer(),
            Text(
              "$progressPercent%",
              style: const TextStyle(
                color: clubOrange,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AnimatedLinearXpBar(value: progress),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TinyChip(
              icon: isEditing
                  ? Icons.edit_note_rounded
                  : Icons.verified_rounded,
              label: isEditing ? "Mode édition" : "Compte actif",
              isActive: isEditing,
            ),
            _TinyChip(
              icon: hasChanges
                  ? Icons.pending_actions_rounded
                  : Icons.check_circle_rounded,
              label: hasChanges ? "Modifs en attente" : "Synchronisé",
              isActive: hasChanges,
            ),
            const _TinyChip(
              icon: Icons.local_fire_department_rounded,
              label: "CHM",
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  const _MiniInfoBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
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

class _AnimatedLinearXpBar extends StatelessWidget {
  final double value;

  const _AnimatedLinearXpBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [clubOrange, clubOrange.withOpacity(0.75)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: clubOrange.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* =========================
   STATS GRID
   ========================= */

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 92,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _StatTile(item: item);
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final _StatItem item;

  const _StatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
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

/* =========================
   BOTTOM ACTION BAR
   ========================= */

class _BottomActionBar extends StatelessWidget {
  final bool isEditing;
  final bool isSaving;
  final bool hasChanges;
  final VoidCallback onCancel;
  final VoidCallback? onMainPressed;

  const _BottomActionBar({
    required this.isEditing,
    required this.isSaving,
    required this.hasChanges,
    required this.onCancel,
    required this.onMainPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: darkBackground.withOpacity(0.72),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isEditing
                    ? Container(
                        key: const ValueKey('editing-banner'),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: hasChanges
                              ? clubOrange.withOpacity(0.10)
                              : Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: hasChanges
                                ? clubOrange.withOpacity(0.18)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasChanges
                                  ? Icons.pending_actions_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: hasChanges ? clubOrange : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasChanges
                                    ? "Des modifications sont prêtes à être enregistrées."
                                    : "Aucune modification détectée pour le moment.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-banner')),
              ),
              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.18),
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "ANNULER",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: isEditing ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: onMainPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clubOrange,
                        disabledBackgroundColor: clubOrange.withOpacity(0.45),
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: clubOrange.withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isSaving
                            ? const SizedBox(
                                key: ValueKey("loading"),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                key: ValueKey(isEditing ? "save" : "edit"),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.edit_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isEditing
                                          ? "ENREGISTRER"
                                          : "MODIFIER LE PROFIL",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.9,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
   UI HELPERS
   ========================= */

class _PillButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _PillButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color c = danger ? const Color(0xFFFF4B4B) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GhostIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _TinyChip({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? clubOrange.withOpacity(0.25)
        : Colors.white.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? clubOrange.withOpacity(0.13)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isActive ? clubOrange : Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? clubOrange : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;

  const _GlassCard({
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(20),
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LocalSectionTitle extends StatelessWidget {
  final String text;

  const _LocalSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.52),
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ModernInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  const _ModernInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = enabled
        ? Colors.white.withOpacity(0.045)
        : Colors.white.withOpacity(0.015);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: Colors.white.withOpacity(enabled ? 0.97 : 0.72),
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(enabled ? 0.65 : 0.40),
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.20)),
          prefixIcon: Icon(
            icon,
            color: enabled ? clubOrange : Colors.white.withOpacity(0.18),
            size: 20,
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: clubOrange, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.6)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? helper;

  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: value,
          enabled: false,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.30)),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withOpacity(0.15),
              size: 20,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.03)),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.01),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              helper!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.32),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
