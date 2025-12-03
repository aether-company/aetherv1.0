import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/forum_post.dart';
import '../../services/forum_service.dart';
import 'post_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class UserPostsScreen extends StatelessWidget {
  final ForumService _forumService = ForumService();
  final String userId =
      FirebaseAuth.instance.currentUser?.uid ?? "default_user";

  void _showDeleteDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Post',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete this post?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: GoogleFonts.poppins()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _forumService.deletePost(postId);
                },
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A2E),
      appBar: AppBar(
        title: Text(
          "Your Posts",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0D1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<ForumPost>>(
        stream: _forumService.getUserPosts(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.post_add_outlined,
                    size: 60,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You haven't posted anything yet",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          List<ForumPost> userPosts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {},
            color: Colors.white,
            backgroundColor: Colors.blue,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: userPosts.length,
              itemBuilder: (context, index) {
                ForumPost post = userPosts[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => PostDetailScreen(
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
                  },
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black54,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    color: const Color(0xFF1A2635),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed:
                                    () =>
                                        _showDeleteDialog(context, post.postId),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${post.likes.length}",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              const SizedBox(width: 18),
                              const Icon(
                                Icons.mode_comment_outlined,
                                size: 20,
                                color: Colors.lightBlueAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${post.commentCount}",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
