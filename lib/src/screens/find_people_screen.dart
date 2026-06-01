part of '../app.dart';

class FindPeopleScreen extends StatefulWidget {
  const FindPeopleScreen({
    super.key,
    required this.repository,
    required this.currentUser,
    required this.onOpenChat,
  });

  final ChatRepository repository;
  final AppUser currentUser;
  final ValueChanged<Conversation> onOpenChat;

  @override
  State<FindPeopleScreen> createState() => _FindPeopleScreenState();
}

class _FindPeopleScreenState extends State<FindPeopleScreen> {
  final _searchController = TextEditingController();
  final Set<String> _requested = <String>{};
  String _query = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(AppUser target) async {
    setState(() => _requested.add(target.id));
    try {
      await widget.repository.sendFriendRequest(widget.currentUser, target);
      if (!mounted) return;
      showAppSnack(context, 'Friend request sent to ${target.displayName}.');
    } on Object catch (error) {
      setState(() => _requested.remove(target.id));
      if (!mounted) return;
      showAppSnack(context, friendlyFirebaseError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find People',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() {
                  _query = v;
                  _isSearching = v.isNotEmpty;
                }),
                style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF075E54),
                    size: 20,
                  ),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF888888),
                          ),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _query = '';
                            _isSearching = false;
                          }),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: widget.repository.watchFindPeople(widget.currentUser.id),
              builder: (context, snapshot) {
                final allPeople = snapshot.data ?? const <AppUser>[];
                final results = _query.isEmpty
                    ? <AppUser>[]
                    : allPeople.where((u) {
                        final nameMatch = u.displayName.toLowerCase().contains(
                          _query.toLowerCase(),
                        );
                        final emailMatch = u.email.toLowerCase().contains(
                          _query.toLowerCase(),
                        );
                        final phoneMatch =
                            u.phoneNumber != null &&
                            u.phoneNumber!.toLowerCase().contains(
                              _query.toLowerCase(),
                            );
                        return nameMatch || emailMatch || phoneMatch;
                      }).toList();

                if (_query.isEmpty) {
                  return _buildEmptyState();
                }

                if (results.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, index) => const Divider(
                    height: 1,
                    indent: 72,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (context, index) {
                    final user = results[index];
                    final requested = _requested.contains(user.id);
                    final initial = user.displayName.trim().isNotEmpty
                        ? user.displayName.trim()[0].toUpperCase()
                        : 'P';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
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
                      title: Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      subtitle: Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      trailing: requested
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF25D366),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Sent',
                                style: TextStyle(
                                  color: Color(0xFF25D366),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _sendRequest(user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Find your friends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by name or email address',
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}
