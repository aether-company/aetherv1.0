// forum_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/forum_post.dart';
import '../../services/forum_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'user_posts_screen.dart';
import 'package:google_fonts/google_fonts.dart';

enum SortMode { top, newest }

class ForumHome extends StatefulWidget {
  @override
  _ForumHomeState createState() => _ForumHomeState();
}

class _ForumHomeState extends State<ForumHome> with TickerProviderStateMixin {
  final ForumService _forumService = ForumService();
  final String userId =
      FirebaseAuth.instance.currentUser?.uid ?? "default_user";

  String _searchQuery = '';
  SortMode _sortMode = SortMode.top;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(String postId) async {
    await _forumService.toggleLike(postId, userId);
    setState(() {});
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 250));
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen()),
    );
  }

  void _navigateToPostDetail(ForumPost post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostDetailScreen(
              postData: {
                'postId': post.postId,
                'title': post.title,
                'content': post.content,
                'userId': post.userId,
                'username': post.username,
                'timestamp': post.timestamp,
                'likeCount': post.likes.length,
                'commentCount': post.commentCount,
              },
            ),
      ),
    );
    setState(() {});
  }

  List<ForumPost> _applySearchAndSort(List<ForumPost> posts) {
    final query = _searchQuery.trim().toLowerCase();
    List<ForumPost> filtered =
        query.isEmpty
            ? posts
            : posts.where((p) {
              final t =
                  '${p.title} ${p.content} ${(p.username ?? '')}'.toLowerCase();
              return t.contains(query);
            }).toList();

    if (_sortMode == SortMode.top) {
      filtered.sort(
        (a, b) => (b.likes.length + b.commentCount).compareTo(
          a.likes.length + a.commentCount,
        ),
      );
    } else {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final String username = FirebaseAuth.instance.currentUser?.email ?? "User";

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(username),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF043A4F), Color(0xFF052B42), Color(0xFF04172C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _searchSortRow(),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<List<ForumPost>>(
                    stream: _forumService.getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.lightBlueAccent,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _EmptyState(onCreate: _openCreate);
                      }

                      final posts = _applySearchAndSort(snapshot.data!);

                      return RefreshIndicator(
                        onRefresh: _refresh,
                        color: Colors.lightBlueAccent,
                        child: Scrollbar(
                          thumbVisibility: true,
                          radius: const Radius.circular(10),
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 90, top: 4),
                            itemCount: posts.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final p = posts[i];
                              return PostCardPro(
                                post: p,
                                isLiked: p.likes.contains(userId),
                                onLike: () => _toggleLike(p.postId),
                                onTap: () => _navigateToPostDetail(p),
                                heroTag: 'post_${p.postId}',
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _fab(),
    );
  }

  /// ---------------- FAB SECTION ----------------
  Widget _fab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'profile_btn',
          backgroundColor: Colors.white,
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserPostsScreen()),
              ),
          child: const Icon(Icons.person, color: Color(0xFF052B42)),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'create_btn',
          backgroundColor: const Color(0xFF1E88E5),
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: Text(
            'Create',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// ---------------- APP BAR ----------------
  AppBar _buildAppBar(String username) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 88,
      flexibleSpace: _AppBarBackground(),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${_shortUserName(username)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catch up with the community',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white12,
              child: Text(
                _initial(username),
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- SEARCH + SORT ROW ----------------
  Widget _searchSortRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2432),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF06202A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              _sortBtn(SortMode.top, 'Top'),
              const SizedBox(width: 6),
              _sortBtn(SortMode.newest, 'New'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sortBtn(SortMode mode, String label) {
    final active = _sortMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _sortMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E88E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  String _shortUserName(String email) =>
      email.contains('@') ? email.split('@')[0] : email;
  String _initial(String email) =>
      _shortUserName(email).isNotEmpty
          ? _shortUserName(email)[0].toUpperCase()
          : "U";
}

/// ---------------- EMPTY STATE ----------------
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum, size: 70, color: Colors.white30),
          const SizedBox(height: 12),
          Text(
            'No posts yet',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create something!',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text("Create"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- APP BAR BACKGROUND ----------------
class _AppBarBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF05445E), Color(0xFF022F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
    );
  }
}

/// ---------------- FULL POST CARD ----------------
class PostCardPro extends StatelessWidget {
  final ForumPost post;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onTap;
  final String heroTag;

  const PostCardPro({
    required this.post,
    required this.isLiked,
    required this.onLike,
    required this.onTap,
    required this.heroTag,
  });

  String _timeAgo(DateTime? ts) {
    final now = DateTime.now();
    final diff = now.difference(ts ?? now);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${ts!.day}/${ts.month}/${ts.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2432),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white12,
                      child: Text(
                        post.username?.isNotEmpty == true
                            ? post.username![0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                post.username ?? 'Anonymous',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "•",
                                style: TextStyle(color: Colors.white24),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _timeAgo(post.timestamp),
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _stat(Icons.favorite, "${post.likes.length}"),
                        const SizedBox(height: 6),
                        _stat(Icons.chat_bubble, "${post.commentCount}"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(.9)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _LikeButton(
                      isLiked: isLiked,
                      likeCount: post.likes.length,
                      onTap: onLike,
                    ),
                    const SizedBox(width: 18),
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${post.commentCount}",
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData i, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 14, color: Colors.white24),
      const SizedBox(width: 4),
      Text(t, style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
    ],
  );
}

/// ---------------- LIKE BUTTON ----------------
class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
  });
  @override
  __LikeButtonState createState() => __LikeButtonState();
}

class __LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: Row(
        children: [
          ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              color: widget.isLiked ? Colors.redAccent : Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "${widget.likeCount}",
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
