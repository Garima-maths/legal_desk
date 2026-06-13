import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/dictionary_term_model.dart';
import '../repositories/firestore_repository.dart';
import '../utils/firebase_error_handler.dart';
import '../utils/ad_constants.dart';
import '../widgets/banner_ad_widget.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  static const _letters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];

  String _selectedLetter = 'A';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isSearchLoading = false;
  List<DictionaryTermModel> _searchResults = [];
  String? _searchError;
  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _letterScrollController = ScrollController();
  final _repo = FirestoreRepository.instance;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _letterScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _isSearchLoading = true;
      _searchError = null;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _repo.searchDictionary(trimmed);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _searchError = e is FirestoreException ? e.message : 'Search failed.';
          _isSearchLoading = false;
        });
      }
    });
  }

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetter = letter;
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        title: Text(
          'Legal Dictionary',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _onSearchChanged(v);
            },
          ),
          _LetterIndexBar(
            letters: _letters,
            selected: _selectedLetter,
            scrollController: _letterScrollController,
            onSelect: _selectLetter,
          ),
          const Divider(height: 1),
          Expanded(
            child: _isSearching
                ? _SearchResultsView(
                    query: _searchQuery,
                    isLoading: _isSearchLoading,
                    results: _searchResults,
                    error: _searchError,
                  )
                : _LetterView(
                    letter: _selectedLetter,
                    repo: _repo,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.nearBlack,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search legal terms...',
          hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.muted, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: AppColors.muted, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.saffron, width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A–Z letter index bar
// ---------------------------------------------------------------------------

class _LetterIndexBar extends StatelessWidget {
  final List<String> letters;
  final String selected;
  final ScrollController scrollController;
  final ValueChanged<String> onSelect;

  const _LetterIndexBar({
    required this.letters,
    required this.selected,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      height: 44,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: letters.length,
        itemBuilder: (_, i) {
          final letter = letters[i];
          final isSelected = letter == selected;
          return GestureDetector(
            onTap: () => onSelect(letter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.saffron : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Terms list for a selected letter
// ---------------------------------------------------------------------------

class _LetterView extends StatelessWidget {
  final String letter;
  final FirestoreRepository repo;

  const _LetterView({required this.letter, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DictionaryTermModel>>(
      stream: repo.streamDictionaryByLetter(letter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          final msg =
              err is FirestoreException ? err.message : 'Failed to load terms.';
          return _ErrorView(message: msg);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.saffron));
        }

        final terms = snapshot.data ?? [];

        if (terms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 56, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(
                  'No terms under "$letter" yet',
                  style:
                      GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: terms.length + terms.length ~/ 8,
          itemBuilder: (context, index) {
            if ((index + 1) % 9 == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                    child: BannerAdWidget(
                        adUnitId: AdConstants.bannerAdUnitIdDictionary)),
              );
            }
            final termIndex = (index ~/ 9) * 8 + (index % 9);
            if (termIndex >= terms.length) return const SizedBox.shrink();
            return _TermTile(term: terms[termIndex]);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Search results view
// ---------------------------------------------------------------------------

class _SearchResultsView extends StatelessWidget {
  final String query;
  final bool isLoading;
  final List<DictionaryTermModel> results;
  final String? error;

  const _SearchResultsView({
    required this.query,
    required this.isLoading,
    required this.results,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.saffron));
    }
    if (error != null) {
      return _ErrorView(message: error!);
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'No results for "$query"',
              style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: results.length,
      itemBuilder: (_, i) => _TermTile(term: results[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable term tile
// ---------------------------------------------------------------------------

class _TermTile extends StatefulWidget {
  final DictionaryTermModel term;
  const _TermTile({required this.term});

  @override
  State<_TermTile> createState() => _TermTileState();
}

class _TermTileState extends State<_TermTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    term.term.isNotEmpty
                        ? term.term[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.saffron,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        term.term,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (!_expanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            term.definition,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term.definition,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    height: 1.65,
                  ),
                ),
                if (term.crossReferences.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    'See also:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: term.crossReferences
                        .map((ref) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.saffron
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ref,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.saffron,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
