import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CervicalScreen extends StatefulWidget {
  const CervicalScreen({super.key});

  @override
  State<CervicalScreen> createState() => _CervicalScreenState();
}

class _CervicalScreenState extends State<CervicalScreen> {
  bool _isFormVisible = true;
  bool _isInitialQuestionVisible = true;
  bool _hasDoneTest = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for test form
  final _ageController = TextEditingController();
  final _sexualPartnersController = TextEditingController();
  final _firstSexualActivityAgeController = TextEditingController();
  final _hpvResultController = TextEditingController();
  final _papSmearResultController = TextEditingController();
  final _smokingStatusController = TextEditingController();
  final _stdsHistoryController = TextEditingController();
  final _screeningTypeController = TextEditingController();

  // Controllers for no-test form
  final _noTestAgeController = TextEditingController();
  final _noTestSexualPartnersController = TextEditingController();
  final _noTestAgeFirstSexController = TextEditingController();
  final _noTestSmokingController = TextEditingController();
  final _noTestMenopauseController = TextEditingController();
  final _noTestFamilyCancerController = TextEditingController();
  final _noTestPreviousStdsController = TextEditingController();
  final _noTestHivStatusController = TextEditingController();
  final _noTestImmuneDrugsController = TextEditingController();
  final _noTestExerciseFrequencyController = TextEditingController();
  final _noTestDietQualityController = TextEditingController();
  final _noTestAlcoholConsumptionController = TextEditingController();
  final _noTestStressLevelController = TextEditingController();
  final _noTestSleepQualityController = TextEditingController();
  final _noTestContraceptiveUseController = TextEditingController();
  final _noTestHpvVaccinationController = TextEditingController();

  final Map<String, bool> _symptoms = {
    'bleeding_between_periods': false,
    'bleeding_after_sex': false,
    'bleeding_after_menopause': false,
    'periods_heavier': false,
    'periods_longer': false,
    'unusual_discharge': false,
    'discharge_smells_bad': false,
    'discharge_color_change': false,
    'pain_during_sex': false,
    'pelvic_pain': false,
    'painful_urination': false,
    'blood_in_urine': false,
    'frequent_urination': false,
    'rectal_bleeding': false,
    'painful_bowel': false,
    'weight_loss': false,
    'tiredness': false,
    'leg_swelling': false,
    'back_pain': false,
  };

  Map<String, dynamic>? _currentResponse;
  String? _patientName;
  String? _token;
  String? _userUid;

