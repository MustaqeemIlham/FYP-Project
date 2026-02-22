import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'name': 'Anonymous',
          'role': 'Farmer',
          'username': 'User',
        };
      }

      // Query user document by userid field (same as EditProfilePage)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userid', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userDoc = snapshot.docs.first;
        final data = userDoc.data();
        return {
          'name': data['username'] ?? user.displayName ?? 'Anonymous',
          'role': data['role'] ?? 'Farmer',
          'userId': user.uid,
        };
      } else {
        // User exists in Firebase Auth but not in Firestore users collection
        return {
          'name': user.displayName ?? user.email?.split('@').first ?? 'User',
          'role': 'Farmer',
          'userId': user.uid,
        };
      }
    } catch (e) {
      print('Error getting user data: $e');
      return {
        'name': 'User',
        'role': 'Farmer',
      };
    }
  }

  Future<void> _savePost() async {
    if (_contentController.text.isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add some content or an image")),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get user data using the same method as EditProfilePage
      final userData = await _getUserData();

      // Save post data into Firestore
      final postData = {
        "content": _contentController.text.trim(),
        "image": _selectedFile?.path, // local path or null
        "name": userData['name'], 
        "role": userData['role'],
        "userId": userData['userId'],
        "time": FieldValue.serverTimestamp(),
        "likes": 0,
        "liked": [], // list of userIds
        "comments": [],
      };

      await FirebaseFirestore.instance.collection('posts').add(postData);

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post saved successfully!")),
      );
      
      // Navigate back to community
      if (mounted) {
        context.go('/community');
      }

    } catch (e) {
      print('Error saving post: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/community'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Post text
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "What's on your mind about farming?",
                filled: true,
                fillColor: Colors.green.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image/file preview
            if (_selectedFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // File picker button
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file, color: Colors.green),
              label: const Text("Upload Image",
                  style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Guidelines box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Community Guidelines",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        SizedBox(height: 4),
                        Text("• Share helpful farming tips and experiences"),
                        Text("• Be respectful to fellow farmers"),
                        Text("• Include relevant crop information"),
                        Text("• Avoid spam or promotional content"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePost,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              label: Text(_isLoading ? "Posting..." : "Share with Community"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:go_router/go_router.dart';

// class AddPostScreen extends StatefulWidget {
//   const AddPostScreen({super.key});

//   @override
//   State<AddPostScreen> createState() => _AddPostScreenState();
// }

// class _AddPostScreenState extends State<AddPostScreen> {
//   final TextEditingController _contentController = TextEditingController();
//   File? _selectedFile;

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//     );
//     if (result != null) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Create Post", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.green,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => context.go('/community'),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Post text
//             TextField(
//               controller: _contentController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 hintText: "What's on your mind about farming?",
//                 filled: true,
//                 fillColor: Colors.green.shade50,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Image/file preview
//             if (_selectedFile != null) ...[
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.file(
//                   _selectedFile!,
//                   height: 200,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],

//             // File picker button
//             OutlinedButton.icon(
//               onPressed: _pickFile,
//               icon: const Icon(Icons.upload_file, color: Colors.green),
//               label: const Text("Upload Image",
//                   style: TextStyle(color: Colors.green)),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.green),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Guidelines box
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(Icons.info, color: Colors.green),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text(
//                           "Community Guidelines",
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold, color: Colors.green),
//                         ),
//                         SizedBox(height: 4),
//                         Text("• Share helpful farming tips and experiences"),
//                         Text("• Be respectful to fellow farmers"),
//                         Text("• Include relevant crop information"),
//                         Text("• Avoid spam or promotional content"),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Submit button
//             ElevatedButton.icon(
//               onPressed: () {
//                 if (_contentController.text.isNotEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Post shared successfully!")),
//                   );
//                   Navigator.pop(context);
//                 }
//               },
//               icon: const Icon(Icons.share),
//               label: const Text("Share with Community"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
