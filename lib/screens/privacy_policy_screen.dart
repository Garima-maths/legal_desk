import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
            Text(
              'Your Privacy Matters',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: 2025',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              'Legal Desk values your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.onSurface,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 28),

            _section(
              '1. Information We Collect',
              'We do not collect personal information such as name, email, or contact details unless voluntarily provided by the user. The app may collect basic usage data for improving performance.',
            ),

            _section(
              '2. How We Use Information',
              'Any information collected is used solely to improve the app\'s functionality, performance, and user experience. We do not sell or share your data with third parties for marketing purposes.',
            ),

            _section(
              '3. Data Security',
              'We take reasonable measures to protect your information. However, no method of transmission over the internet or electronic storage is 100% secure. We cannot guarantee absolute security.',
            ),

            _section(
              '4. Third-Party Services',
              'The app uses Firebase (by Google) for data storage and cloud services. Firebase has its own privacy policy. We recommend reviewing Google\'s privacy practices at firebase.google.com.',
            ),

            _section(
              '5. Offline Data',
              'Content you choose to download is stored locally on your device using Hive, a local database. This data remains on your device and is not transmitted to our servers.',
            ),

            _section(
              '6. Changes to This Policy',
              'We may update this Privacy Policy from time to time. Any changes will be reflected within the app. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.nearBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Questions?',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contact us at forensicmart@gmail.com',
                    style: GoogleFonts.inter(
                      color: AppColors.saffron,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
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
