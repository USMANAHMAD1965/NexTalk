part of '../app.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onSignOut,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final VoidCallback onSignOut;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  int _currentIndex = 0;
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentIndex != _tabController.index) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF075E54),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  List<Conversation> _filter(List<Conversation> items) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<Conversation> filtered = items;
    if (_filterIndex == 1) {
      filtered = filtered.where((item) => item.unreadCount > 0);
    } else if (_filterIndex == 2) {
      filtered = filtered.where(
        (item) => DateTime.now().difference(item.updatedAt).inDays < 1,
      );
    } else if (_filterIndex == 3) {
      filtered = filtered.where((item) => item.peer.online);
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.peer.displayName.toLowerCase().contains(query) ||
            item.lastMessage.toLowerCase().contains(query);
      });
    }
    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 3
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF075E54),
              elevation: 0,
              title: const Text(
                'NexTalk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    // Let focus go directly to search bar
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (val) {
                    if (val == 'settings') {
                      setState(() => _currentIndex = 3);
                    } else if (val == 'logout') {
                      widget.onSignOut();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Log out'),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'CHATS'),
                  Tab(text: 'FRIENDS'),
                  Tab(text: 'NOTIFICATIONS'),
                ],
              ),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Color(0xFF075E54),
                statusBarIconBrightness: Brightness.light,
              ),
            ),
      body: _currentIndex == 3
          ? ProfileScreen(
              repository: widget.repository,
              currentUser: widget.currentUser,
              onSignOut: widget.onSignOut,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(),
                FriendsScreen(
                  repository: widget.repository,
                  currentUser: widget.currentUser,
                  onOpenChat: _openChat,
                ),
                NotificationsScreen(
                  repository: widget.repository,
                  currentUser: widget.currentUser,
                ),
              ],
            ),
      floatingActionButton: _currentIndex == 3
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF25D366),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FindPeopleScreen(
                      repository: widget.repository,
                      currentUser: widget.currentUser,
                      onOpenChat: _openChat,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.chat, color: Colors.white),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            if (i < 3) {
              _tabController.animateTo(i);
            }
          });
        },
        selectedItemColor: const Color(0xFF075E54),
        unselectedItemColor: const Color(0xFFAAAAAA),
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Column(
      children: [
        // Pill filter section matching WhatsApp premium feel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF888888),
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter chips matching original messages view
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (index) {
                final labels = ['All', 'Unread', 'Recent', 'Active'];
                final selected = _filterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    onSelected: (val) {
                      if (val) setState(() => _filterIndex = index);
                    },
                    backgroundColor: const Color(0xFFF0F0F0),
                    selectedColor: const Color(0xFF075E54),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide.none,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // Real conversations list
        Expanded(
          child: StreamBuilder<List<Conversation>>(
            stream: widget.repository.watchConversations(widget.currentUser.id),
            builder: (context, snapshot) {
              final rawConversations = snapshot.data ?? const <Conversation>[];
              final conversations = _filter(rawConversations);

              if (conversations.isEmpty) {
                return _buildEmptyConversations();
              }

              return ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, index) => const Divider(
                  height: 1,
                  indent: 72,
                  color: Color(0xFFF0F0F0),
                ),
                itemBuilder: (context, index) {
                  final chat = conversations[index];
                  final initial = chat.peer.displayName.trim().isNotEmpty
                      ? chat.peer.displayName.trim()[0].toUpperCase()
                      : 'C';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF075E54),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (chat.peer.online)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat.peer.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        Text(
                          shortTime(chat.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: chat.unreadCount > 0
                                ? const Color(0xFF25D366)
                                : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => _openChat(chat),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyConversations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF075E54),
                size: 38,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No conversations yet',
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with friends and start meaningful conversations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FindPeopleScreen(
                      repository: widget.repository,
                      currentUser: widget.currentUser,
                      onOpenChat: _openChat,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_search_rounded),
              label: const Text('Find People'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(180, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
