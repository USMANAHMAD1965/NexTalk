part of '../app.dart';

class ProfileScreen extends StatefulWidget {
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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String get _name => widget.currentUser.displayName;
  String get _status => widget.currentUser.bio;
  String get _email => widget.currentUser.email;
  String get _phone => widget.currentUser.phoneNumber ?? 'No phone number';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Collapsible app bar with avatar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF075E54),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF075E54),
              statusBarIconBrightness: Brightness.light,
            ),
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) {
                  if (val == 'change_password') {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChangePasswordScreen(repository: widget.repository),
                      ),
                    );
                  } else if (val == 'logout') {
                    widget.onSignOut();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'change_password', child: Text('Change password')),
                  const PopupMenuItem(value: 'logout', child: Text('Log out')),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF075E54),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF075E54), width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF075E54)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_status,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Info section
                _buildSection('Account Info', [
                  _buildInfoTile(Icons.person_outline, 'Name', _name),
                  _buildInfoTile(Icons.info_outline, 'Status', _status),
                  _buildInfoTile(Icons.email_outlined, 'Email', _email),
                  _buildInfoTile(Icons.phone_outlined, 'Phone', _phone),
                ]),

                const SizedBox(height: 8),

                // Settings section
                _buildSection('Settings', [
                   _buildActionTile(Icons.lock_outline, 'Change Password', () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChangePasswordScreen(repository: widget.repository),
                      ),
                    );
                  }),
                  _buildActionTile(Icons.notifications_none, 'Notifications', () {}),
                  _buildActionTile(Icons.privacy_tip_outlined, 'Privacy', () {}),
                  _buildActionTile(Icons.help_outline, 'Help', () {}),
                ]),

                const SizedBox(height: 8),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                      label: const Text('Log Out',
                          style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('NexTalk v1.0.0',
                    style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF075E54), letterSpacing: 0.8)),
        ),
        ...tiles,
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF075E54), size: 22),
      title: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w500)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFCCCCCC)),
        onPressed: () {},
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF075E54), size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
      onTap: onTap,
    );
  }
}
