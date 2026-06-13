import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About',
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
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.nearBlack,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.saffron,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.balance, color: AppColors.white, size: 26),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Legal Desk',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "India's Complete Legal Library",
                    style: GoogleFonts.inter(
                      color: AppColors.saffron,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle('Our Mission'),
            const SizedBox(height: 12),
            _bodyText(
              'Legal Desk is a comprehensive legal reference platform designed to make Indian laws easily accessible to everyone. We provide a well-organized collection of Indian Acts, Chapters, and Sections — enabling users to quickly find accurate legal information anytime, anywhere.',
            ),

            const SizedBox(height: 24),
            _sectionTitle('What You Can Do'),
            const SizedBox(height: 12),
            _featureItem(Icons.search, 'Search across all Indian Acts and Sections'),
            _featureItem(Icons.menu_book_outlined, 'Browse laws organized by Chapters and Sections'),
            _featureItem(Icons.download_outlined, 'Download Acts and Sections for offline reading'),
            _featureItem(Icons.gavel_outlined, 'Access reliable legal references in one place'),

            const SizedBox(height: 28),
            Divider(color: AppColors.divider),
            const SizedBox(height: 24),

            _sectionTitle('Our Team'),
            const SizedBox(height: 16),
            _buildTeamMember(
              imagePath: 'assets/images/member1.jpg',
              name: 'Madhav Goyal',
              role: 'Founder & Developer',
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Developed with dedication for legal awareness.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.onSurface,
        height: 1.7,
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.saffron, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTeamMember({
    required String imagePath,
    required String name,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.saffron.withValues(alpha: 0.15),
            backgroundImage: AssetImage(imagePath),
            onBackgroundImageError: (e, st) {},
            child: Icon(Icons.person, color: AppColors.saffron, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
