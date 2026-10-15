import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String _fitnessGoal = 'Weight Loss';

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();

  Timer? _lockoutTimer;

  final List<String> _goals = ['Weight Loss', 'Muscle Gain', 'Maintenance'];
  final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _ageFocusNode.dispose();
    _weightFocusNode.dispose();

    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (!auth.isLockedOut) {
          timer.cancel();
        }
      }
    });
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim().toLowerCase());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enter your registered email address to receive password reset instructions.'),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.pop(ctx),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sanitizedEmail =
                  resetEmailController.text.trim().toLowerCase();
              if (sanitizedEmail.isEmpty ||
                  !_emailRegex.hasMatch(sanitizedEmail)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid email address.')),
                );
                return;
              }
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .resetPassword(sanitizedEmail);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Password reset instructions sent to email.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_isSignUp && authProvider.isLockedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Locked out. Retry in ${authProvider.lockoutSecondsRemaining} seconds.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final sanitizedEmail = _emailController.text.trim().toLowerCase();

    try {
      if (_isSignUp) {
        await authProvider.signUp(
          email: sanitizedEmail,
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          weight: double.tryParse(_weightController.text.trim()),
          fitnessGoal: _fitnessGoal,
          context: context,
        );
      } else {
        await authProvider.login(
          sanitizedEmail,
          _passwordController.text.trim(),
          context,
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (!_isSignUp && authProvider.isLockedOut) {
        _startLockoutTimer();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HERO BRAND IDENTITY HEADER ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(0),
                      // decoration: BoxDecoration(
                      //   color: theme.colorScheme.primaryContainer,
                      //   // shape: BoxShape.circle,
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: theme.colorScheme.primary
                      //           .withValues(alpha: 0.15),
                      //       blurRadius: 16,
                      //       offset: const Offset(0, 6),
                      //     ),
                      //   ],
                      // ),
                      child: Image.asset(
                        'assets/icon/fitlife_logo.PNG', // Replace with your actual asset path
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fitness_center_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      //  Icon(
                      //   Icons.fitness_center_rounded,
                      //   size: 48,
                      //   color: theme.colorScheme.primary,
                      // ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fit Life',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Create your account to start tracking progress.'
                        : 'Track workouts, count macros, and reach your goals.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- SIGN UP FIELDS ---
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocusNode),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // --- EMAIL FIELD ---
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocusNode),
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Enter your email address';
                      }

                      final trimmedEmail = val.trim().toLowerCase();
                      if (!_emailRegex.hasMatch(trimmedEmail)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- PASSWORD FIELD ---
                  PasswordTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    label: 'Password',
                    isSignUp: _isSignUp,
                    textInputAction:
                        _isSignUp ? TextInputAction.next : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_isSignUp) {
                        FocusScope.of(context).requestFocus(_ageFocusNode);
                      } else {
                        _submit();
                      }
                    },
                  ),

                  // --- FORGOT PASSWORD LINK & LOCKOUT MSG ---
                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (authProvider.isLockedOut)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Too many failed login attempts.\nTry again in ${authProvider.lockoutSecondsRemaining}s',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],

                  // --- SIGN UP BODY STATS FIELDS ---
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            focusNode: _ageFocusNode,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_weightFocusNode),
                            decoration: InputDecoration(
                              labelText: 'Age',
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 13 || n > 100) {
                                return '13 - 100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            focusNode: _weightFocusNode,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: const Icon(Icons.scale_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n < 30 || n > 300) {
                                return '30 - 300 kg';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _fitnessGoal,
                      decoration: InputDecoration(
                        labelText: 'Fitness Goal',
                        prefixIcon: const Icon(Icons.fitness_center_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _goals
                          .map((goal) => DropdownMenuItem(
                                value: goal,
                                child: Text(goal),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _fitnessGoal = val);
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // --- PRIMARY SUBMIT BUTTON ---
                  authProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: (!_isSignUp && authProvider.isLockedOut)
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 2,
                          ),
                          child: Text(
                            _isSignUp ? 'Create Account' : 'Log In',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),

                  // --- GOOGLE SIGN IN (LOGIN MODE ONLY) ---
                  if (!_isSignUp) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: theme.colorScheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(
                                color: theme.colorScheme.outlineVariant)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                      onPressed:
                          authProvider.isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- MODE TOGGLE BUTTON ---
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _autovalidateMode = AutovalidateMode.disabled;
                      });
                    },
                    child: Text.rich(
                      TextSpan(
                        text: _isSignUp
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                        children: [
                          TextSpan(
                            text: _isSignUp ? 'Log In' : 'Sign Up',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isSignUp;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.isSignUp = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Enter your password';
        }
        if (widget.isSignUp && val.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}
