import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _allergyController = TextEditingController();

  final Map<String, String> _countryMap = {
    '+91': 'India',
    '+1': 'USA',
    '+44': 'UK',
    '+61': 'Australia',
    '+81': 'Japan',
    '+971': 'UAE',
    '+65': 'Singapore',
  };

  final List<String> _relationshipTypes = [
    'Parent/Guardian',
    'Partner',
    'Child',
    'Friend',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  void _handleAddAllergy() async {
    final allergy = _allergyController.text.trim();
    if (allergy.isEmpty) return;

    final provider = context.read<ProfileProvider>();
    final currentAllergies = List<String>.from(provider.profileData?['allergies'] ?? []);
    if (!currentAllergies.contains(allergy)) {
      currentAllergies.add(allergy);
      final success = await provider.updateProfile({
        'personal_details': {'allergies': currentAllergies}
      });
      if (success) {
        _allergyController.clear();
      }
    }
  }

  void _handleRemoveAllergy(String allergy) async {
    final provider = context.read<ProfileProvider>();
    final currentAllergies = List<String>.from(provider.profileData?['allergies'] ?? []);
    currentAllergies.remove(allergy);
    await provider.updateProfile({
      'personal_details': {'allergies': currentAllergies}
    });
  }

  void _showEditPersonalDetails(Map<String, dynamic> details) {
    final nameController = TextEditingController(text: details['name']);
    final dobController = TextEditingController(text: AppDateUtils.isoToDisplay(details['date_of_birth']) ?? '');
    String? selectedGender = details['gender'];
    final heightController = TextEditingController(text: details['height']?.toString());
    final weightController = TextEditingController(text: details['weight']?.toString());
    final bloodGroupController = TextEditingController(text: details['blood_group']);
    final phoneController = TextEditingController(text: details['phone_number']?.toString());
    final countryCodeController = TextEditingController(text: details['phone_country_code'] ?? '+91');
    final countryController = TextEditingController(text: details['country'] ?? _countryMap['+91']);

    void updateCountry(String code) {
      if (_countryMap.containsKey(code)) {
        countryController.text = _countryMap[code]!;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Personal Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildDateField(context, dobController, 'Date of Birth (DD/MM/YYYY)', setModalState),
                const SizedBox(height: 16),
                _buildGenderDropdown(selectedGender, (val) => setModalState(() => selectedGender = val)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(heightController, 'Height (cm)', Icons.height, keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(weightController, 'Weight (kg)', Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(bloodGroupController, 'Blood Group', Icons.bloodtype_outlined),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildTextField(
                        countryCodeController, 
                        'Code', 
                        Icons.add,
                        onChanged: (val) {
                          setModalState(() => updateCountry(val));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        phoneController, 
                        'Phone Number', 
                        Icons.phone_outlined, 
                        keyboardType: TextInputType.number
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(countryController, 'Country', Icons.public, enabled: false),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                        return;
                      }

                      final dobIso = AppDateUtils.displayToIso(dobController.text);
                      if (dobIso != null) {
                        final birthDate = DateTime.parse(dobIso);
                        if (birthDate.isAfter(DateTime.now())) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Birth date cannot be in the future')));
                          return;
                        }
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final success = await context.read<ProfileProvider>().updateProfile({
                        'personal_details': {
                          'name': nameController.text,
                          'date_of_birth': dobIso,
                          'gender': selectedGender,
                          'height': double.tryParse(heightController.text),
                          'weight': double.tryParse(weightController.text),
                          'blood_group': bloodGroupController.text.isEmpty ? null : bloodGroupController.text,
                          'phone_number': int.tryParse(phoneController.text),
                          'phone_country_code': countryCodeController.text.isEmpty ? null : countryCodeController.text,
                          'country': countryController.text,
                        }
                      });

                      if (success && mounted) {
                        Navigator.pop(context);
                        messenger.showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditEmergencyContact({Map<String, dynamic>? contact}) {
    final isEditing = contact != null;
    final nameController = TextEditingController(text: contact?['name']);
    
    // STRICT SANITIZATION: Default to null if current value is not in allowed list
    String? rawRelation = contact?['relation'];
    String? selectedRelation = _relationshipTypes.contains(rawRelation) ? rawRelation : null;

    final phoneController = TextEditingController(text: contact?['phone_number']?.toString());
    final countryCodeController = TextEditingController(text: contact?['phone_country_code'] ?? '+91');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Edit Emergency Contact' : 'Add Emergency Contact',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Contact Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildRelationDropdown(selectedRelation, (val) => setModalState(() => selectedRelation = val)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100, 
                    child: _buildTextField(countryCodeController, 'Code', Icons.add)
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      phoneController, 
                      'Phone Number', 
                      Icons.phone_outlined, 
                      keyboardType: TextInputType.number
                    )
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || selectedRelation == null || phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                      return;
                    }
                    
                    final data = {
                      'name': nameController.text,
                      'relation': selectedRelation,
                      'phone_number': int.tryParse(phoneController.text),
                      'phone_country_code': countryCodeController.text,
                    };

                    final provider = context.read<ProfileProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    
                    bool success;
                    if (isEditing) {
                      success = await provider.updateEmergencyContact(contact['id'], data);
                    } else {
                      success = await provider.addEmergencyContact(data);
                    }

                    if (success && mounted) {
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Contact updated!' : 'Contact added!'))
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update Contact' : 'Add Contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteContact(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this emergency contact?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final provider = context.read<ProfileProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final success = await provider.deleteEmergencyContact(id);
              if (success && mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('Contact deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType? keyboardType, bool enabled = true, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, TextEditingController controller, String label, StateSetter setModalState) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setModalState(() {
            controller.text = AppDateUtils.formatDateTime(picked);
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildGenderDropdown(String? currentValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      onChanged: onChanged,
      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.wc_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildRelationDropdown(String? currentValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      onChanged: onChanged,
      items: _relationshipTypes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      decoration: InputDecoration(
        labelText: 'Relationship',
        prefixIcon: const Icon(Icons.family_restroom_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    if (profileProvider.isLoading && profileProvider.profileData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileProvider.errorMessage != null && profileProvider.profileData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Something went wrong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(profileProvider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => profileProvider.fetchProfile(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = profileProvider.profileData;
    final personalDetails = data?['personal_details'] ?? {};
    final allergies = List<String>.from(data?['allergies'] ?? []);
    final emergencyContacts = List<dynamic>.from(data?['emergency_contacts'] ?? []);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => profileProvider.fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(personalDetails),
              const SizedBox(height: 32),
              _buildSectionHeader('Personal Details', onEdit: () => _showEditPersonalDetails(personalDetails)),
              const SizedBox(height: 12),
              _buildPersonalDetailsCard(personalDetails),
              const SizedBox(height: 32),
              _buildSectionHeader('Allergies'),
              const SizedBox(height: 12),
              _buildAllergiesCard(allergies),
              const SizedBox(height: 32),
              _buildSectionHeader('Emergency Contacts', onAdd: () => _showAddEditEmergencyContact()),
              const SizedBox(height: 12),
              _buildEmergencyContactsSection(emergencyContacts),
              const SizedBox(height: 32),
              _buildLogoutButton(),
              const SizedBox(height: 16),
              _buildDeleteAccountButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit, VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryColor),
            onPressed: onEdit,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24, color: AppTheme.primaryColor),
            onPressed: onAdd,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> details) {
    String initials = "U";
    if (details['name'] != null && details['name'].toString().isNotEmpty) {
      initials = details['name'].toString().substring(0, 1).toUpperCase();
    }

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          const SizedBox(height: 16),
          Text(details['name'] ?? 'Complete Profile', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today_outlined, 'Date of Birth', AppDateUtils.isoToDisplay(details['date_of_birth']) ?? 'Not set'),
          const Divider(height: 32),
          _buildDetailRow(Icons.person_outline, 'Gender', details['gender'] ?? 'Not set'),
          const Divider(height: 32),
          _buildDetailRow(Icons.height, 'Height', details['height'] != null ? '${details['height']} cm' : 'Not set'),
          const Divider(height: 32),
          _buildDetailRow(Icons.monitor_weight_outlined, 'Weight', details['weight'] != null ? '${details['weight']} kg' : 'Not set'),
          const Divider(height: 32),
          _buildDetailRow(Icons.bloodtype_outlined, 'Blood Group', details['blood_group'] ?? 'Not set'),
          const Divider(height: 32),
          _buildDetailRow(Icons.phone_outlined, 'Phone', '${details['phone_country_code'] ?? '+91'} ${details['phone_number'] ?? 'Not set'}'),
          const Divider(height: 32),
          _buildDetailRow(Icons.public, 'Country', details['country'] ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildAllergiesCard(List<String> allergies) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allergies.isEmpty)
            const Text('No allergies listed', style: TextStyle(color: AppTheme.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergies.map((allergy) => Chip(
                label: Text(allergy),
                onDeleted: () => _handleRemoveAllergy(allergy),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                deleteIconColor: AppTheme.primaryColor,
                side: BorderSide.none,
                labelStyle: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              )).toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _allergyController,
                  decoration: InputDecoration(
                    hintText: 'Add new allergy...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _handleAddAllergy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection(List<dynamic> contacts) {
    if (contacts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text('No emergency contacts added', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Column(
      children: contacts.map((contact) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.emergency_outlined, color: AppTheme.secondaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${contact['relation'] ?? 'N/A'} • ${contact['phone_country_code'] ?? ''} ${contact['phone_number'] ?? ''}', 
                       style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20), 
              onPressed: () => _showAddEditEmergencyContact(contact: contact)
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), 
              onPressed: () => _confirmDeleteContact(contact['id'])
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        onTap: () async {
          await context.read<AuthProvider>().logout();
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        leading: const Icon(Icons.logout_outlined, color: Colors.red),
        title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECACA))
      ),
      child: ListTile(
        onTap: _confirmDeleteAccount,
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data including medical records will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.black))
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              final authProvider = context.read<AuthProvider>();
              final messenger = ScaffoldMessenger.of(context);
              
              final success = await authProvider.deleteAccount();
              if (success && mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                messenger.showSnackBar(const SnackBar(content: Text('Account deleted successfully')));
              } else if (mounted) {
                 messenger.showSnackBar(SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to delete account')));
              }
            },
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
