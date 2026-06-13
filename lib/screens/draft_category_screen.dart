import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/draft_category_model.dart';
import '../models/draft_document_model.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/ad_constants.dart';

class DraftCategoryScreen extends StatelessWidget {
  final DraftCategory category;

  const DraftCategoryScreen({super.key, required this.category});

  Future<void> _download(BuildContext context, DraftDocument doc) async {
    final uri = Uri.parse(doc.downloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        title: Text(
          category.name,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('draft_documents')
            .where('categoryId', isEqualTo: category.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load documents.',
                style: GoogleFonts.inter(color: AppColors.muted),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.saffron),
            );
          }

          final docs = (snapshot.data?.docs ?? [])
              .map((d) => DraftDocument.fromFirestore(d))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No documents found in this category.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length + (docs.length ~/ 7) + 1,
            itemBuilder: (context, index) {
              // Ad every 8th slot (index % 8 == 7)
              if ((index + 1) % 8 == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdHome),
                  ),
                );
              }
              final docIndex = index - index ~/ 8;
              if (docIndex >= docs.length) return const SizedBox.shrink();
              final doc = docs[docIndex];
              return _DocumentTile(doc: doc, onDownload: () => _download(context, doc));
            },
          );
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DraftDocument doc;
  final VoidCallback onDownload;

  const _DocumentTile({required this.doc, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.saffron, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      doc.fileType.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(
                  'Download',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
