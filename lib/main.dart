import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Incubator Monitor',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

// Models to better structure data
class SensorData {
  final double temperature;
  final int humidity;
  final double ammoniaLevel;
  final double co2Level;
  final int lightIntensity;
  final bool isLightOn;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.ammoniaLevel,
    required this.co2Level,
    required this.lightIntensity,
    required this.isLightOn,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: json['humidity'] ?? 0,
      ammoniaLevel: ((json['ammonia'] ?? 0.0) * 100).toDouble(),
      co2Level: ((json['co2'] ?? 0.0) * 100).toDouble(),
      lightIntensity: json['light_intensity'] ?? 0,
      isLightOn: json['light_status'] == 1,
    );
  }

  factory SensorData.empty() {
    return SensorData(
      temperature: 0.0,
      humidity: 0,
      ammoniaLevel: 0.0,
      co2Level: 0.0,
      lightIntensity: 0,
      isLightOn: false,
    );
  }
}

// API Service class for separation of concerns
class IncubatorApiService {
  final String baseUrl;

  const IncubatorApiService({required this.baseUrl});

  Future<SensorData> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sensor-data'));
      if (response.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(response.body));
      }
      return SensorData.empty();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching data: $e");
      }
      return SensorData.empty();
    }
  }

  Future<void> adjustValue(String type, String action) async {
    try {
      await http.get(Uri.parse('$baseUrl/control?type=$type&action=$action'));
    } catch (e) {
      if (kDebugMode) {
        print("Error adjusting $type: $e");
      }
    }
  }
}

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Add explicit type annotation here
    final WebViewController controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse("http://192.168.1.100/stream"));

    return Scaffold(
      appBar: AppBar(title: const Text("Monitoring Page")),
      body: WebViewWidget(controller: controller),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page"), elevation: 2),
      drawer: const AppDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome to the Incubator Monitor",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // No buttons here anymore
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              red: 0,
                              green: 0,
                              blue: 0,
                              alpha: 0.2,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.egg_outlined,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    "Incubator Monitor",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    "Smart Monitoring System",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final IncubatorApiService _apiService;
  SensorData _sensorData = SensorData.empty();
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = const IncubatorApiService(baseUrl: "http://192.168.1.100");
    _fetchData();
    _startPeriodicFetch();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchSensorData();
    setState(() {
      _sensorData = data;
      _isLoading = false;
    });
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  Future<void> _adjustValue(String type, String action) async {
    await _apiService.adjustValue(type, action);
    _fetchData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Control Panel"),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: "Refresh data",
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildControlCard(
                      title: "Temperature",
                      value: "${_sensorData.temperature.toStringAsFixed(1)} °C",
                      icon: Icons.thermostat,
                      onDecrease: () => _adjustValue("temperature", "decrease"),
                      onIncrease: () => _adjustValue("temperature", "increase"),
                    ),
                    _buildControlCard(
                      title: "Humidity",
                      value: "${_sensorData.humidity}%",
                      icon: Icons.water_drop,
                      onDecrease: () => _adjustValue("humidity", "decrease"),
                      onIncrease: () => _adjustValue("humidity", "increase"),
                    ),
                    _buildControlCard(
                      title: "Light Intensity",
                      value: "${_sensorData.lightIntensity}%",
                      icon: Icons.wb_sunny,
                      onDecrease:
                          () => _adjustValue("light_intensity", "decrease"),
                      onIncrease:
                          () => _adjustValue("light_intensity", "increase"),
                    ),
                    _buildSwitchCard(
                      title: "Light Control",
                      icon: Icons.lightbulb,
                      value: _sensorData.isLightOn,
                      onChanged: (value) {
                        _adjustValue("light_status", value ? "on" : "off");
                      },
                    ),
                    _buildInfoCard(
                      title: "Gas Levels",
                      items: [
                        InfoItem(
                          title: "Ammonia Level",
                          value:
                              "${_sensorData.ammoniaLevel.toStringAsFixed(1)}%",
                          color: _getWarningColor(_sensorData.ammoniaLevel, 30),
                          icon: Icons.science,
                        ),
                        InfoItem(
                          title: "CO₂ Level",
                          value: "${_sensorData.co2Level.toStringAsFixed(1)}%",
                          color: _getWarningColor(_sensorData.co2Level, 40),
                          icon: Icons.cloud,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(value, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrease,
              tooltip: "Decrease",
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrease,
              tooltip: "Increase",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: value ? Colors.amber : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Color _getWarningColor(double value, double threshold) {
    if (value > threshold) {
      return Colors.red;
    } else if (value > threshold * 0.7) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Widget _buildInfoCard({
    required String title,
    required List<InfoItem> items,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(item.icon, color: item.color, size: 24),
                    const SizedBox(width: 12),
                    Text(item.title, style: const TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.color,
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
}

class InfoItem {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  InfoItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Incubator Monitor",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Control Panel",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Control Panel"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ControlPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text("Monitoring Page"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MonitoringPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
