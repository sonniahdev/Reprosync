import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cervical Health Data Visualization',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HealthDataScreen(),
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  Map<String, dynamic>? healthData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/health-data'),
      );
      if (response.statusCode == 200) {
        setState(() {
          healthData = jsonDecode(response.body)['cervical_health_data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  // Process data to get counts for charts
  Map<String, dynamic> processChartData() {
    if (healthData == null || healthData!['patients'] == null) {
      return {};
    }
    List patients = healthData!['patients'];

    // HPV Test Result counts
    Map<String, int> hpvCounts = {'Positive': 0, 'Negative': 0};
    for (var patient in patients) {
      String hpvResult = patient['hpv_test_result'];
      if (hpvCounts.containsKey(hpvResult)) {
        hpvCounts[hpvResult] = hpvCounts[hpvResult]! + 1;
      }
    }

    // Pap Smear Result counts
    Map<String, int> papSmearCounts = {'Positive': 0, 'Negative': 0};
    for (var patient in patients) {
      String papResult = patient['pap_smear_result'];
      if (papSmearCounts.containsKey(papResult)) {
        papSmearCounts[papResult] = papSmearCounts[papResult]! + 1;
      }
    }

    // Smoking Status counts
    Map<String, int> smokingCounts = {'Y': 0, 'N': 0};
    for (var patient in patients) {
      String smokingStatus = patient['smoking_status'];
      if (smokingCounts.containsKey(smokingStatus)) {
        smokingCounts[smokingStatus] = smokingCounts[smokingStatus]! + 1;
      }
    }

    // Recommended Action counts with label cleanup
    Map<String, int> actionCounts = {};
    for (var patient in patients) {
      String action = patient['recommended_action'];
      // Clean up inconsistent labels
      action = action
          .replaceAll('Coloscopy', 'Colposcopy')
          .replaceAll('Biospy', 'Biopsy')
          .replaceAll('3Years', '3 Years');
      if (action.contains('Colposcopy Biopsy, Cytology +/- Tah')) {
        action = 'Colposcopy Biopsy, Cytology +/- Tah';
      } else if (action.contains('Colposcopy Biopsy, Cytology')) {
        action = 'Colposcopy Biopsy, Cytology';
      }
      actionCounts[action] = (actionCounts[action] ?? 0) + 1;
    }

    return {
      'hpv_counts': hpvCounts,
      'pap_smear_counts': papSmearCounts,
      'smoking_counts': smokingCounts,
      'action_counts': actionCounts,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text(errorMessage!)));
    }

    final chartData = processChartData();

    return Scaffold(
      appBar: AppBar(title: Text('Cervical Health Data Insights')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Cervical Health Data Insights',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildPieChart(
                  title: 'HPV Test Result Distribution',
                  data: chartData['hpv_counts'],
                  colors: [Colors.redAccent, Colors.blueAccent],
                ),
                _buildPieChart(
                  title: 'Pap Smear Result Distribution',
                  data: chartData['pap_smear_counts'],
                  colors: [Colors.yellowAccent, Colors.teal],
                ),
                _buildBarChart(
                  title: 'Smoking Status Distribution',
                  data: chartData['smoking_counts'],
                  color: Colors.purple,
                ),
                _buildBarChart(
                  title: 'Recommended Action Distribution',
                  data: chartData['action_counts'],
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart({
    required String title,
    required Map<String, int> data,
    required List<Color> colors,
  }) {
    return Container(
      width: 300,
      height: 350,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: PieChart(
              PieChartData(
                sections:
                    data.entries.map((entry) {
                      int index = data.keys.toList().indexOf(entry.key);
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '${entry.key}\n${entry.value}',
                        color: colors[index % colors.length],
                        radius: 100,
                        titleStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required String title,
    required Map<String, int> data,
    required Color color,
  }) {
    return Container(
      width: 300,
      height: 350,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    (data.values.reduce((a, b) => a > b ? a : b) * 1.2)
                        .toDouble(),
                barGroups:
                    data.entries.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value.toDouble(),
                            color: color,
                            width: 20,
                          ),
                        ],
                      );
                    }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String title = data.keys.elementAt(value.toInt());
                        // Shorten long titles for readability
                        if (title.length > 15) {
                          title = title.substring(0, 15) + '...';
                        }
                        return Text(
                          title,
                          style: TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Iterable<MapEntry<String, int>> {
  asMap() {}
}
