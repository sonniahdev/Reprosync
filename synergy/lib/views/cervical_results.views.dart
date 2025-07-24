import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class DoctorCervicalResultsScreen extends StatefulWidget {
  final String patientId;

  const DoctorCervicalResultsScreen({super.key, required this.patientId});

  @override
  State<DoctorCervicalResultsScreen> createState() =>
      _DoctorCervicalResultsScreenState();
}

class _DoctorCervicalResultsScreenState
    extends State<DoctorCervicalResultsScreen> {
  Map<String, dynamic>? _cervicalData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _patientName;
  String? _authToken;
  String? _userUid;
  String? _userRole;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    developer.log(
      'Initializing DoctorCervicalResultsScreen for patientId: ${widget.patientId}',
      name: 'DoctorCervicalResults',
    );
    _loadUserDataAndFetchCervicalData();
  }

  Future<void> _loadUserDataAndFetchCervicalData() async {
    developer.log(
      'Starting _loadUserDataAndFetchCervicalData for patientId: ${widget.patientId}',
      name: 'DoctorCervicalResults',
    );
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      _userUid = prefs.getString('user_uid');
      _userRole = prefs.getString('user_role');

      developer.log(
        'Loaded - authToken: $_authToken, userUid: $_userUid, userRole: $_userRole',
        name: 'DoctorCervicalResults',
      );

      if (_authToken == null || _userUid == null) {
        setState(() {
          _errorMessage = 'No authenticated user found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      if (_userRole == null || _userRole != 'Doctor') {
        developer.log(
          'Access denied: User role is null or not Doctor',
          name: 'DoctorCervicalResults',
        );
        setState(() {
          _errorMessage =
              'Access denied: Only doctors can view patient results';
          _isLoading = false;
        });
        return;
      }

      await _fetchCervicalData();
      await _fetchMessages();
    } catch (e) {
      developer.log(
        'Error in _loadUserDataAndFetchCervicalData: $e',
        name: 'DoctorCervicalResults',
      );
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  // Alternative approach: Use conversation documents
  Future<void> _fetchMessages() async {
    try {
      // Create a conversation ID that combines patient and doctor IDs
      final conversationId = '${widget.patientId}_$_userUid';

      final messagesQuery =
          await FirebaseFirestore.instance
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .get();

      setState(() {
        _messages =
            messagesQuery.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
      });

      developer.log(
        'Fetched ${_messages.length} messages for conversation $conversationId',
        name: 'DoctorCervicalResults',
      );
    } catch (e) {
      developer.log(
        'Error fetching messages: $e',
        name: 'DoctorCervicalResults',
      );
      setState(() {
        _errorMessage = 'Error loading messages: $e';
      });
    }
  }

  Future<void> _fetchCervicalData() async {
    developer.log(
      'Starting _fetchCervicalData for patientId: ${widget.patientId}',
      name: 'DoctorCervicalResults',
    );
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userUid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doctorDoc.exists) {
        developer.log(
          'Doctor document not found for userUid: $_userUid',
          name: 'DoctorCervicalResults',
        );
        setState(() {
          _errorMessage = 'Doctor profile not found';
          _isLoading = false;
        });
        return;
      }

      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final List<String> assignedPatients = List<String>.from(
        doctorData['assignedPatients'] ?? [],
      );
      developer.log(
        'Assigned patients: $assignedPatients',
        name: 'DoctorCervicalResults',
      );

      if (!assignedPatients.contains(widget.patientId)) {
        developer.log(
          'PatientId ${widget.patientId} not in assignedPatients: $assignedPatients',
          name: 'DoctorCervicalResults',
        );
        setState(() {
          _errorMessage = 'This patient is not assigned to you';
          _isLoading = false;
        });
        return;
      }

      final patientDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.patientId)
              .get();

      if (patientDoc.exists) {
        final patientData = patientDoc.data() as Map<String, dynamic>;
        _patientName = patientData['fullName'] ?? 'Unknown Patient';
        developer.log(
          'Patient name retrieved: $_patientName',
          name: 'DoctorCervicalResults',
        );
      } else {
        developer.log(
          'Patient document not found for patientId: ${widget.patientId}',
          name: 'DoctorCervicalResults',
        );
      }

      final cervicalDoc = await FirebaseFirestore.instance
          .collection('cervical_screening')
          .doc(widget.patientId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (cervicalDoc.exists) {
        final data = cervicalDoc.data();
        developer.log(
          'Cervical data retrieved: $data',
          name: 'DoctorCervicalResults',
        );
        setState(() {
          _cervicalData = data;
          _patientName =
              _cervicalData?['patient_name'] ??
              _patientName ??
              'Unknown Patient';
          _isLoading = false;
        });
      } else {
        developer.log(
          'No cervical screening data found for patientId: ${widget.patientId}',
          name: 'DoctorCervicalResults',
        );
        setState(() {
          _errorMessage = 'No cervical screening data found for this patient.';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Error in _fetchCervicalData: $e',
        name: 'DoctorCervicalResults',
      );
      setState(() {
        _errorMessage = 'Error fetching cervical screening data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _editAndSendBack(Map<String, dynamic> editedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('cervical_screening')
          .doc(widget.patientId)
          .update({
            'form_data': editedData['form_data'],
            'doctor_notes': editedData['doctor_notes'],
            'doctor_edited_timestamp': FieldValue.serverTimestamp(),
          });
      developer.log(
        'Cervical data edited and sent back for patientId: ${widget.patientId}',
        name: 'DoctorCervicalResults',
      );

      // Create a new message with all required fields
      await _createMessage(
        'Your cervical screening data has been updated by your doctor.',
      );

      // Refresh messages after sending
      await _fetchMessages();
    } catch (e) {
      developer.log(
        'Error in _editAndSendBack: $e',
        name: 'DoctorCervicalResults',
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Error sending edited data: $e';
        });
      }
    }
  }

  Future<void> _createMessage(String content) async {
    try {
      final conversationId = '${widget.patientId}_$_userUid';

      // First create/update the conversation document
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set({
            'patientId': widget.patientId,
            'doctorId': _userUid,
            'patientName': _patientName,
            'doctorName': await _getDoctorName(),
            'lastMessageTime': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Then add the message to the subcollection
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
            'content': content,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'senderRole': 'Doctor',
            'senderId': _userUid,
          });
    } catch (e) {
      developer.log(
        'Error creating message: $e',
        name: 'DoctorCervicalResults',
      );
      throw e;
    }
  }

  Future<String> _getDoctorName() async {
    try {
      final doctorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userUid)
              .get();
      return doctorDoc.data()?['fullName'] ?? 'Doctor';
    } catch (e) {
      return 'Doctor';
    }
  }

  void _showEditDialog() {
    if (_cervicalData == null) return;

    final Map<String, dynamic> editedData = Map.from(_cervicalData!);
    final Map<String, dynamic> editedFormData = Map.from(
      _cervicalData!['form_data'] ?? {},
    );

    final TextEditingController _notesController = TextEditingController(
      text: editedData['doctor_notes'] ?? '',
    );
    final TextEditingController _ageController = TextEditingController(
      text: editedFormData['age']?.toString() ?? '',
    );
    final TextEditingController _partnersController = TextEditingController(
      text: editedFormData['sexual_partners']?.toString() ?? '',
    );
    final TextEditingController _firstActivityController =
        TextEditingController(
          text: editedFormData['first_sexual_activity_age']?.toString() ?? '',
        );

    String? hpvResult = editedFormData['hpv_result'];
    String? papResult = editedFormData['pap_smear_result'];
    String? smokingStatus = editedFormData['smoking_status'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Patient Data'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _partnersController,
                      decoration: const InputDecoration(
                        labelText: 'Sexual Partners',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _firstActivityController,
                      decoration: const InputDecoration(
                        labelText: 'First Sexual Activity Age',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: hpvResult,
                      decoration: const InputDecoration(
                        labelText: 'HPV Result',
                      ),
                      items:
                          ['Positive', 'Negative', 'Not Tested'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        hpvResult = newValue;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: papResult,
                      decoration: const InputDecoration(
                        labelText: 'Pap Smear Result',
                      ),
                      items:
                          [
                            'Normal',
                            'Abnormal',
                            'ASCUS',
                            'LSIL',
                            'HSIL',
                            'Not Done',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        papResult = newValue;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: smokingStatus,
                      decoration: const InputDecoration(
                        labelText: 'Smoking Status',
                      ),
                      items:
                          ['Never', 'Former', 'Current'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        smokingStatus = newValue;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Notes',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Update form data
                  editedFormData['age'] =
                      int.tryParse(_ageController.text) ??
                      editedFormData['age'];
                  editedFormData['sexual_partners'] =
                      int.tryParse(_partnersController.text) ??
                      editedFormData['sexual_partners'];
                  editedFormData['first_sexual_activity_age'] =
                      int.tryParse(_firstActivityController.text) ??
                      editedFormData['first_sexual_activity_age'];
                  if (hpvResult != null)
                    editedFormData['hpv_result'] = hpvResult;
                  if (papResult != null)
                    editedFormData['pap_smear_result'] = papResult;
                  if (smokingStatus != null)
                    editedFormData['smoking_status'] = smokingStatus;

                  editedData['form_data'] = editedFormData;
                  editedData['doctor_notes'] = _notesController.text;

                  _editAndSendBack(editedData);
                  Navigator.pop(context);
                  setState(() {
                    _cervicalData = editedData;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save and Send'),
              ),
            ],
          ),
    );
  }

  void _showSendMessageDialog() {
    final TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Send Message to Patient'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final message = _messageController.text.trim();
                  if (message.isEmpty) return;

                  try {
                    await _createMessage(message);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent!'),
                        backgroundColor: Color(0xFFff6b9d),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    await _fetchMessages();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send message: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  void _showMessagesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Messages with ${_patientName ?? "Patient"}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child:
                  _messages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final timestamp = message['timestamp'] as Timestamp?;
                          final isFromDoctor =
                              message['senderRole'] == 'Doctor';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                isFromDoctor
                                    ? Icons.medical_services
                                    : Icons.person,
                                color: const Color(0xFFff6b9d),
                              ),
                              title: Text(
                                isFromDoctor ? 'You (Doctor)' : 'Patient',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message['content'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp != null
                                        ? DateFormat(
                                          'MMM d, h:mm a',
                                        ).format(timestamp.toDate())
                                        : 'Unknown time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  message['read'] == false && !isFromDoctor
                                      ? Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                      : null,
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: _showSendMessageDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('New Message'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cervical Results - ${_patientName ?? "Loading..."}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFff6b9d),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditDialog,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: _showMessagesDialog,
              ),
              if (_messages.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${_messages.where((m) => m['read'] == false && m['senderRole'] != 'Doctor').length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_comment, color: Colors.white),
            onPressed: _showSendMessageDialog,
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
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFff6b9d)),
                )
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserDataAndFetchCervicalData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff6b9d),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_cervicalData == null || _cervicalData!['api_response'] == null) {
      return const Center(
        child: Text(
          'No cervical screening data available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final response = _cervicalData!['api_response'] as Map<String, dynamic>;
    final formData = _cervicalData!['form_data'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Submission Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submitted on: ${_cervicalData!['timestamp'] != null ? (DateTime.fromMillisecondsSinceEpoch(_cervicalData!['timestamp'].millisecondsSinceEpoch).toString().split(' ')[0]) : 'Unknown'}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    (_cervicalData!['has_previous_test'] as bool?) ?? false
                        ? 'Previous Test Data'
                        : 'No Prior Test - Risk Assessment',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (_cervicalData!['doctor_edited_timestamp'] != null)
                    Text(
                      'Last Edited by Doctor: ${DateTime.fromMillisecondsSinceEpoch(_cervicalData!['doctor_edited_timestamp'].millisecondsSinceEpoch).toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.message, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Messages: ${_messages.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Form Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildDataCard('Age', formData['age']?.toString() ?? 'N/A'),
          _buildDataCard(
            'Sexual Partners',
            formData['sexual_partners']?.toString() ?? 'N/A',
          ),
          _buildDataCard(
            'First Sexual Activity Age',
            formData['first_sexual_activity_age']?.toString() ?? 'N/A',
          ),
          if (formData['hpv_result'] != null)
            _buildDataCard('HPV Result', formData['hpv_result']),
          if (formData['pap_smear_result'] != null)
            _buildDataCard('Pap Smear Result', formData['pap_smear_result']),
          if (formData['smoking_status'] != null)
            _buildDataCard('Smoking Status', formData['smoking_status']),
          if (formData['stds_history'] != null)
            _buildDataCard('STDs History', formData['stds_history']),
          if (formData['screening_type_last'] != null)
            _buildDataCard(
              'Last Screening Type',
              formData['screening_type_last'],
            ),
          if (formData.containsKey('patient_info'))
            _buildNestedDataCard('Patient Info', formData['patient_info']),
          if (formData.containsKey('medical_history'))
            _buildNestedDataCard(
              'Medical History',
              formData['medical_history'],
            ),
          if (formData.containsKey('lifestyle'))
            _buildNestedDataCard('Lifestyle', formData['lifestyle']),
          if (formData.containsKey('bleeding_symptoms'))
            _buildNestedDataCard(
              'Bleeding Symptoms',
              formData['bleeding_symptoms'],
            ),
          if (formData.containsKey('other_symptoms'))
            _buildNestedDataCard('Other Symptoms', formData['other_symptoms']),
          if (formData.containsKey('general_symptoms'))
            _buildNestedDataCard(
              'General Symptoms',
              formData['general_symptoms'],
            ),
          if (_cervicalData!['doctor_notes'] != null)
            _buildDataCard('Doctor Notes', _cervicalData!['doctor_notes']),
          const SizedBox(height: 20),
          const Text(
            'Assessment Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ...response.entries.map((entry) => _buildResultCard(entry)).toList(),
        ],
      ),
    );
  }

  Widget _buildDataCard(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          subtitle: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ),
      ),
    );
  }

  Widget _buildNestedDataCard(String title, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                data.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_formatTitle(entry.key)}: ${entry.value.toString()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(MapEntry<String, dynamic> entry) {
    String title = _formatTitle(entry.key);
    IconData icon = _getIconForEntry(entry.key);
    Color accentColor = _getAccentColor(entry.key);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entry.value is String)
                  _buildStringContent(entry.value as String)
                else if (entry.value is num)
                  _buildNumericContent(entry.key, entry.value as num)
                else if (entry.value is List)
                  _buildListContent(entry.value as List)
                else if (entry.value is Map)
                  _buildMapContent(entry.value as Map),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStringContent(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildNumericContent(String key, num value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Score:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(List items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF333333),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildMapContent(Map data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            data.entries
                .map(
                  (subEntry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatTitle(subEntry.key.toString()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            subEntry.value.toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  String _formatTitle(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }

  IconData _getIconForEntry(String key) {
    switch (key.toLowerCase()) {
      case 'risk_score':
      case 'score':
        return Icons.analytics;
      case 'next_steps':
      case 'recommendation':
        return Icons.lightbulb;
      case 'symptom_severity':
      case 'symptoms':
        return Icons.medical_services;
      case 'care_plan':
        return Icons.healing;
      case 'diagnostic_history':
        return Icons.history;
      case 'lifestyle_factors':
        return Icons.fitness_center;
      case 'potential_complications':
        return Icons.warning;
      case 'screening_interval':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  Color _getAccentColor(String key) {
    switch (key.toLowerCase()) {
      case 'risk_score':
      case 'score':
        return Colors.red.shade600;
      case 'next_steps':
      case 'recommendation':
        return Colors.blue.shade600;
      case 'symptom_severity':
      case 'symptoms':
        return Colors.orange.shade600;
      case 'care_plan':
        return Colors.green.shade600;
      case 'diagnostic_history':
        return Colors.purple.shade600;
      case 'lifestyle_factors':
        return Colors.teal.shade600;
      case 'potential_complications':
        return Colors.amber.shade700;
      case 'screening_interval':
        return Colors.indigo.shade600;
      default:
        return const Color(0xFFff6b9d);
    }
  }
}
