import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:ionicons/ionicons.dart';

class Awards extends StatefulWidget {
  final int studentNumber;
  final String name;

  const Awards({super.key, required this.studentNumber, required this.name});

  @override
  State<Awards> createState() => _AwardsState();
}

class _AwardsState extends State<Awards> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'Cultural Wear': TextEditingController(),
    'Talent Presentation': TextEditingController(),
    'Creative Wear': TextEditingController(),
    'Gown': TextEditingController(),
    'Q&A': TextEditingController(),
    'Bootcamps': TextEditingController(),
  };

  final Map<String, int> _maxScores = {
    'Cultural Wear': 20,
    'Talent Presentation': 20,
    'Creative Wear': 20,
    'Gown': 20,
    'Q&A': 15,
    'Bootcamps': 5,
  };

  bool _isReviewStep = false; // Track if the first tap has happened

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    _fetchStudentScores();
    super.initState();
  }

  Future<void> _fetchStudentScores() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Retrieve category document reference directly by name
      final categoryQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('name', isEqualTo: widget.name)
          .get();

      if (categoryQuerySnapshot.docs.isEmpty) {
        print('No category found for name: ${widget.name}');
        return;
      }

      final categoryDoc = categoryQuerySnapshot.docs.first;

      // Retrieve the specific student document by its number
      final studentQuerySnapshot = await categoryDoc.reference
          .collection('students')
          .where('number', isEqualTo: widget.studentNumber)
          .get();

      if (studentQuerySnapshot.docs.isEmpty) {
        print('No student found with number: ${widget.studentNumber}');
        return;
      }

      // Use the first matching student document
      final studentDoc = studentQuerySnapshot.docs.first;
      final studentData = studentDoc.data();

      // Prepopulate the controllers with current scores
      _controllers['Cultural Wear']?.text =
          studentData['wear']?.toString() ?? '0';
      _controllers['Talent Presentation']?.text =
          studentData['talent']?.toString() ?? '0';
      _controllers['Creative Wear']?.text =
          studentData['creativity']?.toString() ?? '0';
      _controllers['Gown']?.text = studentData['gown']?.toString() ?? '0';
      _controllers['Q&A']?.text = studentData['qa']?.toString() ?? '0';
      _controllers['Bootcamps']?.text =
          studentData['bootcamps']?.toString() ?? '0';

      setState(() {}); // Update UI to reflect the changes
    } catch (e) {
      print('Error fetching student scores: $e');
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_isReviewStep) {
        // Final submission on the second tap
        print('Scores submitted:');
        _controllers.forEach((key, value) {
          print('$key: ${value.text}');
        });

        // Update scores in Firestore
        try {
          await updateStudentScores(widget.studentNumber.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Scores for Student ${widget.studentNumber} submitted!')),
          );
          Navigator.pop(context); // Return to previous page
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit scores: $e')),
          );
        }
      } else {
        // Show review message on the first tap
        setState(() {
          _isReviewStep = true;
        });
      }
    }
  }

  Future<void> updateStudentScores(String studentId) async {
    try {
      // Prepare the scores data
      final scores = {
        'wear': int.tryParse(_controllers['Cultural Wear']?.text ?? '0') ?? 0,
        'talent':
            int.tryParse(_controllers['Talent Presentation']?.text ?? '0') ?? 0,
        'creativity':
            int.tryParse(_controllers['Creative Wear']?.text ?? '0') ?? 0,
        'gown': int.tryParse(_controllers['Gown']?.text ?? '0') ?? 0,
        'qa': int.tryParse(_controllers['Q&A']?.text ?? '0') ?? 0,
        'bootcamps': int.tryParse(_controllers['Bootcamps']?.text ?? '0') ?? 0,
      };

      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Retrieve category document reference directly by name
      final categoryQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('name', isEqualTo: widget.name)
          .get();

      if (categoryQuerySnapshot.docs.isEmpty) {
        print('No category found for name: ${widget.name}');
        return; // Exit if no category is found
      }

      // Use the first matching category document
      final categoryDoc = categoryQuerySnapshot.docs.first;

      // Retrieve the specific student document by its number
      final studentQuerySnapshot = await categoryDoc.reference
          .collection('students')
          .where('number', isEqualTo: widget.studentNumber)
          .get();

      if (studentQuerySnapshot.docs.isEmpty) {
        print('No student found with number: ${widget.studentNumber}');
        return; // Exit if no student is found
      }

      // Update the student's scores
      final studentDoc = studentQuerySnapshot.docs.first;
      await studentDoc.reference.update(scores);

      print('Scores updated for student ${widget.studentNumber}: $scores');
    } catch (e) {
      print('Error updating scores: $e');
      rethrow; // Rethrow the exception for handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        backgroundColor: Colors.amber[50],
        elevation: 0,
        title: Text(
          'Awards for Contestant ${widget.studentNumber}',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_circle),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Decorative shapes at the top right corner
          Positioned(
            top: -50,
            right: -50,
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Form content
          SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Scores',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._controllers.entries.map((entry) => RewardInputField(
                          label: entry.key,
                          controller: entry.value,
                          maxScore: _maxScores[entry.key]!,
                        )),
                    const SizedBox(height: 16),
                    if (_isReviewStep) // Show the review message if in review step
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Please preview the results above and edit if desired. '
                          'Tap submit again to confirm.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40.0, vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.amber,
                        ),
                        child: Text(
                          _isReviewStep
                              ? 'Confirm Submission'
                              : 'Submit Scores',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RewardInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxScore;

  const RewardInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Form field for user input
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey, // Light grey text color
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 12.0),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a score for $label';
                }
                final score = int.tryParse(value);
                if (score == null || score > maxScore) {
                  return 'Score must be between 0 and $maxScore';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          // Box showing max score
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.amber, // Amber background color
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '/$maxScore',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
