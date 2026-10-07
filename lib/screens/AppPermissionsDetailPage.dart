import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  _AppPermissionsPageState createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage> {
  static const platform = MethodChannel("app_info_channel");
  List<Map<String, dynamic>> _apps = [];

  @override
  void initState() {
    super.initState();
    _fetchInstalledApps();
  }

  Future<void> _fetchInstalledApps() async {
    try {
      final String result = await platform.invokeMethod("getInstalledApps");
      final List<dynamic> jsonData = json.decode(result);

      setState(() {
        _apps = jsonData.map((app) => Map<String, dynamic>.from(app)).toList();
      });
    } catch (e) {
      print("Failed to fetch apps: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150050),
      appBar: AppBar(
        title: const Text(
          "Installed Apps & Permissions",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF150050),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _apps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _apps.length,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                itemBuilder: (context, index) {
                  final app = _apps[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the AppPermissionsDetailPage when an app is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppPermissionsDetailPage(
                            packageName: app['packageName'],
                            appName: app['appName'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E1F92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white54, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: ClipOval(
                            child: app['icon'] != null && app['icon'].isNotEmpty
                                ? Image.memory(
                                    base64Decode(app['icon']),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.android,
                                    size: 40, color: Colors.white),
                          ),
                          title: Text(
                            app['appName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .yellow, // Change this to make the app name more visible
                              fontSize:
                                  18, // You can also increase font size if needed
                            ),
                          ),
                          subtitle: Text(
                            app['packageName'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )),
                  );
                },
              ),
            ),
    );
  }
}

class AppPermissionsDetailPage extends StatefulWidget {
  final String packageName;
  final String appName;

  const AppPermissionsDetailPage({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  _AppPermissionsDetailPageState createState() =>
      _AppPermissionsDetailPageState();
}

class _AppPermissionsDetailPageState extends State<AppPermissionsDetailPage> {
  static const platform = MethodChannel("app_info_channel");
  List<String> _permissions = [];

  // Mapping permission names to human-readable labels
  final Map<String, String> _permissionLabels = {
    'android.permission.CAMERA': 'Camera',
    'android.permission.ACCESS_FINE_LOCATION': 'Location',
    'android.permission.RECORD_AUDIO': 'Microphone',
    'android.permission.READ_EXTERNAL_STORAGE': 'Storage',
    'android.permission.WRITE_EXTERNAL_STORAGE': 'Storage',
    'android.permission.INTERNET': 'Internet',
    'android.permission.READ_CONTACTS': 'Contacts',
    'android.permission.CALL_PHONE': 'Phone Call',
    'android.permission.SEND_SMS': 'SMS',
    // Add more permissions here as needed
  };

  final Map<String, IconData> _permissionIcons = {
    'android.permission.CAMERA': Icons.camera_alt,
    'android.permission.ACCESS_FINE_LOCATION': Icons.location_on,
    'android.permission.RECORD_AUDIO': Icons.mic,
    'android.permission.READ_EXTERNAL_STORAGE': Icons.folder_open,
    'android.permission.WRITE_EXTERNAL_STORAGE': Icons.folder_open,
    'android.permission.INTERNET': Icons.network_wifi,
    'android.permission.READ_CONTACTS': Icons.contacts,
    'android.permission.CALL_PHONE': Icons.call,
    'android.permission.SEND_SMS': Icons.message,
    // Add more permission icons here as needed
  };

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
  }

  Future<void> _fetchPermissions() async {
    try {
      final List<dynamic> permissions =
          await platform.invokeMethod("getAppPermissions", {
        "packageName": widget.packageName,
      });

      setState(() {
        _permissions = List<String>.from(permissions);
      });
    } catch (e) {
      print("Failed to fetch permissions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150050),
      appBar: AppBar(
        title: Text("${widget.appName} Permissions"),
        backgroundColor: const Color(0xFF150050),
        elevation: 0,
      ),
      body: _permissions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _permissions.length,
              itemBuilder: (context, index) {
                final permission = _permissions[index];
                final label = _permissionLabels[permission] ?? permission;
                final icon = _permissionIcons[permission] ?? Icons.help;

                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E1F92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(icon, color: Colors.white),
                    title: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
