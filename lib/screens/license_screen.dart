import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/license_service.dart';

const Color clubOrange = Color(0xFFF57809);
const Color darkBg = Color(0xFF000000);
const Color purpleButton = Color(0xFF5E35B1);

const Color cardColor = Color(0xFF1C1C1E);
const Color dividerColor = Color(0xFF2C2C2E);

const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFF8E8E93);
const Color textMuted = Color(0xFF6F7684);

const Color successColor = Color(0xFF22C55E);
const Color warningColor = Color(0xFFF59E0B);
const Color dangerColor = Color(0xFFEF4444);

// ✅ Logo à mettre dans assets/images/
const String licenseLogoAsset = 'assets/images/logo.png';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final LicenseService _service = LicenseService();
  final TextEditingController _licenseCtrl = TextEditingController();

  LicenseViewState _state = LicenseViewState.loading;
  LicenseDetails? _license;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrapLicenseScreen();
  }

  @override
  void dispose() {
    _licenseCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _bootstrapLicenseScreen() async {
    setState(() {
      _state = LicenseViewState.loading;
      _error = null;
      _license = null;
    });

    final result = await _service.getMyLicense();

    if (!mounted) return;

    if (result != null) {
      final license = LicenseDetails.fromJson(result);

      setState(() {
        _license = license;
        _licenseCtrl.text = license.licenseNumber;
        _state = LicenseViewState.loaded;
        _error = null;
      });

      return;
    }

    setState(() {
      _state = LicenseViewState.lookup;
      _license = null;
      _error = null;
    });
  }

  Future<void> _searchLicense() async {
    FocusScope.of(context).unfocus();

    final number = _licenseCtrl.text.trim();

    if (number.isEmpty) {
      _showSnack("Entre ton numéro de licence.");
      return;
    }

    setState(() {
      _state = LicenseViewState.loading;
      _error = null;
      _license = null;
    });

    final result = await _service.getLicenseByNumber(number);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _state = LicenseViewState.error;
        _error = "Aucune licence trouvée avec ce numéro.";
      });
      return;
    }

    setState(() {
      _license = LicenseDetails.fromJson(result);
      _licenseCtrl.text = number;
      _state = LicenseViewState.loaded;
    });
  }

  Future<void> _openRecoveryFlow() async {
    final selectedLicense = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LicenseRecoveryScreen()),
    );

    if (!mounted || selectedLicense == null) return;

    final licenseNumber = (selectedLicense['licenseNumber'] ?? '').toString();

    if (licenseNumber.isEmpty) {
      _showSnack("Numéro de licence introuvable.");
      return;
    }

    setState(() {
      _license = LicenseDetails.fromJson(selectedLicense);
      _licenseCtrl.text = licenseNumber;
      _error = null;
      _state = LicenseViewState.loaded;
    });

    _showSnack("Licence associée avec succès.");
  }

  void _reset() {
    FocusScope.of(context).unfocus();

    setState(() {
      _state = LicenseViewState.lookup;
      _license = null;
      _error = null;
      _licenseCtrl.clear();
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16161D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d/$m/$y";
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains("pay") || s.contains("act")) return successColor;
    if (s.contains("attente")) return warningColor;
    if (s.contains("expir") || s.contains("non")) return dangerColor;
    return textSecondary;
  }

  String _seasonFromExpiry(DateTime expiryDate) {
    final endYear = expiryDate.year;
    final startYear = endYear - 1;
    return "$startYear / $endYear";
  }

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
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildLicenseRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
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
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? textSecondary,
                fontSize: 16,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainHeader({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Bouclier remplacé par logo asset
  Widget _buildOfficialCard(LicenseDetails l) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          licenseLogoAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_outlined,
                              color: clubOrange,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "FFHM",
                      style: TextStyle(
                        color: Color(0xFFB8BBC2),
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  "NOM DE L'ADHÉRENT",
                  style: TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${l.firstName} ${l.lastName}".toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OfficialInfoBlock(
                        label: "CLUB",
                        value: "CHM SALEUX",
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: _OfficialInfoBlock(
                        label: "SAISON",
                        value: _seasonFromExpiry(l.expiryDate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OfficialInfoBlock(
                        label: "TYPE",
                        value: l.licenseType,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: _OfficialInfoBlock(
                        label: "N° AFFILIATION",
                        value: l.licenseNumber.isEmpty
                            ? "----"
                            : l.licenseNumber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF08090C),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Justificatif",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Document officiel lié à votre licence.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkBg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_state) {
            LicenseViewState.lookup => _buildLookup(),
            LicenseViewState.loading => _buildLoading(),
            LicenseViewState.error => _buildError(),
            LicenseViewState.loaded => _buildDetails(),
          },
        ),
      ),
    );
  }

  Widget _buildLookup() {
    return ListView(
      key: const ValueKey('license_lookup'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 20,
        bottom: 140 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildMainHeader(
          title: "Licence",
          subtitle:
              "Consulte ta licence ou retrouve ton numéro à partir de tes informations personnelles.",
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("CONSULTATION"),
        _buildCardGroup(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: const Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: clubOrange,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Recherche par numéro",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  _DarkInputField(
                    controller: _licenseCtrl,
                    hintText: "Ex : LIC-2026-00421",
                    icon: Icons.search_rounded,
                    onSubmitted: (_) => _searchLicense(),
                  ),
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: "Consulter la licence",
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _searchLicense,
                    backgroundColor: purpleButton,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("RÉCUPÉRATION"),
        _buildCardGroup(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: clubOrange, size: 22),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "Retrouver mon numéro",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openRecoveryFlow,
                    icon: const Icon(
                      Icons.chevron_right,
                      color: textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView(
      key: const ValueKey('license_loading'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 20,
        bottom: 140 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildMainHeader(
          title: "Licence",
          subtitle: "Vérification de la licence associée à votre compte.",
        ),
        const SizedBox(height: 24),
        _buildCardGroup(
          children: const [
            SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: clubOrange,
                ),
              ),
            ),
            SizedBox(height: 18),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Chargement de la licence...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Text(
                "Cette opération peut prendre quelques instants.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      key: const ValueKey('license_error'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 20,
        bottom: 140 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildMainHeader(
          title: "Licence introuvable",
          subtitle:
              "La recherche n’a pas permis d’identifier une licence correspondant au numéro saisi.",
        ),
        const SizedBox(height: 24),
        _buildCardGroup(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dangerColor.withOpacity(0.20)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: dangerColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Aucune licence trouvée",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                _error ?? "Une erreur est survenue.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _PrimaryButton(
                label: "Rechercher à nouveau",
                icon: Icons.refresh_rounded,
                onPressed: _reset,
                backgroundColor: purpleButton,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: _SecondaryButton(
                label: "Retrouver mon numéro",
                icon: Icons.mail_outline_rounded,
                onPressed: _openRecoveryFlow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ Section INFORMATIONS supprimée (doublon avec la carte du haut)
  Widget _buildDetails() {
    final l = _license!;

    return ListView(
      key: const ValueKey('license_loaded'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 14,
        bottom: 140 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Votre Licence Officielle",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildOfficialCard(l),
        const SizedBox(height: 24),
        _buildSectionTitle("STATUT"),
        _buildCardGroup(
          children: [
            _buildLicenseRow(
              icon: Icons.payments_outlined,
              label: "Paiement",
              value: l.paymentStatus,
              valueColor: _statusColor(l.paymentStatus),
            ),
            _buildDivider(),
            _buildLicenseRow(
              icon: Icons.verified_outlined,
              label: "Adhésion",
              value: l.memberStatus,
              valueColor: _statusColor(l.memberStatus),
            ),
            _buildDivider(),
            _buildLicenseRow(
              icon: Icons.euro_rounded,
              label: "Montant",
              value: "${l.paymentAmount.toStringAsFixed(2)} €",
            ),
            _buildDivider(),
            _buildLicenseRow(
              icon: Icons.event_outlined,
              label: "Expiration",
              value: _formatDate(l.expiryDate),
            ),
          ],
        ),
      ],
    );
  }
}

class LicenseRecoveryScreen extends StatefulWidget {
  const LicenseRecoveryScreen({super.key});

  @override
  State<LicenseRecoveryScreen> createState() => _LicenseRecoveryScreenState();
}

class _LicenseRecoveryScreenState extends State<LicenseRecoveryScreen> {
  final LicenseService _service = LicenseService();

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _infoMessage;
  bool _isError = false;
  String _loadingLabel = "Recherche en cours...";

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _requestRecovery() async {
    FocusScope.of(context).unfocus();

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      setState(() {
        _infoMessage = "Veuillez renseigner le prénom, le nom et l’email.";
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
      _infoMessage = null;
      _loadingLabel = "Recherche d’une licence...";
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final response = await _service.requestLicenseRecovery(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );

    if (!mounted) return;

    final success = response['success'] == true;
    final message = (response['message'] ?? '').toString();
    final token = response['token']?.toString();

    if (!success || token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _infoMessage = message.isNotEmpty
            ? message
            : "Aucune licence trouvée avec ces informations.";
      });
      return;
    }

    setState(() {
      _loadingLabel = "Licence trouvée, envoi du code...";
      _isError = false;
      _infoMessage = "Une licence a bien été trouvée avec ces informations.";
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final selectedLicense = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LicenseVerificationScreen(token: token, email: email),
      ),
    );

    if (!mounted) return;

    if (selectedLicense != null) {
      Navigator.pop(context, selectedLicense);
    }
  }

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: const _ProAppBar(title: "Retrouver ma licence"),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: 18,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Retrouver ma licence",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Renseigne tes informations pour recevoir un code de vérification par email.",
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("IDENTITÉ"),
          _buildCardGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    _DarkInputField(
                      controller: _firstNameCtrl,
                      hintText: "Prénom",
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    _DarkInputField(
                      controller: _lastNameCtrl,
                      hintText: "Nom",
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    _DarkInputField(
                      controller: _emailCtrl,
                      hintText: "Email",
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: _isLoading ? _loadingLabel : "Envoyer le code",
                      icon: Icons.mark_email_read_outlined,
                      onPressed: _isLoading ? null : _requestRecovery,
                      backgroundColor: purpleButton,
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _loadingLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                    if (_infoMessage != null) ...[
                      const SizedBox(height: 14),
                      _MessageBox(text: _infoMessage!, isError: _isError),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LicenseVerificationScreen extends StatefulWidget {
  final String token;
  final String email;

  const LicenseVerificationScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<LicenseVerificationScreen> createState() =>
      _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final LicenseService _service = LicenseService();
  final TextEditingController _codeCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  List<Map<String, dynamic>> _licenses = [];
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  String? _associatingLicenseNumber;
  String? _associatedLicenseNumber;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    final code = _codeCtrl.text.trim();

    if (code.isEmpty) {
      setState(() {
        _feedbackMessage = "Entre le code reçu par email.";
        _feedbackIsError = true;
      });
      return;
    }

    if (code.length < 6) {
      setState(() {
        _feedbackMessage = "Le code doit contenir 6 chiffres.";
        _feedbackIsError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    final licenses = await _service.verifyLicenseRecovery(
      token: widget.token,
      code: code,
    );

    if (!mounted) return;

    if (licenses.isEmpty) {
      setState(() {
        _licenses = [];
        _isLoading = false;
        _isVerified = false;
        _feedbackMessage = "Code invalide ou expiré.";
        _feedbackIsError = true;
      });
      return;
    }

    setState(() {
      _licenses = licenses;
      _isLoading = false;
      _isVerified = true;
      _feedbackMessage = "Code validé. Sélectionne maintenant ta licence.";
      _feedbackIsError = false;
    });
  }

  Future<void> _associateLicense(Map<String, dynamic> license) async {
    final licenseNumber = (license['licenseNumber'] ?? '').toString();

    if (licenseNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Numéro de licence introuvable."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16161D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    setState(() {
      _associatingLicenseNumber = licenseNumber;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    final response = await _service.associateRecoveredLicense(
      token: widget.token,
      licenseNumber: licenseNumber,
    );

    if (!mounted) return;

    final success = response['success'] == true;

    if (!success) {
      setState(() {
        _associatingLicenseNumber = null;
        _feedbackMessage =
            (response['message'] ?? "Impossible d’associer cette licence.")
                .toString();
        _feedbackIsError = true;
      });
      return;
    }

    final rawLicense = response['license'];
    Map<String, dynamic> licenseData = Map<String, dynamic>.from(license);

    if (rawLicense is Map<String, dynamic>) {
      licenseData = rawLicense;
    } else if (rawLicense is Map) {
      licenseData = Map<String, dynamic>.from(rawLicense);
    }

    setState(() {
      _associatingLicenseNumber = null;
      _associatedLicenseNumber = licenseNumber;
      _feedbackMessage = "Licence $licenseNumber associée avec succès.";
      _feedbackIsError = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("Licence $licenseNumber associée ✅"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16161D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    Navigator.pop(context, licenseData);
  }

  String _formatRawDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d/$m/$y";
  }

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> map) {
    final licenseNumber = (map['licenseNumber'] ?? '').toString();
    final isAssociating = _associatingLicenseNumber == licenseNumber;
    final isAssociated = _associatedLicenseNumber == licenseNumber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${map['firstName'] ?? ''} ${map['lastName'] ?? ''}".trim(),
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${map['licenseType'] ?? ''}",
              style: const TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "N° $licenseNumber",
              style: const TextStyle(
                color: clubOrange,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if ((map['expiryDate'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Expire le ${_formatRawDate((map['expiryDate'] ?? '').toString())}",
                style: const TextStyle(color: textSecondary, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            _PrimaryButton(
              label: isAssociated
                  ? "Licence associée"
                  : "Associer cette licence",
              icon: isAssociated ? Icons.check_rounded : Icons.link_rounded,
              onPressed: (isAssociating || isAssociated)
                  ? null
                  : () => _associateLicense(map),
              backgroundColor: purpleButton,
              child: isAssociating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts.first;
    final domain = parts.last;
    if (name.length <= 2) return "${name[0]}***@$domain";
    return "${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: const _ProAppBar(title: "Vérification"),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: 18,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Validation du code",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Un code temporaire a été envoyé sur ${_maskEmail(widget.email)}.",
              style: const TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("CODE"),
          _buildCardGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _codeCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        hintText: "000000",
                        counterText: "",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.18),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10,
                        ),
                        filled: true,
                        fillColor: darkBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(
                            color: purpleButton,
                            width: 1.2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _verifyCode(),
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: "Vérifier le code",
                      icon: Icons.verified_rounded,
                      onPressed: _isLoading ? null : _verifyCode,
                      backgroundColor: purpleButton,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                    ),
                    if (_feedbackMessage != null) ...[
                      const SizedBox(height: 14),
                      _MessageBox(
                        text: _feedbackMessage!,
                        isError: _feedbackIsError,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_isVerified) ...[
            const SizedBox(height: 24),
            _buildSectionTitle("LICENCES TROUVÉES"),
            ..._licenses.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildResultCard(e),
              );
            }),
          ],
        ],
      ),
    );
  }
}

enum LicenseViewState { lookup, loading, loaded, error }

class LicenseDetails {
  final String licenseNumber;
  final String firstName;
  final String lastName;
  final String licenseType;
  final String paymentStatus;
  final double paymentAmount;
  final DateTime expiryDate;
  final String memberStatus;

  LicenseDetails({
    required this.licenseNumber,
    required this.firstName,
    required this.lastName,
    required this.licenseType,
    required this.paymentStatus,
    required this.paymentAmount,
    required this.expiryDate,
    required this.memberStatus,
  });

  factory LicenseDetails.fromJson(Map<String, dynamic> json) {
    return LicenseDetails(
      licenseNumber: (json['licenseNumber'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      licenseType: (json['licenseType'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      paymentAmount: (json['paymentAmount'] is num)
          ? (json['paymentAmount'] as num).toDouble()
          : double.tryParse((json['paymentAmount'] ?? '0').toString()) ?? 0,
      expiryDate:
          DateTime.tryParse((json['expiryDate'] ?? '').toString()) ??
          DateTime.now(),
      memberStatus: (json['memberStatus'] ?? '').toString(),
    );
  }
}

class _ProAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _ProAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _OfficialInfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _OfficialInfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9A9A9A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _DarkInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  const _DarkInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: textMuted),
        filled: true,
        fillColor: darkBg,
        prefixIcon: Icon(icon, color: textSecondary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: purpleButton, width: 1.2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Widget? child;
  final Color backgroundColor;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.child,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild =
        child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.check_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.45),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: buttonChild,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.10)),
        backgroundColor: Colors.white.withOpacity(0.02),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: clubOrange, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final bool isError;

  const _MessageBox({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? dangerColor : successColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
