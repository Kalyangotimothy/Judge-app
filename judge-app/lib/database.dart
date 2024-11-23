import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a category
  Future<String> addCategory(String userId, String categoryName, int id) async {
    DocumentReference categoryRef =
        _db.collection('users').doc(userId).collection('categories').doc();

    await categoryRef.set({'name': categoryName, 'id': id});
    return categoryRef.id;
  }

  // Add a student to a category
  Future<void> addStudent(
      String userId, String categoryId, int studentNumber) async {
    // Check if the category already has 100 students
    QuerySnapshot studentSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .collection('students')
        .get();

    if (studentSnapshot.docs.length >= 100) {
      throw Exception('This category already has 100 students.');
    }

    DocumentReference studentRef = _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .collection('students')
        .doc();

    await studentRef.set({'number': studentNumber});
  }

  // Add an award to a student
  Future<void> addAward(String userId, String categoryId, String studentId,
      String awardName, int mark) async {
    DocumentReference awardRef = _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .collection('students')
        .doc(studentId)
        .collection('awards')
        .doc();

    await awardRef.set({
      'name': awardName,
      'mark': mark,
    });
  }

  // Function to get students by category for a specific user
  Future<List<Map<String, dynamic>>> getStudentsByCategory(
      String userId, String categoryName) async {
    try {
      // Get the categories for the specified user that match the given category name
      final categorySnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      List<Map<String, dynamic>> matchingStudents = [];

      // Check if any categories matched
      for (final categoryDoc in categorySnapshot.docs) {
        // Now fetch the students for this specific category
        final studentSnapshot =
            await categoryDoc.reference.collection('students').get();

        // Iterate through each student document in this category
        for (final studentDoc in studentSnapshot.docs) {
          matchingStudents.add(studentDoc.data());
        }
      }

      matchingStudents.sort((a, b) {
        return (a['number'] as int).compareTo(b['number'] as int);
      });

      return matchingStudents; // Return the collected student documents
    } catch (e) {
      print('Error fetching students: $e');
      rethrow; // Rethrow the exception to handle it where this function is called
    }
  }

  // Get categories for a user
  Stream<List<String>> getCategories(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['name'] as String).toList());
  }

  Stream<List<Map<String, dynamic>>> getCategories_2(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ({'name': doc['name']})).toList());
  }

  // Fetch top contestants for a single category
  Future<List<Map<String, dynamic>>> _fetchTopContestantsForCategory(
    String userId,
    String categoryId,
    String categoryName,
  ) async {
    try {
      // Fetch all students in the given category
      final studentsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .collection('students')
          .get();

      List<Map<String, dynamic>> contestants = [];

      // Iterate through each student to get total marks directly from the student document
      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();

        // Calculate total marks from specified fields
        int totalMarks = 0;

        // Loop through all fields in the student data, excluding 'number' (or any other field you want to skip)
        for (var entry in studentData.entries) {
          if (entry.key != 'number') {
            totalMarks += entry.value as int? ??
                0; // Safely add the marks, defaulting to 0 if null
          }
        }

        // Add student data to the contestants list
        contestants.add({
          'number': studentData['number'],
          'totalMarks': totalMarks,
          'category': categoryName,
        });
      }

      // Sort contestants by totalMarks in descending order and return top 5
      contestants.sort((a, b) => b['totalMarks'].compareTo(a['totalMarks']));
      return contestants.take(5).toList();
    } catch (e) {
      print("Error fetching contestants for category $categoryName: $e");
      return [];
    }
  }

  // Fetch top contestants for all categories with parallelization
  Future<List<Map<String, dynamic>>> fetchTopContestantsForAllCategories(
      String userId) async {
    try {
      // Get all categories
      final categoriesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      // Parallel fetching of contestants for each category
      List<Future<List<Map<String, dynamic>>>> futures =
          categoriesSnapshot.docs.map((doc) {
        final categoryName =
            doc['name']; // Ensure we extract category name correctly
        return _fetchTopContestantsForCategory(userId, doc.id, categoryName);
      }).toList();

      // Wait for all results to complete
      List<List<Map<String, dynamic>>> allResults = await Future.wait(futures);

      // Flatten the results into a single list
      return allResults.expand((result) => result).toList();
    } catch (e) {
      print("Error fetching contestants: $e");
      return [];
    }
  }
}
