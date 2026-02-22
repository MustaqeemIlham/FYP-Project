import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => {context.go('/profile')},
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 FAQs Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Frequently Asked Questions",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  SizedBox(height: 12),
                  Text("Q: How do I edit my profile?\n"
                      "A: Go to Profile > Edit Profile to update your details."),
                  SizedBox(height: 8),
                  Text("Q: How do I view past recommendations?\n"
                      "A: Visit the Recommendation History page from your Profile."),
                  SizedBox(height: 8),
                  Text("Q: How can I contact support?\n"
                      "A: Use the contact details below."),
                ],
              ),
            ),
          ),

          // 🔹 Contact Info Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Contact Us",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.green),
                      SizedBox(width: 8),
                      Text("support@farmwise.com"),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green),
                      SizedBox(width: 8),
                      Text("+60 123-456-789"),
                    ],
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
