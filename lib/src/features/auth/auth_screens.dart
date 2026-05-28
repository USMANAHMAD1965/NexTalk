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
    if (!widget.repository.firebaseEnabled) {
      showAppSnack(
        context,
        'Firebase is not configured, so demo mode will not send a real OTP.',
      );
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
        phoneNumber: _phoneController.text,
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

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome Back',
      subtitle: 'Enter your phone number with country code to receive an OTP',
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
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _loading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Please enter your username.');
      return;
    }
    if (!phone.startsWith('+') || phone.length < 8) {
      showAppSnack(context, 'Enter phone number with country code.');
      return;
    }
    if (!widget.repository.firebaseEnabled) {
      showAppSnack(
        context,
        'Firebase is not configured, so demo mode will not send a real OTP.',
      );
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
      onAutoVerified: (user) => unawaited(_finishSignup(user)),
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
        phoneNumber: _phoneController.text,
      );
      await _finishSignup(user);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishSignup(AppUser user) async {
    try {
      final updatedUser = await widget.repository.updatePhoneUserDisplayName(
        user: user,
        displayName: _nameController.text,
      );
      if (!mounted) return;
      widget.onAuthenticated(updatedUser);
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
      subtitle: 'Enter your username and phone number to receive an OTP',
      leading: const BackButton(),
      headerIcon: Icons.person_add_alt_1_rounded,
      child: Column(
        children: [
          AppTextField(
            controller: _nameController,
            hintText: 'User Name',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
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
            label: _codeSent ? 'Verify & Sign Up' : 'Send OTP',
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
    if (!widget.repository.firebaseEnabled) {
      showAppSnack(
        context,
        'Firebase is not configured, so demo mode will not send a real OTP.',
      );
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
