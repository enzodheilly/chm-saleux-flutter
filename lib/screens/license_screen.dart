import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/license_service.dart';
import '../services/qr_code_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

// =========================
// ENUM & MODÈLE
// =========================

enum LicenseViewState { loading, input, loaded }

class LicenseDetails {
  final String licenseNumber;
  final String firstName;
  final String lastName;
  final String licenseType;
  final String paymentStatus;
  final String memberStatus;
  final double paymentAmount;
  final DateTime expiryDate;

  const LicenseDetails({
    required this.licenseNumber,
    required this.firstName,
    required this.lastName,
    required this.licenseType,
    required this.paymentStatus,
    required this.memberStatus,
    required this.paymentAmount,
    required this.expiryDate,
  });

  factory LicenseDetails.fromJson(Map<String, dynamic> j) {
    // ✅ FIX — fallback sur DateTime passée (pas aujourd'hui) pour éviter
    // qu'une licence mal parsée apparaisse comme "valide"
    final expiry =
        DateTime.tryParse((j['expiryDate'] ?? '').toString()) ??
        DateTime(2000, 1, 1);

    return LicenseDetails(
      licenseNumber: (j['licenseNumber'] ?? '').toString(),
      firstName: (j['firstName'] ?? '').toString(),
      lastName: (j['lastName'] ?? '').toString(),
      licenseType: (j['licenseType'] ?? '').toString(),
      paymentStatus: (j['paymentStatus'] ?? '').toString(),
      memberStatus: (j['memberStatus'] ?? '').toString(),
      paymentAmount: j['paymentAmount'] is num
          ? (j['paymentAmount'] as num).toDouble()
          : double.tryParse((j['paymentAmount'] ?? '0').toString()) ?? 0.0,
      expiryDate: expiry,
    );
  }
}

