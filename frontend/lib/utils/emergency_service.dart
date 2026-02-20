import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  static const String emergencyNumber = "112";

  /// Initiates a call to the emergency number.
  /// Shows a confirmation dialog before proceeding.
  static Future<void> triggerSOS(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Emergency SOS',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to call emergency services (112)?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('CALL 112'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final Uri telUri = Uri.parse('tel:$emergencyNumber');
      
      try {
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        } else {
          if (context.mounted) {
            _showErrorSnackBar(context, 'Could not initiate the call. Please dial 112 manually.');
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'An error occurred: $e');
        }
      }
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
