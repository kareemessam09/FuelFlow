import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../blocs/auth/auth.dart';
import '../../widgets/common/common.dart';

/// Login screen with vibrant theme
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  final AuthRepository _authRepository = AuthRepositoryImpl();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLogin(email: _emailCtrl.text.trim(), password: _passwordCtrl.text),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first')),
      );
      return;
    }
    try {
      await _authRepository.forgotPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If this email exists, a reset token has been sent. Enter it below to continue.',
          ),
        ),
      );
      final tokenCtrl = TextEditingController();
      final newPasswordCtrl = TextEditingController();
      final confirmPasswordCtrl = TextEditingController();
      final shouldReset = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set a new password for $email',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenCtrl,
                decoration: const InputDecoration(labelText: 'Reset token'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (shouldReset != true) return;

      final newPassword = newPasswordCtrl.text.trim();
      final confirmPassword = confirmPasswordCtrl.text.trim();
      final token = tokenCtrl.text.trim();
      if (token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset token is required')),
        );
        return;
      }
      if (newPassword.length < 8) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 8 characters'),
          ),
        );
        return;
      }
      if (newPassword != confirmPassword) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      await _authRepository.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. You can now sign in.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reset password: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go('/');
          }
        },
        builder: (context, state) {
          return FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Logo
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/fuelflow_icon.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'WELCOME BACK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sign in to sync your energy data',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Error banner
                      if (state.status == AuthStatus.error &&
                          state.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextActionButton(
                          label: 'Forgot Password?',
                          onPressed: _forgotPassword,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 32),

                      BrutalButton(
                        label: 'Sign In',
                        height: 60,
                        icon: Icons.login_rounded,
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-In Button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: state.status == AuthStatus.loading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                      const AuthGoogleSignIn(),
                                    );
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (state.status == AuthStatus.loading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.primary,
                                        ),
                                      ),
                                    )
                                  else
                                    Image.asset(
                                      'assets/icons/google_icon.png',
                                      width: 24,
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.account_circle),
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextActionButton(
                              label: 'Sign Up',
                              onPressed: () => context.go('/register'),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Register screen with vibrant theme
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegister(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go('/');
          }
        },
        builder: (context, state) {
          return FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Logo
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/fuelflow_icon.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.accentGradient.createShader(bounds),
                        child: const Text(
                          'CREATE ACCOUNT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Track your energy, optimize your life',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Error banner
                      if (state.status == AuthStatus.error &&
                          state.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Your name',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'Min 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      BrutalButton(
                        label: 'Create Account',
                        height: 60,
                        icon: Icons.person_add_rounded,
                        isPrimary: false,
                        isLoading: state.status == AuthStatus.loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-In Button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: state.status == AuthStatus.loading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                      const AuthGoogleSignIn(),
                                    );
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (state.status == AuthStatus.loading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.primary,
                                        ),
                                      ),
                                    )
                                  else
                                    Image.asset(
                                      'assets/icons/google_icon.png',
                                      width: 24,
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.account_circle),
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign up with Google',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextActionButton(
                              label: 'Sign In',
                              onPressed: () => context.go('/login'),
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