// =========================
// SCREEN
// =========================

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final LicenseService _service = LicenseService();
  final QrCodeService _qrService = QrCodeService();
  final TextEditingController _ctrl = TextEditingController();

  LicenseViewState _state = LicenseViewState.loading;
  LicenseDetails? _license;
  bool _saving = false;

  bool _qrLoading = true;
  String? _qrToken;

  @override
  void initState() {
    super.initState();
    _load();
    _loadQrCode();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _service.dispose();
    _qrService.dispose();
    super.dispose();
  }

  // =========================
  // ACTIONS
  // =========================

  Future<void> _load() async {
    setState(() {
      _state = LicenseViewState.loading;
      _license = null;
    });
    final r = await _service.getMyLicense();
    if (!mounted) return;
    setState(() {
      if (r != null) {
        _license = LicenseDetails.fromJson(r);
        _state = LicenseViewState.loaded;
      } else {
        _state = LicenseViewState.input;
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final n = _ctrl.text.trim();
    if (n.isEmpty) {
      _snack('Veuillez saisir votre numéro de licence.');
      return;
    }
    setState(() => _saving = true);
    final result = await _service.linkLicense(n);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success || result.license == null) {
      _snack(
        result.message ??
            "Numéro introuvable. Vérifiez l'e-mail de confirmation FFHM.",
      );
      return;
    }

    setState(() {
      _license = LicenseDetails.fromJson(result.license!);
      _state = LicenseViewState.loaded;
    });
    _loadQrCode();
  }

  // =========================
  // QR CODE D'ACCÈS
  // =========================

  Future<void> _loadQrCode() async {
    final token = await _qrService.getMyQrCode();
    if (!mounted) return;
    setState(() {
      _qrToken = token;
      _qrLoading = false;
    });
    if (token == null) {
      _snack("Impossible de récupérer votre QR code.");
    }
  }

  void _openFullscreenQr() {
    if (_qrToken == null) return;
    final memberName = _license != null
        ? '${_license!.firstName} ${_license!.lastName}'.trim()
        : null;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(
              opacity: animation,
              child: _FullscreenQrView(
                token: _qrToken!,
                memberName: memberName,
              ),
            ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
      );
  }

  // =========================
  // HELPERS
  // =========================

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ✅ Vérifie si la licence n'est pas expirée
  bool _isExpired(DateTime expiry) => expiry.isBefore(DateTime.now());

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: switch (_state) {
            LicenseViewState.loading => _buildLoading(),
            LicenseViewState.input => _buildInput(),
            LicenseViewState.loaded => _buildLoaded(),
          },
        ),
      ),
    );
  }

  // =========================
  // VUE : CHARGEMENT
  // =========================

  Widget _buildLoading() => const Center(
    key: ValueKey('lic_loading'),
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
    ),
  );

  // =========================
  // VUE : SAISIE NUMÉRO
  // =========================

  Widget _buildInput() {
    return ListView(
      key: const ValueKey('lic_input'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        28,
        20,
        140 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        const PageHeader(
          title: 'Ma licence',
          subtitle: 'Rattachez votre licence FFHM',
        ),
        const SizedBox(height: 24),

        _buildQrSection(),
        const SizedBox(height: 28),

        // Info : où trouver son numéro
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Où trouver mon numéro ?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Il figure dans l'e-mail de confirmation envoyé par la FFHM après validation par votre club.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        const SectionHeader(title: 'Numéro de licence'),
        const SizedBox(height: 14),

        // Champ de saisie
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.line),
          ),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 1,
            ),
            onSubmitted: (_) => _saving ? null : _save(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ex : 484045',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: InputBorder.none,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.tag_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        PrimaryButton(
          label: 'Valider ma licence',
          loading: _saving,
          onPressed: _save,
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textSecondary.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              'Données utilisées à des fins fédérales uniquement',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  // =========================
  // VUE : LICENCE CHARGÉE
  // =========================

  Widget _buildLoaded() {
    final l = _license!;

    return ListView(
      key: const ValueKey('lic_loaded'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        28,
        20,
        140 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildQrSection(showActiveBadge: !_isExpired(l.expiryDate)),
        const SizedBox(height: 6),

        Text(
          "Scannez ce QR code à votre arrivée\nà la salle et à votre sortie.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        Container(
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              SpecRow(
                label: 'Type de licence',
                value: l.licenseType,
                labelColor: AppColors.bg,
                labelWeight: FontWeight.w800,
                valueColor: Colors.white,
                valueWeight: FontWeight.w800,
              ),
              const RowSep(),
              SpecRow(
                label: 'Numéro',
                value: l.licenseNumber,
                mono: true,
                labelColor: AppColors.bg,
                labelWeight: FontWeight.w800,
                valueColor: Colors.white,
                valueWeight: FontWeight.w800,
              ),
              const RowSep(),
              SpecRow(
                label: 'Expiration',
                value: _fmt(l.expiryDate),
                accentColor: _isExpired(l.expiryDate) ? AppColors.danger : null,
                mono: true,
                labelColor: AppColors.bg,
                labelWeight: FontWeight.w800,
                valueColor: Colors.white,
                valueWeight: FontWeight.w800,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ─ Aide ──────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              _HelpRow(
                icon: Icons.help_outline_rounded,
                label: 'Comment ça fonctionne ?',
                onTap: _showHowItWorks,
              ),
              _HelpRow(
                icon: Icons.support_agent_rounded,
                label: "Besoin d'aide ?",
                onTap: _showHelp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHowItWorks() {
    _showInfoSheet(
      icon: Icons.qr_code_2_rounded,
      title: 'Comment ça fonctionne ?',
      body:
          "Présentez votre QR code à l'accueil pour enregistrer votre entrée. "
          "Scannez-le à nouveau en repartant pour enregistrer votre sortie. "
          "Le code se régénère automatiquement toutes les 24h, vous n'avez rien à faire.",
    );
  }

  void _showHelp() {
    _showInfoSheet(
      icon: Icons.support_agent_rounded,
      title: "Besoin d'aide ?",
      body:
          "Pour toute question sur votre licence ou votre accès à la salle, "
          "adressez-vous directement à l'accueil du club.",
    );
  }

  void _showInfoSheet({required IconData icon, required String title, required String body}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.9),
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// QR fictif flouté affiché tant qu'aucune licence n'est associée au compte :
  /// donne un aperçu de ce à quoi ressemblera le vrai QR, sans être scannable.
  Widget _buildFakeBlurredQr() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
          child: IgnorePointer(
            child: QrImageView(
              data: 'CHM-SALEUX-APERCU',
              version: QrVersions.auto,
              size: 260,
              gapless: true,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(color: Colors.black26),
              dataModuleStyle: const QrDataModuleStyle(color: Colors.black26),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // =========================
  // WIDGET : QR CODE D'ACCÈS (carte façon billet)
  // =========================

  Widget _buildQrSection({bool showActiveBadge = false}) {
    final ready = !_qrLoading && _qrToken != null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: ready ? _openFullscreenQr : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: _qrLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent,
                                ),
                              )
                            : _qrToken != null
                            ? QrImageView(
                                data: _qrToken!,
                                version: QrVersions.auto,
                                size: 260,
                                gapless: true,
                                backgroundColor: Colors.white,
                              )
                            : _buildFakeBlurredQr(),
                      ),
                    ),
                  ),
                ),
                if (ready) ...[
                  if (showActiveBadge) ...[
                    const SizedBox(height: 26),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            "Activé",
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (!_qrLoading) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 11, color: AppColors.textSecondary.withOpacity(0.7)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Associez votre licence ci-dessous pour débloquer votre QR code",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation d'un scan détecté pendant l'affichage plein écran du QR.
class _ScanConfirmation {
  final String? type;
  final String? firstName;
  const _ScanConfirmation({this.type, this.firstName});
}

/// Affichage plein écran du QR code d'accès (présenté à l'accueil de la salle).
/// Sonde discrètement en arrière-plan pendant l'affichage : dès qu'un scan est
/// détecté à l'accueil, le QR est remplacé par une confirmation visuelle.
class _FullscreenQrView extends StatefulWidget {
  final String token;
  final String? memberName;

  const _FullscreenQrView({required this.token, this.memberName});

  @override
  State<_FullscreenQrView> createState() => _FullscreenQrViewState();
}

class _FullscreenQrViewState extends State<_FullscreenQrView> {
  final QrCodeService _qrService = QrCodeService();
  Timer? _pollTimer;
  Timer? _autoCloseTimer;

  String? _baselineScannedAt;
  _ScanConfirmation? _confirmation;

  @override
  void initState() {
    super.initState();
    _initBaseline();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _autoCloseTimer?.cancel();
    _qrService.dispose();
    super.dispose();
  }

  Future<void> _initBaseline() async {
    final status = await _qrService.getScanStatus();
    if (!mounted) return;
    _baselineScannedAt = status?.scannedAt;
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 2500),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    if (_confirmation != null) return;
    final status = await _qrService.getScanStatus();
    if (!mounted || status?.scannedAt == null) return;

    if (status!.scannedAt != _baselineScannedAt) {
      _pollTimer?.cancel();
      setState(() {
        _confirmation = _ScanConfirmation(
          type: status.type,
          firstName: status.firstName ?? widget.memberName,
        );
      });
      _autoCloseTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _confirmation != null
                      ? _buildConfirmation(_confirmation!)
                      : _buildQr(),
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQr() {
    return Column(
      key: const ValueKey('qr'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 3, height: 11, color: AppColors.accent),
            const SizedBox(width: 9),
            const Text(
              "CHM SALEUX",
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: QrImageView(
            data: widget.token,
            version: QrVersions.auto,
            gapless: true,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 120,
          child: DashedLine(color: Colors.white.withOpacity(0.15)),
        ),
        const SizedBox(height: 24),
        if (widget.memberName != null && widget.memberName!.isNotEmpty)
          Text(
            widget.memberName!.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            "Présentez ce code à l'accueil pour enregistrer votre entrée ou votre sortie.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation(_ScanConfirmation confirmation) {
    final isIn = confirmation.type != 'OUT';
    final name = confirmation.firstName;

    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withOpacity(0.4)),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 48,
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            isIn
                ? (name != null && name.isNotEmpty
                      ? "Bon entraînement, $name !"
                      : "Bon entraînement !")
                : (name != null && name.isNotEmpty
                      ? "À bientôt, $name !"
                      : "À bientôt !"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isIn ? "Entrée enregistrée" : "Sortie enregistrée",
          style: TextStyle(
            color: AppColors.success.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// =========================
// WIDGET : LIGNE D'AIDE
// =========================

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HelpRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
