import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

// =========================
// COULEURS GLOBALES
// (pointent vers le système de design partagé — valeurs centralisées,
// noms locaux conservés pour ne pas toucher aux usages dans tout le fichier)
// =========================
const Color clubOrange = AppColors.accent;
const Color appBgColor = AppColors.bg;
const Color _cardBg = AppColors.surface;
const Color _borderColor = AppColors.line;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // =========================
  // CONTROLLERS & SERVICES
  // =========================
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();

  // ✅ Animation d'entrée du formulaire
  late final AnimationController _formAnimController;
  late final Animation<double> _formFadeAnim;
  late final Animation<Offset> _formSlideAnim;

  // =========================
  // ÉTATS
  // =========================
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showLoginForm = false;
  int _currentPage = 0;
  bool _rememberMe = false;

  // =========================
  // DONNÉES ONBOARDING
  // =========================
  final List<Map<String, String>> _onboardingSlides = [
    {
      "image": "assets/images/onboarding1.jpg",
      "title": "Bouge Ton Corps\npour Être en Forme",
      "description":
          "L'application t'aide à te dépasser et à adopter un mode de vie sain grâce à l'entraînement.",
    },
    {
      "image": "assets/images/onboarding2.jpg",
      "title": "Dépasse Tes Limites\nChaque Jour",
      "description":
          "Accède à des programmes personnalisés en haltérophilie et musculation pour exploser tes perfs.",
    },
    {
      "image": "assets/images/onboarding3.jpg",
      "title": "Rejoins La\nCommunauté CHM",
      "description":
          "Suis ta progression, reste motivé(e) et atteins enfin tes objectifs avec nous.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _formFadeAnim = CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOutCubic,
    );
    _formSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _formAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _maybeAutoFillDevCredentials();
  }

  // ✅ DEBUG ONLY : pré-remplit et soumet le login avec les identifiants
  // passés via `flutter run --dart-define-from-file=dev.json` (fichier
  // gitignoré, jamais commité). N'a aucun effet en release.
  void _maybeAutoFillDevCredentials() {
    if (!kDebugMode) return;
    const devEmail = String.fromEnvironment('DEV_EMAIL');
    const devPassword = String.fromEnvironment('DEV_PASSWORD');
    if (devEmail.isEmpty || devPassword.isEmpty) return;

    _emailController.text = devEmail;
    _passwordController.text = devPassword;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _goToLoginForm();
      _submit();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    _formAnimController.dispose();
    super.dispose();
  }

  // =========================
  // NAVIGATION
  // =========================

  void _goToLoginForm() {
    setState(() => _showLoginForm = true);
    _formAnimController.forward(from: 0);
  }

  void _goToOnboarding() {
    setState(() {
      _showLoginForm = false;
      _isPasswordVisible = false;
    });
    _formAnimController.reset();
  }

  // =========================
  // ACTIONS
  // =========================

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs', AppColors.warning);
      return;
    }
    setState(() => _isLoading = true);
    // ✅ _rememberMe transmis au service
    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      _showSnackBar('Bienvenue au Club ! 🎉', AppColors.success);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Email ou mot de passe incorrect', AppColors.danger);
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final success = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      _showSnackBar('Connexion Google réussie !', AppColors.success);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Échec de la connexion Google', AppColors.danger);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  // =========================
  // BUILD PRINCIPAL
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      resizeToAvoidBottomInset: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showLoginForm ? _buildLoginForm() : _buildOnboarding(),
      ),
    );
  }

  // =========================
  // ÉCRAN 1 : ONBOARDING
  // =========================

  Widget _buildOnboarding() {
    return Stack(
      key: const ValueKey('onboarding_view'),
      children: [
        // Carrousel d'images
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: _onboardingSlides.length,
          itemBuilder: (context, index) {
            final slide = _onboardingSlides[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(slide["image"]!, fit: BoxFit.cover),
                // Dégradé principal
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.92),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.72, 1.0],
                    ),
                  ),
                ),
                // Texte de la slide
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 176),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numéro de slide
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 3, height: 11, color: clubOrange),
                            const SizedBox(width: 9),
                            Text(
                              "${index + 1} / ${_onboardingSlides.length}",
                              style: const TextStyle(
                                color: clubOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide["title"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide["description"]!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Bouton "Passer"
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 16.0),
              child: TextButton(
                onPressed: _goToLoginForm,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
                child: Text(
                  "Passer",
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bas de l'écran : dots + CTA + legal
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicateurs de slide
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingSlides.length,
                      (i) => _buildDot(isActive: i == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bouton CTA principal
                  _OrangeButton(
                    label: _currentPage == _onboardingSlides.length - 1
                        ? 'Commencer'
                        : 'Suivant',
                    isLoading: false,
                    onPressed: () {
                      if (_currentPage == _onboardingSlides.length - 1) {
                        _goToLoginForm();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 22),

                  // Texte légal
                  Text.rich(
                    TextSpan(
                      text: "En continuant, tu acceptes nos ",
                      children: [
                        TextSpan(
                          text: "Conditions d'utilisation",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: " et la "),
                        TextSpan(
                          text: "Politique de confidentialité",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? clubOrange : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }

  // =========================
  // ÉCRAN 2 : FORMULAIRE
  // =========================

  Widget _buildLoginForm() {
    return FadeTransition(
      key: const ValueKey('login_form_view'),
      opacity: _formFadeAnim,
      child: SlideTransition(
        position: _formSlideAnim,
        child: Stack(
          children: [
            // Fond : motif grille subtil
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // Contenu scrollable
            SafeArea(
              child: Column(
                children: [
                  // AppBar custom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _BackButton(onTap: _goToOnboarding),
                        const Spacer(),
                        // Repère "CHM SALEUX"
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 3, height: 11, color: clubOrange),
                            const SizedBox(width: 9),
                            const Text(
                              "CHM SALEUX",
                              style: TextStyle(
                                color: clubOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 36),

                            // Logo + titre hero
                            Center(
                              child: Column(
                                children: [
                                  // Logo
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _cardBg,
                                      border: Border.all(
                                        color: _borderColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Hero(
                                          tag: 'app_logo',
                                          child: Image.asset(
                                            'assets/images/logo.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Bon retour,",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const Text(
                                    "Champion.",
                                    style: TextStyle(
                                      color: clubOrange,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Connecte-toi pour reprendre là où tu t'es arrêté.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ─── Carte formulaire ───
                            AppCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(label: "Adresse email"),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'exemple@email.com',
                                    icon: Icons.mail_outline_rounded,
                                    type: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 18),
                                  _FieldLabel(label: "Mot de passe"),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    onSubmitted: (_) =>
                                        _isLoading ? null : _submit(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Options : remember me + mot de passe oublié
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _rememberMe
                                              ? clubOrange.withOpacity(0.15)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: _rememberMe
                                                ? clubOrange
                                                : AppColors.textSecondary
                                                      .withOpacity(0.5),
                                            width: 1.8,
                                          ),
                                        ),
                                        child: _rememberMe
                                            ? const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: clubOrange,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Se souvenir de moi",
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showSnackBar(
                                    "Bientôt disponible 🔥",
                                    AppColors.info,
                                  ),
                                  child: const Text(
                                    "Mot de passe oublié ?",
                                    style: TextStyle(
                                      color: clubOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Bouton SE CONNECTER
                            _OrangeButton(
                              label: "SE CONNECTER",
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _submit,
                            ),

                            const SizedBox(height: 28),

                            // Séparateur
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: _borderColor,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    "ou continuer avec",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: _borderColor,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Boutons sociaux
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    // ✅ FIX — FaIcon Google au lieu de Image.network
                                    iconWidget: const FaIcon(
                                      FontAwesomeIcons.google,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                    label: "Google",
                                    onPressed: _isLoading
                                        ? null
                                        : _loginWithGoogle,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SocialButton(
                                    iconWidget: const FaIcon(
                                      FontAwesomeIcons.apple,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: "Apple",
                                    onPressed: _isLoading
                                        ? null
                                        : () => _showSnackBar(
                                            "Apple Login — Bientôt 🍎",
                                            AppColors.info,
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 36),

                            // ✅ FIX — "S'inscrire" avec TapGestureRecognizer
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: "Pas encore de compte ? ",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "S'inscrire",
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => _showSnackBar(
                                          "Inscription — Bientôt 🚀",
                                          AppColors.info,
                                        ),
                                      style: const TextStyle(
                                        color: clubOrange,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                        decorationColor: clubOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // CHAMP DE TEXTE
  // =========================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: type,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      cursorColor: clubOrange,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: clubOrange, width: 1.4),
        ),
      ),
    );
  }
}

// =========================
// WIDGETS RÉUTILISABLES
// =========================

/// Bouton orange principal
class _OrangeButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _OrangeButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: clubOrange,
          disabledBackgroundColor: clubOrange.withOpacity(0.35),
          foregroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.bg,
                ),
              )
            : Text(label.toUpperCase(), style: AppText.button),
      ),
    );
  }
}

/// Bouton social (Google / Apple)
class _SocialButton extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.iconWidget,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _cardBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label au-dessus d'un champ
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
}

/// Bouton retour circulaire
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: clubOrange.withOpacity(0.1),
        border: Border.all(color: clubOrange.withOpacity(0.2)),
      ),
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: clubOrange,
        size: 16,
      ),
    ),
  );
}

// =========================
// MOTIF GRILLE EN FOND
// =========================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5;

    const double spacing = 40;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Points aux intersections
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
