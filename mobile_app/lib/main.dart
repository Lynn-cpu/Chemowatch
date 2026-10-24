import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'reading_storage.dart';
import 'vital_reading.dart';

void main (){
  runApp(const ChemoWatchApp());
}

const Color navy = Color(0xFF102A43);
const Color teal = Color(0xFF16B8A6);
const Color pageBackground = Color(0xFFF4F7FA);
const Color mutedText = Color(0xFF64748B);
const Color warningRed = Color(0xFFB42318);
const Color warningBackground = Color(0xFFFFF0EE);
const Color safeGreen = Color(0xFF18794E);

enum UserRole{
  patient,
  caregiver,
  doctor,
}

String rolename(UserRole role) {
  switch (role) {
    case UserRole.patient:
      return 'Patient';
    case UserRole.caregiver:
      return 'Caregiver';
    case UserRole.doctor:
      return 'Doctor';
  }
}

class ChemoWatchApp extends StatelessWidget {
  const ChemoWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:'ChemoWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBackground, 
        colorScheme: ColorScheme.fromSeed(
          seedColor:teal,
          primary: navy,
          secondary:teal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBackground,
          foregroundColor: navy, 
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home:const RoleSelectionPage(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget{
  const RoleSelectionPage({super.key});


  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: Center(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width:76,
                  height:76,
                  decoration: BoxDecoration(
                    color: navy, 
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height:22),
                const Text(
                  'Chemowatch',
                  style:TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color:navy
                  ),
                ),
                const SizedBox(height: 8),
                Const Text(
                  'Helping patients and their care teams keep track of important vital readings.',
                  style: TextStyle(
                    fontSize:16,
                    color:mutedText,
                    height: 1.5,
                  ),
                ),
                const Sized Box(height: 28),
                const Text(
                  'Choose a view',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:navy,
                  ),
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: Icons.favorite_rounded,
                  title:'Patient',
                  description:
                      'A simple dashboard with large readinings and alerts',
                      onTap: () => _openRole(context, userRole.patient),
                ),
                _RoleCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Caregiver',
                  description:
                      'View trends, recent readings, and warning history.',
                  onTap:() => _openRole(context, UserRole.caregiver),
                ),
            _RoleCard(
              icon: Icons.medical_services_rounded,
              title: 'Doctor',
              description:
                  'Review readings, summaries, and recorded alerts.',
              onTap: () => _openRole(context, UserRole.doctor),
            ),
            const SizedBox(height: 20),
            const Text(
              'DEMO MODE: readings are simulated. This app is not '
              'connected to a watch or a medical record system yet.',
              style: TextStyle(
                color: mutedText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
              ],
            ),
          ),

        ),
      ),
    );
  }

  void _openROle(BuildContext context, UserRole role) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationPage(initialRole: role),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const_RoleCard({
    required this.icon,
    required this.title,
    required this.desription,
    required this.onTap,
  }),

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE5F8F5),
                child: Icon(icon, color: navy, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size:17),
            ],
          ),
        ),
      ),
    );
  }
}
class MainNavigationPage extends StatefulWidget{
  final UserRole initialRole;


