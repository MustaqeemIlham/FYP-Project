
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
// import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  void _createPost() {
    context.go("/addpost");
  }


  Widget _buildNewsCard(Map<String, dynamic> newsItem) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.network(
                newsItem['image'],
                fit: BoxFit.cover,
              ),
            ),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newsItem['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    newsItem['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                     onPressed: () async {
                      final url = newsItem['link'];
                      if (url != null && url.isNotEmpty) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Could not launch $url")),
                          );
                        }
                      }
                    },
                      child: const Text(
                        'Read More',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



Widget _buildPost(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  final String user = data['name'] ?? 'Unknown';
  final String role = data['role'] ?? '';
  final String content = data['content'] ?? '';
  final String? image = data['image'];

  // 🔹 Handle Timestamp OR String
  String timeText = '';
  if (data['time'] != null) {
    if (data['time'] is String) {
      // old data stored as String (fallback)
      timeText = data['time'];
    } else if (data['time'] is Timestamp) {
      // convert Timestamp → DateTime → timeago
      final DateTime dateTime = (data['time'] as Timestamp).toDate();
      timeText = timeago.format(dateTime, locale: 'en'); 
      // you can use 'ms' for Malay support
    }
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade300,
              child: Text(
                user.isNotEmpty ? user[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (role.isNotEmpty || timeText.isNotEmpty)
                    Text(
                      '${role.isNotEmpty ? role : ''}${role.isNotEmpty && timeText.isNotEmpty ? ' • ' : ''}$timeText',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'share') {
                  Share.share("This is my shared content!");
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Text("Share"),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        if (content.isNotEmpty)
          Text(content, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        if (image != null && image.isNotEmpty)
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: image.startsWith('http')
        ? Image.network( // online image
            image,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          )
        : Image.file( // local image
            File(image),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
  ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: Row(
          children: [
            // Icon(Icons.agriculture, color: Colors.white),
            // SizedBox(width: 8), // spacing between icon and text
            Icon(Icons.group, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "AgriCommunity",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // 🔹 NEWS Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Latest Agricultural News",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.article_outlined, color: Colors.green.shade700),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('news')
                        .orderBy('title')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final newsList = snapshot.data!.docs;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: newsList.length,
                        itemBuilder: (context, index) =>
                            _buildNewsCard(newsList[index].data() as Map<String, dynamic>),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 🔹 POSTS Section
            Row(
              children: [
                const Text("Community Posts",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _createPost,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Create Post"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final postsList = snapshot.data!.docs;
                return Column(
                  children: postsList.map((doc) => _buildPost(doc)).toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/recom2');
              break;
            case 2:
              context.go('/community');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.recommend), label: 'Recommendation'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

