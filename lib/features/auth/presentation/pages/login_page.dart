import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/storage/cloud_sync.dart';
import '../widgets/auth_brand.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});
  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authStore = FirebaseAuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final user = await _authStore.signIn(
        email: _usernameController.text,
        password: _passwordController.text,
      );
      var importGuest = await CloudSync.instance.hasGuestData();
      if (importGuest &&
          await CloudSync.instance.needsGuestConfirmation(user.uid)) {
        if (!mounted) return;
        final l = AppLocalizations.of(context);
        importGuest =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (d) => AlertDialog(
                title: Text(l.text('guestOtherAccountTitle')),
                content: Text(
                  l.text('guestOtherAccountMessage', {
                    'email': user.email ?? '',
                  }),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(d, false),
                    child: Text(l.text('signInOnly')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(d, true),
                    child: Text(l.text('mergeAndSignIn')),
                  ),
                ],
              ),
            ) ??
            false;
      }
      await CloudSync.instance.start(user, importGuest: importGuest);
      if (mounted) widget.onLoginSuccess();
    } catch (error) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final code = error is FirebaseAuthException
          ? error.code
          : 'sync-unavailable';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.text(switch (code) {
              'invalid-email' => 'invalidEmail',
              'network-request-failed' ||
              'sync-unavailable' => 'cloudUnavailable',
              'too-many-requests' => 'authTooManyRequests',
              _ => 'loginError',
            }),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, _) => const RegisterPage(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        ),
      ),
    );
    if (!mounted || registered != true) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('registerSuccessHint') ?? '注册成功，请登录'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: Colors.transparent,
              leading: const BackButton(),
            )
          : null,
      body: AuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewport.maxHeight - 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const HabitBrand(compact: true),
                              SizedBox(
                                height: viewport.maxHeight < 720 ? 38 : 62,
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).text('loginHeadline'),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: dark
                                      ? const Color(0xFFEDEADF)
                                      : const Color(0xFF173B2C),
                                  fontSize: 43,
                                  height: 1.02,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.7,
                                ),
                              ),
                              const SizedBox(height: 13),
                              Text(
                                AppLocalizations.of(context).text('loginIntro'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 34),
                              PremiumAuthField(
                                controller: _usernameController,
                                hint: loc.text('emailHint'),
                                icon: Icons.person_outline_rounded,
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? loc.text('emailRequired')
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              PremiumAuthField(
                                controller: _passwordController,
                                hint:
                                    loc.translate('passwordHint') ?? 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _isLoading ? null : _submit(),
                                suffix: IconButton(
                                  tooltip: _obscurePassword
                                      ? AppLocalizations.of(
                                          context,
                                        ).text('showPassword')
                                      : AppLocalizations.of(
                                          context,
                                        ).text('hidePassword'),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return loc.translate('passwordRequired') ??
                                        '请输入密码';
                                  }
                                  if (value.length < 3) {
                                    return loc.translate('passwordTooShort') ??
                                        '密码至少3位';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).text('localPrivacy'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 58,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: premiumAuthButtonStyle(context),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _isLoading
                                        ? const SizedBox(
                                            key: ValueKey('loading'),
                                            width: 21,
                                            height: 21,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            key: const ValueKey('login'),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                loc.translate('login') ??
                                                    'Sign in',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).text('newUser'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _openRegistration,
                                    child: Text(
                                      loc.translate('noAccount') ??
                                          'Create one',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
