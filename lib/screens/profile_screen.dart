import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

// =========================
// PALETTE
// =========================
// Alias locaux vers le système de design partagé (AppColors) — conservés
// pour ne pas avoir à renommer tous les usages dans ce fichier.
const Color appBackground = AppColors.bg;
const Color cardColor = AppColors.surface;
const Color dividerColor = AppColors.line;
const Color textSecondary = AppColors.textSecondary;
const Color clubOrange = AppColors.accent;

class ProfileScreen extends StatefulWidget {
  /// true lorsque l'écran est affiché comme onglet de la bottom nav (pas de
  /// bouton retour, car il n'y a pas de route à dépiler dans ce cas).
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

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
  bool _notificationsEnabled = true;

  File? _pickedImageFile;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;

  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialPhone = '';

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

  // =========================
  // CHARGEMENT PROFIL
  // =========================

  Future<void> _loadProfile() async {
    try {
      final data = await _authService.getUserProfile();
      if (!mounted) return;
      _profile = data;
      _hydrateControllers(data);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _hydrateControllers(Map<String, dynamic>? data) {
    final fn = (data?['firstName'] ?? data?['first_name'] ?? '').toString();
    final ln = (data?['lastName'] ?? data?['last_name'] ?? '').toString();
    final ph = (data?['phone'] ?? '').toString();

    _initialFirstName = fn;
    _initialLastName = ln;
    _initialPhone = ph;

    _firstNameCtrl.text = fn;
    _lastNameCtrl.text = ln;
    _phoneCtrl.text = ph;
    _pickedImageFile = null;
  }

  // =========================
  // MODES ÉDITION
  // =========================

  void _enterEditMode() => setState(() {
    _isEditing = true;
    _autoValidate = false;
  });

  /// Annule les modifications et quitte le mode édition
  void _cancelEdit() {
    _firstNameCtrl.text = _initialFirstName;
    _lastNameCtrl.text = _initialLastName;
    _phoneCtrl.text = _initialPhone;
    _pickedImageFile = null;
    setState(() {
      _isEditing = false;
      _autoValidate = false;
    });
  }

  bool get _hasChanges =>
      _firstNameCtrl.text.trim() != _initialFirstName.trim() ||
      _lastNameCtrl.text.trim() != _initialLastName.trim() ||
      _phoneCtrl.text.trim() != _initialPhone.trim() ||
      _pickedImageFile != null;

  // =========================
  // AVATAR
  // =========================

  Future<void> _pickProfileImage() async {
    if (!_isEditing) return;
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );
      if (file == null) return;
      setState(() => _pickedImageFile = File(file.path));
    } catch (e) {
      debugPrint("Erreur sélection image: $e");
    }
  }

  // ✅ FIX — Provider calculé une seule fois par appel, pas appelé en double
  ImageProvider? _avatarProvider() {
    if (_pickedImageFile != null) return FileImage(_pickedImageFile!);
    final raw =
        (_profile?['profileImageUrl'] ??
                _profile?['profile_image_url'] ??
                _profile?['avatar'] ??
                '')
            .toString()
            .trim();
    if (raw.isEmpty) return null;
    try {
      if (raw.startsWith('http')) return NetworkImage(raw);
      if (raw.startsWith('data:image'))
        return MemoryImage(base64Decode(raw.split(',').last));
      if (raw.length > 80) return MemoryImage(base64Decode(raw));
    } catch (e) {
      debugPrint("Erreur decode avatar: $e");
    }
    return null;
  }

