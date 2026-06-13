import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/act_model.dart';
import '../repositories/firestore_repository.dart';
import '../utils/firebase_error_handler.dart';
import 'chapters_screen.dart';

class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  List<ActModel> _actResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  final _repo = FirestoreRepository.instance;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = val.trim().toLowerCase();
        _errorMessage = null;
      });
      if (_query.length >= 2) {
        _performSearch();
      } else {
        setState(() {
          _actResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
    });
    try {
      final results = await _repo.searchActs(_query);
      if (!mounted) return;
      setState(() {
        _actResults = results;
        _isLoading = false;
      });
    } on FirestoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Search failed. Please try again.';
      });
    }
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: GoogleFonts.inter(
            textStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: GoogleFonts.inter(
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.saffron,
            backgroundColor: AppColors.saffron.withValues(alpha: 0.1),
          ),
        ),
      ));
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildActResult(ActModel act) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChaptersScreen(
              actId: act.id,
              actTitle: act.title,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.saffron.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.gavel, color: AppColors.saffron, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightText(act.title, _query),
                    if (act.year > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        act.year.toString(),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              'Search across all Indian Acts',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Type at least 2 characters to search',
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.saffron));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 56, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(_errorMessage!,
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
                onPressed: _performSearch,
              ),
            ],
          ),
        ),
      );
    }

    if (_actResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text('No results for "$_query"',
                style:
                    GoogleFonts.inter(fontSize: 15, color: AppColors.muted)),
            const SizedBox(height: 8),
            Text('Try different keywords or browse all acts',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Acts  •  ${_actResults.length} found',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ..._actResults.map(_buildActResult),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search Acts, Chapters, Sections...',
            hintStyle:
                GoogleFonts.inter(color: AppColors.muted, fontSize: 15),
            border: InputBorder.none,
            filled: false,
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: AppColors.muted, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _query = '';
                        _actResults = [];
                        _hasSearched = false;
                        _errorMessage = null;
                      });
                    },
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.white12, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }
}
