import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regionController = TextEditingController();

  // Dropdown values
  String? _selectedRole;
  String? _hasFamilyHistory;
  String? _familyHistoryType;
  String? _familyRelation;

  final List<String> _roles = ['Doctor', 'Patient'];
  final List<String> _familyHistoryTypes = ['Ovarian Cysts', 'Cervical Cancer'];
  final List<String> _familyRelations = [
    'Mother',
    'Sister',
    'Grandmother',
    'Aunt',
    'Cousin',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (_fullNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedRole == null ||
        _regionController.text.isEmpty ||
        _hasFamilyHistory == null ||
        (_hasFamilyHistory == 'Yes' &&
            (_familyHistoryType == null || _familyRelation == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('http://localhost:5000/register');
    final userData = {
      'fullName': _fullNameController.text,
      'username': _usernameController.text,
      'email': _emailController.text.trim(),
      'dateOfBirth': _dobController.text,
      'role': _selectedRole,
      'region': _regionController.text,
      'hasFamilyHistory': _hasFamilyHistory,
      'familyHistoryType': _familyHistoryType,
      'familyRelation': _familyRelation,
      'password':
          _passwordController.text
              .trim(), // Include password for backend hashing
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${responseData['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef), Color(0xFFfecfef)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 30),
                      const Text(
                        'Join Rep',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Create your account to start your health journey',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildInputField(
                        'Full Name',
                        controller: _fullNameController,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        'Username',
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        'Email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        'Date of Birth',
                        controller: _dobController,
                        isDate: true,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown('Role', _selectedRole, _roles, (value) {
                        setState(() => _selectedRole = value);
                      }),
                      const SizedBox(height: 20),
                      _buildInputField('Region', controller: _regionController),
                      const SizedBox(height: 20),
                      _buildInputField(
                        'Password',
                        controller: _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        'Family History of Ovarian Cysts/Cervical Cancer',
                        _hasFamilyHistory,
                        ['Yes', 'No'],
                        (value) {
                          setState(() {
                            _hasFamilyHistory = value;
                            if (value == 'No') {
                              _familyHistoryType = null;
                              _familyRelation = null;
                            }
                          });
                        },
                      ),
                      if (_hasFamilyHistory == 'Yes') ...[
                        const SizedBox(height: 20),
                        _buildDropdown(
                          'Type of Family History',
                          _familyHistoryType,
                          _familyHistoryTypes,
                          (value) {
                            setState(() => _familyHistoryType = value);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildDropdown(
                          'Family Relation',
                          _familyRelation,
                          _familyRelations,
                          (value) {
                            setState(() => _familyRelation = value);
                          },
                        ),
                      ],
                      const SizedBox(height: 30),
                      _buildPrimaryButton(
                        'Create Account',
                        () => _handleRegistration(),
                      ),
                      const SizedBox(height: 20),
                      _buildLoginPrompt(),
                    ],
                  ),
                ),
              ),
              Positioned(top: 50, left: 20, child: _buildBackButton(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _animation.value),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'H❤️P',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(
    String hint, {
    TextEditingController? controller,
    bool isPassword = false,
    bool isDate = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType ?? (isDate ? TextInputType.datetime : null),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon:
              isDate
                  ? const Icon(Icons.calendar_today, color: Color(0xFF666666))
                  : null,
        ),
        style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
        onTap: isDate ? () => _selectDate(context) : null,
        readOnly: isDate,
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 8,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF666666)),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => onPressed(),
      child: Container(
        width: double.infinity,
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

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/login'),
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

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/login'),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFff6b9d),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFff6b9d),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}
