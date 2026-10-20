import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_local_store.dart';
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
  final _authStore = AuthLocalStore();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final valid = await _authStore.verifyCredentials(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (valid) {
      widget.onLoginSuccess();
      return;
    }
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(loc.translate('loginError') ?? '用户名或密码错误'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) => const RegisterPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
    if (!mounted || registered != true) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(loc.translate('registerSuccessHint') ?? '注册成功，请登录'),
      behavior: SnackBarBehavior.floating,
    ));
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
      body: AuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, viewport) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight - 48),
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
                            SizedBox(height: viewport.maxHeight < 720 ? 38 : 62),
                            Text(
                              'Small habits,\nbig changes.',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: dark ? const Color(0xFFEDEADF) : const Color(0xFF173B2C),
                                fontSize: 43,
                                height: 1.02,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.7,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Text(
                              'Build a calmer, healthier and happier you.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                height: 1.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 34),
                            PremiumAuthField(
                              controller: _usernameController,
                              hint: loc.translate('usernameHint') ?? 'Username',
                              icon: Icons.person_outline_rounded,
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? (loc.translate('usernameRequired') ?? '请输入用户名')
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            PremiumAuthField(
                              controller: _passwordController,
                              hint: loc.translate('passwordHint') ?? 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                              suffix: IconButton(
                                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return loc.translate('passwordRequired') ?? '请输入密码';
                                if (value.length < 3) return loc.translate('passwordTooShort') ?? '密码至少3位';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(children: [
                              Icon(Icons.shield_outlined, size: 16, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 7),
                              Text('Your progress stays private on this device.', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            ]),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 58,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                style: premiumAuthButtonStyle(context),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _isLoading
                                      ? const SizedBox(key: ValueKey('loading'), width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                      : Row(
                                          key: const ValueKey('login'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(loc.translate('login') ?? 'Sign in', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.arrow_forward_rounded, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('New to Habit?', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                              TextButton(onPressed: _openRegistration, child: Text(loc.translate('noAccount') ?? 'Create one')),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
