import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Grand titre de page (remplace les en-têtes en italique gras).
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppText.display),
      if (subtitle != null) ...[
        const SizedBox(height: 5),
        Text(subtitle!, style: AppText.subtitle),
      ],
    ],
  );
}

/// En-tête de section : trait d'accent + libellé tracké, remplace les icônes
/// répétées dans des pastilles colorées.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 3, height: 13, color: AppColors.accent),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title.toUpperCase(), style: AppText.eyebrow),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

/// Carte de base : fond surface, bordure fine, rayon homogène.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Ligne "fiche technique" : libellé à gauche, valeur alignée à droite
/// (chiffres tabulaires pour les données numériques, pastille de couleur
/// pour les statuts).
class SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;
  final bool mono;
  final Color? labelColor;
  final Color? valueColor;
  final FontWeight? labelWeight;
  final FontWeight? valueWeight;

  const SpecRow({
    super.key,
    required this.label,
    required this.value,
    this.accentColor,
    this.mono = false,
    this.labelColor,
    this.valueColor,
    this.labelWeight,
    this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppText.label.copyWith(
                color: labelColor,
                fontWeight: labelWeight,
              ),
            ),
          ),
          if (accentColor != null)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            ),
          Text(
            value,
            style: AppText.value.copyWith(
              color: accentColor ?? valueColor ?? AppColors.textPrimary,
              fontWeight: valueWeight,
              letterSpacing: mono ? 0.6 : 0,
              fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Séparateur de ligne pleine largeur, pour les listes dans une [AppCard].
class RowSep extends StatelessWidget {
  const RowSep({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    color: AppColors.line,
    indent: 18,
    endIndent: 18,
  );
}

/// Bouton principal plein, fond accent uni (pas de dégradé, pas de glow).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: disabled ? AppColors.accent.withOpacity(0.35) : AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: AppColors.bg, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(label.toUpperCase(), style: AppText.button),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Bouton secondaire discret : icône + texte, sans fond ni bordure.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const GhostButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Pastille de statut : point coloré + texte, remplace les pills avec fond+bordure.
class StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const StatusDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ],
  );
}

/// Ligne pointillée (motif billet), pour les cartes carte-membre / QR / tickets.
class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, this.color = AppColors.line});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 5.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor().clamp(0, 999);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: gap / 2),
              child: Container(width: dashWidth, height: 1, color: color),
            ),
          ),
        );
      },
    );
  }
}

/// Bande de perforation avec encoches façon billet déchiré. Le parent direct
/// doit avoir `clipBehavior: Clip.antiAlias` et un `BoxDecoration.borderRadius`
/// pour que les encoches "mordent" sur la bordure arrondie de la carte.
class TicketPerforation extends StatelessWidget {
  const TicketPerforation({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DashedLine(),
          ),
          Positioned(
            left: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de document/action téléchargeable : icône plate, titre + sous-titre,
/// chevron. Remplace les icônes en dégradé dans des carrés arrondis.
class DocumentRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const DocumentRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.description_outlined,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: AppText.label.copyWith(fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
      ],
    ),
  );
}
