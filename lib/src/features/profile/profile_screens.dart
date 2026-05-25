part of '../../../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onSignOut,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        children: [
          HeaderBar(
            title: 'Profile',
            action: TextButton(onPressed: () {}, child: const Text('Edit')),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                AvatarCircle(user: currentUser, size: 84, fontSize: 30),
                const SizedBox(height: 14),
                Text(
                  currentUser.displayName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.email,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tint(AppColors.accent, 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionLabel('Personal Information'),
          const SizedBox(height: 10),
          InfoPanel(
            children: [
              InfoRow(
                icon: Icons.person_outline,
                label: 'Display Name',
                value: currentUser.displayName,
              ),
              const Divider(height: 18, color: AppColors.line),
              InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: currentUser.email,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ProfileMenuItem(
            icon: Icons.security_rounded,
            title: 'Change Password',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangePasswordScreen(repository: repository),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ProfileMenuItem(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            destructive: true,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.repository});

  final ChatRepository repository;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_currentController.text.isEmpty || _newController.text.isEmpty) {
      showAppSnack(context, 'Please complete all password fields.');
      return;
    }
    if (_newController.text != _confirmController.text) {
      showAppSnack(context, 'New passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.repository.updatePassword(
        _currentController.text,
        _newController.text,
      );
      if (!mounted) return;
      showAppSnack(context, 'Password updated.');
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.softPurple,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Update Your Password',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your current password and choose a new secure password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 26),
              AppTextField(
                controller: _currentController,
                hintText: 'Current Password',
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _newController,
                hintText: 'New Password',
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmController,
                hintText: 'Confirm New Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Update Password',
                icon: Icons.shield_rounded,
                loading: _loading,
                onPressed: _update,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