  const MainNavigationPage({
    super.key,
    required this.initialRole
    
  });
  
  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();

}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late UserRole role;

  List<VitalReading> readings = [];

  bool isLoading = true;
  bool isSaving = false;

  double alertThreshold = 100.4;

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final savedReadings = await ReadingStorage.loadReadings();

    if (!mounted) return;

    setState((){
      readings = savedReadings;
      isLoading = false;
    });
  }

  Future<void> _recordReading() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    final random = math.Random();

    final newReading = VitalReading(
      temperature: double.parse(
        (97.8 + random.nextDouble() * 3.5).toStringAsFixed(1), 
       ),

       heartRate: 65 + random.nextInt(36),
       time: DateTime.now(),
    );

    final updateReadings = [...readings, newReading];

    try{
      await ReadingStorage.saveReadings(updatedReadings);\

      if (!mounted) return;

      setState(() {
        readings = updatedReadings;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated reading saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return; 


      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The reading could not be saved. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearReadings() async {
    await ReadingStorage.clearReadings();

    if (!mounted) return;

    setState(() {
      readings = [];
    });
  }

  void _changeRole(UserRole newRole) {
    setState(() {
      role = newRole;
      selectedTab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      HistoryPage(
        readings: readings,
        threshold: alertThreshold,
      ),
      ReportsPage(
        readings: readings,
        threshold: alertThreshold,
      ),
      const AssistantPage(),
      SettingsPage(
        role: role,
        threshold: alertThreshold,
        onRoleChanged: _changeRole,
        onThresholdChanged: (value) {
          setState((){
            alertThreshold = value;
          });
        },
        onClearReadings: _clearReadings,
        onSignOut: (){
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const RoleSelectionPage(),
            ),
            (route) => false,
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChemoWatch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F8F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                roleName(role),
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ) ,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color:teal))
          : IndexedStack(
            index: selectedTab,
            children: pages,
          ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const[
          NavigationDestination(
            icon:Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (role == UserRole.patient) {
      return PatientDashboard(
        readings: readings,
        threshold: alertThreshold,
        isSaving: isSaving, 
        onRecordReading: _recordReading,
      );
    }

    if (role == UserRole.caregiver) {
      return CaregiverDashboard(
        readings: readings,
        threshold: alertThreshold,
        isSaving: isSaving,
        onRecordReading: _recordReading, 
      );
    }

    return DoctorDashboard(
      readings: readings,
      threshold: alertThreshold,
      isSaving: isSaving,
      onRecordReading: _recordReading,
    );
  }
}

class PageContent extends StatelessWidget {
  final List<Widget> children;

  const PageContent({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class PatientDashboard extends StatelessWidget {
  final List<VitalReading> readings;
  final double threshold;
  final bool isSaving;
  final VoidCallback onRecordReading;

  const PatientDashboard({
    super.key,
    required this.readings,
    required this.threshold,
    required this.isSaving,
    required this.onRecordReading,
  }),

  @override
  Widget build(BuildContext context) {
    final latest = readings.isEmpty ? null : readings.last;
    final hasWarning = 
        latest != null && latest.temperature >= threshold;

    return PageContent(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Your heath overview',
          style: TextStyle(
            color: navy,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your readings, in one simple place.',
          style TextStyle(color: mutedText, fontSize: 15),
        ),
        const SizedBox(height: 20),

        if (hasWarning)
           const AlertBubble(
            isWarning: true,
            title: 'Temperature warning',
            message: 
               'This recorded temperature has reached the demo alert threshold. Follow your oncology teams fever plan and contact them as directed.' 
           )

           else
             const AlertBubble(
              isWarning: false,
              title: 'No demo temperature alert',
              message:
                  'The latest simulated temperature is below the demo threshold. This does not vonfirm that you are medically safe'
             ),

             const SizedBox(height: 18),
             VitalCard(
              title: 'Temperature',
              value: latest == null
              ? 'No reading recorded yet'
              : 'Latest simulated reading', 
             ),
             const SizedBox(height: 14),
             VitalCard(
              title: 'Heart rate',
              value: latest == null ? '--' : '" ${latest.heartRate}"',
              unit: 'bpm',
              icon: Icons.favorite_rounded,
              accent: teal,
              subtitle: latest == null
                 ? 'No reading recorded yet'
                 : 'Latest simulated reading',
             ),
             const SizedBox(height: 16),
             if (latest != null)
                Text(
                  'Last recorded: ${formatDateTime(latest.time)}',
                  style: const TextStyle(color: mutedText, fontSize: 13),
                ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isSaving ? null : onRecordReading,
              icon: isSaving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(isSaving ? 'Saving reading...' : 'Record demo reading'),
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              padding: const EdgeInsets.symmetric(vertical: 17),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ),
            const SizedBox(height: 12),
            Text(
              '${readings.length} reading${readings.length == 1 ? '' : 's'} saved',
              textAlign: TextAlign.center,
              style: const TextStyle(color: mutedText),
            ),
            const SizedBox(height: 20),
            const DemoNotice(),
      ],
    );
  }
}

class CaregiverDashboard extends StatelessWidget {
  final List<VitalReading> readings;
  final double threshold;
  final bool isSaving;
  final VoidCallback onRecordReading;

  const CaregiverDashboard({
    super.key,
    required this.readings,
    required this.threshold,
    required this.isSaving,
    required this.onRecordReading.
  });

  @override
  Widget build(BuildContext context) {
    final latest = readings.isEmpty ? null : readings.last;
    final alertCount = readings 
          .where((reading) => reading.temperature >= threshold)
          .length;

    return PageContent(
      children: [
        const PageHeading(
          title: 'Caregiver overview',
          subtitle: 'Review trends and recent recorded readings.',
        ),
        const SizedBox(height: 18),
        SummaryRow(
          firstLabel: 'Total readings',
          firstValue: '${readings.length}',
          secondLabel: 'Demo alerts',
          secondValue: '$alertCount',
        ),
        const SizedBox(height: 16),
        if (latest != null && latest.temperature >= threshold)
            const AlertBubble(
              isWarning: true,
              title: 'Temperature warning recorded',
              message:
                  'The latest reading reached the demo threshold.'
                  'Follow the patients oncology team instructions.',
            )
        else 
          const AlertBubble(
            isWarning: false,
            title: 'Latest demo status',
            message: 
                'No temperature alert is recorded for the latest reading.'
                'This is not a medical assessment.',
          ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Temperature trend',
          subtitle: 'Recent simulated readings in ॰F',
          child: TemperatureChart(
            readings: readings,
            threshold: threshold,
          ),
        ),
        const SizedBox(height: 18),
        SecctionCard(
          title: 'Latest reading',
          child: latest == null
              ? const EmptyMessage(
                message: 'No readings have been recorded yet.',
              )
            : ReadingTile(
                 reading: latest,
                 threshold: threshold,
            ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: isSaving ? null : onRecordReading,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isSaving ? 'Saving reading...' : 'Record demo reading',
          ),
        ),
        const SizedBox(height: 12),
        const DemoNotice(),
      ],
    );
  }
}

class DoctorDashboard extends StatelessWidget{
  final List<VitalReading> readings;
  final double threshold;
  final bool isSaving;
  final VoidCallback onRecordReading;

  const DoctorDashboard({
    super.key,
    required this.readings,
    required this.threshold,
    required this.isSaving,
    required this.onRecornReading,
  });

  @override 
  Widget build(BuildContext context) {
    final latest = readings.isEmpty ? null : readings.last;
    final alerts = readings
         .where((reading) => reading.temperature >= threshold)
         .toList()
         .reversed
         .toList();

    final averageTemperature = readings.isEmpty
        ? null
        : readings  
                 .map((reading) => reading.temperature)
                 .reduce((a,b) => a + b) /
            readings.length;

    return PageContent(
      children: [
        const PageHeading(
          title: 'Clinical overview',
          subtitle: 
              'Review the saved demonstration readings and recorded alerts',
        ),
        const SizedBox(height: 18),
        SummaryRow(
          firstLabel: 'Readings recorded',
          firstValue: '${readings.length}',
          secondLabel: 'Threshold alerts',
          secondValue: '${alerts.length}',
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Reading summary',
          child: Column(
            children: [
              _SummaryLine(
                label: 'Latest temperature',
                value: latest == null
                    ? 'No data'
                    : '${latest.temperature.toStringAsFixed(1)} ॰F',
              ),
          _SummaryLine(
            label: 'Latest heart rate',
            value: latest == null ? 'No data' : '${latest.heartRate} bpm',
          ),
          _SummaryLine(
            label: 'Latest heart rate',
            value: latest == null ? 'No data' : '${latest.heartRate} bpm',
          ),
          _SummaryLine(
            label: 'Average recorded temperaature',
            value: averageTemperature == null
                ? 'No data'
                : '${averageTemperature.toStringAsFixed} ॰F',
          ),
          _SummaryLine(
            label: 'Latest timestamp',
            value: latest == null 
                 ? 'No data'
                 : formatDateTime(latest.time),
          ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Temperature trend',
          subtitle: 'Simulated data only - not a clinical record',
          child: TemperatureChart(
            readings: readings,
            threshold: threshold,
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Alert history',
          subtitle: 'Readings at or above the current demo threshold',
          child: alerts.isEmpty
               ? const EmptyMessage(
                   message: 'No threshold alerts have been recoreded.',
               )
             : Column(
                 children: alerts.map(
                  (reading) => ReadingTile(
                    reading: reading,
                    threshold: threshold,
                  ),
                 )
                 .toList(),
             ),
        ),
        const SizedBox(height:18),
        OutlinedButton.icon(
          onPressed: isSaving ? null : onRecordReading,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            isSaving ? 'Saving reading...' : 'Record demo reading',
          ),
        ),
        const SizedBox(height: 12),
        const DemoNotice(),
      ],
    );
  }
}

class AlertBubble extends StatelessWidget{
  final bool isWarning;
  final String title;
  final String message;

  cconst AlertBubble({
    super.key,
    required this.isWarning,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? warningRed : safeGreen;
    final background = isWarning
        ? warningBackground
        : const Color(0xFFEAF8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
               ? Icons.warning_amber_rounded
               : Icons.info_outline_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: navy,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VitalCard extends StatelessWidget{
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accent;
  final String subtitle;

  const VitalCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: Row(
          children: [
            Container(
              width: 54,
              height 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment. start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              value,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              unit,
                              style: const TextStyle(
                                color: mutedText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PageHeading extends StatelessWidget{
  final String title;
  final String subtitle;

  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: mutedText,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget{
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondLabel;
  final String secondValue;

  const SummaryRow({
    super.key,
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            label: firstLabel,
            value: firstValue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryBox(
            label: secondLabel,
            value: secondValue,
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryBox({
    required this.label,
    required this.value,
  });

  @override 
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: mutedText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({
    required this.label,
    required this.vale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: mutedText),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final List<VitalReading> readings;
  final double threshold;

  const HistoryPage({
    super.key,
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final newestFirst = readings.reversed.toList();

    return PageContent(
      children: [
        const PageHeading(
          title: 'Reading history',
          subtitle: 'All readings saved on this device, newest first.',
        ),
        const SizedBox(height: 18),
        if (newestFirst.isEmpty)
           const SectionCard(
            title: 'No readings yet',
            child: EmptyMessage(
              message: 
                  'Record a demo reading from Home to see it appear here.',
            ),
           )
        else
          SectionCard(
            title: '${newestFirst.length} saved readings',
            child: Column(
              children: newestFirst
                  .map(
                    (reading) => ReadingTile(
                      reading: reading,
                      threshold: threshold,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          const DemoNotice(),
      ],
    );
    }
}

class ReadingTile extends StatelessWidget{
  final VitalReading reading;
  final double threshold;

  const ReadingTile({
    super.key,
    required this.reading,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = reading.temperature >= threshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isWarning ? warningBackground: pageBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.warning_rounded : Icons.monitor_heart_rounded,
            color: isWarning ? warningRed : teal,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading.temperature.toStringAsFixed(1)} ॰F',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${reading.heartRate} bpm •  ${formatDateTime(reading.time)}',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isWarning)
             const Text(
              'ALERT',
              style: TextStyle(
                color: warningRed,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
             ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget{
  final List<VitalReading> readings;
  final double threshold;

  const ReportsPage({
    super.key,
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final alertReadings = readings
        .where((reading) => reading.temperature >= threshold)
        .toList();

    final averageTemperature = reading.isEmpty
         ? null
         : readings
                .map ((reading) => reading.temperature)
                .reduce((a,b) => a + b) / 
              readings.length;

    final averageHeartRate = readings.isEmpty 
        ? null
        : readings
               .map((reading) => reading.heartRate)
               .reduce((a,b) => a + b) /
            readings.length;

    final highestTemperature = readings.isEmpty
        ? null
        : readings
            .map((reading) => reading.temperature)
            .reduce(math.max);

    return PageContent(
      children: [
        const PageHeading(
          title: 'Reports',
          subtitle: 'A summary of the readings currently saved on this device.',
        ),
        const SizedBox(height: 18),
        SummaryRow(
          firstLabel: 'Total readings',
          firstValue: '${readinga.length}',
          seconLabel: 'Demo alerts',
          secondValue: '${alertReadings.length}',
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Reading summary',
          child: Column(
            children: [
          _SummaryLine(
            label: 'Average temperature',
            value: averageTemperature == null
                ? 'No data'
                : '${highestTemperature.toStringAsFixed(1)} ॰F',
          ),
          _SummaryLine(
            label:'Average heart rate',
            value: averageHeartRate == null
                ? 'No data'
                : '${highestTemperature.toStringAsFixed(1)} ॰F',
          ),
          _SummaryLine(
            label: 'Average heart rate',
            value: averageHeartRate == null  
                 ? 'No data'
                 : '${averageHeartRate.toStringAsFixed(1)} bpm',
          ),
          _SummaryLine(
            label: 'Demo alert threshold',
            value:'${threshold.toStringAsFixed(1)} ॰F',
          ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Alert history',
          child: alertReadings.isEmpty
              ? const EmptyMessage(
                  message:
                    'No saved readings have reached the demo threshold.',
              )
            : Column(
              children: alertReadings.reversed.
                  .map(
                    (reading) => ReadingTile(
                      reading: reading,
                      threshold: threshold,
                    ),
                  ),
                  .toList(),
            ),
        ),
        const SizedBox(height: 12),
        const DemoNotice(),
      ],
    );
  }
}

class TemperatureChart extends StatelessWidget {
  final List<VitalReading> readings;
  final double threshold;

  const TemperatureChart({
    super.key,
    required this.readings,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const EmptyMessage(
        message: 'Record readings to build a temperature trend.',
      );
    }

    final recentReadings = readings.length <= 12
        ? readings
        : readings.sublist(readings.length - 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          width: double.infinty,
          child: CustomPaint(
            painter: TemperatureChartPainter(
              temperatures: recentReadings
                   .map((reading) => reading.temperature)
                   .toList(),
              threshold: threshold,
            ),
          ),
        ),
        const SizedBox(height:8),
        const Text(
          'Each point represents one saved simulated reading.'
          'This graph is for demonstration, not clinical monitoring.',
          style: TextStyle(
            color: mutedText,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class TemperatureChartPainter({
  required this.temperatures,
  required this.threshold,
});

@override
void paint(Canvas canvas, Size size) {
  if (temperatures.isEmpty) return;

  const leftPadding = 42.0;
  const rightPadding = 12.0;
  const topPadding = 18.0;
  const bottomPadding = 28.0;

  final chartWidth = size.width - leftPadding - rightPadding;
  final chartHeight = size.heught - topPadding - bottomPadding;

  if (chartWidth <= 0 || chartHeight <= 0) return;

  final lowest = math.min(
    96.0,
    temperatures.reduce(math.min) - 0.5,
  );
  final highest - math.max(
    threshold + 0.8,
    temperatures.reduce(math.max) + 0.5,
  );

  final range = highest - lowest;

  final gridPaint = Paint()
   ..color = const Color(0xFFE5EAF0)
   ..strokeWidth = 1;

   final linePaint = Paint()
    ..color = teal
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final dotPaint = Paint()
   ..color = navy
   ..style = PaintingStyle.fill;

  final alertPaint = Paint()
   ..color = warningRed 
   ..strokeWidth = 1.5;

   for (int i = 0; i <= 4; i++) {
    final y = topPadding + chartHeight * i/4;
    final value = highest - range * i/4;

    canvas.drawLine(
      Offset(leftPadding, y),
      Offset(size.width - rightPadding, y),
      gridPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toStringAs Fixed(0),
        style: const TextStyle(
          color: mutedText,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(0, y - textPainter.height / 2),
    );
   }

   final thresholdY = topPadding +
   ((highest - threshold) / range) * chartHeight;

   double dashX = leftPadding;

   while (dahsX < size.width - rightPadding) {
    canvas.drawLine(
      Offset(dashX, thresholdY),
      Offset(math.min(dashX + 6, size.width - rightPadding), thresholdY),
      alertPaint,
    );

    dashX +=11;
   }

   final points = <Offset>[];
   for (int i=-; i < temperatures.length; i++){
   final x = temperatures.length == 1
         ? leftPadding + chartWidth /2
         : leftpadding + chartWidthe * i ./ (temperatures.length - 1);
    
   final y = topPadding + 
       ((highest - temperature[i]) / range) * chartHeight;
   points.add(Offset (x,y));
   }

   final path = Path();

   for (int i = 0; i< points.length; i++) {
    if (i == 0) {
      path.moveTo(points[i].dx, points[i].dy);
    } else{
      path.lineTo(points[i].dx, points [i].dy);
    }
   }

   canvas.drawPath(path, linePaint);

   for (int i = 0; i < points.length; i++){
    final isAlert = temperatures[i] >= threshold;

    canvas.drawCircle(
      points[i],
      4.5,
      Paint()
       ..color = isAlert ? warningRed : teal
       ..style = PaintingStyle.fil,
    );

    canvas.drawCircle(
      points[i],
      4.5,
      Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke,
    );
   }

   _drawBottomLabel(
    canvas,
    'Oldest',
    Offset(left Padding,sexe.height - 19),
   );

   _drawBottomLabel(
    canvas, 
    'Newest',
    Offset (size.width - rightPadding - 37, size.height -19),
   );
}

void _drawBottomLabel(Canvas canvas, String label, Offset position) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: mutedText,
        fontSize: 10,
      ),
    ),
    textDirection: TextDirection.ltr,
  )...layout();

  painter.paint(canvas, position);
}

@override
bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) {
  return oldDelegate.temperatures != temperatures ||
     oldDelegate.threshold != threshold;
}

class EMptyMessage extends StatelessWidget {
  final String message;

  const EmptyMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuldContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: mutedText,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class DemoNotice extends StatelessWidget {
  const DemoNotice ({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decorationL BoxDecoration(
        color: const Color(0xFFEAF0F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icons.info_outline_rounded, color: navy),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo mode: These readings are simulated and stored locally. No watch connection, remote sharing, or live medical monitoring in this verision.',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatDateTime(DateTime time) {
  final localTime = time.toLocal();

  final month = localTime.month.toString().padLeft(2,'0');
  final day = localTime.day.toString().padLeft(2,'0');
  final year = localTime.year;

  final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
  final minute = localTime.minute.toString().padleft(2,'0');
  final period = localTime.hour >=12 ? 'PM' : 'AM';

  return '$month/$day/$year, $hour:$minute $period';
}