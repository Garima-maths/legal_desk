import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../repositories/firestore_repository.dart';
import '../services/download_service.dart';
import '../utils/firebase_error_handler.dart';
import 'sections_screen.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';

class ChaptersScreen extends StatefulWidget {
  final String actId;
  final String actTitle;

  const ChaptersScreen({
    super.key,
    required this.actId,
    required this.actTitle,
  });

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isDownloadingAct = false;

  final _repo = FirestoreRepository.instance;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadEntireAct() async {
    setState(() => _isDownloadingAct = true);
    try {
      await DownloadService.downloadEntireAct(
        actId: widget.actId,
        actName: widget.actTitle,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.actTitle} downloaded')),
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
                  onPressed: _downloadEntireAct,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingAct = false);
    }
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
          widget.actTitle,
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _isDownloadingAct
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.saffron, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon:
                      const Icon(Icons.download_outlined, color: AppColors.saffron),
                  tooltip: 'Download Full Act',
                  onPressed: _downloadEntireAct,
                ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Filter chapters...',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.muted, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.muted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.muted, size: 20),
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
                  borderSide:
                      const BorderSide(color: AppColors.saffron, width: 1.5),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                });
              },
            ),
          ),

          // Chapters list
          Expanded(
            child: StreamBuilder<List<ChapterModel>>(
              stream: _repo.streamChapters(widget.actId),
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
                      : 'Unable to load chapters.';
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

                final chapters = snapshot.data ?? [];

                if (chapters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined,
                            size: 56, color: AppColors.divider),
                        const SizedBox(height: 8),
                        Text('No chapters yet',
                            style:
                                GoogleFonts.inter(color: AppColors.muted)),
                      ],
                    ),
                  );
                }

                final filtered = _searchQuery.isEmpty
                    ? chapters
                    : chapters
                        .where((c) => c.title
                            .toLowerCase()
                            .contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            size: 56, color: AppColors.divider),
                        const SizedBox(height: 12),
                        Text('No chapters match "$_searchQuery"',
                            style: GoogleFonts.inter(
                                color: AppColors.muted, fontSize: 14)),
                      ],
                    ),
                  );
                }

                final totalWithAds = filtered.length + filtered.length ~/ 6;
                return ListView.builder(
                  itemCount: totalWithAds + 1,
                  itemBuilder: (context, index) {
                    if (index == totalWithAds) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Text(
                          '${filtered.length} chapter${filtered.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      );
                    }
                    if ((index + 1) % 7 == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdChapters)),
                      );
                    }
                    final chapterIndex = (index ~/ 7) * 6 + (index % 7);
                    if (chapterIndex >= filtered.length) {
                      return const SizedBox.shrink();
                    }
                    final chapter = filtered[chapterIndex];
                    return _ChapterCard(
                      chapter: chapter,
                      actId: widget.actId,
                      actTitle: widget.actTitle,
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

/// Stateful card so each chapter row manages its own download loading state.
class _ChapterCard extends StatefulWidget {
  final ChapterModel chapter;
  final String actId;
  final String actTitle;

  const _ChapterCard({
    required this.chapter,
    required this.actId,
    required this.actTitle,
  });

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _isDownloading = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      await DownloadService.downloadChapter(
        actId: widget.actId,
        actName: widget.actTitle,
        chapterId: widget.chapter.id,
        chapterTitle: widget.chapter.title,
        sectionsCollection: widget.chapter.sectionsCollection,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.chapter.title} downloaded')),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.nearBlack, width: 3),
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
            builder: (_) => SectionsScreen(
              actId: widget.actId,
              actName: widget.actTitle,
              chapterId: widget.chapter.id,
              chapterTitle: widget.chapter.title,
              sectionsCollection: widget.chapter.sectionsCollection,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.nearBlack.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book,
                    color: AppColors.nearBlack, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.chapter.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.saffron, strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download_outlined,
                          size: 20, color: AppColors.muted),
                      tooltip: 'Download chapter',
                      onPressed: _download,
                    ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
