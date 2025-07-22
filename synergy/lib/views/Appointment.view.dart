import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Added for proper date formatting

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String? selectedType;
  DateTime? selectedDate;
  String? selectedPatientId; // For doctor to select patient
  String? doctorId; // For patient to know their doctor
  final List<Map<String, dynamic>> _patients = []; // For doctor's patient list
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole; // Store user role

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Replace your _loadUserData method with this:
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userUid = prefs.getString('user_uid');
      final token = prefs.getString('auth_token');

      if (userUid == null || token == null) {
        throw Exception('No authenticated user');
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] as String?;

      if (!mounted) return;
      setState(() {
        _userRole = role;
      });

      if (role == 'Doctor') {
        final List<String> assignedPatientIds = List<String>.from(
          userData['assignedPatients'] ?? [],
        );

        if (assignedPatientIds.isNotEmpty) {
          List<Map<String, dynamic>> patientsList = [];
          for (String patientId in assignedPatientIds) {
            try {
              final patientDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(patientId)
                      .get();
              if (patientDoc.exists) {
                final patientData = patientDoc.data() as Map<String, dynamic>;
                patientsList.add({
                  'patientId': patientId,
                  'name': patientData['fullName'] ?? 'Unknown Patient',
                  'email': patientData['email'] ?? 'No email',
                  'role': patientData['role'] ?? 'Unknown',
                });
              }
            } catch (e) {
              print('Error fetching patient $patientId: $e');
            }
          }
          if (!mounted) return;
          setState(() {
            _patients.clear();
            _patients.addAll(patientsList);
            selectedPatientId =
                _patients.isNotEmpty ? _patients.first['patientId'] : null;
          });
        }
      } else if (role == 'Patient') {
        final List<String> assignedDoctorIds = List<String>.from(
          userData['assignedDoctors'] ?? [],
        );
        String? foundDoctorId;
        if (assignedDoctorIds.isNotEmpty) {
          foundDoctorId = assignedDoctorIds.first;
        }
        if (!mounted) return;
        setState(() {
          doctorId = foundDoctorId;
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    final prefs = await SharedPreferences.getInstance();
    final userUid = prefs.getString('user_uid');

    if ((selectedType == null || selectedDate == null) ||
        (userUid == null) ||
        (_userRole == 'Doctor' && selectedPatientId == null) ||
        (_userRole == 'Patient' && doctorId == null)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _userRole == 'Patient' && doctorId == null
                ? 'No doctor assigned. Please contact support.'
                : 'Please select all details',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final role = _userRole!;
      final userEmail = prefs.getString('user_email') ?? 'Unknown';

      String receiverId = '';
      String receiverEmail = '';
      String senderEmail = userEmail;
      String appointmentDetails;
      String finalDoctorId = '';
      String finalPatientId = '';

      if (role == 'Doctor') {
        final patientDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(selectedPatientId)
                .get();
        if (!patientDoc.exists) throw Exception('Patient not found');
        receiverId = selectedPatientId!;
        receiverEmail = patientDoc.data()?['email'] as String? ?? 'Unknown';
        finalDoctorId = userUid;
        finalPatientId = selectedPatientId!;
        appointmentDetails =
            'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)} • Type: $selectedType • Doctor: $senderEmail • Patient: $receiverEmail';
      } else {
        if (doctorId == null) throw Exception('No doctor assigned');
        final doctorDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(doctorId)
                .get();
        if (!doctorDoc.exists) throw Exception('Doctor not found');
        receiverId = doctorId!;
        receiverEmail = doctorDoc.data()?['email'] as String? ?? 'Unknown';
        finalDoctorId = doctorId!;
        finalPatientId = userUid;
        appointmentDetails =
            'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)} • Type: $selectedType • Patient: $senderEmail • Doctor: $receiverEmail';
      }

      // Store date consistently without timezone conversion
      final appointmentData = {
        'doctorId': finalDoctorId,
        'patientId': finalPatientId,
        'type': selectedType,
        'date': DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDate!), // Consistent formatting
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userUid,
        'details': appointmentDetails,
        'isDoctorCreated': _userRole == 'Doctor',
      };

      print(
        'Saving appointment with date: ${appointmentData['date']}',
      ); // Debug print

      final docRef = await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);

      final notificationData = {
        'senderId': userUid,
        'receiverId': receiverId,
        'senderEmail': senderEmail,
        'receiverEmail': receiverEmail,
        'type': 'appointment',
        'title': 'New Appointment Scheduled',
        'message': appointmentDetails,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      _sendEmailNotification(receiverEmail, appointmentDetails);

      if (!mounted) return;
      setState(() {
        selectedType = null;
        selectedDate = null;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Color(0xFFff6b9d),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error booking appointment: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking appointment: $e')));
    }
  }

  // Replace your _rescheduleAppointment method with this:
  Future<void> _rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
  ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final appointmentDoc =
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .get();
      if (!appointmentDoc.exists) throw Exception('Appointment not found');
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final doctorId = appointmentData['doctorId'] as String;
      final patientId = appointmentData['patientId'] as String;
      final type = appointmentData['type'] as String;

      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? 'Unknown';

      final doctorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(doctorId)
              .get();
      final patientDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();

      final doctorEmail = doctorDoc.data()?['email'] as String? ?? 'Unknown';
      final patientEmail = patientDoc.data()?['email'] as String? ?? 'Unknown';

      final appointmentDetails =
          'Date: ${newDate.toString().split(' ')[0]} • Type: $type • Doctor: $doctorEmail • Patient: $patientEmail';

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'date': DateFormat('yyyy-MM-dd').format(newDate),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      final notificationData = {
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'receiverId': _userRole == 'Doctor' ? patientId : doctorId,
        'senderEmail': userEmail,
        'receiverEmail': _userRole == 'Doctor' ? patientEmail : doctorEmail,
        'type': 'appointment',
        'title': 'Appointment Rescheduled',
        'message': appointmentDetails,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      _sendEmailNotification(
        _userRole == 'Doctor' ? patientEmail : doctorEmail,
        appointmentDetails,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment rescheduled successfully!'),
          backgroundColor: Color(0xFFff6b9d),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error rescheduling appointment: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rescheduling appointment: $e')),
      );
    }
  }

  void _sendEmailNotification(String receiverEmail, String details) {
    print('Sending email to $receiverEmail with details: $details');
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Replace your _getAppointmentsStream method with this:
  Stream<QuerySnapshot> _getAppointmentsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No current user found');
      return const Stream.empty();
    }

    // Use local time consistently, not UTC
    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);
    print('=== APPOINTMENTS QUERY DEBUG ===');
    print('Today string for query: $todayString');
    print('Querying appointments for user: ${currentUser.uid}');
    print('User role: $_userRole');

    if (_userRole == null) {
      print('User role is null, waiting...');
      return const Stream.empty();
    }

    Query query;

    if (_userRole == 'Doctor') {
      print('Setting up doctor query for doctorId: ${currentUser.uid}');
      query = FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: currentUser.uid);
    } else if (_userRole == 'Patient') {
      print('Setting up patient query for patientId: ${currentUser.uid}');
      query = FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: currentUser.uid);
    } else {
      print('Invalid user role: $_userRole');
      return const Stream.empty();
    }

    // For now, let's remove the date filter to see if we get any results
    print('Executing query without date filter first...');
    return query
        .snapshots()
        .map((snapshot) {
          print('Raw query returned ${snapshot.docs.length} documents');
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            print(
              'Document ${doc.id}: date=${data['date']}, type=${data['type']}, doctorId=${data['doctorId']}, patientId=${data['patientId']}',
            );
          }

          // Now filter by date in code
          final filteredDocs =
              snapshot.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docDate = data['date'] as String?;
                if (docDate == null) return false;

                final comparison = docDate.compareTo(todayString);
                print(
                  'Date comparison: $docDate >= $todayString = ${comparison >= 0}',
                );
                return comparison >= 0;
              }).toList();

          print('After date filtering: ${filteredDocs.length} documents');

          // Create a new QuerySnapshot-like object (we'll modify this approach)
          return snapshot;
        })
        .handleError((error) {
          print('Appointments query error: $error');
          return const Stream.empty();
        });
  }

  List<Map<String, dynamic>> _filterAndSortAppointments(
    List<QueryDocumentSnapshot> docs,
  ) {
    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);

    final appointments =
        docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {...data, 'id': doc.id};
            })
            .where((appointment) {
              final docDate = appointment['date'] as String?;
              if (docDate == null) return false;
              return docDate.compareTo(todayString) >= 0;
            })
            .toList();

    // Sort by date
    appointments.sort((a, b) {
      final dateA = a['date'] as String? ?? '';
      final dateB = b['date'] as String? ?? '';
      return dateA.compareTo(dateB);
    });

    return appointments;
  }

  // Also update your _bookAppointment method to ensure consistent date formatting:
  // Replace your _buildAppointmentCard method with this:
  Future<Widget> _buildAppointmentCard(Map<String, dynamic> appointment) async {
    final date = appointment['date'] as String? ?? 'Unknown Date';
    final type = appointment['type'] as String? ?? 'Unknown Type';
    final doctorId = appointment['doctorId'] as String? ?? '';
    final patientId = appointment['patientId'] as String? ?? '';
    final appointmentId = appointment['id'] as String;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    String doctorName = 'Unknown Doctor';
    String doctorEmail = '';
    if (doctorId.isNotEmpty) {
      try {
        final doctorDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(doctorId)
                .get();
        if (doctorDoc.exists) {
          final doctorData = doctorDoc.data() as Map<String, dynamic>;
          doctorName = doctorData['fullName'] as String? ?? 'Unknown Doctor';
          doctorEmail = doctorData['email'] as String? ?? '';
        }
      } catch (e) {
        print('Error fetching doctor data: $e');
      }
    }

    String patientName = 'Unknown Patient';
    String patientEmail = '';
    if (patientId.isNotEmpty) {
      try {
        final patientDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(patientId)
                .get();
        if (patientDoc.exists) {
          final patientData = patientDoc.data() as Map<String, dynamic>;
          patientName = patientData['fullName'] as String? ?? 'Unknown Patient';
          patientEmail = patientData['email'] as String? ?? '';
        }
      } catch (e) {
        print('Error fetching patient data: $e');
      }
    }

    // Determine what to display based on current user role
    String displayName = '';
    String displayRole = '';
    String displayEmail = '';
    String appointmentCreatedBy = '';

    if (_userRole == 'Doctor') {
      // Doctor sees patient info
      displayName = patientName;
      displayRole = 'Patient';
      displayEmail = patientEmail;
      appointmentCreatedBy =
          currentUserId == doctorId
              ? 'You scheduled this'
              : 'Patient requested this';
    } else {
      // Patient sees doctor info
      displayName = doctorName;
      displayRole = 'Doctor';
      displayEmail = doctorEmail;
      appointmentCreatedBy =
          currentUserId == patientId
              ? 'You requested this'
              : 'Doctor scheduled this';
    }
    // In your _buildAppointmentCard method, modify the appointmentCreatedBy logic:

    if (appointment['createdBy'] == currentUserId) {
      appointmentCreatedBy = 'You created this';
    } else if (_userRole == 'Doctor' &&
        appointment['patientId'] == currentUserId) {
      appointmentCreatedBy = 'Patient created this';
    } else if (_userRole == 'Patient' &&
        appointment['doctorId'] == currentUserId) {
      appointmentCreatedBy = 'Doctor created this';
    } else {
      appointmentCreatedBy = 'Created by another user';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          left: BorderSide(color: Color(0xFFff6b9d), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$type - $date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$displayRole: $displayName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.5,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayEmail.isNotEmpty)
                      Text(
                        'Email: $displayEmail',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          height: 1.3,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      appointmentCreatedBy,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            appointmentCreatedBy.contains('You')
                                ? Colors.blue
                                : Colors.green,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _buildPrimaryButton('Reschedule', () async {
              final DateTime? newDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (newDate != null) {
                await _rescheduleAppointment(appointmentId, newDate);
              }
            }, width: 120),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFffeef8), Color(0xFFf8f0ff), Color(0xFFe8f5ff)],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFffeef8), Color(0xFFf8f0ff), Color(0xFFe8f5ff)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadUserData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFffeef8), Color(0xFFf8f0ff), Color(0xFFe8f5ff)],
          ),
        ),
        child: Column(
          children: [
            _buildStatusBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAppointmentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('StreamBuilder error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error loading appointments: ${snapshot.error}'),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final appointmentDocs = snapshot.data?.docs ?? [];
                  print(
                    'StreamBuilder received ${appointmentDocs.length} appointments',
                  );

                  // Use our custom filtering method
                  final appointmentsFromDb = _filterAndSortAppointments(
                    appointmentDocs,
                  );
                  print(
                    'After filtering: ${appointmentsFromDb.length} appointments',
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        _buildContent(appointmentsFromDb),
                      ],
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

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '00:34',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            '🔋 100%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Appointments & Screening',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your health schedule',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'SF Pro Display',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(top: 60, left: 20, child: _buildBackButton(context)),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/dashboard'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> appointmentsFromDb) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),

          if (appointmentsFromDb.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 25,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'No upcoming appointments scheduled.',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...appointmentsFromDb.map(
              (appointment) => FutureBuilder<Widget>(
                future: _buildAppointmentCard(appointment),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return snapshot.data ?? const SizedBox.shrink();
                },
              ),
            ),

          const SizedBox(height: 20),
          const Text(
            'Schedule New Appointment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                if (_userRole == 'Doctor' && _patients.isNotEmpty)
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: selectedPatientId,
                        hint: const Text('Select Patient'),
                        items:
                            _patients.map((patient) {
                              return DropdownMenuItem<String>(
                                value: patient['patientId'],
                                child: Text(
                                  patient['name'] ?? 'Unknown Patient',
                                  style: const TextStyle(
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPatientId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                else if (_userRole == 'Doctor' && _patients.isEmpty)
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'No patients assigned yet. Add patients to schedule appointments.',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                else if (_userRole == 'Patient')
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          doctorId != null
                              ? 'Booking appointment with your assigned doctor'
                              : 'No doctor assigned. Please contact support.',
                          style: TextStyle(
                            color: doctorId != null ? Colors.blue : Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: selectedType,
                  hint: const Text('Select Appointment Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pap Smear',
                      child: Text(
                        'Pap Smear',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Ultrasound',
                      child: Text(
                        'Ultrasound',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'HPV Test',
                      child: Text(
                        'HPV Test',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : selectedDate!.toString().split(' ')[0],
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            selectedDate == null
                                ? const Color(0xFF333333)
                                : const Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton('Book Appointment', _bookAppointment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
    String text,
    VoidCallback onPressed, {
    double? width,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff6b9d), Color(0xFFc44cff)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFff6b9d).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }
}
