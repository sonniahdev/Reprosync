import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OvarianScreen extends StatefulWidget {
  const OvarianScreen({super.key});

  @override
  State<OvarianScreen> createState() => _OvarianScreenState();
}

class _OvarianScreenState extends State<OvarianScreen> {
  bool _isFormVisible = true;
  bool _isInitialQuestionVisible = true;
  bool _hasPreviousTest = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _testFormKey = GlobalKey<FormState>();

  // Controllers for both forms
  // For users who have had tests before
  final _ageController = TextEditingController();
  final _menopauseStatusController = TextEditingController();
  final _cystSizeController = TextEditingController();
  final _ca125LevelController = TextEditingController();
  final _ultrasoundFeaturesController = TextEditingController();
  final _symptomsController = TextEditingController();

  // For users who haven't had tests before
  final _ageNewController = TextEditingController();
  final _cycleLengthController = TextEditingController();
  final _irregularityController = TextEditingController();
  final _pregnancyController = TextEditingController();
  final _menopauseNewController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _pcosController = TextEditingController();
  final _endometriosisController = TextEditingController();
  final _previousCystsController = TextEditingController();
  final _hormoneTherapyController = TextEditingController();
  final _fertilityController = TextEditingController();
  final _surgeryController = TextEditingController();
  final _lastExamController = TextEditingController();
  final _lastUltrasoundController = TextEditingController();
  final _exerciseController = TextEditingController();
  final _dietController = TextEditingController();
  final _stressController = TextEditingController();
  final _sleepController = TextEditingController();
  final _weightController = TextEditingController();
  final _contraceptiveController = TextEditingController();
  final _smokingController = TextEditingController();
  final _pelvicPainController = TextEditingController();
  final _bloatingController = TextEditingController();
  final _fullnessController = TextEditingController();
  final _urinationController = TextEditingController();
  final _bladderController = TextEditingController();
  final _sexPainController = TextEditingController();
  final _irregularPeriodsController = TextEditingController();
  final _heavyPeriodsController = TextEditingController();
  final _painfulPeriodsController = TextEditingController();
  final _spottingController = TextEditingController();
  final _missedPeriodsController = TextEditingController();
  final _breastTendernessController = TextEditingController();
  final _moodController = TextEditingController();
  final _weightGainController = TextEditingController();
  final _acneController = TextEditingController();
  final _hairController = TextEditingController();
  final _nauseaController = TextEditingController();
  final _backPainController = TextEditingController();
  final _legPainController = TextEditingController();
  final _fatigueController = TextEditingController();

  Map<String, dynamic>? _currentResponse;
  String? _patientName;
  String? _authToken;
  String? _userUid;

