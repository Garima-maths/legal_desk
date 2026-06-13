import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'act_screen.dart';
import 'dictionary_screen.dart';
import 'universal_search_screen.dart';
import 'downloaded_sections_screen.dart';
import 'about_screen.dart';
import 'disclaimer_screen.dart';
import 'privacy_policy_screen.dart';
import 'drafts_screen.dart';
import 'judgements_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        title: Text(
          'Legal Desk',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.saffron),
            tooltip: 'Universal Search',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UniversalSearchScreen(),
              ),
            ),
          ),
        ],
      ),
      drawer: _AppDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBanner(),
          Expanded(child: _FeatureGrid()),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.drawerBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            color: AppColors.nearBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.saffron,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.balance, color: AppColors.white, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  'Legal Desk',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "India's Complete Legal Library",
                  style: GoogleFonts.inter(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(context, Icons.home_outlined, 'Home',
              () => Navigator.pop(context)),
          _drawerItem(context, Icons.search, 'Universal Search', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UniversalSearchScreen()));
          }),
          _drawerItem(context, Icons.download_outlined, 'Downloads', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DownloadedSectionsScreen()));
          }),
          const Spacer(),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          _drawerItemSmall(context, Icons.info_outline, 'About', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutScreen()));
          }),
          _drawerItemSmall(context, Icons.warning_amber_outlined, 'Disclaimer', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DisclaimerScreen()));
          }),
          _drawerItemSmall(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
          }),
          _drawerItemSmall(context, Icons.mail_outline, 'Contact Us', () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Contact Us',
                    style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w600)),
                content: Text('Email: forensicmart@gmail.com',
                    style: GoogleFonts.inter()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _drawerItemSmall(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.muted, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      dense: true,
    );
  }
}

class _AppBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      color: AppColors.heroBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "India's Complete\nLegal Library",
            style: GoogleFonts.playfairDisplay(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse Acts, search judgements & more',
            style: GoogleFonts.inter(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FeatureCard(
              icon: Icons.gavel,
              label: 'Acts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActScreen()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _FeatureCard(
              icon: Icons.account_balance,
              label: 'Judgements',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JudgementsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _FeatureCard(
              icon: Icons.menu_book,
              label: 'Dictionary',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DictionaryScreen()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _FeatureCard(
              icon: Icons.edit_note,
              label: 'Drafts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DraftsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.saffron, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
