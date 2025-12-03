import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/comment_model.dart';
import '../../services/forum_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostDetailScreen({Key? key, required this.postData}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await ForumService().addComment(
      postId: widget.postData['postId'],
      userId: user.uid,
      username: 'Anonymous',
      content: _commentController.text.trim(),
    );

    setState(() {
      widget.postData['commentCount']++;
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postData;

    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          "Post Details",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          /// POST CARD
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  post['content'],
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '${post['likeCount']}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.comment, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '${post['commentCount']}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade700, indent: 12, endIndent: 12),

          /// COMMENTS LIST
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: ForumService().getCommentsForPost(post['postId']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      "No comments yet.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(12),
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isAuthor =
                        comment.userId == widget.postData['userId'];

                    return Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (isAuthor)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Author",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              Spacer(),
                              Text(
                                TimeOfDay.fromDateTime(
                                  comment.timestamp,
                                ).format(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                              if (comment.userId ==
                                  FirebaseAuth.instance.currentUser?.uid)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => AlertDialog(
                                            backgroundColor: Color(0xFF1E1E1E),
                                            title: Text(
                                              "Delete Comment",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            content: Text(
                                              "Are you sure?",
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  await ForumService()
                                                      .deleteComment(
                                                        postId:
                                                            widget
                                                                .postData['postId'],
                                                        commentId:
                                                            comment.commentId,
                                                      );
                                                  setState(
                                                    () =>
                                                        widget
                                                            .postData['commentCount']--,
                                                  );
                                                },
                                                child: Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            comment.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// COMMENT BOX
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addComment,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
