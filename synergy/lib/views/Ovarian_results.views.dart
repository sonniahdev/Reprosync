import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorOvarianResultsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorOvarianResultsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorOvarianResultsScreen> createState() =>
      _DoctorOvarianResultsScreenState();
}

class _DoctorOvarianResultsScreenState
    extends State<DoctorOvarianResultsScreen> {
  Map<String, dynamic>? _currentResponse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('ovarian_screening')
              .doc(widget.patientId)
              .get();

      if (doc.exists && mounted) {
        setState(() {
          _currentResponse =
              doc.data()?['api_response'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No ovarian screening data found for this patient.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.patientName}\'s Ovarian Results',
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
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
                : _currentResponse == null
                ? const Center(
                  child: Text(
                    'No results available for this patient.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      ...(_currentResponse!.entries.map((entry) {
                        return _buildResultCard(entry);
                      }).toList()),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          const Icon(Icons.health_and_safety, size: 48, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            '${widget.patientName}\'s Ovarian Health Assessment',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'Generated on ${DateTime.now().toString().split(' ')[0]}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
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
}
