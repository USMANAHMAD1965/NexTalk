part of '../app.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onOpenChat,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final ValueChanged<Conversation> onOpenChat;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _openingChatUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(AppUser friend) async {
    if (_openingChatUserId != null) return;
    setState(() => _openingChatUserId = friend.id);
    try {
      final conversation = await widget.repository.openConversation(
        currentUser: widget.currentUser,
        peer: friend,
      );
      if (!mounted) return;
      widget.onOpenChat(conversation);
    } on Object catch (error) {
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    } finally {
      if (mounted) setState(() => _openingChatUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FindPeopleScreen(
                    repository: widget.repository,
                    currentUser: widget.currentUser,
                    onOpenChat: widget.onOpenChat,
                  ),
                ),
              );
            },
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF075E54),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF075E54),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search friends',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white60,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Friends list
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: widget.repository.watchFriends(widget.currentUser.id),
              builder: (context, snapshot) {
                final allFriends = snapshot.data ?? const <AppUser>[];
                final filtered = allFriends.where((f) {
                  final nameMatch = f.displayName.toLowerCase().contains(
                    _query.toLowerCase(),
                  );
                  final emailMatch = f.email.toLowerCase().contains(
                    _query.toLowerCase(),
                  );
                  final phoneMatch =
                      f.phoneNumber != null &&
                      f.phoneNumber!.toLowerCase().contains(
                        _query.toLowerCase(),
                      );
                  return nameMatch || emailMatch || phoneMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No friends found',
                      style: TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const Divider(
                    height: 1,
                    indent: 72,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (context, index) {
                    final f = filtered[index];
                    final opening = _openingChatUserId == f.id;
                    final initial = f.displayName.trim().isNotEmpty
                        ? f.displayName.trim()[0].toUpperCase()
                        : 'F';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF075E54),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (f.online)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 11,
                                height: 11,
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
                      title: Text(
                        f.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      subtitle: Text(
                        f.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      trailing: IconButton(
                        icon: opening
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.chat_outlined,
                                color: Color(0xFF075E54),
                              ),
                        onPressed: opening ? null : () => _openChat(f),
                      ),
                      onTap: opening ? null : () => _openChat(f),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
