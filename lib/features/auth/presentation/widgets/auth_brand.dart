import 'package:flutter/material.dart';

class HabitBrand extends StatelessWidget {
  const HabitBrand({super.key, this.compact = false, this.centered = true});

  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.brightness == Brightness.dark
        ? const Color(0xFFE9E7DE)
        : const Color(0xFF173B2C);
    final children = <Widget>[
      _HabitMark(size: compact ? 44 : 62),
      SizedBox(height: compact ? 9 : 12),
      Text(
        'H A B I T',
        style: theme.textTheme.titleMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: compact ? 4 : 5.5,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        'A  B E T T E R  Y O U  ·  E V E R Y  D A Y',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground.withValues(alpha: .52),
          fontSize: 8,
          letterSpacing: 1.55,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _HabitMark extends StatelessWidget {
  const _HabitMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HabitMarkPainter()),
    );
  }
}

class _HabitMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stem = Paint()
      ..color = const Color(0xFF345D49)
      ..strokeWidth = w * .055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .50, h * .82), Offset(w * .50, h * .37), stem);

    final left = Path()
      ..moveTo(w * .47, h * .70)
      ..cubicTo(w * .15, h * .65, w * .13, h * .29, w * .19, h * .20)
      ..cubicTo(w * .44, h * .27, w * .52, h * .49, w * .47, h * .70)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFF6F8D68));

    final right = Path()
      ..moveTo(w * .53, h * .70)
      ..cubicTo(w * .85, h * .65, w * .87, h * .34, w * .82, h * .27)
      ..cubicTo(w * .60, h * .30, w * .49, h * .50, w * .53, h * .70)
      ..close();
    canvas.drawPath(right, Paint()..color = const Color(0xFF315943));

    canvas.drawCircle(
      Offset(w * .67, h * .16),
      w * .105,
      Paint()..color = const Color(0xFFD9B477),
    );

    final vein = Paint()
      ..color = const Color(0xFFF4F0E4).withValues(alpha: .48)
      ..strokeWidth = w * .018
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .23, h * .28), Offset(w * .45, h * .63), vein);
    canvas.drawLine(Offset(w * .78, h * .35), Offset(w * .55, h * .63), vein);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF0C1511), Color(0xFF172019), Color(0xFF11130F)]
                    : const [Color(0xFFFFFCF5), Color(0xFFF2EBDD), Color(0xFFE9EFE5)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -80,
          child: _SoftOrb(
            size: 300,
            color: const Color(0xFFD8B77A).withValues(alpha: dark ? .08 : .16),
          ),
        ),
        Positioned(
          bottom: -130,
          left: -110,
          child: _SoftOrb(
            size: 340,
            color: const Color(0xFF739073).withValues(alpha: dark ? .10 : .16),
          ),
        ),
        Positioned(top: 80, right: -20, child: _BotanicalBranch(dark: dark)),
        child,
      ],
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 25)],
        ),
      );
}

class _BotanicalBranch extends StatelessWidget {
  const _BotanicalBranch({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dark ? .18 : .25,
        child: SizedBox(
          width: 120,
          height: 190,
          child: CustomPaint(painter: _BranchPainter()),
        ),
      );
}

class _BranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stem = Paint()
      ..color = const Color(0xFF315943)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .94, 0)
      ..cubicTo(size.width * .72, size.height * .25, size.width * .58, size.height * .55, size.width * .18, size.height);
    canvas.drawPath(path, stem);
    final leaf = Paint()..color = const Color(0xFF6F8D68);
    for (final spec in const [
      [88.0, 34.0, -0.7],
      [69.0, 70.0, 0.45],
      [55.0, 105.0, -0.65],
      [37.0, 139.0, 0.45],
    ]) {
      canvas.save();
      canvas.translate(spec[0], spec[1]);
      canvas.rotate(spec[2]);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(28, -18, 42, 2)
        ..quadraticBezierTo(20, 20, 0, 0)
        ..close();
      canvas.drawPath(p, leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PremiumAuthField extends StatelessWidget {
  const PremiumAuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: dark ? const Color(0xFF202A24).withValues(alpha: .88) : Colors.white.withValues(alpha: .70),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: const BorderSide(color: Color(0xFF456A55), width: 1.4),
        ),
      ),
    );
  }
}

ButtonStyle premiumAuthButtonStyle(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    backgroundColor: dark ? const Color(0xFF42614F) : const Color(0xFF234A38),
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFF234A38).withValues(alpha: .45),
    elevation: 8,
    shadowColor: const Color(0xFF234A38).withValues(alpha: .22),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}
