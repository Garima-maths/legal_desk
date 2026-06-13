import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/section_model.dart';
import '../services/download_service.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';

class SectionDetailScreen extends StatelessWidget {
  final SectionModel section;
  final String actId;
  final String actName;
  final String chapterName;

  const SectionDetailScreen({
    super.key,
    required this.section,
    required this.actId,
    required this.actName,
    required this.chapterName,
  });

  String _estimatedReadTime(String content) {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return minutes <= 1 ? '~1 min read' : '~$minutes min read';
  }

  Future<void> _openVideo(BuildContext context) async {
    final url = Uri.parse(section.videoUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }

  List<Widget> _buildContentWithAds(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    for (int i = 0; i < lines.length; i += 20) {
      final end = (i + 20 < lines.length) ? i + 20 : lines.length;
      final chunk = lines.sublist(i, end).join('\n');
      if (i > 0) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(Center(
          child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdSectionDetail),
        ));
        widgets.add(const SizedBox(height: 16));
      }
      widgets.add(Text(
        chunk,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.onSurface,
          height: 1.8,
        ),
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final before = section.contentBeforeVideo ?? '';
    final after = section.contentAfterVideo ?? '';
    final hasVideo = section.videoUrl != null;

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
          'Section ${section.sectionNumber}',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.saffron),
            tooltip: 'Download section',
            onPressed: () async {
              await DownloadService.downloadSection(
                actId: actId,
                actName: actName,
                chapterName: chapterName,
                section: section,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Section downloaded')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              section.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            // Section badge + read time
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Section ${section.sectionNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.saffron,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _estimatedReadTime(section.content),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 20),
            Center(child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdSectionDetail)),
            const SizedBox(height: 20),

            // Content — with inline video link where the URL was
            if (hasVideo) ...[
              if (before.isNotEmpty) ...[
                ..._buildContentWithAds(before),
                const SizedBox(height: 16),
              ],
              // Inline "Watch on YouTube" link
              GestureDetector(
                onTap: () => _openVideo(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill,
                          color: Color(0xFFFF0000), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Watch on YouTube',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF0000),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (after.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._buildContentWithAds(after),
              ],
            ] else ...[
              ..._buildContentWithAds(section.content),
            ],

            Center(child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdSectionDetail)),
            const SizedBox(height: 16),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
