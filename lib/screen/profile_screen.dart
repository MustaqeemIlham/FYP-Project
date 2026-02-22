import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // add this for File
import 'package:image_picker/image_picker.dart';
class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3; // Profile selected

Future<void> pickAndSaveProfileImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Get the user's document based on userid field
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where("userid", isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id; // correct Firestore document ID

        await FirebaseFirestore.instance
            .collection("users")
            .doc(docId)
            .update({"image": pickedFile.path});
      }
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: const Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userid', isEqualTo: currentUser.uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No profile found"));
          }

          final userProfile =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;

          return Stack(
            children: [
              // Green curved header
              Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),

              // Content
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 50), // space for header
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                      GestureDetector(
        onTap: () => pickAndSaveProfileImage(), // tap to change image
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          backgroundImage: (userProfile['image'] != null &&
                  userProfile['image'].isNotEmpty)
              ? (userProfile['image'].startsWith('/data') || userProfile['image'].startsWith('/storage'))
                  ? FileImage(File(userProfile['image'])) as ImageProvider
                  : NetworkImage(userProfile['image'])
              : null,
          child: (userProfile['image'] == null ||
                  userProfile['image'].isEmpty)
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
      ),

                          const SizedBox(height: 12),
                          Text(
                            userProfile['username'] ?? "No Name",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            userProfile['farmname'] ?? "No Farm Name",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                             Text(
                                userProfile['state'] != null && userProfile['district'] != null
                                    ? "${userProfile['district']}, ${userProfile['state']}"
                                    : (userProfile['state'] ?? userProfile['district'] ?? "No Location"),
                                style: const TextStyle(color: Colors.white70),
                              ),

                            ],
                          ),
                          const SizedBox(height: 5),

                          // Farm stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                'Farm Size',
                               ('${userProfile['farmsize ']?.toString() ?? "-"} Hectares'),
                                Colors.white,
                              ),
                              _buildStatItem(
                                'Crops',
                                (userProfile['croppreference'] ?? 0).toString(),
                                Colors.white,
                              ),
                              _buildStatItem(
                                'Member Since',
                                userProfile['memberdate'] != null
                                    ? DateFormat('dd MMM yyyy').format(
                                        (userProfile['memberdate']
                                                as Timestamp)
                                            .toDate(),
                                      )
                                    : "-",
                                Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Account Features
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Account Features'),
                          const SizedBox(height: 12),
                          _buildVerticalFeatureButton(
                              Icons.edit, 'Edit Profile', Colors.blue, '/edit'),
                          const SizedBox(height: 12),
                          _buildVerticalFeatureButton(Icons.history,
                              'Activity History', Colors.orange, '/history'),
                          const SizedBox(height: 12),
                          _buildVerticalFeatureButton(Icons.help,
                              'Help & Support', Colors.green, '/support'),
                          const SizedBox(height: 12),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                context.go('/sigin');
                              },
                              child: const Text(
                                "Log Out",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: 'Recommendation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalFeatureButton(
      IconData icon, String label, Color color, String route) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        onPressed: () {
          context.go(route);
        },
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

