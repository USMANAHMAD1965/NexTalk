part of '../app.dart';

class PhoneSignUpScreen extends StatefulWidget {
  const PhoneSignUpScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final ChatRepository repository;
  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<PhoneSignUpScreen> createState() => _PhoneSignUpScreenState();
}

class _PhoneSignUpScreenState extends State<PhoneSignUpScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showAppSnack(context, 'Enter your phone number with country code.');
      return;
    }
    setState(() => _isLoading = true);
    await widget.repository.startPhoneOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
        showAppSnack(context, 'OTP sent to $phone');
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        widget.onAuthenticated(user);
      },
      onFailed: (message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showAppSnack(context, message);
      },
    );
  }

  void _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      showAppSnack(context, 'Enter the OTP code.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await widget.repository.confirmPhoneOtp(
        verificationId: _verificationId!,
        smsCode: code,
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      final needsName =
          user.displayName.trim().isEmpty ||
          user.displayName.trim() == user.email.trim();
      if (needsName) {
        setState(() => _isLoading = false);
        await _askForDisplayNameAndFinish(user);
        return;
      }

      widget.onAuthenticated(user);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _askForDisplayNameAndFinish(AppUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose a display name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Enter a display name to continue.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updated = await widget.repository.updatePhoneUserDisplayName(
        user: user,
        displayName: name,
      );
      if (!mounted) return;
      widget.onAuthenticated(updated);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF075E54), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF075E54), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: const Text('Sign up with Phone'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  'Phone number (e.g. +1234567890)',
                  Icons.phone_android,
                ),
              ),
              const SizedBox(height: 12),
              if (!_codeSent)
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text('Send OTP'),
                  ),
                ),
              if (_codeSent) ...[
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Enter OTP', Icons.message),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text('Verify & Continue'),
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