  @override
  void initState() {
    super.initState();
    _getPatientName();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userUid = prefs.getString('user_uid');
    if (_token == null || _userUid == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else {
      setState(() {});
      _loadSavedData();
    }
  }

  void _getPatientName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null && mounted) {
      setState(() {
        _patientName = user.email!.split('@')[0];
      });
    }
  }

  Future<void> _loadSavedData() async {
    if (_userUid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('cervical_screening')
              .doc(_userUid)
              .get();
      if (doc.exists && mounted) {
        setState(() {
          _currentResponse =
              doc.data()?['api_response'] as Map<String, dynamic>?;
          _isFormVisible = _currentResponse == null;
          _isInitialQuestionVisible = _currentResponse == null;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _submitTestForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_userUid == null || _token == null) {
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final patientId = 'P${_userUid!.substring(0, 4).padLeft(4, '0')}';
    final data = {
      "age": int.parse(_ageController.text),
      "sexual_partners": int.parse(_sexualPartnersController.text),
      "first_sexual_activity_age": int.parse(
        _firstSexualActivityAgeController.text,
      ),
      "hpv_result": _hpvResultController.text,
      "pap_smear_result": _papSmearResultController.text,
      "smoking_status": _smokingStatusController.text,
      "stds_history": _stdsHistoryController.text,
      "screening_type_last": _screeningTypeController.text,
    };

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/cervical_recommendation'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isFormVisible = false;
            _isInitialQuestionVisible = false;
            _currentResponse = responseData;
          });

          await FirebaseFirestore.instance
              .collection('cervical_screening')
              .doc(_userUid)
              .set({
                'user_uid': _userUid,
                'patient_id': patientId,
                'patient_name': _patientName ?? 'Unknown',
                'form_data': data,
                'api_response': responseData,
                'has_previous_test': true,
                'timestamp': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analysis complete!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentResponse = {'next_steps': 'Error submitting data: $e'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitNoTestForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_userUid == null || _token == null) {
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final patientId = 'P${_userUid!.substring(0, 4).padLeft(4, '0')}';
    final data = {
      "patient_info": {
        "age": int.parse(_noTestAgeController.text),
        "sexual_partners": int.parse(_noTestSexualPartnersController.text),
        "age_first_sex": int.parse(_noTestAgeFirstSexController.text),
        "smoking": _noTestSmokingController.text,
        "menopause_status": _noTestMenopauseController.text,
      },
      "medical_history": {
        "family_cancer_history": _noTestFamilyCancerController.text,
        "previous_stds": _noTestPreviousStdsController.text,
        "hiv_status": _noTestHivStatusController.text,
        "taking_immune_drugs": _noTestImmuneDrugsController.text,
        "had_pap_test": "No",
        "had_hpv_test": "No",
        "last_screening": "Never",
      },
      "lifestyle": {
        "exercise_frequency": _noTestExerciseFrequencyController.text,
        "diet_quality": _noTestDietQualityController.text,
        "alcohol_consumption": _noTestAlcoholConsumptionController.text,
        "stress_level": _noTestStressLevelController.text,
        "sleep_quality": _noTestSleepQualityController.text,
        "contraceptive_use": _noTestContraceptiveUseController.text,
        "hpv_vaccination": _noTestHpvVaccinationController.text,
      },
      "bleeding_symptoms": {
        "bleeding_between_periods":
            _symptoms['bleeding_between_periods']! ? "Yes" : "No",
        "bleeding_after_sex": _symptoms['bleeding_after_sex']! ? "Yes" : "No",
        "bleeding_after_menopause":
            _symptoms['bleeding_after_menopause']! ? "Yes" : "No",
        "periods_heavier_than_before":
            _symptoms['periods_heavier']! ? "Yes" : "No",
        "periods_longer_than_before":
            _symptoms['periods_longer']! ? "Yes" : "No",
      },
      "other_symptoms": {
        "unusual_discharge": _symptoms['unusual_discharge']! ? "Yes" : "No",
        "discharge_smells_bad":
            _symptoms['discharge_smells_bad']! ? "Yes" : "No",
        "discharge_color_change":
            _symptoms['discharge_color_change']! ? "Yes" : "No",
        "pain_during_sex": _symptoms['pain_during_sex']! ? "Yes" : "No",
        "pelvic_pain": _symptoms['pelvic_pain']! ? "Yes" : "No",
        "painful_urination": _symptoms['painful_urination']! ? "Yes" : "No",
        "blood_in_urine": _symptoms['blood_in_urine']! ? "Yes" : "No",
        "frequent_urination": _symptoms['frequent_urination']! ? "Yes" : "No",
        "rectal_bleeding": _symptoms['rectal_bleeding']! ? "Yes" : "No",
        "painful_bowel_movements": _symptoms['painful_bowel']! ? "Yes" : "No",
      },
      "general_symptoms": {
        "unexplained_weight_loss": _symptoms['weight_loss']! ? "Yes" : "No",
        "constant_tiredness": _symptoms['tiredness']! ? "Yes" : "No",
        "leg_swelling": _symptoms['leg_swelling']! ? "Yes" : "No",
        "back_pain": _symptoms['back_pain']! ? "Yes" : "No",
      },
    };

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/cervical_risk_assessment'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isFormVisible = false;
            _isInitialQuestionVisible = false;
            _currentResponse = responseData;
          });

          await FirebaseFirestore.instance
              .collection('cervical_screening')
              .doc(_userUid)
              .set({
                'user_uid': _userUid,
                'patient_id': patientId,
                'patient_name': _patientName ?? 'Unknown',
                'form_data': data,
                'api_response': responseData,
                'has_previous_test': false,
                'timestamp': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analysis complete!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentResponse = {'next_steps': 'Error submitting data: $e'};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAnotherForm() {
    setState(() {
      _isFormVisible = true;
      _isInitialQuestionVisible = true;
      _hasDoneTest = false;
      _currentResponse = null;
      _ageController.clear();
      _sexualPartnersController.clear();
      _firstSexualActivityAgeController.clear();
      _hpvResultController.clear();
      _papSmearResultController.clear();
      _smokingStatusController.clear();
      _stdsHistoryController.clear();
      _screeningTypeController.clear();
      _noTestAgeController.clear();
      _noTestSexualPartnersController.clear();
      _noTestAgeFirstSexController.clear();
      _noTestSmokingController.clear();
      _noTestMenopauseController.clear();
      _noTestFamilyCancerController.clear();
      _noTestPreviousStdsController.clear();
      _noTestHivStatusController.clear();
      _noTestImmuneDrugsController.clear();
      _noTestExerciseFrequencyController.clear();
      _noTestDietQualityController.clear();
      _noTestAlcoholConsumptionController.clear();
      _noTestStressLevelController.clear();
      _noTestSleepQualityController.clear();
      _noTestContraceptiveUseController.clear();
      _noTestHpvVaccinationController.clear();
      _symptoms.updateAll((key, value) => false);
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _sexualPartnersController.dispose();
    _firstSexualActivityAgeController.dispose();
    _hpvResultController.dispose();
    _papSmearResultController.dispose();
    _smokingStatusController.dispose();
    _stdsHistoryController.dispose();
    _screeningTypeController.dispose();
    _noTestAgeController.dispose();
    _noTestSexualPartnersController.dispose();
    _noTestAgeFirstSexController.dispose();
    _noTestSmokingController.dispose();
    _noTestMenopauseController.dispose();
    _noTestFamilyCancerController.dispose();
    _noTestPreviousStdsController.dispose();
    _noTestHivStatusController.dispose();
    _noTestImmuneDrugsController.dispose();
    _noTestExerciseFrequencyController.dispose();
    _noTestDietQualityController.dispose();
    _noTestAlcoholConsumptionController.dispose();
    _noTestStressLevelController.dispose();
    _noTestSleepQualityController.dispose();
    _noTestContraceptiveUseController.dispose();
    _noTestHpvVaccinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    if (_isFormVisible && _isInitialQuestionVisible)
                      _buildInitialQuestion(),
                    if (_isFormVisible && !_isInitialQuestionVisible)
                      _hasDoneTest ? _buildTestForm() : _buildNoTestForm(),
                    if (!_isFormVisible && _currentResponse != null)
                      _buildContent(),
                    if (!_isFormVisible)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: _showAnotherForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFff6b9d),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Fill Another Form',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
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
        children: [
          const Text(
            '20:35', // Updated to current time (08:35 PM EAT)
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const Text(
            '🔋 100%',
            style: TextStyle(
              fontSize: 15,
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
          colors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
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
              children: [
                Text(
                  'Cervical Health - ${_patientName ?? 'Loading...'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Risk Assessment & Recommendations',
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

  Widget _buildInitialQuestion() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Have you had a cervical cancer screening test before?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please select an option below to continue:',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasDoneTest = true;
                        _isInitialQuestionVisible = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFff6b9d),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Yes, I have',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasDoneTest = false;
                        _isInitialQuestionVisible = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'No, never',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1C2526),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cervical Health Screening Form',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please provide details about your previous screening and health history.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Age',
                  _ageController,
                  'Enter your age (e.g., 30)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Number of Sexual Partners',
                  _sexualPartnersController,
                  'Enter number (e.g., 2)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Age of First Sexual Activity',
                  _firstSexualActivityAgeController,
                  'Enter age (e.g., 20)',
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownField('HPV Test Result', _hpvResultController, [
                  'Positive',
                  'Negative',
                  'Unknown',
                ], 'Select HPV result'),
                _buildDropdownField(
                  'Pap Smear Result',
                  _papSmearResultController,
                  ['Positive', 'Negative', 'Unknown'],
                  'Select Pap smear result',
                ),
                _buildDropdownField(
                  'Smoking Status',
                  _smokingStatusController,
                  ['Yes', 'No'],
                  'Do you smoke?',
                ),
                _buildDropdownField('History of STDs', _stdsHistoryController, [
                  'Yes',
                  'No',
                ], 'Any history of STDs?'),
                _buildDropdownField(
                  'Last Screening Type',
                  _screeningTypeController,
                  ['Pap Smear', 'HPV Test', 'Both'],
                  'What was your last screening?',
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitTestForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff6b9d),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTestForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cervical Health Risk Assessment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please answer the following questions about your health and lifestyle.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildTextField(
                  'Age',
                  _noTestAgeController,
                  'Enter your age (e.g., 30)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Number of Sexual Partners',
                  _noTestSexualPartnersController,
                  'Enter number (e.g., 2)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Age of First Sexual Activity',
                  _noTestAgeFirstSexController,
                  'Enter age (e.g., 20)',
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownField(
                  'Smoking Status',
                  _noTestSmokingController,
                  ['Yes', 'No'],
                  'Do you smoke?',
                ),
                _buildDropdownField(
                  'Menopause Status',
                  _noTestMenopauseController,
                  ['Yes', 'No'],
                  'Have you reached menopause?',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Medical History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildDropdownField(
                  'Family Cancer History',
                  _noTestFamilyCancerController,
                  ['Yes', 'No'],
                  'Any family history of cancer?',
                ),
                _buildDropdownField(
                  'Previous STDs',
                  _noTestPreviousStdsController,
                  ['Yes', 'No'],
                  'Any history of STDs?',
                ),
                _buildDropdownField(
                  'HIV Status',
                  _noTestHivStatusController,
                  ['Positive', 'Negative', 'Unknown'],
                  'What is your HIV status?',
                ),
                _buildDropdownField(
                  'Taking Immune Drugs',
                  _noTestImmuneDrugsController,
                  ['Yes', 'No'],
                  'Are you taking immune-suppressing drugs?',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lifestyle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildDropdownField(
                  'Exercise Frequency',
                  _noTestExerciseFrequencyController,
                  ['Regularly', 'Occasionally', 'Rarely', 'Never'],
                  'How often do you exercise?',
                ),
                _buildDropdownField(
                  'Diet Quality',
                  _noTestDietQualityController,
                  ['Good', 'Average', 'Poor'],
                  'How would you rate your diet?',
                ),
                _buildDropdownField(
                  'Alcohol Consumption',
                  _noTestAlcoholConsumptionController,
                  ['None', 'Light', 'Moderate', 'Heavy'],
                  'How much alcohol do you consume?',
                ),
                _buildDropdownField(
                  'Stress Level',
                  _noTestStressLevelController,
                  ['Low', 'Moderate', 'High'],
                  'How would you rate your stress level?',
                ),
                _buildDropdownField(
                  'Sleep Quality',
                  _noTestSleepQualityController,
                  ['Good', 'Average', 'Poor'],
                  'How would you rate your sleep quality?',
                ),
                _buildDropdownField(
                  'Contraceptive Use',
                  _noTestContraceptiveUseController,
                  ['None', 'Condoms', 'Pills', 'IUD', 'Other'],
                  'What contraceptive do you use?',
                ),
                _buildDropdownField(
                  'HPV Vaccination',
                  _noTestHpvVaccinationController,
                  ['Yes', 'No'],
                  'Have you had HPV vaccination?',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Symptoms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Select any symptoms you are experiencing by tapping them:',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 10),
                _buildSymptomChecklist(),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitNoTestForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFff6b9d),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: _hasDoneTest ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: _hasDoneTest ? Colors.white70 : Colors.black54,
          ),
          hintStyle: TextStyle(
            color: _hasDoneTest ? Colors.white70 : Colors.black54,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _hasDoneTest ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (keyboardType == TextInputType.number &&
              int.tryParse(value) == null)
            return '$label must be a number';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<String> options,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        dropdownColor: _hasDoneTest ? const Color(0xFF1C2526) : Colors.white,
        style: TextStyle(color: _hasDoneTest ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: _hasDoneTest ? Colors.white70 : Colors.black54,
          ),
          hintStyle: TextStyle(
            color: _hasDoneTest ? Colors.white70 : Colors.black54,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _hasDoneTest ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        value: controller.text.isEmpty ? null : controller.text,
        items:
            options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: _hasDoneTest ? Colors.white : Colors.black,
                  ),
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
          }
        },
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildSymptomChecklist() {
    final symptomLabels = {
      'bleeding_between_periods': 'Bleeding between periods',
      'bleeding_after_sex': 'Bleeding after sex',
      'bleeding_after_menopause': 'Bleeding after menopause',
      'periods_heavier': 'Heavier periods than usual',
      'periods_longer': 'Longer periods than usual',
      'unusual_discharge': 'Unusual vaginal discharge',
      'discharge_smells_bad': 'Discharge with bad smell',
      'discharge_color_change': 'Discharge color change',
      'pain_during_sex': 'Pain during sex',
      'pelvic_pain': 'Pelvic pain',
      'painful_urination': 'Painful urination',
      'blood_in_urine': 'Blood in urine',
      'frequent_urination': 'Frequent urination',
      'rectal_bleeding': 'Rectal bleeding',
      'painful_bowel': 'Painful bowel movements',
      'weight_loss': 'Unexplained weight loss',
      'tiredness': 'Constant tiredness',
      'leg_swelling': 'Leg swelling',
      'back_pain': 'Back pain',
    };

    return Column(
      children:
          _symptoms.keys.map((key) {
            return CheckboxListTile(
              title: Text(
                symptomLabels[key]!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
              ),
              value: _symptoms[key],
              onChanged: (value) {
                setState(() {
                  _symptoms[key] = value!;
                });
              },
              activeColor: const Color(0xFFff6b9d),
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
    );
  }

  Widget _buildContent() {
    if (_currentResponse == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFff6b9d), Color(0xFFc44569)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Cervical Health Assessment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Generated on ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...(_currentResponse!.entries.map((entry) {
            return _buildResultCard(entry);
          }).toList()),
        ],
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
}
