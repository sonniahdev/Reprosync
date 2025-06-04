import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

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
                  children: [_buildHeader(context), _buildContent()],
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
        children: const [
          Text(
            '21:34', // Updated to current time (09:34 PM EAT)
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
              children: [
                const Text(
                  'Appointments & Screening',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
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

  Widget _buildContent() {
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
          _buildAppointmentCard(
            'June 15, 2025',
            'Ultrasound',
            '10:00 AM • Dr. Emily Carter • City Health Clinic',
          ),
          _buildAppointmentCard(
            'February 1, 2026',
            'HPV Test',
            '9:00 AM • Dr. Maria Lopez • Women’s Health Center',
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
                _buildDropdownField(),
                const SizedBox(height: 20),
                _buildInputField('Select Date', isDate: true),
                const SizedBox(height: 20),
                _buildPrimaryButton('Book Appointment', () {}),
              ],
            ),
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
          child: Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(String date, String type, String details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity,
      height: 100,
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
      child: Row(
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
                Expanded(
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                      fontFamily: 'SF Pro Display',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
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
        decoration: InputDecoration(
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
        value: null,
        hint: const Text(
          'Select Appointment Type',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
        items: const [
          DropdownMenuItem(value: 'Pap Smear', child: Text('Pap Smear')),
          DropdownMenuItem(value: 'Ultrasound', child: Text('Ultrasound')),
          DropdownMenuItem(value: 'HPV Test', child: Text('HPV Test')),
        ],
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildInputField(String hint, {bool isDate = false}) {
    // Use a local state to manage the selected date
    DateTime? selectedDate;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return GestureDetector(
          onTap:
              isDate
                  ? () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  }
                  : null,
          child: Container(
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
            child: InputDecorator(
              decoration: InputDecoration(
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
                        ? const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF666666),
                        )
                        : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? hint
                          : selectedDate!.toString().split(' ')[0],
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            selectedDate == null
                                ? const Color(0xFF666666)
                                : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => Transform.scale(scale: 0.98),
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
}
