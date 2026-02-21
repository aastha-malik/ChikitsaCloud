import 'package:flutter/material.dart';
import '../utils/emergency_service.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => EmergencyService.triggerSOS(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000), // Pure bright red
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF0000).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.emergency, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white, // Proper white
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
