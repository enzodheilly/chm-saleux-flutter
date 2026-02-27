import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

// --- COULEURS STYLE iOS DARK MODE ---
const Color appBackground = Color(0xFF000000);
const Color cardColor = Color(0xFF1C1C1E); // Gris iOS standard
const Color dividerColor = Color(0xFF2C2C2E);
const Color textSecondary = Color(0xFF8E8E93);
const Color clubOrange = Color(0xFFF57809);

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

  bool _notificationsEnabled = true;

  File? _pickedImageFile; // ✅ Avatar uniquement

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
    }
  }

  void _hydrateControllersFromProfile(Map<String, dynamic>? data) {
    final firstName = (data?['firstName'] ?? data?['first_name'] ?? '')
        .toString();
    final lastName = (data?['lastName'] ?? data?['last_name'] ?? '').toString();
    final phone = (data?['phone'] ?? '').toString();

    _initialFirstName = firstName;
    _initialLastName = lastName;
    _initialPhone = phone;

    _firstNameCtrl.text = firstName;
    _lastNameCtrl.text = lastName;
    _phoneCtrl.text = phone;

    _pickedImageFile = null;
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _firstNameCtrl.text = _initialFirstName;
      _lastNameCtrl.text = _initialLastName;
      _phoneCtrl.text = _initialPhone;
      _pickedImageFile = null;
    }
    setState(() {
      _isEditing = !_isEditing;
      _autoValidate = false;
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

  // Pick AVATAR
  Future<void> _pickProfileImage() async {
    if (!_isEditing) return;
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );
      if (file == null) return;
      setState(() {
        _pickedImageFile = File(file.path);
      });
    } catch (e) {
      debugPrint("Erreur sélection image: $e");
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

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

      if (updatedText == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de mettre à jour les informations"),
          ),
        );
        return;
      }

      _profile = {...?_profile, ...updatedText};

      // Upload Avatar
      if (_pickedImageFile != null) {
        final updatedPhoto = await _authService.uploadProfileImage(
          _pickedImageFile!,
        );
        if (updatedPhoto != null) {
          _profile = {...?_profile, ...updatedPhoto};
        }
      }

      _hydrateControllersFromProfile(_profile);

      if (!mounted) return;
      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil mis à jour ✅"),
          backgroundColor: clubOrange,
        ),
      );
    } catch (e) {
      debugPrint("Erreur save profil: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l’enregistrement")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Construit l'image pour l'Avatar
  ImageProvider? _buildAvatarProvider() {
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
      if (raw.startsWith('data:image')) {
        return MemoryImage(base64Decode(raw.split(',').last));
      }
      if (raw.length > 80) return MemoryImage(base64Decode(raw));
    } catch (e) {
      debugPrint("Erreur decode avatar: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final email = (_profile?['email'] ?? 'Non renseigné').toString();

    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: appBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          "Mon Profil",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isLoading)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.only(right: 20.0),
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
                : TextButton(
                    onPressed: _isEditing ? _saveProfile : _toggleEditMode,
                    child: Text(
                      _isEditing ? "Terminer" : "Modifier",
                      style: TextStyle(
                        color: _isEditing ? clubOrange : Colors.white,
                        fontSize: 16,
                        fontWeight: _isEditing
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
        ],
      ),
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
                  // ===================
                  // HEADER : AVATAR + NOM
                  // ===================
                  _buildProfileHeader(),

                  const SizedBox(height: 20),

                  // ===================
                  // SECTION : MON COMPTE
                  // ===================
                  _buildSectionTitle("MON COMPTE"),
                  _buildCardGroup(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.person_outline,
                        label: "Prénom",
                        controller: _firstNameCtrl,
                        isEditing: _isEditing,
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: Icons.badge_outlined,
                        label: "Nom",
                        controller: _lastNameCtrl,
                        isEditing: _isEditing,
                      ),
                      _buildDivider(),
                      _buildSettingsRow(
                        icon: Icons.phone_outlined,
                        label: "Téléphone",
                        controller: _phoneCtrl,
                        isEditing: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildDivider(),
                      _buildReadonlyRow(
                        icon: Icons.alternate_email,
                        label: "Email",
                        value: email,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===================
                  // SECTION : PRÉFÉRENCES
                  // ===================
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

                  // ===================
                  // SECTION : INFORMATION
                  // ===================
                  _buildSectionTitle("INFORMATION"),
                  _buildCardGroup(
                    children: [
                      _buildReadonlyRow(
                        icon: Icons.phone_iphone,
                        label: "Version de l'app",
                        value: "Version 4.1.3",
                      ),
                      _buildDivider(),
                      _buildReadonlyRow(
                        icon: Icons.verified_user_outlined,
                        label: "Politique de confidentialité",
                        value: "",
                      ),
                      _buildDivider(),
                      _buildReadonlyRow(
                        icon: Icons.info_outline,
                        label: "Contactez-nous",
                        value: "",
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    const double avatarSize = 96.0;

    final fullName = [
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardColor,
                  border: Border.all(color: appBackground, width: 3.5),
                  image: _buildAvatarProvider() != null
                      ? DecorationImage(
                          image: _buildAvatarProvider()!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _buildAvatarProvider() == null
                    ? const Icon(Icons.person, size: 44, color: textSecondary)
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        shape: BoxShape.circle,
                        border: Border.all(color: appBackground, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
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
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // --- WIDGETS FACTORY UTILS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, right: 20),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: dividerColor,
      indent: 48,
      endIndent: 0,
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isEditing
                ? TextFormField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: keyboardType,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
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
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: clubOrange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
