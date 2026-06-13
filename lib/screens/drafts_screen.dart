import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/draft_category_model.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/ad_constants.dart';
import 'draft_category_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        title: Text(
          'Legal Drafts',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('draft_categories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 56, color: AppColors.muted),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load drafts.',
                      style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final categories = docs
              .map((d) => DraftCategory.fromFirestore(d))
              .where((c) =>
                  _query.isEmpty ||
                  c.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  color: AppColors.heroBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Draft\nFormats',
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '20 categories · 600+ ready-to-use legal templates',
                        style: GoogleFonts.inter(
                          color: AppColors.saffron,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: Icon(Icons.search, color: AppColors.muted, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 18, color: AppColors.muted),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.white,
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.saffron, width: 1.5),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdDrafts),
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting && docs.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.saffron),
                    ),
                  ),
                )
              else if (categories.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'No categories found'
                              : 'No categories match "$_query"',
                          style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = categories[index];
                        return _CategoryCard(
                          category: cat,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DraftCategoryScreen(category: cat),
                            ),
                          ),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DraftCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('matrimonial') || n.contains('divorce') || n.contains('marriage')) return Icons.favorite_border;
    if (n.contains('motor') || n.contains('vehicle')) return Icons.directions_car_outlined;
    if (n.contains('negotiable') || n.contains('cheque') || n.contains('पराक्रम्य')) return Icons.receipt_long_outlined;
    if (n.contains('notice')) return Icons.notifications_none;
    if (n.contains('attorney') || n.contains('power')) return Icons.handshake_outlined;
    if (n.contains('petition') || n.contains('slp') || n.contains('special leave')) return Icons.gavel;
    if (n.contains('adoption')) return Icons.child_care_outlined;
    if (n.contains('specific relief')) return Icons.balance;
    if (n.contains('affidavit')) return Icons.edit_document;
    if (n.contains('will') || n.contains('gift')) return Icons.card_giftcard_outlined;
    if (n.contains('agreement')) return Icons.handshake_outlined;
    if (n.contains('appointment') || n.contains('employment')) return Icons.work_outline;
    if (n.contains('criminal') || n.contains('दण्डिक')) return Icons.security_outlined;
    if (n.contains('civil')) return Icons.account_balance_outlined;
    if (n.contains('banking') || n.contains('bank')) return Icons.account_balance;
    if (n.contains('arbitration')) return Icons.people_outline;
    if (n.contains('bond')) return Icons.link;
    if (n.contains('rent')) return Icons.home_outlined;
    if (n.contains('writ')) return Icons.gavel;
    if (n.contains('उपभोक्ता') || n.contains('consumer')) return Icons.shopping_bag_outlined;
    if (n.contains('सूचना') || n.contains('rti')) return Icons.info_outline;
    return Icons.description_outlined;
  }

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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFor(category.name), color: AppColors.saffron, size: 28),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
