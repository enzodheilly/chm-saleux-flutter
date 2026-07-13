import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable "Liquid Glass" (iOS-style glassmorphism) container.
///
/// Wraps [child] with a frosted blur background, a soft luminous border,
/// an elevation shadow, a top sheen (approximating a CSS inset highlight,
/// which Flutter's [BoxShadow] has no native equivalent for) and a tactile
/// press animation (slight scale-down + opacity dip).
class GlassSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color tintColor;
  final double tintOpacity;
  final double borderOpacity;
  final BoxShape shape;

  const GlassSurface({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.all(10),
    this.blurSigma = 20,
    this.tintColor = Colors.white,
    this.tintOpacity = 0.15,
    this.borderOpacity = 0.25,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = widget.shape == BoxShape.circle;
    final radius = isCircle ? null : widget.borderRadius;

    final glass = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.tintColor.withOpacity(widget.tintOpacity),
        shape: widget.shape,
        borderRadius: radius,
        border: Border.all(
          color: widget.tintColor.withOpacity(widget.borderOpacity),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.55],
        ),
      ),
      child: widget.child,
    );

    final blurred = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
      child: glass,
    );

    final clipped = isCircle
        ? ClipOval(child: blurred)
        : ClipRRect(borderRadius: widget.borderRadius, child: blurred);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: clipped,
        ),
      ),
    );
  }
}
