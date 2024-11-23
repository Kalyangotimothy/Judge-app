import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:judge_app_2/students.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:judge_app_2/database.dart'; // Firestore service

class Homescreen extends StatefulWidget {
  final String username;

  const Homescreen({super.key, required this.username});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Stack(
        children: [
          // Background Color
          Container(color: Colors.amber[50]),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Greeting Text
                Container(
                  alignment: Alignment.topRight,
                  margin: const EdgeInsets.only(right: 20.0, top: 20.0),
                  child: Text(
                    "Hi, ${widget.username}",
                    style: GoogleFonts.poppins(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Instruction Text
                Text(
                  "Choose a category",
                  style: GoogleFonts.montserrat(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Category Grid
                Flexible(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: userId != null
                        ? _fs.getCategories_2(userId)
                        : Stream.value([]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final categories = snapshot.data ?? [];

                      if (categories.isEmpty) {
                        return const Center(
                            child: Text('No categories available.'));
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.2, // Reduce card height
                        ),
                        padding: const EdgeInsets.all(16.0),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];

                          return buildCardWithIcon(
                            context,
                            category['name'] ?? 'Unnamed',
                            Icons.category,
                            Colors.amber[(index + 1) * 100],
                            userId!,
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 50),
                Text("The Top Scorers for each Category.",
                    style: GoogleFonts.poppins(
                      fontSize: 18.0,
                      color: Colors.grey[500],
                    )),
                const SizedBox(height: 50),
                // Contestants List by Category
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fs.fetchTopContestantsForAllCategories(userId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.amber)));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final allContestants = snapshot.data ?? [];

                      if (allContestants.isEmpty) {
                        return const Center(
                          child: Text(
                            'No contestants available.',
                            style: TextStyle(color: Colors.black87),
                          ),
                        );
                      }

                      // Group contestants by category
                      Map<String, List<Map<String, dynamic>>>
                          contestantsByCategory = {};
                      for (var contestant in allContestants) {
                        String category = contestant['category'];
                        if (!contestantsByCategory.containsKey(category)) {
                          contestantsByCategory[category] = [];
                        }
                        contestantsByCategory[category]!.add(contestant);
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: contestantsByCategory.entries.map((entry) {
                          String category = entry.key;
                          List<Map<String, dynamic>> contestants = entry.value;

                          return ExpansionTile(
                            title: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 25.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            children: contestants.map((contestant) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber[400],
                                  child: Text(
                                    '${contestants.indexOf(contestant) + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  'Contestant ${contestant['number']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  'Score: ${contestant['totalMarks']}/100',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.0,
                                    color: Colors.black54,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build a card with an icon
  Widget buildCardWithIcon(
    BuildContext context,
    String name,
    IconData icon,
    Color? color,
    String userId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Students(userId: userId, name: name),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 30.0,
              child: Icon(
                icon,
                color: Colors.white,
                size: 30.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 16.0, // Reduced font size
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
