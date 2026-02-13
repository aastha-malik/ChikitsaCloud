import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/analysis_provider.dart';
import '../presentation/providers/profile_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Inputs (removed height and weight as per request)
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _hbController = TextEditingController();
  final _creatinineController = TextEditingController();
  final _sugarController = TextEditingController();
  final _cholesterolController = TextEditingController();

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _spo2Controller.dispose();
    _hbController.dispose();
    _creatinineController.dispose();
    _sugarController.dispose();
    _cholesterolController.dispose();
    super.dispose();
  }

  Future<void> _handleAnalyze() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final analysisProvider = context.read<AnalysisProvider>();
      
      final data = {
        "user_id": authProvider.userId,
        "bp_systolic": double.tryParse(_sysController.text) ?? 0,
        "bp_diastolic": double.tryParse(_diaController.text) ?? 0,
        "spo2": double.tryParse(_spo2Controller.text) ?? 0,
        "hemoglobin": double.tryParse(_hbController.text) ?? 0,
        "creatinine": double.tryParse(_creatinineController.text) ?? 0,
        "blood_sugar": double.tryParse(_sugarController.text) ?? 0,
        "cholesterol": double.tryParse(_cholesterolController.text) ?? 0,
      };

      final success = await analysisProvider.analyzeData(data);
      if (success && mounted) {
        _showResultModal(analysisProvider.analysisResult!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(analysisProvider.errorMessage ?? 'Analysis failed'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    }
  }

  void _showResultModal(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Analysis Results',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result['summary'] ?? '',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildRiskIndicator(result['overall_health_risk']),
              const SizedBox(height: 32),
              const Text(
                'Parameters Detail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (result['all_analysis'] != null)
                ... (result['all_analysis'] as List).map((item) => _buildResultTile(item)),
              const SizedBox(height: 24),
              PrimaryButton(
                text: "Close",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String? risk) {
    Color color;
    switch (risk?.toLowerCase()) {
      case 'low risk':
        color = Colors.green;
        break;
      case 'moderate risk':
        color = Colors.orange;
        break;
      case 'high risk':
        color = Colors.red;
        break;
      case 'critical risk':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Health Risk',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                Text(
                  risk ?? 'Unknown',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(Map<String, dynamic> item) {
    final severity = item['severity'] ?? '⚪';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['parameter'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                severity,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Value: ${item['value']} ${item['unit']}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Text(
                'Range: ${item['range']}',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (item['explanation'] != null) ...[
            const SizedBox(height: 8),
            Text(
              item['explanation'],
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisProvider = context.watch<AnalysisProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profileData?['personal_details'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Abnormalities'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserContext(profile),
              const SizedBox(height: 32),
              const Text(
                'Enter Lab Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your recent medical parameters for AI analysis.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Sys BP",
                      hintText: "e.g. 120",
                      controller: _sysController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: "Dia BP",
                      hintText: "e.g. 80",
                      controller: _diaController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "SpO2 (%)",
                hintText: "e.g. 98",
                controller: _spo2Controller,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Hemoglobin (g/dL)",
                hintText: "e.g. 14.2",
                controller: _hbController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Creatinine (mg/dL)",
                hintText: "e.g. 1.0",
                controller: _creatinineController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Blood Sugar (Fasting)",
                hintText: "e.g. 95",
                controller: _sugarController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Cholesterol (mg/dL)",
                hintText: "e.g. 180",
                controller: _cholesterolController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: "Analyze Health Metrics",
                isLoading: analysisProvider.isLoading,
                onPressed: _handleAnalyze,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserContext(Map<String, dynamic>? profile) {
    if (profile == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile['name'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "Height: ${profile['height'] ?? '--'} cm | Weight: ${profile['weight'] ?? '--'} kg",
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
