import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Disclaimer',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.saffron.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.saffron, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This app provides legal information for educational purposes only and does not constitute legal advice.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7A5800),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _section(
              'General Disclaimer',
              'The information provided in the Legal Desk application is for general educational and informational purposes only.\n\n'
              'This app does NOT provide legal advice and should not be considered a substitute for professional legal consultation.',
            ),

            _section(
              'Accuracy & Updates',
              'While we strive to keep the content accurate and updated, laws and interpretations may change over time. Legal Desk makes no warranties regarding completeness, reliability, or accuracy of the information provided.',
            ),

            _section(
              'Professional Advice',
              'Users are advised to consult a qualified legal professional before taking any action based on the information provided in this app.',
            ),

            _section(
              'Independence',
              'This application is not affiliated with, endorsed by, or representative of any government entity. It is a privately developed platform created for educational purposes.\n\n'
              'All content is sourced from publicly available historical documents and is not connected to any official government authority.',
            ),

            _section(
              'Content Sources',
              '1. IPC (Indian Penal Code) — indiacode.nic.in\n'
              '2. CrPC (Code of Criminal Procedure, 1973) — indiacode.nic.in',
            ),

            _section(
              'Limitation of Liability',
              'By using this application, you agree that Legal Desk shall not be held responsible for any loss, damage, or legal consequences arising from the use of this content.',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.onSurface,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.divider),
        ],
      ),
    );
  }
}
