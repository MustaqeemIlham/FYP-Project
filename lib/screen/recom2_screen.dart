import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CropRecommendationsPage extends StatelessWidget {
  const CropRecommendationsPage({super.key});
  
void _showDetails(BuildContext context, Map<String, dynamic> item) {
  // Helper function to calculate month/year from week
  Map<String, dynamic> _getPlantingDateInfo(int weekNumber, DateTime baseDate) {
    final plantingDate = baseDate.add(Duration(days: (weekNumber - 1) * 7));
    return {
      'month': DateFormat('MMMM').format(plantingDate),
      'year': plantingDate.year,
      'week': weekNumber,
    };
  }
  
  // Get current year for reference
  final currentYear = DateTime.now().year;
  final plantingWeek = item["recommended_planting_week"] ?? 0;
  final harvestWeek = item["expected_harvest_week"] ?? 0;

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat("MMMM dd, yyyy").format(date); // e.g. March 15, 2024
  }

  String _formatDateFromString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat("MMMM dd, yyyy").format(date);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

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
  
  // Calculate planting and harvest info
  final plantingInfo = plantingWeek > 0 
      ? _getPlantingDateInfo(plantingWeek, DateTime(currentYear, 1, 1))
      : null;
  
  final harvestInfo = harvestWeek > 0 
      ? _getPlantingDateInfo(harvestWeek, DateTime(currentYear, 1, 1))
      : null;

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
              item["cropname"] ?? "Unknown",
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
                          "📅 Recommended on: ${item["date"] != null
                              ? _formatDate(item["date"] as Timestamp)
                              : "Unknown date"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "💲 Predicted Price: RM${item["price"]?.toString() ?? "N/A"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "⏱️ Growth Cycle: $growthCycle weeks",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "🌱 Planting Date: $plantingDate",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "🌾 Expected Harvest: $harvestDate",
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (item["planting_week_of_year"] != null && item["harvest_week_of_year"] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "📆 Timeline: Week ${item["planting_week_of_year"]} → Week ${item["harvest_week_of_year"]}",
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          "Crop Recommendations",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("history")
            .where("userid", isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recommendations found."));
          }

          final crops = snapshot.data!.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Green Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.agriculture, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Best Vegetables for Your Farm",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Based on your location and season, here are your crop recommendations.",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Highly Recommended",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Cards
              ...crops.map((item) {
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
                                      (item["cropname"] ?? "-")
                                          .toString()
                                          .split(" ")
                                          .map((word) => word.isNotEmpty
                                              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                                              : "")
                                          .join(" "),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item["date"] != null
                                  ? DateFormat('dd MMM yyyy').format(
                                      (item["date"] as Timestamp).toDate(),
                                    )
                                  : "-",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description with flexible height
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 80, // Limit description height
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  item["description"] ?? "-",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 4, // Limit to 4 lines
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
              }),

              // Continue Button
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.go("/home"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

