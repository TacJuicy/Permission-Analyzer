import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../theme/theme.dart';
import './app_permissions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double noRisk = 0;
  double lowRisk = 0;
  double mediumRisk = 0;
  double highRisk = 0;

  static const platform = MethodChannel('app_info_channel');
  List<Map<String, dynamic>> _allApps = [];

  @override
  void initState() {
    super.initState();
    loadAppData();
  }

  Future<void> loadAppData() async {
    try {
      final String result = await platform.invokeMethod('getInstalledApps');
      final List<dynamic> apps = json.decode(result);
      int no = 0, low = 0, med = 0, high = 0;

      List<Map<String, dynamic>> appList = [];

      for (var app in apps) {
        int score = app['riskScore'];
        if (score < 50) {
          no++;
        } else if (score < 100) {
          low++;
        } else if (score < 250) {
          med++;
        } else {
          high++;
        }
        appList.add(Map<String, dynamic>.from(app));
      }

      setState(() {
        noRisk = no.toDouble();
        lowRisk = low.toDouble();
        mediumRisk = med.toDouble();
        highRisk = high.toDouble();
        _allApps = appList;
      });
    } on PlatformException catch (e) {
      print("Failed to get installed apps: '${e.message}'.");
    }
  }

  void _navigateToFilteredApps(String riskLevel) {
    List<Map<String, dynamic>> filteredApps = _allApps.where((app) {
      int score = app['riskScore'];
      switch (riskLevel) {
        case 'no':
          return score < 50;
        case 'low':
          return score >= 50 && score < 100;
        case 'medium':
          return score >= 100 && score < 250;
        case 'high':
          return score >= 250;
        default:
          return false;
      }
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppPermissionsPage(filteredApps: filteredApps),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalApps = noRisk + lowRisk + mediumRisk + highRisk;
    double securityScore = totalApps == 0
        ? 0
        : ((noRisk * 1.0) +
                (lowRisk * 0.75) +
                (mediumRisk * 0.4) +
                (highRisk * 0.1)) /
            totalApps *
            100;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const SizedBox(height: 200),
            const Divider(color: AppColors.secondary),
            ListTile(
              title: const Text('All Apps', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AppPermissionsPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Notification', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.secondary),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      body: Container(
        color: AppColors.primary,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            const Text(
              "Hello!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToFilteredApps('no'),
                    child: _buildGauge("No Risk Apps", Colors.green, percent(noRisk, totalApps)),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToFilteredApps('low'),
                    child: _buildGauge("Low Risk Apps", Colors.lightGreen, percent(lowRisk, totalApps)),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToFilteredApps('medium'),
                    child: _buildGauge("Medium Risk Apps", Colors.orange, percent(mediumRisk, totalApps)),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToFilteredApps('high'),
                    child: _buildGauge("High Risk Apps", Colors.red, percent(highRisk, totalApps)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSecurityPosture(securityScore),
          ],
        ),
      ),
    );
  }

  double percent(double count, double total) {
    return total == 0 ? 0 : (count / total) * 100;
  }

  Widget _buildGauge(String title, Color color, double value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 50,
                  showLabels: true,
                  axisLabelStyle: const GaugeTextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  onLabelCreated: (args) {
                    if (args.text == '0' || args.text == '50') {
                      args.text = '';
                    }
                  },
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 0, endValue: value, color: color),
                    GaugeRange(startValue: value, endValue: 100, color: Colors.grey.shade300),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: value,
                      needleLength: 0.4,
                      needleStartWidth: 1,
                      needleEndWidth: 3,
                      knobStyle: const KnobStyle(
                        knobRadius: 0.035,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      angle: 90,
                      positionFactor: 0.78,
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSecurityPosture(double score) {
    String label;
    Color labelColor;
    Color barColor;

    if (score >= 85) {
      label = "Excellent";
      labelColor = Colors.green;
      barColor = Colors.green;
    } else if (score >= 70) {
      label = "Good";
      labelColor = Colors.lightGreen;
      barColor = Colors.lightGreen;
    } else if (score >= 50) {
      label = "Moderate";
      labelColor = Colors.orange;
      barColor = Colors.orange;
    } else {
      label = "Poor";
      labelColor = Colors.red;
      barColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overall Security Posture",
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Status:",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: labelColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade300,
          ),
          child: Stack(
            children: [
              Container(
                width: score.clamp(0, 100) * 3,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: barColor,
                ),
              ),
              Center(
                child: Text(
                  '${score.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
