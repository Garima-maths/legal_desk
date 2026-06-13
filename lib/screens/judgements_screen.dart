import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/judgement_model.dart';
import '../repositories/firestore_repository.dart';
import '../utils/firebase_error_handler.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';
import 'judgement_detail_screen.dart';

class JudgementsScreen extends StatefulWidget {
  const JudgementsScreen({super.key});

  @override
  State<JudgementsScreen> createState() => _JudgementsScreenState();
}

class _JudgementsScreenState extends State<JudgementsScreen> {
  static const _years = [2026, 2025, 1985, 1984, 1983, 1982, 1977, 1968, 1967, 1966, 1965, 1964, 1963, 1960, 1959, 1958, 1957, 1956, 1955, 1954, 1953, 1952, 1951, 1950, 1911, 1907, 1906, 1905, 1800];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  int? _selectedYear;

  final ScrollController _scrollController = ScrollController();
  final List<JudgementModel> _additionalJudgements = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  JudgementModel? _lastStreamJudgement;

  final _repo = FirestoreRepository.instance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _selectYear(int? year) {
    setState(() {
      _selectedYear = year;
      _additionalJudgements.clear();
      _hasMore = true;
      _isLoadingMore = false;
      _lastStreamJudgement = null;
      _searchQuery = '';
      _searchController.clear();
    });
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastStreamJudgement == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final more = await _repo.fetchMoreJudgements(_lastStreamJudgement!);
      if (!mounted) return;
      if (more.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _additionalJudgements.addAll(more);
          _lastStreamJudgement = more.last;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Judgements',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<JudgementModel>>(
        stream: _selectedYear == null
            ? _repo.streamJudgements()
            : _repo.streamJudgementsByYear(_selectedYear!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error;
            final msg = err is FirestoreException
                ? err.message
                : 'Failed to load judgements.';
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

          final streamJudgements = snapshot.data ?? [];

          if (streamJudgements.isNotEmpty) {
            _lastStreamJudgement = streamJudgements.last;
          }

          final all = [...streamJudgements, ..._additionalJudgements];

          final filtered = _searchQuery.isEmpty
              ? all
              : all.where((j) {
                  return j.title.toLowerCase().contains(_searchQuery) ||
                      j.snippet.toLowerCase().contains(_searchQuery) ||
                      j.year.toString().contains(_searchQuery);
                }).toList();

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero banner
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  color: AppColors.heroBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supreme Court\nJudgements 2026',
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        all.isNotEmpty
                            ? '${all.length}+ judgements — all in one place'
                            : '400 Supreme Court judgements — all in one place',
                        style: GoogleFonts.inter(
                          color: AppColors.saffron,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Year filter chips
              SliverToBoxAdapter(
                child: _YearFilterBar(
                  years: _years,
                  selected: _selectedYear,
                  onSelect: _selectYear,
                ),
              ),

              // Section header + search
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                      child: Text(
                        'All Judgements',
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
                          hintText: 'Search judgements...',
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

              // Ad banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: BannerAdWidget(
                        adUnitId: AdConstants.bannerAdUnitIdJudgements),
                  ),
                ),
              ),

              // Loading / empty / list
              if (snapshot.connectionState == ConnectionState.waiting &&
                  all.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: AppColors.saffron),
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
                              ? 'No judgements found'
                              : 'No judgements match "$_searchQuery"',
                          style: GoogleFonts.inter(
                              color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if ((index + 1) % 7 == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: BannerAdWidget(
                                adUnitId:
                                    AdConstants.bannerAdUnitIdJudgements),
                          ),
                        );
                      }
                      final jIndex = (index ~/ 7) * 6 + (index % 7);
                      if (jIndex >= filtered.length) {
                        return const SizedBox.shrink();
                      }
                      final j = filtered[jIndex];
                      return _JudgementCard(
                        judgement: j,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JudgementDetailScreen(judgement: j),
                            ),
                          );
                        },
                      );
                    },
                    childCount: filtered.length + filtered.length ~/ 6,
                  ),
                ),

                // Footer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      '${filtered.length} judgement${filtered.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ),
                if (_hasMore && _searchQuery.isEmpty && _selectedYear == null)
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

class _JudgementCard extends StatelessWidget {
  final JudgementModel judgement;
  final VoidCallback onTap;

  const _JudgementCard({
    required this.judgement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.saffron, width: 3),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.saffron.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_balance,
                    color: AppColors.saffron, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (judgement.date.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          judgement.date,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ),
                    Text(
                      judgement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (judgement.snippet.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        judgement.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Year filter bar
// ---------------------------------------------------------------------------

class _YearFilterBar extends StatelessWidget {
  final List<int> years;
  final int? selected;
  final ValueChanged<int?> onSelect;

  const _YearFilterBar({
    required this.years,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip(label: 'All', isSelected: selected == null,
              onTap: () => onSelect(null)),
          ...years.map((y) => _chip(
                label: y.toString(),
                isSelected: selected == y,
                onTap: () => onSelect(y),
              )),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.saffron : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.saffron : AppColors.divider,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
