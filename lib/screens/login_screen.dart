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
  static const Color limeGreen = Color(0xFFF57809); // Le vert de la capture
  static const Color appBgColor = Color(0xFF06060B);

  // Controllers et services
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Controller pour le carrousel d'images
  final PageController _pageController = PageController();

  // États
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showLoginForm = false; // Permet de basculer entre l'accueil et le login
  int _currentPage = 0; // Suit la slide actuelle

  // 📝 Les données de tes 3 slides (Tu devras mettre ces 3 images dans tes assets)
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

  // ... Méthodes de connexion (identiques) ...
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
        // 1. Le PageView pour faire défiler les images et textes
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
                // Image de fond
                Image.asset(slide["image"]!, fit: BoxFit.cover),
                // Dégradé pour rendre le texte lisible
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
                // Textes de la slide
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      180,
                    ), // Espace en bas pour les boutons
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

        // Bouton "Passer" en haut à droite
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () => setState(() => _showLoginForm = true),
              child: Text(
                "Passer",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        // 3. Contrôles statiques en bas (Points + Bouton + Mentions)
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
                  // Indicateur de pagination (les points)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingSlides.length,
                      (index) => _buildDot(isActive: index == _currentPage),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton dynamique (Suivant -> Commencer)
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: limeGreen.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingSlides.length - 1) {
                          // Dernière slide : on affiche le formulaire de login
                          setState(() {
                            _showLoginForm = true;
                          });
                        } else {
                          // Slides précédentes : on passe à l'image suivante
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: limeGreen,
                        foregroundColor: Colors.black,
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

                  // Footer Mentions Légales
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

  // Widget dynamique pour les points
  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? limeGreen : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  // ==========================================
  // 🟠 ÉCRAN 2 : TON FORMULAIRE DE CONNEXION
  // ==========================================
  Widget _buildLoginForm() {
    return SafeArea(
      key: const ValueKey('login_form_view'),
      child: Stack(
        children: [
          // Bouton Retour pour revenir au carrousel
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showLoginForm = false;
                });
              },
            ),
          ),

          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "𝗖𝗛𝗠 𝗦𝗔𝗟𝗘𝗨𝗫",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.2,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2.2
                              ..color = clubOrange.withOpacity(0.38),
                          ),
                        ),
                        Text(
                          "𝗖𝗛𝗠 𝗦𝗔𝗟𝗘𝗨𝗫",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.60),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "HALTÉROPHILIE & MUSCULATION",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 36),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      onSubmitted: (_) => _isLoading ? null : _submit(),
                    ),

                    const SizedBox(height: 6),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          _showSnackBar("Bientôt disponible 🔥", clubOrange);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: clubOrange.withOpacity(0.9),
                        ),
                        child: const Text(
                          "Mot de passe oublié ?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: clubOrange,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: clubOrange.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "OU",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.40),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.12)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        label: const Text(
                          "Continuer avec Google",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withOpacity(
                            0.55,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "© ${DateTime.now().year} CHM Saleux • Tous droits réservés",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.28),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      cursorColor: clubOrange,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: clubOrange.withOpacity(0.95)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.45),
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: clubOrange, width: 1.4),
        ),
      ),
    );
  }
}
