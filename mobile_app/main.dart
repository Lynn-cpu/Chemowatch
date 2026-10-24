
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications.init();
  runApp(const ChemoWatch());
}


class Notifications {
  static final plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await plugin.initialize(settings);
  }

  static Future<void> requestPermission() async {
    await Permission.notification.request();

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> urgent(String message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        // A new channel ID lets Android apply the updated settings.
        'health_alerts_v2',
        'Urgent health alerts',
        channelDescription:
            'Urgent ChemoWatch temperature and health warnings',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
    );

    await plugin.show(
      1,
      '⚠️ CHEMOWATCH — URGENT ALERT',
      message,
      details,
    );
  }
}


class Reading {
  final double temperature;
  final int heartRate;
  final DateTime time;
  final String source;

  Reading(this.temperature, this.heartRate, this.time, this.source);

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'heartRate': heartRate,
        'time': time.toIso8601String(),
        'source': source,
      };

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
        (json['temperature'] as num).toDouble(),
        (json['heartRate'] as num).toInt(),
        DateTime.parse(json['time'] as String),
        json['source'] as String? ?? 'Saved reading',
      );
}

class ChemoWatch extends StatelessWidget {
  const ChemoWatch({super.key});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF119D91);
    return MaterialApp(
      title: 'ChemoWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int tab = 0;
  String userRole = 'Patient';
  String userName = '';
  String userPhone = '';
  String userLocation = '';
  bool signedIn = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  bool scanning = false;
  bool asking = false;
  BluetoothDevice? device;
  List<ScanResult> devices = [];
  List<Reading> readings = [];
  final question = TextEditingController();
  final messages = <String>[
    'Welcome! I can answer general questions, but I cannot diagnose medical conditions.',
  ];

  // Android emulator URL. For a physical phone, use your computer's LAN IP.
static const backendUrl = 'http://10.0.2.2:8000';  @override
  void initState() {
    super.initState();
    loadReadings();
    Notifications.requestPermission();
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) setState(() => devices = results);
    });
  }

 @override
 void dispose() {
  nameController.dispose();
  phoneController.dispose();
  locationController.dispose();
  super.dispose();
 }

  Future<void> loadReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chemowatch_readings') ?? '[]';
    try {
      final list = jsonDecode(raw) as List;
      if (mounted) {
        setState(() {
          readings = list
              .map((item) =>
                  Reading.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList()
            ..sort((a, b) => b.time.compareTo(a.time));
        });
      }
    } catch (_) {
      if (mounted) setState(() => readings = []);
    }
  }

  Future<void> saveReading(Reading reading) async {
    final updated = [reading, ...readings]
      ..sort((a, b) => b.time.compareTo(a.time));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chemowatch_readings',
      jsonEncode(updated.map((r) => r.toJson()).toList()),
    );
    if (!mounted) return;
    setState(() => readings = updated);

    // 38.0°C is the app's confugured temperature-alert threshold.
    // Follow the patient's oncology team's specific instructions.
    if (reading.temperature >= 38.0) {
      await Notifications.urgent(
        'Temperature ${reading.temperature.toStringAsFixed(1)}°C. '
        'Follow your oncology team’s fever instructions and contact them urgently.',
      );
    }
  }



