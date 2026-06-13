import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/judgement_model.dart';
import '../repositories/firestore_repository.dart';
import '../utils/firebase_error_handler.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';

class JudgementDetailScreen extends StatefulWidget {
  final JudgementModel judgement;

  const JudgementDetailScreen({super.key, required this.judgement});

  @override
  State<JudgementDetailScreen> createState() => _JudgementDetailScreenState();
}

class _JudgementDetailScreenState extends State<JudgementDetailScreen> {
  String _content = '';
  String? _htmlContent; // non-null → use HTML renderer (2025+ docs)
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  String _cleanContent(String raw) {
    return raw
        .replaceAll(RegExp(r'\[Cites \d+.*?Cited by \d+\]'), '')
        .replaceAll('\f', '\n\n')
        .replaceAll(RegExp(r'^[ \t]+', multiLine: true), '')
        .replaceAll(RegExp(r'[ \t]+$', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FirestoreRepository.instance
          .fetchJudgementContent(widget.judgement.id);
      if (!mounted) return;
      setState(() {
        _content     = _cleanContent(result.text);
        _htmlContent = (result.htmlContent?.isNotEmpty ?? false)
            ? result.htmlContent
            : null;
        _loading = false;
      });
    } on FirestoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load judgement content.';
        _loading = false;
      });
    }
  }

  String _estimatedReadTime(String content) {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return minutes <= 1 ? '~1 min read' : '~$minutes min read';
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://indiankanoon.org/doc/${widget.judgement.id}/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  Future<void> _openPdf() async {
    final pdfUrl = widget.judgement.pdfUrl;
    if (pdfUrl == null) return;
    // In-app browser lets the user read the PDF without leaving the context
    if (!await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.inAppBrowserView)) {
      // Fallback to external if in-app not supported
      await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadPdf() async {
    final pdfUrl = widget.judgement.pdfUrl;
    if (pdfUrl == null) return;
    // External application triggers the OS download / share flow
    if (!await launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open download')),
        );
      }
    }
  }

  // ── Plain-text renderer (2026 docs / fallback) ────────────────────────────
  List<Widget> _buildContentWithAds(String content) {
    final paragraphs = content
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final widgets = <Widget>[];
    for (int i = 0; i < paragraphs.length; i++) {
      if (i > 0 && i % 8 == 0) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(Center(
          child: BannerAdWidget(
              adUnitId: AdConstants.bannerAdUnitIdJudgementDetail),
        ));
        widgets.add(const SizedBox(height: 16));
      }
      widgets.add(Text(
        paragraphs[i],
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.onSurface,
          height: 1.75,
        ),
      ));
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  // ── HTML renderer (2025 docs — preserves original formatting) ─────────────
  Widget _buildHtmlContent(String htmlContent) {
    return Html(
      data: htmlContent,
      style: {
        'body': Style(
          fontSize: FontSize(15),
          lineHeight: LineHeight(1.75),
          color: AppColors.onSurface,
          fontFamily: 'Inter',
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'pre': Style(
          fontFamily: 'monospace',
          fontSize: FontSize(13),
          backgroundColor: const Color(0xFFF0F0F0),
          padding: HtmlPaddings.all(8),
          whiteSpace: WhiteSpace.pre,
        ),
        'h2': Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          margin: Margins.only(top: 16, bottom: 8),
        ),
        'h3': Style(
          fontSize: FontSize(16),
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          margin: Margins.only(top: 12, bottom: 6),
        ),
        'p': Style(
          margin: Margins.only(bottom: 10),
        ),
        'blockquote': Style(
          margin: Margins.only(left: 16, top: 8, bottom: 8),
          padding: HtmlPaddings.only(left: 12),
          border: Border(
            left: BorderSide(color: AppColors.saffron, width: 3),
          ),
          color: AppColors.muted,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.judgement;
    final hasPdf = j.pdfUrl != null;

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
          'Supreme Court · ${j.year}',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (hasPdf)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.saffron),
              tooltip: 'View PDF',
              onPressed: _openPdf,
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppColors.saffron),
            tooltip: 'View on Indian Kanoon',
            onPressed: _openInBrowser,
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
              j.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata badges
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (j.court.isNotEmpty)
                  _Badge(label: j.court, color: AppColors.saffron),
                if (j.date.isNotEmpty)
                  _Badge(label: j.date, color: AppColors.nearBlack),
                if (_content.isNotEmpty)
                  _Badge(
                    label: _estimatedReadTime(_content),
                    color: AppColors.muted,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // View + Download PDF buttons (2025+ docs only)
            if (hasPdf) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.saffron,
                        side: const BorderSide(color: AppColors.saffron),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            const Divider(color: AppColors.divider),
            const SizedBox(height: 20),

            // Top ad
            Center(
              child: BannerAdWidget(
                  adUnitId: AdConstants.bannerAdUnitIdJudgementDetail),
            ),
            const SizedBox(height: 20),

            // Content area
            if (_loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.saffron),
                ),
              )
            else if (_error != null)
              Column(
                children: [
                  Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppColors.muted, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: AppColors.white),
                    onPressed: _loadContent,
                  ),
                ],
              )
            else if (_content.isEmpty && _htmlContent == null)
              Center(
                child: Text(
                  'Content not yet available.',
                  style: GoogleFonts.inter(
                      color: AppColors.muted, fontSize: 14),
                ),
              )
            // HTML renderer for 2025+ docs (original formatting preserved)
            else if (_htmlContent != null)
              _buildHtmlContent(_htmlContent!)
            // Plain text renderer for 2026 docs (backward compatible)
            else
              ..._buildContentWithAds(_content),

            const SizedBox(height: 20),

            // Bottom ad
            Center(
              child: BannerAdWidget(
                  adUnitId: AdConstants.bannerAdUnitIdJudgementDetail),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color == AppColors.muted ? AppColors.muted : color,
        ),
      ),
    );
  }
}