  @override
  void initState() {
    super.initState();
    _getPatientName();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _userUid = prefs.getString('user_uid');
    if (_authToken == null || _userUid == null) {
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
              .collection('ovarian_screening')
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_userUid == null || _authToken == null) {
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final patientId = 'P${_userUid!.substring(0, 4).padLeft(4, '0')}';
    final data = {
      "age": int.parse(_ageController.text),
      "menopause_status": _menopauseStatusController.text,
      "cyst_size": double.parse(_cystSizeController.text),
      "ca125_level": double.parse(_ca125LevelController.text),
      "ultrasound_features": _ultrasoundFeaturesController.text,
      "symptoms": _symptomsController.text.split(','),
    };

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/ovarian_recommendation'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
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
              .collection('ovarian_screening')
              .doc(_userUid)
              .set({
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
        throw Exception(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
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

  Future<void> _submitNewTestForm() async {
    if (!_testFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_userUid == null || _authToken == null) {
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final patientId = 'P${_userUid!.substring(0, 4).padLeft(4, '0')}';
    final data = {
      "patient_info": {
        "age": int.parse(_ageNewController.text),
        "menstrual_cycle_length": int.parse(_cycleLengthController.text),
        "menstrual_irregularity": _irregularityController.text,
        "pregnancy_history": _pregnancyController.text,
        "menopause_status": _menopauseNewController.text,
        "family_history_ovarian": _familyHistoryController.text,
      },
      "medical_history": {
        "pcos_diagnosis": _pcosController.text,
        "endometriosis": _endometriosisController.text,
        "previous_ovarian_cysts": _previousCystsController.text,
        "hormone_therapy": _hormoneTherapyController.text,
        "fertility_treatments": _fertilityController.text,
        "previous_ovarian_surgery": _surgeryController.text,
        "last_pelvic_exam": _lastExamController.text,
        "last_ultrasound": _lastUltrasoundController.text,
      },
      "lifestyle": {
        "exercise_frequency": _exerciseController.text,
        "diet_quality": _dietController.text,
        "stress_level": _stressController.text,
        "sleep_quality": _sleepController.text,
        "weight_status": _weightController.text,
        "contraceptive_use": _contraceptiveController.text,
        "smoking_status": _smokingController.text,
      },
      "pelvic_symptoms": {
        "pelvic_pain": _pelvicPainController.text,
        "abdominal_bloating": _bloatingController.text,
        "feeling_full_quickly": _fullnessController.text,
        "frequent_urination": _urinationController.text,
        "difficulty_emptying_bladder": _bladderController.text,
        "pain_during_sex": _sexPainController.text,
      },
      "menstrual_symptoms": {
        "irregular_periods": _irregularPeriodsController.text,
        "heavy_periods": _heavyPeriodsController.text,
        "painful_periods": _painfulPeriodsController.text,
        "spotting_between_periods": _spottingController.text,
        "missed_periods": _missedPeriodsController.text,
      },
      "hormonal_symptoms": {
        "breast_tenderness": _breastTendernessController.text,
        "mood_changes": _moodController.text,
        "weight_gain": _weightGainController.text,
        "acne_changes": _acneController.text,
        "hair_growth_changes": _hairController.text,
      },
      "general_symptoms": {
        "nausea_vomiting": _nauseaController.text,
        "back_pain": _backPainController.text,
        "leg_pain": _legPainController.text,
        "fatigue": _fatigueController.text,
      },
    };

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/ovarian_cysts_assessment'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
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
              .collection('ovarian_screening')
              .doc(_userUid)
              .set({
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
            content: Text('✅ Initial assessment complete!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
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
      _currentResponse = null;
      // Clear all controllers
      _ageController.clear();
      _menopauseStatusController.clear();
      _cystSizeController.clear();
      _ca125LevelController.clear();
      _ultrasoundFeaturesController.clear();
      _symptomsController.clear();
      _ageNewController.clear();
      _cycleLengthController.clear();
      _irregularityController.clear();
      _pregnancyController.clear();
      _menopauseNewController.clear();
      _familyHistoryController.clear();
      _pcosController.clear();
      _endometriosisController.clear();
      _previousCystsController.clear();
      _hormoneTherapyController.clear();
      _fertilityController.clear();
      _surgeryController.clear();
      _lastExamController.clear();
      _lastUltrasoundController.clear();
      _exerciseController.clear();
      _dietController.clear();
      _stressController.clear();
      _sleepController.clear();
      _weightController.clear();
      _contraceptiveController.clear();
      _smokingController.clear();
      _pelvicPainController.clear();
      _bloatingController.clear();
      _fullnessController.clear();
      _urinationController.clear();
      _bladderController.clear();
      _sexPainController.clear();
      _irregularPeriodsController.clear();
      _heavyPeriodsController.clear();
      _painfulPeriodsController.clear();
      _spottingController.clear();
      _missedPeriodsController.clear();
      _breastTendernessController.clear();
      _moodController.clear();
      _weightGainController.clear();
      _acneController.clear();
      _hairController.clear();
      _nauseaController.clear();
      _backPainController.clear();
      _legPainController.clear();
      _fatigueController.clear();
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _ageController.dispose();
    _menopauseStatusController.dispose();
    _cystSizeController.dispose();
    _ca125LevelController.dispose();
    _ultrasoundFeaturesController.dispose();
    _symptomsController.dispose();
    _ageNewController.dispose();
    _cycleLengthController.dispose();
    _irregularityController.dispose();
    _pregnancyController.dispose();
    _menopauseNewController.dispose();
    _familyHistoryController.dispose();
    _pcosController.dispose();
    _endometriosisController.dispose();
    _previousCystsController.dispose();
    _hormoneTherapyController.dispose();
    _fertilityController.dispose();
    _surgeryController.dispose();
    _lastExamController.dispose();
    _lastUltrasoundController.dispose();
    _exerciseController.dispose();
    _dietController.dispose();
    _stressController.dispose();
    _sleepController.dispose();
    _weightController.dispose();
    _contraceptiveController.dispose();
    _smokingController.dispose();
    _pelvicPainController.dispose();
    _bloatingController.dispose();
    _fullnessController.dispose();
    _urinationController.dispose();
    _bladderController.dispose();
    _sexPainController.dispose();
    _irregularPeriodsController.dispose();
    _heavyPeriodsController.dispose();
    _painfulPeriodsController.dispose();
    _spottingController.dispose();
    _missedPeriodsController.dispose();
    _breastTendernessController.dispose();
    _moodController.dispose();
    _weightGainController.dispose();
    _acneController.dispose();
    _hairController.dispose();
    _nauseaController.dispose();
    _backPainController.dispose();
    _legPainController.dispose();
    _fatigueController.dispose();
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
            // _buildStatusBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    if (_isFormVisible && _isInitialQuestionVisible)
                      _buildInitialQuestion(),
                    if (_isFormVisible && !_isInitialQuestionVisible)
                      _hasPreviousTest
                          ? _buildPreviousTestForm()
                          : _buildNewTestForm(),
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
                'Have you had an ovarian test before?',
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
                        _hasPreviousTest = true;
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
                        _hasPreviousTest = false;
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

  Widget _buildPreviousTestForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                  'Ovarian Test Results',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Age',
                  _ageController,
                  'Enter your age',
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownField(
                  'Menopause Status',
                  _menopauseStatusController,
                  ['Pre-Menopausal', 'Postmenopausal', 'Perimenopausal'],
                  'Select status',
                ),
                _buildTextField(
                  'Cyst Size (cm)',
                  _cystSizeController,
                  'Enter cyst size',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                _buildTextField(
                  'CA 125 Level',
                  _ca125LevelController,
                  'Enter CA 125 level',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                // _buildDropdownField(
                //   'Ultrasound Features',
                //   _ultrasoundFeaturesController,
                //   ['Simple', 'Complex', 'Septated', 'Solid', 'Multilocular'],
                //   'Select features',
                // ),
                _buildTextField(
                  'Symptoms (comma separated)',
                  _symptomsController,
                  'e.g., Pelvic Pain, Bloating',
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
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

  Widget _buildNewTestForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _testFormKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ovarian Health Assessment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Patient Information'),
                  _buildTextField(
                    'Age',
                    _ageNewController,
                    'Enter your age',
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    'Menstrual Cycle Length (days)',
                    _cycleLengthController,
                    'Enter average cycle length',
                    keyboardType: TextInputType.number,
                  ),
                  _buildYesNoDropdown(
                    'Menstrual Irregularity',
                    _irregularityController,
                  ),
                  _buildYesNoDropdown(
                    'Pregnancy History',
                    _pregnancyController,
                  ),
                  _buildYesNoDropdown(
                    'Menopause Status',
                    _menopauseNewController,
                  ),
                  _buildYesNoDropdown(
                    'Family History of Ovarian Issues',
                    _familyHistoryController,
                  ),
                  _buildSectionHeader('Medical History'),
                  _buildYesNoDropdown('PCOS Diagnosis', _pcosController),
                  _buildYesNoDropdown(
                    'Endometriosis',
                    _endometriosisController,
                  ),
                  _buildYesNoDropdown(
                    'Previous Ovarian Cysts',
                    _previousCystsController,
                  ),
                  _buildYesNoDropdown(
                    'Hormone Therapy',
                    _hormoneTherapyController,
                  ),
                  _buildYesNoDropdown(
                    'Fertility Treatments',
                    _fertilityController,
                  ),
                  _buildYesNoDropdown(
                    'Previous Ovarian Surgery',
                    _surgeryController,
                  ),
                  _buildDropdownField('Last Pelvic Exam', _lastExamController, [
                    'Never',
                    'Within last year',
                    '1-3 years ago',
                    'More than 3 years ago',
                  ], 'Select time'),
                  _buildDropdownField(
                    'Last Ultrasound',
                    _lastUltrasoundController,
                    [
                      'Never',
                      'Within last year',
                      '1-3 years ago',
                      'More than 3 years ago',
                    ],
                    'Select time',
                  ),
                  _buildSectionHeader('Lifestyle Factors'),
                  _buildDropdownField(
                    'Exercise Frequency',
                    _exerciseController,
                    [
                      'Never',
                      'Rarely',
                      '1-2 times/week',
                      '3-5 times/week',
                      'Daily',
                    ],
                    'Select frequency',
                  ),
                  _buildDropdownField('Diet Quality', _dietController, [
                    'Poor',
                    'Fair',
                    'Good',
                    'Excellent',
                  ], 'Select quality'),
                  _buildDropdownField('Stress Level', _stressController, [
                    'Low',
                    'Moderate',
                    'High',
                    'Very High',
                  ], 'Select level'),
                  _buildDropdownField('Sleep Quality', _sleepController, [
                    'Poor',
                    'Fair',
                    'Good',
                    'Excellent',
                  ], 'Select quality'),
                  _buildDropdownField('Weight Status', _weightController, [
                    'Underweight',
                    'Normal',
                    'Overweight',
                    'Obese',
                  ], 'Select status'),
                  _buildDropdownField(
                    'Contraceptive Use',
                    _contraceptiveController,
                    ['None', 'Pill', 'IUD', 'Implant', 'Other'],
                    'Select type',
                  ),
                  _buildYesNoDropdown('Smoking Status', _smokingController),
                  _buildSectionHeader('Pelvic Symptoms'),
                  _buildYesNoDropdown('Pelvic Pain', _pelvicPainController),
                  _buildYesNoDropdown(
                    'Abdominal Bloating',
                    _bloatingController,
                  ),
                  _buildYesNoDropdown(
                    'Feeling Full Quickly',
                    _fullnessController,
                  ),
                  _buildYesNoDropdown(
                    'Frequent Urination',
                    _urinationController,
                  ),
                  _buildYesNoDropdown(
                    'Difficulty Emptying Bladder',
                    _bladderController,
                  ),
                  _buildYesNoDropdown('Pain During Sex', _sexPainController),
                  _buildSectionHeader('Menstrual Symptoms'),
                  _buildYesNoDropdown(
                    'Irregular Periods',
                    _irregularPeriodsController,
                  ),
                  _buildYesNoDropdown('Heavy Periods', _heavyPeriodsController),
                  _buildYesNoDropdown(
                    'Painful Periods',
                    _painfulPeriodsController,
                  ),
                  _buildYesNoDropdown(
                    'Spotting Between Periods',
                    _spottingController,
                  ),
                  _buildYesNoDropdown(
                    'Missed Periods',
                    _missedPeriodsController,
                  ),
                  _buildSectionHeader('Hormonal Symptoms'),
                  _buildYesNoDropdown(
                    'Breast Tenderness',
                    _breastTendernessController,
                  ),
                  _buildYesNoDropdown('Mood Changes', _moodController),
                  _buildYesNoDropdown('Weight Gain', _weightGainController),
                  _buildYesNoDropdown('Acne Changes', _acneController),
                  _buildYesNoDropdown('Hair Growth Changes', _hairController),
                  _buildSectionHeader('General Symptoms'),
                  _buildYesNoDropdown('Nausea/Vomiting', _nauseaController),
                  _buildYesNoDropdown('Back Pain', _backPainController),
                  _buildYesNoDropdown('Leg Pain', _legPainController),
                  _buildYesNoDropdown('Fatigue', _fatigueController),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitNewTestForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFff6b9d),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Submit Assessment',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFff6b9d),
        ),
      ),
    );
  }

  Widget _buildYesNoDropdown(String label, TextEditingController controller) {
    return _buildDropdownField(label, controller, [
      'Yes',
      'No',
    ], 'Select option');
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<String> items,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        style: const TextStyle(color: Colors.black),
        items:
            items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: (newValue) {
          controller.text = newValue ?? '';
        },
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please select $label';
          return null;
        },
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
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (keyboardType != TextInputType.text &&
              double.tryParse(value) == null &&
              int.tryParse(value) == null) {
            return '$label must be a number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_currentResponse == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
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
                  'Your Health Assessment',
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

          // Results cards
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
                // Header with icon and title
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

                // Content based on data type
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

  Widget _buildRecommendationCard(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: ListTile(
          leading: Icon(
            _getIconForTitle(title),
            color: const Color(0xFFff6b9d),
            size: 24,
          ),
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

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Next Screening':
        return Icons.calendar_today;
      case 'Lifestyle Tip':
        return Icons.fitness_center;
      case 'Preventive Measures':
        return Icons.shield;
      case 'Contact Support':
        return Icons.phone;
      case 'Diagnostic History':
        return Icons.local_hospital;
      case 'Lifestyle Factors':
        return Icons.eco;
      case 'Potential Complications':
        return Icons.warning;
      case 'Screening Interval':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  // Widget _buildStatusBar() {
  //   return Container(
  //     height: 50,
  //     color: Colors.blue,
  //     child: const Center(
  //       child: Text(
  //         'Status Bar',
  //         style: TextStyle(color: Colors.white, fontSize: 16),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Ovarian Health Assessment',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF333333),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
