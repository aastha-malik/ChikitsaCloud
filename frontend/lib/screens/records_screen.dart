import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../presentation/providers/reports_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../widgets/record_tile.dart';
import '../theme/app_theme.dart';

class RecordsScreen extends StatefulWidget {
  final String? ownerId;
  final String? ownerName;

  const RecordsScreen({super.key, this.ownerId, this.ownerName});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchRecords(ownerId: widget.ownerId);
    });
  }

  void _showUploadModal() {
    final titleController = TextEditingController();
    String selectedType = 'lab_report';
    PlatformFile? selectedFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Medical Record', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Blood Test Report',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Record Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'lab_report', child: Text('Lab Report')),
                  DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                  DropdownMenuItem(value: 'scan_image', child: Text('Scan/Image')),
                  DropdownMenuItem(value: 'discharge_summary', child: Text('Discharge Summary')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null) {
                    setModalState(() => selectedFile = result.files.single);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedFile?.name ?? 'Select File (PDF, JPG, PNG)',
                          style: TextStyle(color: selectedFile == null ? Colors.grey : Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    final success = await context.read<ReportsProvider>().uploadRecord(
                      title: titleController.text,
                      recordType: selectedType,
                      filePath: selectedFile!.path!,
                      fileName: selectedFile!.name,
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Upload Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String recordId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to permanently delete this medical record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ReportsProvider>().deleteRecord(recordId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isViewingOthers = widget.ownerId != null && widget.ownerId != authProvider.userId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isViewingOthers ? "${widget.ownerName}'s Records" : 'Medical Records', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (isViewingOthers)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Read-only Access', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          Expanded(
            child: reportsProvider.isLoading && reportsProvider.records.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => reportsProvider.fetchRecords(ownerId: widget.ownerId),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: reportsProvider.records.length,
                    itemBuilder: (context, index) {
                      final record = reportsProvider.records[index];
                      final isLatest = index == 0;
                      final hasInsight = record['ai_insight'] != null;

                      return Column(
                        children: [
                          if (isLatest && hasInsight) _buildAIInsightBox(record['ai_insight']),
                          RecordTile(
                            title: record['title'] ?? 'Untitled',
                            date: record['created_at']?.split('T')[0] ?? 'N/A',
                            type: _formatType(record['record_type']),
                            onDelete: isViewingOthers ? null : () => _confirmDelete(record['id']),
                            onTap: () {
                              final ext = record['file_path'].split('.').last;
                              reportsProvider.viewRecord(record['id'], "${record['title']}.$ext");
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: isViewingOthers ? null : FloatingActionButton(
        heroTag: 'add_record',
        onPressed: _showUploadModal,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAIInsightBox(String insight) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCE3FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF0066FF), size: 18),
              const SizedBox(width: 8),
              Text('LATEST AI INSIGHT', style: TextStyle(color: const Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14)),
        ],
      ),
    );
  }

  String _formatType(String? type) {
    if (type == null) return 'General';
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
