import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../presentation/providers/family_provider.dart';
import '../theme/app_theme.dart';
import 'records_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().fetchQRData();
      context.read<FamilyProvider>().fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTab('My QR Code', 0),
                  _buildTab('Requests & Access', 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: _tabIndex == 0 ? _buildQRTab(familyProvider) : _buildRequestsTab(familyProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRTab(FamilyProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Column(
              children: [
                if (provider.qrData != null)
                  QrImageView(
                    data: provider.qrData!,
                    version: QrVersions.auto,
                    size: 200.0,
                    foregroundColor: AppTheme.primaryColor,
                  )
                else
                  const Icon(Icons.qr_code, size: 200, color: Colors.grey),
                const SizedBox(height: 24),
                const Text('Share Medical Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Show this QR code to a family member to grant them read-only access to your records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanningUI ? null : _openScanner,
                  icon: _isScanningUI 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt_outlined),
                  label: const Text('Scan QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Send Invite'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Access Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email address of the user whose medical records you want to request access to.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'User Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              
              Navigator.pop(context);
              final success = await context.read<FamilyProvider>().requestAccessByEmail(email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Request sent successfully!' : 'User not found or request failed'))
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  bool _isScanningUI = false;

  void _openScanner() {
    if (_isScanningUI) return;
    setState(() => _isScanningUI = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    ).then((token) async {
      setState(() => _isScanningUI = false);
      if (token != null && token is String) {
        final provider = context.read<FamilyProvider>();
        final success = await provider.redeemInvite(token);
        
        if (mounted) {
          String message = 'Access request sent!';
          if (!success && provider.errorMessage != null) {
            message = provider.errorMessage!;
          } else if (success && provider.lastRedeemResult?['status'] == 'already_exists') {
            message = provider.lastRedeemResult?['message'] ?? 'You already have access or a pending request.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  Widget _buildRequestsTab(FamilyProvider provider) {
    debugPrint('[DEBUG] Pending: ${provider.pendingRequests.length}, Sent: ${provider.sentRequests.length}');
    return RefreshIndicator(
      onRefresh: () => provider.fetchRequests(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        _buildSectionTitle('PENDING (INCOMING)'),
        const SizedBox(height: 12),
        if (provider.pendingRequests.isEmpty)
          Text('No incoming requests', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
        else
          ...provider.pendingRequests.map((r) => _buildRequestCard(r, provider)),
        const SizedBox(height: 32),
        _buildSectionTitle('SENT REQUESTS (WAITING)'),
        const SizedBox(height: 12),
        if (provider.sentRequests.isEmpty)
          Text('No sent requests pending', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
        else
          ...provider.sentRequests.map((r) => _buildSentRequestCard(r)),
        const SizedBox(height: 32),
        _buildSectionTitle('MUTUAL ACCESS (FAMILY CONNECTIONS)'),
        const SizedBox(height: 12),
        if (provider.activeAccess.isEmpty)
          Text('No active family connections', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
        else
          ...provider.activeAccess.map((a) => _buildAccessCard(a, provider)),
      ],
    ),
);
  }

  Widget _buildSentRequestCard(dynamic r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text(r['owner_name']?[0] ?? '?', style: const TextStyle(color: Colors.blue))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requested: ${r['owner_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(r['owner_email'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          const Chip(
            label: Text('Pending', style: TextStyle(fontSize: 10, color: Colors.blue)),
            backgroundColor: Color(0xFFE3F2FD), // Subtle blue
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2));
  }

  Widget _buildRequestCard(dynamic r, FamilyProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.orange.shade50, child: Text(r['requester_name']?[0] ?? '?', style: const TextStyle(color: Colors.orange))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['requester_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(r['requester_email'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => provider.respondToRequest(r['id'], false),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
          IconButton(
            onPressed: () => provider.respondToRequest(r['id'], true),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(dynamic a, FamilyProvider provider) {
    final name = a['viewer_name'];
    final email = a['viewer_email'];
    final targetId = a['viewer_user_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: Text(name?[0] ?? '?')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(email ?? 'N/A', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordsScreen(
                    ownerId: targetId,
                    ownerName: name,
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => provider.revokeAccess(targetId),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  // CRITICAL: Synchronous lock to prevent double-pop and double-request
  bool _hasDetected = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // If already detected, UNMOUNT the scanner immediately to release GPU
          if (!_hasDetected)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) async {
                if (_hasDetected) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  // Hard lock immediately
                  _hasDetected = true;
                  final String code = barcodes.first.rawValue!;
                  
                  // Release hardware
                  await _controller.stop();
                  
                  if (mounted) {
                    // Force rebuild to unmount scanner widget from Stack
                    setState(() {});
                    
                    // Give OS time to clear the camera buffer
                    await Future.delayed(const Duration(milliseconds: 150));
                    
                    if (mounted) {
                      Navigator.of(context).pop(code);
                    }
                  }
                }
              },
            ),
          
          if (_hasDetected)
            const Center(child: CircularProgressIndicator()),

          // UI Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: _hasDetected ? Colors.white : Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          if (!_hasDetected)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
