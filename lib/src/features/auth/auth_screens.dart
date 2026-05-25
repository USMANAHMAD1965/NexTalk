part of '../../../main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/app_logo.png',
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'NexTalk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with friends instantly',
                style: TextStyle(color: tint(Colors.white, 0.74), fontSize: 13),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tint(Colors.white, 0.95),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final ChatRepository repository;
  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'programmer@gmail.com');
  final _passwordController = TextEditingController(text: 'password');
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      showAppSnack(context, 'Please enter your email and password.');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await widget.repository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      widget.onAuthenticated(user);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPhoneAuth() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhoneAuthScreen(
          repository: widget.repository,
          onAuthenticated: widget.onAuthenticated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome Back!',
      subtitle: 'Sign in to continue chatting with your friends',
      headerIcon: Icons.chat_bubble_rounded,
      child: Column(
        children: [
          AppTextField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Sign In',
            loading: _loading,
            onPressed: _signIn,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ForgotPasswordScreen(repository: widget.repository),
                ),
              );
            },
            child: const Text('Forgot Password?'),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Continue with Phone',
            icon: Icons.phone_iphone_rounded,
            onPressed: _openPhoneAuth,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account?",
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CreateAccountScreen(
                        repository: widget.repository,
                        onAuthenticated: widget.onAuthenticated,
                      ),
                    ),
                  );
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final ChatRepository repository;
  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      showAppSnack(context, 'Please complete all fields.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      showAppSnack(context, 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.repository.createAccount(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verify your email'),
          content: Text(
            'We sent a verification link to ${_emailController.text.trim()}. '
            'Open that link, then come back and sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create Account',
      subtitle: 'Fill in your details to get started',
      leading: const BackButton(),
      child: Column(
        children: [
          AppTextField(
            controller: _nameController,
            hintText: 'Display Name',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Create Account',
            loading: _loading,
            onPressed: _createAccount,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Use Phone OTP',
            icon: Icons.phone_iphone_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PhoneAuthScreen(
                    repository: widget.repository,
                    onAuthenticated: widget.onAuthenticated,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account?',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final ChatRepository repository;
  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _loading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (!phone.startsWith('+') || phone.length < 8) {
      showAppSnack(context, 'Enter phone number with country code.');
      return;
    }

    setState(() => _loading = true);
    await widget.repository.startPhoneOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _loading = false;
        });
        showAppSnack(context, 'OTP code sent.');
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        widget.onAuthenticated(user);
        Navigator.of(context).pop();
      },
      onFailed: (message) {
        if (!mounted) return;
        setState(() => _loading = false);
        showAppSnack(context, message);
      },
    );
  }

  Future<void> _verifyCode() async {
    final verificationId = _verificationId;
    final code = _codeController.text.trim();
    if (verificationId == null) {
      showAppSnack(context, 'Request an OTP code first.');
      return;
    }
    if (code.length < 6) {
      showAppSnack(context, 'Enter the 6 digit OTP code.');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await widget.repository.confirmPhoneOtp(
        verificationId: verificationId,
        smsCode: code,
      );
      if (!mounted) return;
      widget.onAuthenticated(user);
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Phone Verification',
      subtitle: 'Sign in or create an account with an OTP code',
      leading: const BackButton(),
      headerIcon: Icons.phone_iphone_rounded,
      child: Column(
        children: [
          AppTextField(
            controller: _phoneController,
            hintText: 'Phone Number (+923001234567)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: _codeSent
                ? TextInputAction.next
                : TextInputAction.send,
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            AppTextField(
              controller: _codeController,
              hintText: 'OTP Code',
              icon: Icons.password_rounded,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: _codeSent ? 'Verify OTP' : 'Send OTP',
            icon: _codeSent ? Icons.verified_rounded : Icons.sms_rounded,
            loading: _loading,
            onPressed: _codeSent ? _verifyCode : _sendCode,
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _sendCode,
              child: const Text('Resend OTP'),
            ),
          ],
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.repository});

  final ChatRepository repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_emailController.text.trim().isEmpty) {
      showAppSnack(context, 'Please enter your email address.');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.repository.sendPasswordReset(_emailController.text);
      if (!mounted) return;
      showAppSnack(context, 'Password reset link sent.');
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Forgot Password',
      subtitle: 'Enter your email to receive a password reset link',
      leading: const BackButton(),
      headerIcon: Icons.lock_reset_rounded,
      child: Column(
        children: [
          AppTextField(
            controller: _emailController,
            hintText: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Send Reset Link',
            icon: Icons.send_rounded,
            loading: _loading,
            onPressed: _sendReset,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Remember your password?',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.headerIcon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final IconData? headerIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leading ?? const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 22),
              if (headerIcon != null) ...[
                Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.softPurple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(headerIcon, color: AppColors.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 26),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
