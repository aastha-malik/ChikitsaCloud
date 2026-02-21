import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/record_tile.dart';
import '../presentation/providers/reports_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/profile_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'profile_screen.dart';
import 'family_screen.dart';
import 'records_screen.dart';
import 'hospitals_screen.dart';
import '../presentation/providers/theme_provider.dart';
import 'analysis_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/sos_button.dart';
import '../utils/emergency_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        context.read<ReportsProvider>().fetchRecords();
        await context.read<ProfileProvider>().fetchProfile();
        
        if (mounted) {
          final profile = context.read<ProfileProvider>().profileData;
          final themePref = profile?['personal_details']?['theme_preference'];
          if (themePref != null) {
             final mode = themePref == 'dark' ? ThemeMode.dark : ThemeMode.light;
             context.read<ThemeProvider>().setTheme(mode, save: false);
          }
        }
      }
    });
  }

  Future<void> _handleUpload() async {
    final authProvider = context.read<AuthProvider>();
    final reportsProvider = context.read<ReportsProvider>();

    if (authProvider.userId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final success = await reportsProvider.uploadRecord(
        title: result.files.single.name.split('.').first,
        recordType: 'other',
        filePath: result.files.single.path!,
        fileName: result.files.single.name,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report uploaded successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reportsProvider.errorMessage ?? 'Upload failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profileData?['personal_details'];

    final List<Widget> _bodies = [
      _buildHomeContent(reportsProvider, authProvider, profile),
      RecordsScreen(),
      FamilyScreen(),
      HospitalsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _bodies,
      ),
      floatingActionButton: const SOSButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2A8B8B),
        unselectedItemColor: const Color(0xFF64748B),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home', activeIcon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Hospitals'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent(ReportsProvider reportsProvider, AuthProvider authProvider, Map<String, dynamic>? profile) {
    // Show max 3 latest records
    final recentRecords = reportsProvider.records.take(3).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, authProvider, profile),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Quick Access'),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuickAccessCard(
                        title: 'Upload Record',
                        icon: Icons.note_add_outlined,
                        iconColor: AppTheme.accentBlue,
                        onTap: _handleUpload,
                      ),
                      const SizedBox(width: 16),
                      QuickAccessCard(
                        title: 'Share Access',
                        icon: Icons.share_location_outlined,
                        iconColor: AppTheme.accentPurple,
                        onTap: () => setState(() => _selectedIndex = 2), // Switch to Family tab
                      ),
                      const SizedBox(width: 16),
                      QuickAccessCard(
                        title: 'Health AI',
                        icon: Icons.analytics_outlined,
                        iconColor: Colors.orange, // Keep orange as is or add to AppTheme if needed
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AnalysisScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Recent Records'),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1), // Switch to Records tab
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Color(0xFF2A8B8B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (reportsProvider.isLoading && recentRecords.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (reportsProvider.errorMessage != null && recentRecords.isEmpty)
                  Center(child: Text(reportsProvider.errorMessage!, style: const TextStyle(color: Colors.red)))
                else if (recentRecords.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No records found', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...recentRecords.map((record) => RecordTile(
                        title: record['title'] ?? 'Untitled',
                        date: record['created_at']?.split('T')[0] ?? 'Unknown',
                        type: _formatType(record['record_type']),
                        onTap: () {
                          final ext = record['file_path'].split('.').last;
                          reportsProvider.viewRecord(record['id'], "${record['title']}.$ext");
                        },
                      )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String? type) {
    if (type == null) return 'General';
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Widget _buildPlaceholder(String title) {
    return Center(child: Text('$title Screen Coming Soon'));
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider, Map<String, dynamic>? profile) {
    final String name = profile?['name'] ?? 'User';
    final String age = _calculateAge(profile?['date_of_birth']);
    final String height = profile?['height']?.toString() ?? '--';
    final String weight = profile?['weight']?.toString() ?? '--';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF2A8B8B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 32,
                  height: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30), // Increased space since ID tag is removed
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(label: 'Age', value: age),
                const _VerticalDivider(),
                _InfoItem(label: 'Height', value: height != '--' ? '$height cm' : '--'),
                const _VerticalDivider(),
                _InfoItem(label: 'Weight', value: weight != '--' ? '$weight kg' : '--'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAge(String? dobString) {
    if (dobString == null) return '--';
    try {
      final dob = DateTime.parse(dobString);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return '--';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}
