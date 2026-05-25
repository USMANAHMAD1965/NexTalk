part of '../../../main.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onSignOut,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final VoidCallback onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _openChat(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          repository: widget.repository,
          currentUser: widget.currentUser,
          conversation: conversation,
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          repository: widget.repository,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _openFriendRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendRequestsScreen(
          repository: widget.repository,
          currentUser: widget.currentUser,
          onOpenChat: _openChat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MessagesScreen(
        repository: widget.repository,
        currentUser: widget.currentUser,
        onOpenChat: _openChat,
        onOpenFindPeople: () => setState(() => _selectedIndex = 2),
        onOpenNotifications: _openNotifications,
      ),
      FriendsScreen(
        repository: widget.repository,
        currentUser: widget.currentUser,
        onOpenChat: _openChat,
        onOpenRequests: _openFriendRequests,
      ),
      FindPeopleScreen(
        repository: widget.repository,
        currentUser: widget.currentUser,
        onOpenChat: _openChat,
      ),
      ProfileScreen(
        repository: widget.repository,
        currentUser: widget.currentUser,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.softPurple,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1_outlined),
            selectedIcon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Find Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
