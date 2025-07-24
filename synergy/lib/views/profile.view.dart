import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _familyHistoryTypeController = TextEditingController();
  final _familyRelationController = TextEditingController();
  final _hasFamilyHistoryController = TextEditingController();
  final _regionController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _photoUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _userUid;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    developer.log('Starting _loadUserData', name: 'ProfileScreen');
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _userUid = prefs.getString('user_uid');
      _authToken = prefs.getString('auth_token');

      if (_userUid == null || _authToken == null) {
        developer.log('No user UID or auth token found', name: 'ProfileScreen');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      developer.log(
        'Fetching user data for UID: $_userUid',
        name: 'ProfileScreen',
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userUid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              developer.log(
                'Firestore request timed out',
                name: 'ProfileScreen',
              );
              throw TimeoutException('Firestore request timed out');
            },
          );

      if (userDoc.exists && mounted) {
        developer.log('User data fetched successfully', name: 'ProfileScreen');
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] as String? ?? 'Unknown';
          _dobController.text = _normalizeDate(
            data['dateOfBirth'] as String? ?? 'Unknown',
          );
          _roleController.text = data['role'] as String? ?? 'Unknown';
          _emailController.text = data['email'] as String? ?? 'Unknown';
          _familyHistoryTypeController.text =
              data['familyHistoryType'] as String? ?? 'Unknown';
          _familyRelationController.text =
              data['familyRelation'] as String? ?? 'Unknown';
          _hasFamilyHistoryController.text =
              data['hasFamilyHistory'] as String? ?? 'Unknown';
          _regionController.text = data['region'] as String? ?? 'Unknown';
          _usernameController.text = data['username'] as String? ?? 'Unknown';
          _photoUrl = data['photoUrl'] as String? ?? null;
        });
      } else if (mounted) {
        developer.log('User document does not exist', name: 'ProfileScreen');
        setState(() {
          _fullNameController.text = 'Unknown';
          _dobController.text = 'Unknown';
          _roleController.text = 'Unknown';
          _emailController.text = 'Unknown';
          _familyHistoryTypeController.text = 'Unknown';
          _familyRelationController.text = 'Unknown';
          _hasFamilyHistoryController.text = 'Unknown';
          _regionController.text = 'Unknown';
          _usernameController.text = 'Unknown';
          _photoUrl = null;
        });
      }
    } catch (e) {
      developer.log('Error in _loadUserData: $e', name: 'ProfileScreen');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted) {
        developer.log('Exiting _loadUserData', name: 'ProfileScreen');
        setState(() => _isLoading = false);
      }
    }
  }

  String _normalizeDate(String date) {
    if (date == 'Unknown') return date;
    final parts = date.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final day = parts[2]; // Day from YYYY-MM-DD
      final month = parts[1]; // Month from YYYY-MM-DD
      final year = parts[0]; // Year from YYYY-MM-DD
      return '$day/$month/$year';
    }
    return date;
  }

  Future<void> _pickImage() async {
    developer.log('Starting _pickImage', name: 'ProfileScreen');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _userUid != null) {
      setState(() => _isLoading = true);
      try {
        developer.log('Uploading image to storage', name: 'ProfileScreen');
        final file = File(pickedFile.path);
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_photos/$_userUid.jpg');
        await storageRef.putFile(file);
        final photoUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userUid)
            .update({'photoUrl': photoUrl});

        if (mounted) {
          developer.log(
            'Image upload successful, URL: $photoUrl',
            name: 'ProfileScreen',
          );
          setState(() {
            _photoUrl = photoUrl;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          developer.log('Error in _pickImage: $e', name: 'ProfileScreen');
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
        }
      }
    } else if (mounted) {
      developer.log('No image picked or no user UID', name: 'ProfileScreen');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    developer.log('Starting _updateProfile', name: 'ProfileScreen');
    if (!_validateInputs() || _userUid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields or correct invalid data'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      developer.log('Updating user data in Firestore', name: 'ProfileScreen');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userUid)
          .update({
            'fullName': _fullNameController.text.trim(),
            'dateOfBirth': _dobController.text.trim(),
            'role': _roleController.text.trim(),
            'email': _emailController.text.trim(),
            'familyHistoryType': _familyHistoryTypeController.text.trim(),
            'familyRelation': _familyRelationController.text.trim(),
            'hasFamilyHistory': _hasFamilyHistoryController.text.trim(),
            'region': _regionController.text.trim(),
            'username': _usernameController.text.trim(),
          });

      if (mounted) {
        developer.log('Profile updated successfully', name: 'ProfileScreen');
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        developer.log('Error in _updateProfile: $e', name: 'ProfileScreen');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  bool _validateInputs() {
    if (![
      _fullNameController.text,
      _dobController.text,
      _roleController.text,
      _emailController.text,
      _familyHistoryTypeController.text,
      _familyRelationController.text,
      _hasFamilyHistoryController.text,
      _regionController.text,
      _usernameController.text,
    ].every((field) => field.isNotEmpty)) {
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return false;
    }
    final dateParts = _dobController.text.trim().split('/');
    if (dateParts.length != 3 ||
        int.tryParse(dateParts[0]) == null ||
        int.tryParse(dateParts[1]) == null ||
        int.tryParse(dateParts[2]) == null ||
        int.parse(dateParts[0]) < 1 ||
        int.parse(dateParts[0]) > 31 ||
        int.parse(dateParts[1]) < 1 ||
        int.parse(dateParts[1]) > 12 ||
        int.parse(dateParts[2]) < 1900 ||
        int.parse(dateParts[2]) > DateTime.now().year) {
      return false;
    }
    return true;
  }

  Future<void> _selectDate() async {
    developer.log('Starting _selectDate', name: 'ProfileScreen');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      developer.log(
        'Date selected: ${picked.toIso8601String()}',
        name: 'ProfileScreen',
      );
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _familyHistoryTypeController.dispose();
    _familyRelationController.dispose();
    _hasFamilyHistoryController.dispose();
    _regionController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      developer.log('Screen is loading', name: 'ProfileScreen');
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

    developer.log('Screen built successfully', name: 'ProfileScreen');
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child: Column(
                    children: [_buildHeader(context), _buildContent()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final now = DateTime.now();
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
          Text(
            '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'} EAT',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const Text(
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFffeef8), Color(0xFFf8f0ff)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                    child:
                        _photoUrl == null
                            ? const Icon(Icons.camera_alt, color: Colors.white)
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _fullNameController.text.isEmpty
                    ? 'Loading...'
                    : _fullNameController.text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_dobController.text.isNotEmpty ? DateTime.now().year - int.parse(_dobController.text.split('/')[2]) : 'Unknown'} years old • ${_roleController.text}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
          Positioned(top: 50, left: 0, child: _buildBackButton(context)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection('Personal Details', [
            _buildInfoField('Full Name', _fullNameController),
            _buildInfoField(
              'Date of Birth (DD/MM/YYYY)',
              _dobController,
              isDate: true,
              onTap: _selectDate,
            ),
            _buildInfoField('Role', _roleController),
            _buildInfoField('Email', _emailController),
            _buildInfoField(
              'Family History Type',
              _familyHistoryTypeController,
            ),
            _buildInfoField('Family Relation', _familyRelationController),
            _buildInfoField('Has Family History', _hasFamilyHistoryController),
            _buildInfoField('Region', _regionController),
            _buildInfoField('Username', _usernameController),
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEditing)
                Flexible(child: _buildPrimaryButton('Save', _updateProfile)),
              if (_isEditing)
                Flexible(
                  child: _buildSecondaryButton('Cancel', () {
                    if (mounted) {
                      setState(() {
                        _isEditing = false;
                        _loadUserData();
                      });
                    }
                  }),
                ),
              if (!_isEditing)
                Flexible(
                  child: _buildPrimaryButton('Edit', () {
                    if (mounted) setState(() => _isEditing = true);
                  }),
                ),
            ],
          ),
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
          child: Text(
            '←',
            style: TextStyle(fontSize: 18, color: Color(0xFF333333)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> fields) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    bool isDate = false,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          SizedBox(
            width: 150,
            child: TextFormField(
              controller: controller,
              enabled: _isEditing,
              readOnly: isDate,
              onTap: isDate ? onTap : null,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => Transform.scale(scale: 0.98),
      onTapUp: (_) => onPressed(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(top: 10),
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
          child: Text(
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

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => Transform.scale(scale: 0.98),
      onTapUp: (_) => onPressed(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}