Future<void> addReading() async {
  final temp = TextEditingController();
  final pulse = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<Reading>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Record a real measurement'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: temp,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Temperature (°C)',
              ),
              validator: (value) {
                final n = double.tryParse(value ?? '');
                return n == null || n < 30 || n > 45
                    ? 'Enter a valid temperature'
                    : null;
              },
            ),
            TextFormField(
              controller: pulse,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heart rate (BPM)',
              ),
              validator: (value) {
                final n = int.tryParse(value ?? '');
                return n == null || n < 20 || n > 250
                    ? 'Enter a valid heart rate'
                    : null;
              },
            ),
            const SizedBox(height: 8),
            const Text('Manually entered measurements will be labeled.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(
                dialogContext,
                Reading(
                  double.parse(temp.text),
                  int.parse(pulse.text),
                  DateTime.now(),
                  'Manually entered',
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  // Temporary debugging version: don't dispose these controllers yet.
  if (!mounted) return;
  if (result != null) await saveReading(result);
}


  Future<void> scanBluetooth() async {
    setState(() {
      scanning = true;
      devices = [];
    });
    try {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();

      if (!await FlutterBluePlus.isSupported) {
        showMessage('Bluetooth is not supported on this device.');
        return;
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      await Future.delayed(const Duration(seconds: 8));
    } catch (_) {
      showMessage('Bluetooth scan failed. Check Bluetooth and permissions.');
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> connect(BluetoothDevice selected) async {
    try {
      await selected.connect(timeout: const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => device = selected);
      showMessage(
        'Connected to ${selected.platformName.isEmpty ? selected.remoteId.str : selected.platformName}. '
        'Live readings still require the wearable data format.',
      );
    } catch (_) {
      if (selected.isConnected && mounted) {
        setState(() => device = selected);
      } else {
        showMessage('Could not connect. Check that the wearable is nearby.');
      }
    }
  }

  Future<void> askAssistant() async {
    final text = question.text.trim();
    if (text.isEmpty || asking) return;

    setState(() {
      messages.add('You: $text');
      question.clear();
      asking = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/assistant'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': text,
              'recentReadings': readings.take(10).map((r) => r.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        messages.add('Assistant: ${data['answer'] ?? 'No answer returned.'}');
      } else {
        messages.add(
          'Assistant unavailable (${response.statusCode}). Check your backend and API key.',
        );
      }
    } catch (_) {
      messages.add(
        'Cannot reach the backend. Check the server address and ensure the server is running.',
      );
    } finally {
      if (mounted) setState(() => asking = false);
    }
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!signedIn) {
      return Scaffold(
        body: SafeArea(
          child: signupPage(),
    ),
  );
}
    final pages = [
      homePage(),
      historyPage(),
      assistantPage(),
      settingsPage(),
      signupPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('♥  ChemoWatch'),
        actions: [
          IconButton(
            onPressed: addReading,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Record reading',
          ),
        ],
      ),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
),
        ],
      ),
  floatingActionButton: tab == 0
    ? FloatingActionButton.extended(
        onPressed: () => setState(() => tab = 2),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask Lumi'),
      )
    : null,
    );
  }

  Widget homePage() {
    final latest = readings.isEmpty ? null : readings.first;
    debugPrint('Latest temperature: ${latest?.temperature}');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF10243A),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your health, more visible.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep track of measurements and stay connected with your care plan.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
               if (latest != null && latest.temperature >= 38.0)
          const Card(
            color: Color(0xFFFFE8E5),
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.red),
              title: Text('Temperature alert'),
              subtitle: Text(
                'A saved measurement is at least 38.0°C. '
                'Follow your oncology team’s instructions and contact them urgently. '
                'Do not wait for this app.',
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: metric(
                'Temperature',
                latest == null
                    ? '—'
                    : '${latest.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: metric(
                'Heart rate',
                latest == null ? '—' : '${latest.heartRate} BPM',
                Icons.favorite_outline,
              ),
            ),
          ],
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bluetooth, color: Color(0xFF119D91)),
            title: Text(device == null ? 'Connect wearable' : 'Wearable connected'),
            subtitle: Text(
              device == null
                  ? 'Search for nearby Bluetooth devices'
                  : device!.platformName.isEmpty
                      ? device!.remoteId.str
                      : device!.platformName,
            ),
            onTap: () => setState(() => tab = 3),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Important: after chemotherapy, a temperature of 38.0°C (100.4°F) or higher may require urgent medical attention. Follow your oncology team’s specific instructions. This app cannot rule out an emergency.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Recent readings', style: Theme.of(context).textTheme.titleLarge),
        if (latest == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No measurements saved yet. Record a real reading to begin.'),
            ),
          )
        else
          ...readings.take(3).map(readingTile),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget metric(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF119D91), size: 28),
            const SizedBox(height: 12),
            Text(title),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              readings.isEmpty ? 'No measurement' : readings.first.source,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget readingTile(Reading r) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: Text(
          '${r.temperature.toStringAsFixed(1)}°C  •  ${r.heartRate} BPM',
        ),
        subtitle: Text('${r.time.toLocal()}\n${r.source}'),
        isThreeLine: true,
      ),
    );
  }

  Widget historyPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reading history', style: Theme.of(context).textTheme.headlineSmall),
        const Text('Measurements saved locally on this phone.'),
        const SizedBox(height: 10),
        if (readings.isEmpty)
          const Text('No readings recorded yet.')
        else
          ...readings.map(readingTile),
      ],
    );
  }

  
