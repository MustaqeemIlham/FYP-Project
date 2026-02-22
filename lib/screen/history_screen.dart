import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // for date formatting
import 'package:firebase_auth/firebase_auth.dart';

class RecommendationHistoryPage extends StatelessWidget {
  RecommendationHistoryPage({super.key});

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat("MMMM dd, yyyy").format(date); 
  }

  String _formatDateFromString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat("MMMM dd, yyyy").format(date);
    } catch (e) {
      return dateString; 
    }
  }

  final currentUser = FirebaseAuth.instance.currentUser;
  
  void _showDetails(BuildContext context, Map<String, dynamic> item) {
  
    final plantingDate = item["planting_date"] != null
        ? (item["planting_date"] is Timestamp
            ? _formatDate(item["planting_date"] as Timestamp)
            : _formatDateFromString(item["planting_date"].toString()))
        : "Not specified";

    final harvestDate = item["harvest_date"] != null
        ? (item["harvest_date"] is Timestamp
            ? _formatDate(item["harvest_date"] as Timestamp)
            : _formatDateFromString(item["harvest_date"].toString()))
        : "Not calculated";

    final growthCycle = item["growth_cycle_weeks"]?.toString() ?? "N/A";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.agriculture, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item["cropname"]?.toString() ?? "Unknown Crop",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                " Recommended on: ${item["date"] != null
                    ? _formatDate(item["date"] as Timestamp)
                    : "Unknown date"}",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                " Predicted Price: RM${item["price"]?.toString() ?? "N/A"}",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                " Growth Cycle: $growthCycle weeks",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                " Planting Date: $plantingDate",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                " Expected Harvest: $harvestDate",
                style: const TextStyle(fontSize: 14),
              ),
              if (item["planting_week_of_year"] != null && item["harvest_week_of_year"] != null) ...[
                const SizedBox(height: 8),
                Text(
                  " Timeline: Week ${item["planting_week_of_year"]} → Week ${item["harvest_week_of_year"]}",
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                "Description:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item["description"]?.toString() ?? "No description available",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.green)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text(
          "Recommendation History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('history')
            .where('userid', isEqualTo: currentUser!.uid)
           // .orderBy('date', descending: true) // Show newest first
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    "No recommendations yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Get your first crop recommendation!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final recommendations = snapshot.data!.docs;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header
              Container(
                width: double.infinity,
                color: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Recommendations",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendations.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.agriculture, color: Colors.white, size: 40),
                  ],
                ),
              ),

              // 🔹 History List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final doc = recommendations[index];
                    final item = doc.data() as Map<String, dynamic>;
                    
                    // Format dates
                    final recommendationDate = item["date"] != null
                        ? _formatDate(item["date"] as Timestamp)
                        : "Unknown date";
                    
                    final plantingDate = item["planting_date"] != null
                        ? (item["planting_date"] is Timestamp
                            ? DateFormat("MMM dd").format((item["planting_date"] as Timestamp).toDate())
                            : item["planting_date"].toString().split('-').skip(1).join('-').substring(0, 5)) // Show "Apr-15"
                        : "N/A";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + Date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.eco, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item["cropname"]?.toString() ?? "Unknown Crop",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  recommendationDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Price and Timeline
                            Row(
                              children: [
                                Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  "RM${item["price"]?.toStringAsFixed(2) ?? "N/A"}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.timeline, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  "$plantingDate → ${item["growth_cycle_weeks"]?.toString() ?? "?"}w",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Description with flexible height
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 60, // Limit description height
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    child: Text(
                                      item["description"]?.toString() ?? "No description",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // View Details Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showDetails(context, item),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                                child: const Text("View Details"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