  // =========================
  // SAUVEGARDE
  // =========================

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _autoValidate = true);
    // ✅ FIX — validate() ne lancera pas d'exception si le state existe
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_hasChanges) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedText = await _authService.updateUserProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (!mounted) return;

      if (updatedText == null) {
        _showSnack("Impossible de mettre à jour les informations");
        return;
      }

      _profile = {...?_profile, ...updatedText};

      if (_pickedImageFile != null) {
        final updatedPhoto = await _authService.uploadProfileImage(
          _pickedImageFile!,
        );
        if (updatedPhoto != null) _profile = {...?_profile, ...updatedPhoto};
      }

      _hydrateControllers(_profile);
      if (!mounted) return;
      setState(() => _isEditing = false);
      _showSnack("Profil mis à jour ✅", color: clubOrange);
    } catch (e) {
      debugPrint("Erreur save profil: $e");
      if (mounted) _showSnack("Erreur lors de l'enregistrement");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color != null ? AppColors.bg : AppColors.textPrimary,
          ),
        ),
        backgroundColor: color ?? AppColors.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: color == null ? const BorderSide(color: AppColors.line) : BorderSide.none,
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    // ✅ FIX — PopScope intercepte le retour arrière en mode édition
    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_hasChanges) {
          _showDiscardDialog();
        } else {
          _cancelEdit();
        }
      },
      child: Scaffold(
        backgroundColor: appBackground,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: clubOrange))
            : Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 60),
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildSectionTitle("MON COMPTE"),
                    _buildCardGroup(
                      children: [
                        _buildEditableRow(
                          icon: Icons.person_outline,
                          label: "Prénom",
                          controller: _firstNameCtrl,
                          // ✅ FIX — Validator ajouté (était absent)
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? "Requis" : null,
                        ),
                        _buildDivider(),
                        _buildEditableRow(
                          icon: Icons.badge_outlined,
                          label: "Nom",
                          controller: _lastNameCtrl,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? "Requis" : null,
                        ),
                        _buildDivider(),
                        _buildEditableRow(
                          icon: Icons.phone_outlined,
                          label: "Téléphone",
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildDivider(),
                        _buildReadonlyRow(
                          icon: Icons.alternate_email,
                          label: "Email",
                          value: (_profile?['email'] ?? 'Non renseigné')
                              .toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("PRÉFÉRENCES"),
                    _buildCardGroup(
                      children: [
                        _buildSwitchRow(
                          icon: Icons.notifications_none,
                          label: "Notifications",
                          value: _notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _notificationsEnabled = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("INFORMATION"),
                    _buildCardGroup(
                      children: [
                        _buildReadonlyRow(
                          icon: Icons.phone_iphone,
                          label: "Version de l'app",
                          value: "4.1.3",
                        ),
                        _buildDivider(),
                        _buildReadonlyRow(
                          icon: Icons.verified_user_outlined,
                          label: "Confidentialité",
                          value: "",
                        ),
                        _buildDivider(),
                        _buildReadonlyRow(
                          icon: Icons.mail_outline_rounded,
                          label: "Nous contacter",
                          value: "",
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // ✅ Bouton déconnexion
                    _buildCardGroup(
                      borderColor: AppColors.danger.withOpacity(0.3),
                      children: [
                        _buildDestructiveRow(
                          icon: Icons.logout_rounded,
                          label: "Se déconnecter",
                          onTap: _confirmLogout,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // =========================
  // APPBAR
  // =========================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: appBackground,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: !widget.embedded || _isEditing,
      // ✅ FIX — Bouton retour consciemment géré (pas de sortie silencieuse en edit)
      leading: _isEditing
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
              onPressed: () => _hasChanges ? _showDiscardDialog() : _cancelEdit(),
            )
          : widget.embedded
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
              onPressed: () => Navigator.pop(context, true),
            ),
      title: const Text(
        "Mon Profil",
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        if (!_isLoading)
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: clubOrange,
                      ),
                    ),
                  ),
                )
              : _isEditing
              // ✅ En mode édition : deux boutons Annuler + Terminer
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _cancelEdit,
                      child: const Text(
                        "Annuler",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: _saveProfile,
                      child: const Text(
                        "Terminer",
                        style: TextStyle(
                          color: clubOrange,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              : TextButton(
                  onPressed: _enterEditMode,
                  child: const Text(
                    "Modifier",
                    style: TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
      ],
    );
  }

  // =========================
  // DIALOGUE DISCARD
  // =========================

  void _showDiscardDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Annuler les modifications ?",
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          "Vos modifications non enregistrées seront perdues.",
          style: TextStyle(color: textSecondary.withOpacity(0.9), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Continuer l'édition"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    ).then((discard) {
      if (discard == true && mounted) {
        _cancelEdit();
        Navigator.pop(context, true);
      }
    });
  }

  // =========================
  // DIALOGUE DÉCONNEXION
  // =========================

  void _confirmLogout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Se déconnecter ?",
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Déconnecter",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    });
  }

  // =========================
  // HEADER AVATAR
  // =========================

  Widget _buildProfileHeader() {
    const double size = 96.0;

    // ✅ FIX — provider calculé une seule fois, pas appelé en double
    final provider = _avatarProvider();

    final fullName = [
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Anneau orange en mode édition
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size + (_isEditing ? 6 : 0),
                height: size + (_isEditing ? 6 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _isEditing
                      ? Border.all(color: clubOrange, width: 2)
                      : null,
                ),
                child: Container(
                  margin: EdgeInsets.all(_isEditing ? 2 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                    image: provider != null
                        ? DecorationImage(image: provider, fit: BoxFit.cover)
                        : null,
                  ),
                  child: provider == null
                      ? const Icon(Icons.person, size: 44, color: textSecondary)
                      : null,
                ),
              ),
              // Bouton caméra (mode édition)
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: clubOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: appBackground, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 15,
                        color: AppColors.bg,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (fullName.isNotEmpty && !_isEditing) ...[
            const SizedBox(height: 12),
            Text(
              fullName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              (_profile?['email'] ?? '').toString(),
              style: const TextStyle(color: textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          if (_isEditing) ...[
            const SizedBox(height: 10),
            Text(
              "Appuyer pour changer la photo",
              style: TextStyle(
                color: clubOrange.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================
  // WIDGETS FACTORY
  // =========================

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 2),
    child: SectionHeader(title: title),
  );

  Widget _buildCardGroup({
    required List<Widget> children,
    Color borderColor = AppColors.line,
  }) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: borderColor),
    ),
    child: Column(children: children),
  );

  Widget _buildDivider() =>
      const Divider(height: 1, thickness: 1, color: dividerColor, indent: 48);

  Widget _buildEditableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isEditing
                  ? TextFormField(
                      controller: controller,
                      textAlign: TextAlign.right,
                      keyboardType: keyboardType,
                      validator: validator,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: "Saisir...",
                        hintStyle: TextStyle(color: textSecondary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            controller.text.isEmpty
                                ? "Non renseigné"
                                : controller.text,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadonlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (value.isNotEmpty)
                      Expanded(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            CupertinoSwitch(
              value: value,
              activeTrackColor: clubOrange,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestructiveRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.danger, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
