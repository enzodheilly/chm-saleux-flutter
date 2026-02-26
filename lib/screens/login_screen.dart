import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Couleurs du design
  static const Color clubOrange = Color(0xFFF57809);
  static const Color appBgColor = Color(0xFF06060B);

  // Fond très transparent pour les champs (style CashPay)
  static final Color inputBgColor = Colors.white.withOpacity(0.03);

  // Controllers et services
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Controller pour le carrousel d'images
  final PageController _pageController = PageController();

  // États
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showLoginForm = false;
  int _currentPage = 0;
  bool _rememberMe = false;

  // 📝 Les données de tes 3 slides
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Bienvenue au Club ! 🎉', Colors.green);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Email ou mot de passe incorrect', Colors.redAccent);
    }
  }

  void _loginWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final success = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Connexion Google réussie !', Colors.green);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Échec de la connexion Google', Colors.redAccent);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showLoginForm ? _buildLoginForm() : _buildOnboarding(),
      ),
    );
  }

  // ==========================================
  // 🟢 ÉCRAN 1 : ONBOARDING AVEC SLIDER
  // ==========================================
  Widget _buildOnboarding() {
    return Stack(
      key: const ValueKey('onboarding_view'),
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _onboardingSlides.length,
          itemBuilder: (context, index) {
            final slide = _onboardingSlides[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(slide["image"]!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.95),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          slide["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide["description"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
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

        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, top: 12.0),
              child: TextButton(
                onPressed: () => setState(() => _showLoginForm = true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.black.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "Passer",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingSlides.length,
                      (index) => _buildDot(isActive: index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: clubOrange.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingSlides.length - 1) {
                          setState(() {
                            _showLoginForm = true;
                          });
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clubOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _onboardingSlides.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      text: "En t'inscrivant, tu acceptes nos\n",
                      children: [
                        TextSpan(
                          text: "Conditions d'utilisation",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: " et notre "),
                        TextSpan(
                          text: "Politique de confidentialité",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? clubOrange : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  // ==========================================
  // 🟠 ÉCRAN 2 : FORMULAIRE DE CONNEXION (Style CashPay Amélioré)
  // ==========================================
  Widget _buildLoginForm() {
    return Stack(
      key: const ValueKey('login_form_view'),
      children: [
        // ✅ 1. EFFET DE LUEUR ORANGE EN HAUT (Glow style CashPay)
        Positioned(
          top: -200,
          left: MediaQuery.of(context).size.width / 2 - 250,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  clubOrange.withOpacity(0.20), // Centre lumineux
                  Colors.transparent, // Fondu vers le noir
                ],
                stops: const [0.1, 0.7],
              ),
            ),
          ),
        ),

        // 2. Contenu principal
        SafeArea(
          child: Stack(
            children: [
              // Bouton Retour
              Positioned(
                top: 16,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showLoginForm = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: clubOrange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: clubOrange,
                      size: 22,
                    ),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),

                        // Logo & Titre
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "CHM SALEUX",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Titres de connexion
                        const Center(
                          child: Text(
                            "Connectez-vous à votre compte",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "Bon retour ! Sélectionnez une méthode de connexion",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Champs de texte avec le nouveau style transparent / moins arrondi
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Votre Email',
                          icon: Icons.mail_outline_rounded,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Votre Mot de passe',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          onSubmitted: (_) => _isLoading ? null : _submit(),
                        ),

                        const SizedBox(height: 16),

                        // Ligne "Se souvenir de moi" / "Mot de passe oublié"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _rememberMe
                                            ? clubOrange
                                            : Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: _rememberMe
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: clubOrange,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Se souvenir de moi",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _showSnackBar(
                                  "Bientôt disponible 🔥",
                                  clubOrange,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                        const SizedBox(height: 32),

                        // Grand bouton de connexion
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: clubOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'SE CONNECTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Séparateur
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "Ou continuer avec",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Boutons sociaux
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                // ✅ 2. VRAI LOGO GOOGLE (Multicouleur via réseau pour marcher immédiatement)
                                // Si tu veux utiliser une image locale plus tard : Image.asset('assets/images/google.png', width: 18)
                                iconWidget: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                                  width: 18,
                                  height: 18,
                                ),
                                label: "Google",
                                onPressed: _isLoading ? null : _loginWithGoogle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSocialButton(
                                iconWidget: const FaIcon(
                                  FontAwesomeIcons.apple,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: "Apple",
                                onPressed: () {
                                  _showSnackBar(
                                    "Apple Login - Bientôt",
                                    clubOrange,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Lien d'inscription
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: "Pas encore de compte ? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "S'inscrire",
                                  style: const TextStyle(
                                    color: clubOrange,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ 3. CHAMPS PLUS TRANSPARENTS ET MOINS ARRONDIS
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
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      cursorColor: clubOrange,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(icon, color: Colors.white.withOpacity(0.5), size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.remove_red_eye_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: inputBgColor, // Plus transparent
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ), // Moins arrondi (12 au lieu de 20)
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ), // Bordure super discrète
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: clubOrange, width: 1.2),
        ),
      ),
    );
  }

  // Boutons sociaux mis à jour pour matcher avec les champs de texte
  Widget _buildSocialButton({
    required Widget iconWidget,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: inputBgColor, // Même fond transparent que les inputs
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Même arrondi de 12
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
    );
  }
}