Widget assistantPage() {
  return Column(
    children: [
      // Lumi's chat header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF0B1F33),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF119D91),
              child: Icon(Icons.auto_awesome, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lumi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your ChemoWatch assistant',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Medical safety reminder
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: const Color(0xFFFFF3D6),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined,
                color: Color(0xFF8A5A00), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'General information only. If you have a fever or feel unwell '
                'after chemotherapy, follow your oncology team’s instructions '
                'and contact them urgently. Do not wait for an AI response.',
                style: TextStyle(fontSize: 12, color: Color(0xFF654500)),
              ),
            ),
          ],
        ),
      ),

      // Scrollable chat history
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (asking ? 1 : 0),
          itemBuilder: (context, index) {
            if (asking && index == messages.length) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final message = messages[index];
            final isUser = message.startsWith('You: ');
            final displayMessage = message.startsWith('Assistant: ')
                ? message.substring('Assistant: '.length)
                : (isUser ? message.substring(5) : message);

            return Align(
              alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF087E70)
                      : const Color(0xFFEAF0F5),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                ),
                child: Text(
                  displayMessage,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF172B3A),
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Message composer at the bottom
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: question,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Message Lumi...',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!asking) askAssistant();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send message',
                onPressed: asking ? null : askAssistant,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF087E70),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: const Text('Scan for Bluetooth devices'),
            subtitle: Text(
              scanning
                  ? 'Scanning…'
                  : device == null
                      ? 'No wearable connected'
                      : 'Connected: ${device!.remoteId.str}',
            ),
            trailing: const Icon(Icons.search),
            onTap: scanning ? null : scanBluetooth,
          ),
        ),
        if (devices.isNotEmpty)
          ...devices.map(
            (result) => Card(
              child: ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(
                  result.device.platformName.isEmpty
                      ? 'Unnamed device'
                      : result.device.platformName,
                ),
                subtitle: Text(result.device.remoteId.str),
                onTap: () => connect(result.device),
              ),
            ),
          ),
        if (device != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Disconnect wearable'),
              onTap: () async {
                await device!.disconnect();
                if (mounted) setState(() => device = null);
              },
            ),
          ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Request notification permission'),
            onTap: Notifications.requestPermission,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear reading history'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('chemowatch_readings');
              if (mounted) setState(() => readings = []);
            },
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bluetooth connection alone does not provide readings. The wearable’s service and characteristic format must be integrated before live temperature and heart-rate monitoring can work.',
            ),
          ),
        ),
      ],
    );
  }



  Widget signupPage() {
    
    return StatefulBuilder(
      builder: (context, refresh) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.health_and_safety, size: 56, color: Color(0xFF119D91)),
          const SizedBox(height: 12),
          const Text(
            'Welcome to ChemoWatch',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your profile to personalize your experience.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text('I am a...'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final role in ['Patient', 'Caregiver', 'Doctor'])
                ChoiceChip(
                  label: Text(role),
                  selected: userRole == role,
                  onSelected: (_) {
                    setState(() => userRole = role);
                    refresh(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              labelText: 'City or general location',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please complete all profile fields.'),
                  ),
                );
                return;
              }

              setState(() {
                userName = nameController.text.trim();
                userPhone = phoneController.text.trim();
                userLocation = locationController.text.trim();
                signedIn = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$userRole profile details saved for this session.')),
              );

              setState(() => tab = 0);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save profile'),
          ),
          const SizedBox(height: 12),
          const Text(
            'This screen stores details only for the current app session. It does not create a secure account or verify professional credentials.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
