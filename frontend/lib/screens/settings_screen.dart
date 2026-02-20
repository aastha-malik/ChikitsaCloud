import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../utils/emergency_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;

    void showDeleteConfirmation() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to delete your account? This action is permanent and all your medical records will be lost forever.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final success = await authProvider.deleteAccount();
                if (success && context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to delete account')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }

    Future<void> _contactSupport() async {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'aasthamalik.work@gmail.com',
        queryParameters: {
          'subject': 'Support Request - ChikitsaCloud',
        },
      );
      
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email app')),
          );
        }
      }
    }

    void _showContactOptions() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Contact Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'How would you like to reach us?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                ),
                title: const Text('Send Email', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Open your default email app'),
                onTap: () {
                  Navigator.pop(context);
                  _contactSupport();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.copy_outlined, color: Colors.blue),
                ),
                title: const Text('Copy Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('aasthamalik.work@gmail.com'),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'aasthamalik.work@gmail.com'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email address copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                value: isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_reset_outlined, color: AppTheme.primaryColor),
                title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Change your account password', style: Theme.of(context).textTheme.bodyMedium),
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color),
                onTap: () {
                  Navigator.pushNamed(context, '/reset-password');
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.mail_outline, color: AppTheme.primaryColor),
                title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Email us at aasthamalik.work@gmail.com', style: Theme.of(context).textTheme.bodyMedium),
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color),
                onTap: _showContactOptions,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.emergency_outlined, color: Colors.red),
                title: const Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: Text('Call emergency services (112)', style: Theme.of(context).textTheme.bodyMedium),
                trailing: const Icon(Icons.call, color: Colors.red),
                onTap: () => EmergencyService.triggerSOS(context),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                subtitle: Text('Permanently remove your account', style: Theme.of(context).textTheme.bodyMedium),
                onTap: showDeleteConfirmation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
