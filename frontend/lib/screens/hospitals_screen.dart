import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../presentation/providers/hospital_provider.dart';
import '../theme/app_theme.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final TextEditingController _locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HospitalProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Nearby Hospitals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildGPSButton(provider),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildManualInput(provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildResultsList(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSButton(HospitalProvider provider) {
    return Container(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: provider.isLoading ? null : () => provider.fetchNearbyWithGPS(),
        icon: const Icon(Icons.near_me_outlined, size: 20),
        label: const Text('Use GPS'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildManualInput(HospitalProvider provider) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Enter location manually',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              onSubmitted: (value) => provider.fetchNearbyWithText(value),
            ),
          ),
          if (_locationController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                setState(() => _locationController.clear());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList(HospitalProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.hospitals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No hospitals found near you', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Try using GPS or entering a city name', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: provider.hospitals.length,
      itemBuilder: (context, index) {
        final hospital = provider.hospitals[index];
        return _buildHospitalCard(hospital);
      },
    );
  }

  Widget _buildHospitalCard(dynamic hospital) {
    final name = hospital['name'] ?? 'Hospital';
    final address = hospital['address'] ?? 'Address not available';
    final distance = hospital['distance_km']?.toStringAsFixed(1) ?? '0.0';
    final phone = hospital['phone'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$distance km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: phone != null ? () => _makeCall(phone) : null,
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text(phone ?? 'No phone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _makeCall(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
