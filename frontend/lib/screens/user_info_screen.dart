import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+91'); // Default
  final _allergiesController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _initialized = false;

  final Map<String, String> _countryMap = {
    '+91': 'India',
    '+1': 'USA',
    '+44': 'UK',
    '+61': 'Australia',
    '+81': 'Japan',
    '+971': 'UAE',
    '+65': 'Singapore',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().fetchProfile();
      if (mounted) {
        _populateFields();
        setState(() => _initialized = true);
      }
    });
  }

  void _populateFields() {
    final profile = context.read<ProfileProvider>().profileData?['personal_details'];
    if (profile != null) {
      if (profile['name'] != null && _nameController.text.isEmpty) {
        // If name is just the email prefix (default), maybe let user edit it or clear it? 
        // We'll keep it as is, user can change it.
        _nameController.text = profile['name']; 
      }
      if (profile['date_of_birth'] != null) {
        _dobController.text = AppDateUtils.isoToDisplay(profile['date_of_birth']) ?? '';
      }
      if (profile['gender'] != null) _selectedGender = profile['gender'];
      if (profile['height'] != null) _heightController.text = profile['height'].toString();
      if (profile['weight'] != null) _weightController.text = profile['weight'].toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    _countryCodeController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _handleDatePick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = AppDateUtils.formatDateTime(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your gender')));
      return;
    }

    final dobIso = AppDateUtils.displayToIso(_dobController.text);
    if (dobIso == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid date format')));
       return;
    }

    final data = {
      'personal_details': {
        'name': _nameController.text.trim(),
        'date_of_birth': dobIso,
        'gender': _selectedGender,
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
        'phone_country_code': _countryCodeController.text.trim(),
        'phone_number': int.tryParse(_phoneController.text.trim()),
        'blood_group': _selectedBloodGroup,
        'allergies': _allergiesController.text.isNotEmpty 
            ? _allergiesController.text.split(',').map((e) => e.trim()).toList() 
            : [],
      }
    };

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(data);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Setup failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading && !_initialized;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome to ChikitsaCloud",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Let's set up your medical profile. This information is critical for your health records.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Basic Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "All fields are required for accurate medical history.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Full Name
                              _buildLabel("Full Name"),
                              _buildTextField(
                                controller: _nameController,
                                hint: "e.g. Sarah Jenkins",
                                validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 20),
                              
                              // Row: DOB & Gender
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Date of Birth"),
                                        _buildTextField(
                                          controller: _dobController,
                                          hint: "dd/mm/yyyy",
                                          readOnly: true,
                                          onTap: _handleDatePick,
                                          suffixIcon: Icons.calendar_today_outlined,
                                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Gender"),
                                        DropdownButtonFormField<String>(
                                          value: _selectedGender,
                                          items: ['Male', 'Female', 'Other']
                                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                              .toList(),
                                          onChanged: (val) => setState(() => _selectedGender = val),
                                          decoration: _inputDecoration("Select"),
                                          hint: const Text("Select", style: TextStyle(color: Color(0xFF94A3B8))),
                                          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                                          validator: (v) => v == null ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Row: Height & Weight
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Height (cm)"),
                                        _buildTextField(
                                          controller: _heightController,
                                          hint: "165",
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Weight (kg)"),
                                        _buildTextField(
                                          controller: _weightController,
                                          hint: "62",
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Blood Group
                              _buildLabel("Blood Group"),
                              DropdownButtonFormField<String>(
                                value: _selectedBloodGroup,
                                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedBloodGroup = val),
                                decoration: _inputDecoration("Select Blood Group"),
                                hint: const Text("Select Blood Group", style: TextStyle(color: Color(0xFF94A3B8))),
                                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 20),

                              // Phone Number
                              _buildLabel("Phone Number"),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: _buildTextField(
                                      controller: _countryCodeController,
                                      hint: "+91",
                                      keyboardType: TextInputType.phone,
                                      validator: (v) => v?.isEmpty == true ? 'Req' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _phoneController,
                                      hint: "9876543210",
                                      keyboardType: TextInputType.phone,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Required';
                                        if (v.length < 10) return 'Invalid number';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Allergies
                              Row(
                                children: [
                                  _buildLabel("Allergies"),
                                  const SizedBox(width: 8),
                                  const Text("(Optional)", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                ],
                              ),
                              _buildTextField(
                                controller: _allergiesController,
                                hint: "e.g. Peanuts, Penicillin (separate by comma)",
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 32),
                              
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: context.watch<ProfileProvider>().isLoading && _initialized ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2A8B8B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: context.watch<ProfileProvider>().isLoading && _initialized 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Complete Setup", 
                                            style: TextStyle(
                                              color: Colors.white, 
                                              fontSize: 16, 
                                              fontWeight: FontWeight.w600
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16),
      validator: validator,
      decoration: _inputDecoration(hint, suffixIcon),
    );
  }

  InputDecoration _inputDecoration(String hint, [IconData? suffixIcon]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A8B8B), width: 1.5),
      ),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF94A3B8), size: 20) : null,
    );
  }
}
