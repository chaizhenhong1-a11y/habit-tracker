import 'package:flutter/material.dart';

class LifeSurface extends StatelessWidget {
  const LifeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: accent
            ? (dark ? const Color(0xFF1D392B) : const Color(0xFFE7EADB))
            : (dark ? const Color(0xFF171D18) : const Color(0xFFFFFCF6)),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .06)
              : const Color(0xFF234A37).withValues(alpha: .08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173E2D).withValues(alpha: dark ? .12 : .055),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LifePageHeader extends StatelessWidget {
  const LifePageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final green = dark ? const Color(0xFFA9C4A7) : const Color(0xFF194B36);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: green,
                  letterSpacing: 2.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: const ['Times New Roman'],
                  fontSize: 34,
                  height: 1.02,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -.8,
                  color: dark
                      ? const Color(0xFFF1EDE3)
                      : const Color(0xFF163C2C),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 9),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 14), trailing!],
      ],
    );
  }
}

class LifeSectionTitle extends StatelessWidget {
  const LifeSectionTitle({
    super.key,
    required this.title,
    this.caption,
    this.action,
  });
  final String title;
  final String? caption;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.25,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 3),
              Text(
                caption!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      ?action,
    ],
  );
}

class LifeMetricPill extends StatelessWidget {
  const LifeMetricPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: .055)
            : Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: dark ? const Color(0xFFA9C4A7) : const Color(0xFF194B36),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
