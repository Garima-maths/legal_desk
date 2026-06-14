import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/act_model.dart';
import '../repositories/firestore_repository.dart';
import '../utils/firebase_error_handler.dart';
import '../widgets/act_card.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/bookmark_service.dart';
import 'chapters_screen.dart';
import 'universal_search_screen.dart';

class ActScreen extends StatefulWidget {
  const ActScreen({super.key});

  @override
  State<ActScreen> createState() => _ActScreenState();
}

class _ActScreenState extends State<ActScreen> {
  // Pagination state
  final ScrollController _scrollController = ScrollController();
  final List<ActModel> _additionalActs = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  ActModel? _lastStreamAct;

  final _repo = FirestoreRepository.instance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _downloadPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastStreamAct == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final more = await _repo.fetchMoreActs(_lastStreamAct!);
      if (!mounted) return;
      if (more.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _additionalActs.addAll(more);
          _lastStreamAct = more.last;
        });
      }
    } on FirestoreException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  /// One act row — the card plus its optional "Download Now" PDF button.
  /// Shared between the "Saved" section and the main browse list.
  Widget _actCard(BuildContext context, ActModel act,
      {required bool isBookmarked}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActCard(
          title: act.title,
          year: act.year > 0 ? act.year.toString() : null,
          isBookmarked: isBookmarked,
          onBookmarkTap: () async {
            await BookmarkService.toggleAct(act);
            if (mounted) setState(() {});
          },
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChaptersScreen(
                actId: act.id,
                actTitle: act.title,
              ),
            ),
          ),
        ),
        if (act.pdfUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _downloadPdf(context, act.pdfUrl!),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text(
                  'Download Now',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        title: Text(
          'Acts',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
      body: StreamBuilder<List<ActModel>>(
        stream: _repo.streamActs(),
        builder: (context, snapshot) {
          // ---- Error state ----
          if (snapshot.hasError) {
            final err = snapshot.error;
            final msg = err is FirestoreException
                ? err.message
                : 'Failed to load acts.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 56, color: AppColors.muted),
                    const SizedBox(height: 16),
                    Text(msg,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: AppColors.muted, fontSize: 14)),
                    const SizedBox(height: 20),
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

          final streamActs = snapshot.data ?? [];

          // Track last item for pagination cursor
          if (streamActs.isNotEmpty) {
            _lastStreamAct = streamActs.last;
          }

          // Merge stream page with additional loaded pages
          final allActs = [...streamActs, ..._additionalActs];

          // Bookmarked acts are pinned to a "Saved" section at the top and
          // removed from the browse list below to avoid duplicates.
          final saved = BookmarkService.getActs();
          final savedIds = saved.map((a) => a.id).toSet();
          final browse =
              allActs.where((a) => !savedIds.contains(a.id)).toList();

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sliver 1 — Hero Banner
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
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
                      const SizedBox(height: 10),
                      Text(
                        allActs.isNotEmpty
                            ? 'Browse ${allActs.length}+ Acts — all in one place'
                            : 'All Acts — all in one place',
                        style: GoogleFonts.inter(
                          color: AppColors.saffron,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UniversalSearchScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  color: AppColors.muted, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Search across all Acts, Chapters & Sections...',
                                style: GoogleFonts.inter(
                                    color: AppColors.muted, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Saved section — bookmarked acts pinned to the top
              if (saved.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark, color: AppColors.saffron, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Saved',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _actCard(context, saved[index], isBookmarked: true),
                    childCount: saved.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                ),
              ],

              // Sliver 2 — Section header
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                      child: Text(
                        'All Acts',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ad banner between search and list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdHome)),
                ),
              ),

              // Sliver 3 — Loading shimmer or empty state
              if (snapshot.connectionState == ConnectionState.waiting &&
                  allActs.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.saffron),
                    ),
                  ),
                )
              else if (saved.isEmpty && browse.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          'No acts found',
                          style: GoogleFonts.inter(
                              color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Acts list
                if (browse.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if ((index + 1) % 7 == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(child: BannerAdWidget(adUnitId: AdConstants.bannerAdUnitIdHome)),
                          );
                        }
                        final actIndex = (index ~/ 7) * 6 + (index % 7);
                        if (actIndex >= browse.length) {
                          return const SizedBox.shrink();
                        }
                        return _actCard(context, browse[actIndex],
                            isBookmarked: false);
                      },
                      childCount: browse.length + browse.length ~/ 6,
                    ),
                  ),

                // Footer: count + load more
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      '${browse.length} act${browse.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ),
                if (_hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: _isLoadingMore
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    color: AppColors.saffron, strokeWidth: 2),
                              ),
                            )
                          : TextButton(
                              onPressed: _loadMore,
                              child: Text('Load more',
                                  style: GoogleFonts.inter(
                                      color: AppColors.saffron,
                                      fontWeight: FontWeight.w500)),
                            ),
                    ),
                  ),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          );
        },
      ),
    );
  }
}
