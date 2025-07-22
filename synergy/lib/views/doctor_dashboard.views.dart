import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synergy/views/Ovarian_results.views.dart';
import 'package:synergy/views/cervical_results.views.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken;
  String? _userUid;

  @override
  void initState() {
    super.initState();
    _loadAuthTokenAndUser();
  }

  Future<void> _loadAuthTokenAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _userUid = prefs.getString('user_uid');

    if (_authToken == null || _userUid == null) {
      setState(() {
        _errorMessage = 'No authenticated doctor';
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithCustomToken(_authToken!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: $e';
        _isLoading = false;
      });
      return;
    }

    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != _userUid) {
        throw Exception('No authenticated user or UID mismatch');
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(currentUser.uid)
              .collection('patients')
              .get();

      setState(() {
        _patients =
            snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching patients: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addPatient(String patientEmail) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != _userUid) {
        throw Exception('No authenticated user or UID mismatch');
      }

      final patientSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: patientEmail.trim())
              .where('role', isEqualTo: 'Patient')
              .limit(1)
              .get();

      if (patientSnapshot.docs.isEmpty) {
        throw Exception(
          'No patient found with this email or user is not a patient',
        );
      }

      final patientDoc = patientSnapshot.docs.first;
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(currentUser.uid)
          .collection('patients')
          .doc(patientDoc.id)
          .set({
            'patientId': patientDoc.id,
            'name': patientDoc['name'],
            'email': patientDoc['email'],
            'addedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _patients.add(patientDoc.data() as Map<String, dynamic>);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient added successfully!'),
          backgroundColor: Color(0xFFff6b9d),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding patient: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removePatient(String patientId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != _userUid) {
        throw Exception('No authenticated user or UID mismatch');
      }

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(currentUser.uid)
          .collection('patients')
          .doc(patientId)
          .delete();

      setState(() {
        _patients.removeWhere((p) => p['patientId'] == patientId);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient removed successfully!'),
          backgroundColor: Color(0xFFff6b9d),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error removing patient: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddPatientDialog() {
    final _patientEmailController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Patient'),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _patientEmailController,
                decoration: const InputDecoration(
                  labelText: 'Patient Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a patient email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    _addPatient(_patientEmailController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Patient'),
              ),
            ],
          ),
    );
  }

  void _showScreeningSelectionDialog(String patientId, String patientName) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Select Screening for $patientName'),
            content: const Text('Which screening data would you like to view?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToCervicalScreen(patientId);
                },
                child: const Text('Cervical Screening'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToOvarianScreen(patientId, patientName);
                },
                child: const Text('Ovarian Screening'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _navigateToCervicalScreen(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final originalToken = _authToken;
      final originalUid = _userUid;

      await prefs.setString('user_uid', patientId);
      final patientDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();

      if (patientDoc.exists && patientDoc.data()!.containsKey('auth_token')) {
        await prefs.setString('auth_token', patientDoc['auth_token']);
      } else {
        throw Exception('Patient auth token not found');
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorCervicalResultsScreen(patientId: patientId),
        ),
      );

      await prefs.setString('auth_token', originalToken ?? '');
      await prefs.setString('user_uid', originalUid ?? '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing patient data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToOvarianScreen(
    String patientId,
    String patientName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final originalToken = _authToken;
      final originalUid = _userUid;

      await prefs.setString('user_uid', patientId);
      final patientDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();

      if (patientDoc.exists && patientDoc.data()!.containsKey('auth_token')) {
        await prefs.setString('auth_token', patientDoc['auth_token']);
      } else {
        throw Exception('Patient auth token not found');
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => DoctorOvarianResultsScreen(
                patientId: patientId,
                patientName: patientName,
              ),
        ),
      );

      await prefs.setString('auth_token', originalToken ?? '');
      await prefs.setString('user_uid', originalUid ?? '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing patient data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFff6b9d),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddPatientDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFff6b9d)),
              )
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : _patients.isEmpty
              ? const Center(child: Text('No patients yet.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFff6b9d),
                        child: Text(
                          (patient['name']?.isNotEmpty ?? false)
                              ? patient['name'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(patient['name'] ?? 'Unknown'),
                      subtitle: Text(patient['email'] ?? 'No email'),
                      onTap:
                          () => _showScreeningSelectionDialog(
                            patient['patientId'],
                            patient['name'] ?? '',
                          ),
                    ),
                  );
                },
              ),
    );
  }
}
