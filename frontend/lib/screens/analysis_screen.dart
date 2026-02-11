import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/analysis_provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Inputs
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _sysController = TextEditingController(text: '120');
  final _diaController = TextEditingController(text: '80');
  final _spo2Controller = TextEditingController(text: '98');
  final _hbController = TextEditingController(text: '14');
  final _creatinineController = TextEditingController(text: '1.0');
  final _sugarController = TextEditingController(text: '90');
  final _cholesterolController = TextEditingController(text: '180');

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
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
        "height": double.tryParse(_heightController.text),
        "weight": double.tryParse(_weightController.text),
        "bp_systolic": int.tryParse(_sysController.text),
        "bp_diastolic": int.tryParse(_diaController.text),
        "spo2": int.tryParse(_spo2Controller.text),
        "hemoglobin": double.tryParse(_hbController.text),
        "creatinine": double.tryParse(_creatinineController.text),
        "blood_sugar": double.tryParse(_sugarController.text),
        "cholesterol": double.tryParse(_cholesterolController.text),
      };

      final success = await analysisProvider.analyzeData(data);
      if (success && mounted) {
        _showResultDialog(analysisProvider.analysisResult!);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(analysisProvider.errorMessage ?? 'Analysis failed')),
        );
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Risk Level: ${result['overall_health_risk']}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              const Text('Flags:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (result['flagged_parameters'] != null)
                ...(result['flagged_parameters'] as List).map((flag) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${flag['parameter']}: ${flag['severity']} - ${flag['explanation']}'),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Health Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(label: "Height (cm)", controller: _heightController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomTextField(label: "Weight (kg)", controller: _weightController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: "BP Systolic", controller: _sysController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(label: "BP Diastolic", controller: _diaController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(label: "SpO2 (%)", controller: _spo2Controller, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomTextField(label: "Hemoglobin (g/dL)", controller: _hbController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomTextField(label: "Creatinine (mg/dL)", controller: _creatinineController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomTextField(label: "Blood Sugar (mg/dL)", controller: _sugarController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomTextField(label: "Cholesterol (mg/dL)", controller: _cholesterolController, keyboardType: TextInputType.number),
              const SizedBox(height: 32),
              PrimaryButton(
                text: "Run AI Analysis",
                isLoading: analysisProvider.isLoading,
                onPressed: _handleAnalyze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
