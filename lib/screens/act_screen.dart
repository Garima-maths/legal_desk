import 'dart:async';
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
import 'chapters_screen.dart';
import 'universal_search_screen.dart';

class ActScreen extends StatefulWidget {
  const ActScreen({super.key});

  @override
  State<ActScreen> createState() => _ActScreenState();
}

class _ActScreenState extends State<ActScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
    _debounce?.cancel();
    _searchController.dispose();
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

          // Client-side filter
          final filtered = _searchQuery.isEmpty
              ? allActs
              : allActs
                  .where((a) =>
                      a.title.toLowerCase().contains(_searchQuery) ||
                      a.year.toString().contains(_searchQuery))
                  .toList();

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

              // Sliver 2 — Section header + local search
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Filter acts...',
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.muted, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      size: 18, color: AppColors.muted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.white,
                          hintStyle: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.muted),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                            borderSide: BorderSide(
                                color: AppColors.saffron, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 300),
                            () => setState(
                                () => _searchQuery = val.trim().toLowerCase()),
                          );
                        },
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
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No acts found'
                              : 'No acts match "$_searchQuery"',
                          style: GoogleFonts.inter(
                              color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Acts list
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
                      if (actIndex >= filtered.length) {
                        return const SizedBox.shrink();
                      }
                      final act = filtered[actIndex];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ActCard(
                            title: act.title,
                            year: act.year > 0 ? act.year.toString() : null,
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
                    },
                    childCount: filtered.length + filtered.length ~/ 6,
                  ),
                ),

                // Footer: count + load more
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      '${filtered.length} act${filtered.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ),
                if (_hasMore && _searchQuery.isEmpty)
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
