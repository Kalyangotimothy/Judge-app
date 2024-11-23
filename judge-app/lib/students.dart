import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:judge_app_2/awards.dart';
import 'package:judge_app_2/database.dart';

class Students extends StatelessWidget {
  final String userId; // Add userId
  final String name; // Add categoryId

  const Students({super.key, required this.userId, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50], // Set background color
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.amber[50], // Set app bar color
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_circle),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<int>>(
          future: getStudents(userId, name), // Fetch students
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No students found.'));
            }

            final students = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40), // Add some space
                Text(
                  'Please choose from one of these students:',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40), // Add some space
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10, // 10 columns
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount:
                        students.length, // Use the number of students fetched
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Navigate to the Awards page with the student number as an argument
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Awards(studentNumber: students[index], name: name),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Box color
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${students[index]}', // Number inside the box
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber, // Amber-colored text
                              ),
                            ),
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
      ),
    );
  }

  // Method to fetch students for a specific category
  Future<List<int>> getStudents(String userId, String categoryName) async {
    FirestoreService firestoreService = FirestoreService();

    // Query Firestore to get the students for the specified category
    List<Map<String, dynamic>> studentDocuments =
        await firestoreService.getStudentsByCategory(userId, categoryName);

    // Extract and return the 'number' field from each document
    return studentDocuments.map((doc) => doc['number'] as int).toList();
  }

}
