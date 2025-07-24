import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synergy/views/Ovarian_results.views.dart';
import 'package:synergy/views/cervical_results.views.dart';
import 'dart:async';
import 'dart:developer' as developer;

class DoctorDashboardScreens extends StatefulWidget {
  const DoctorDashboardScreens({super.key});

  @override
  State<DoctorDashboardScreens> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreens> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken;
  String? _userUid;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetch();
  }

  // Helper method to safely extract boolean values from Firestore data
  bool _safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  // Helper method to safely extract string values from Firestore data
  String _safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Helper method to safely extract number values from Firestore data
  num _safeNumber(dynamic value, {num defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Helper method to safely extract list values from Firestore data
  List<T> _safeList<T>(dynamic value, {List<T> defaultValue = const []}) {
    if (value == null) return defaultValue;
    if (value is List) {
      return List<T>.from(value);
    }
    return defaultValue;
  }

  // Helper method to safely extract map values from Firestore data
  Map<String, dynamic> _safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Future<void> _loadUserDataAndFetch() async {
    developer.log('Starting _loadUserDataAndFetch', name: 'DoctorDashboard');
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      _userUid = prefs.getString('user_uid');
      _userRole = prefs.getString('user_role');

      developer.log('Loaded token: $_authToken', name: 'DoctorDashboard');
      developer.log('Loaded user UID: $_userUid', name: 'DoctorDashboard');
      developer.log('User role: $_userRole', name: 'DoctorDashboard');

      if (_authToken == null || _userUid == null) {
        developer.log(
          'No auth token or user UID found',
          name: 'DoctorDashboard',
        );
        if (mounted) {
          setState(() {
            _errorMessage = 'No authenticated user found';
            _isLoading = false;
          });
        }
        return;
      }

      if (_userRole != 'Doctor') {
        developer.log(
          'Access denied: User role is not Doctor',
          name: 'DoctorDashboard',
        );
        if (mounted) {
          setState(() {
            _errorMessage =
                'Access denied: Only doctors can access this dashboard';
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch patients directly from Firestore
      await _fetchPatients();
    } catch (e) {
      developer.log(
        'Error in _loadUserDataAndFetch: $e',
        name: 'DoctorDashboard',
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading user data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPatients() async {
    developer.log('Starting _fetchPatients', name: 'DoctorDashboard');
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Fetch doctor's document to get assigned patients
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userUid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              developer.log(
                'Firestore request timed out',
                name: 'DoctorDashboard',
              );
              throw TimeoutException('Firestore request timed out');
            },
          );

      if (!doctorDoc.exists) {
        developer.log(
          'Doctor document does not exist',
          name: 'DoctorDashboard',
        );
        if (mounted) {
          setState(() {
            _errorMessage = 'Doctor profile not found';
            _isLoading = false;
          });
        }
        return;
      }

      final doctorData = _safeMap(doctorDoc.data());
      final List<String> assignedPatients = _safeList<String>(
        doctorData['assignedPatients'],
        defaultValue: <String>[],
      );

      developer.log(
        'Found ${assignedPatients.length} assigned patients',
        name: 'DoctorDashboard',
      );

      if (assignedPatients.isEmpty) {
        if (mounted) {
          setState(() {
            _patients = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch patient details for each assigned patient
      List<Map<String, dynamic>> patientsList = [];

      for (String patientId in assignedPatients) {
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get()
              .timeout(const Duration(seconds: 5));

          if (patientDoc.exists) {
            final patientData = _safeMap(patientDoc.data());

            // Process patient data with safe extraction
            patientsList.add({
              'id': patientId,
              'patientId': patientId,
              'name': _safeString(
                patientData['fullName'],
                defaultValue: 'Unknown',
              ),
              'email': _safeString(
                patientData['email'],
                defaultValue: 'No email',
              ),
              'dateOfBirth': _safeString(
                patientData['dateOfBirth'],
                defaultValue: 'Unknown',
              ),
              'role': _safeString(patientData['role'], defaultValue: 'Unknown'),
              'region': _safeString(
                patientData['region'],
                defaultValue: 'Unknown',
              ),
              'photoUrl': patientData['photoUrl'], // This can be null
              // Add any boolean fields with safe extraction
              'isActive': _safeBool(
                patientData['isActive'],
                defaultValue: true,
              ),
              'hasConsent': _safeBool(
                patientData['hasConsent'],
                defaultValue: false,
              ),
            });
          }
        } catch (e) {
          developer.log(
            'Error fetching patient $patientId: $e',
            name: 'DoctorDashboard',
          );
        }
      }

      if (mounted) {
        setState(() {
          _patients = patientsList;
          _isLoading = false;
        });
      }

      developer.log(
        'Successfully fetched ${patientsList.length} patients',
        name: 'DoctorDashboard',
      );
    } catch (e) {
      developer.log('Error in _fetchPatients: $e', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching patients: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addPatient(String patientEmail) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    developer.log(
      'Starting _addPatient for email: $patientEmail',
      name: 'DoctorDashboard',
    );
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Find patient by email
      final patientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: patientEmail.trim())
          .where('role', isEqualTo: 'Patient')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (patientQuery.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Patient not found or not registered as a patient';
            _isLoading = false;
          });
        }
        return;
      }

      final patientDoc = patientQuery.docs.first;
      final patientId = patientDoc.id;

      // Check if patient is already assigned to this doctor
      final doctorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userUid)
              .get();

      if (doctorDoc.exists) {
        final doctorData = _safeMap(doctorDoc.data());
        final List<String> assignedPatients = _safeList<String>(
          doctorData['assignedPatients'],
          defaultValue: <String>[],
        );

        if (assignedPatients.contains(patientId)) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Patient is already assigned to you';
              _isLoading = false;
            });
          }
          return;
        }

        // Add patient to doctor's assigned patients
        assignedPatients.add(patientId);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userUid)
            .update({'assignedPatients': assignedPatients});

        // Add doctor to patient's assigned doctors
        final patientData = _safeMap(patientDoc.data());
        final List<String> assignedDoctors = _safeList<String>(
          patientData['assignedDoctors'],
          defaultValue: <String>[],
        );
        if (!assignedDoctors.contains(_userUid)) {
          assignedDoctors.add(_userUid!);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .update({'assignedDoctors': assignedDoctors});
        }

        developer.log('Patient added successfully', name: 'DoctorDashboard');

        // Refresh patients list
        await _fetchPatients();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient added successfully!'),
              backgroundColor: Color(0xFFff6b9d),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error in _addPatient: $e', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error adding patient: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removePatient(String patientId) async {
    developer.log(
      'Starting _removePatient for ID: $patientId',
      name: 'DoctorDashboard',
    );
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Remove patient from doctor's assigned patients
      final doctorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userUid)
              .get();

      if (doctorDoc.exists) {
        final doctorData = _safeMap(doctorDoc.data());
        final List<String> assignedPatients = _safeList<String>(
          doctorData['assignedPatients'],
          defaultValue: <String>[],
        );

        assignedPatients.remove(patientId);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userUid)
            .update({'assignedPatients': assignedPatients});

        // Remove doctor from patient's assigned doctors
        final patientDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(patientId)
                .get();

        if (patientDoc.exists) {
          final patientData = _safeMap(patientDoc.data());
          final List<String> assignedDoctors = _safeList<String>(
            patientData['assignedDoctors'],
            defaultValue: <String>[],
          );
          assignedDoctors.remove(_userUid);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .update({'assignedDoctors': assignedDoctors});
        }

        developer.log('Patient removed successfully', name: 'DoctorDashboard');

        // Refresh patients list
        await _fetchPatients();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient removed successfully!'),
              backgroundColor: Color(0xFFff6b9d),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error in _removePatient: $e', name: 'DoctorDashboard');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error removing patient: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearUserData() async {
    developer.log('Clearing user data', name: 'DoctorDashboard');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_uid');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('login_time');
  }

  void _showAddPatientDialog() {
    final patientEmailController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Patient'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: patientEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Email',
                      hintText: 'Enter patient email',
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context);
                    _addPatient(patientEmailController.text);
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

  void _showRemovePatientDialog(String patientId, String patientName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Patient'),
            content: Text(
              'Are you sure you want to remove $patientName from your supervision?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removePatient(patientId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove Patient'),
              ),
            ],
          ),
    );
  }

  void _showScreenSelectionDialog(String patientId, String patientName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Screening Results'),
            content: const Text(
              'Which screening results would you like to view?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              DoctorCervicalResultsScreen(patientId: patientId),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFff6b9d),
                ),
                child: const Text('Cervical Results'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DoctorOvarianResultsScreen(
                            patientId: patientId,
                            patientName: patientName,
                          ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFff6b9d),
                ),
                child: const Text('Ovarian Results'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPatients() {
    if (_searchController.text.isEmpty) {
      return _patients;
    }

    final searchTerm = _searchController.text.toLowerCase();
    return _patients.where((patient) {
      final name = _safeString(patient['name']).toLowerCase();
      final email = _safeString(patient['email']).toLowerCase();
      return name.contains(searchTerm) || email.contains(searchTerm);
    }).toList();
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _clearUserData();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf8f0ff), Color(0xFFe8f5ff), Color(0xFFffeef8)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search patients by name or email...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFFff6b9d)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        // Trigger rebuild to filter patients
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFff6b9d),
                        ),
                      )
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUserDataAndFetch,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : _patients.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_disabled,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No patients assigned yet.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click the "+" button to add your first patient.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _showAddPatientDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFff6b9d),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add Patient'),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredPatients().length,
                        itemBuilder: (context, index) {
                          final patient = _getFilteredPatients()[index];
                          final photoUrl = patient['photoUrl'];
                          final patientName = _safeString(
                            patient['name'],
                            defaultValue: 'Unknown',
                          );

                          return Card(
                            elevation: 6,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFff6b9d),
                                backgroundImage:
                                    (photoUrl != null &&
                                            photoUrl.toString().isNotEmpty)
                                        ? NetworkImage(photoUrl.toString())
                                        : null,
                                child:
                                    (photoUrl == null ||
                                            photoUrl.toString().isEmpty)
                                        ? Text(
                                          patientName.isNotEmpty
                                              ? patientName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        )
                                        : null,
                              ),
                              title: Text(
                                patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _safeString(
                                      patient['email'],
                                      defaultValue: 'No email',
                                    ),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (_safeString(patient['region']) !=
                                          'Unknown' &&
                                      _safeString(patient['region']).isNotEmpty)
                                    Text(
                                      'Region: ${_safeString(patient['region'])}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    _showRemovePatientDialog(
                                      _safeString(patient['id']),
                                      patientName,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'remove',
                                        child: Text('Remove Patient'),
                                      ),
                                    ],
                              ),
                              onTap: () {
                                final patientId = _safeString(patient['id']);
                                final patientName = _safeString(
                                  patient['name'],
                                  defaultValue: 'Unknown',
                                );
                                developer.log(
                                  'Showing screen selection dialog for patient: $patientId',
                                  name: 'DoctorDashboard',
                                );
                                if (patientId.isNotEmpty) {
                                  _showScreenSelectionDialog(
                                    patientId,
                                    patientName,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
