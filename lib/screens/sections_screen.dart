import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/section_model.dart';
import '../repositories/firestore_repository.dart';
import '../services/download_service.dart';
import '../utils/firebase_error_handler.dart';
import 'section_detail_screen.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';

class SectionsScreen extends StatefulWidget {
  final String actId;
  final String actName;
  final String chapterId;
  final String chapterTitle;
  final String sectionsCollection;

  const SectionsScreen({
    super.key,
    required this.actId,
    required this.actName,
    required this.chapterId,
    required this.chapterTitle,
    this.sectionsCollection = 'sections',
  });

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  String _searchQuery = '';
  late TextEditingController _searchController;
  Timer? _debounce;

  final _repo = FirestoreRepository.instance;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.toLowerCase());
    });
  }

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
          widget.chapterTitle,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search sections...',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.muted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.muted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.saffron, width: 1.5),
                ),
              ),
            ),
          ),

          // Sections list
          Expanded(
            child: StreamBuilder<List<SectionModel>>(
              stream: _repo.streamSections(widget.actId, widget.chapterId,
                  sectionsCollection: widget.sectionsCollection),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.saffron),
                  );
                }

                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg = err is FirestoreException
                      ? err.message
                      : 'Error loading sections.';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off,
                              size: 48, color: AppColors.muted),
                          const SizedBox(height: 12),
                          Text(msg,
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
                            onPressed: () => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sections = snapshot.data ?? [];

                if (sections.isEmpty) {
                  return Center(
                    child: Text('No sections found',
                        style: GoogleFonts.inter(color: AppColors.muted)),
                  );
                }

                // Build the downloaded-key set once per rebuild — avoids n
                // individual Hive lookups inside the list builder.
                final downloadedKeys = <String>{};
                for (final s in sections) {
                  if (DownloadService.isDownloaded(
                      widget.actName, widget.chapterTitle, s.sectionNumber)) {
                    downloadedKeys.add(s.id);
                  }
                }

                final filtered = _searchQuery.isEmpty
                    ? sections
                    : sections.where((s) {
                        return s.title.toLowerCase().contains(_searchQuery) ||
                            s.content.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            color: AppColors.muted, size: 40),
                        const SizedBox(height: 12),
                        Text('No sections match your search',
                            style: GoogleFonts.inter(
                                color: AppColors.muted, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filtered.length + filtered.length ~/ 5,
                  itemBuilder: (context, index) {
                    if ((index + 1) % 6 == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdSections)),
                      );
                    }
                    final sectionIndex = (index ~/ 6) * 5 + (index % 6);
                    if (sectionIndex >= filtered.length) {
                      return const SizedBox.shrink();
                    }
                    final section = filtered[sectionIndex];
                    final isDownloaded = downloadedKeys.contains(section.id);

                    return _SectionCard(
                      section: section,
                      isDownloaded: isDownloaded,
                      actId: widget.actId,
                      actName: widget.actName,
                      chapterTitle: widget.chapterTitle,
                      onDownloaded: () => setState(() {}),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful card so each section row manages its own download loading state.
class _SectionCard extends StatefulWidget {
  final SectionModel section;
  final bool isDownloaded;
  final String actId;
  final String actName;
  final String chapterTitle;
  final VoidCallback onDownloaded;

  const _SectionCard({
    required this.section,
    required this.isDownloaded,
    required this.actId,
    required this.actName,
    required this.chapterTitle,
    required this.onDownloaded,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _isDownloading = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      await DownloadService.downloadSection(
        actId: widget.actId,
        actName: widget.actName,
        chapterName: widget.chapterTitle,
        section: widget.section,
      );
      if (!mounted) return;
      widget.onDownloaded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section downloaded')),
      );
    } on FirestoreException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          action: e.isRetryable
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: AppColors.white,
                  onPressed: _download,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: widget.isDownloaded ? AppColors.success : AppColors.saffron,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SectionDetailScreen(
              section: section,
              actId: widget.actId,
              actName: widget.actName,
              chapterName: widget.chapterTitle,
            ),
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section ${section.sectionNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (section.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.content,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isDownloaded)
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 22)
                  else if (_isDownloading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: AppColors.saffron, strokeWidth: 2),
                    )
                  else
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.download_outlined,
                          color: AppColors.muted, size: 22),
                      onPressed: _download,
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
