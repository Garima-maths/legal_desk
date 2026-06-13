import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/section_model.dart';
import 'section_detail_screen.dart';

class DownloadedSectionsScreen extends StatefulWidget {
  const DownloadedSectionsScreen({super.key});

  @override
  State<DownloadedSectionsScreen> createState() =>
      _DownloadedSectionsScreenState();
}

class _DownloadedSectionsScreenState extends State<DownloadedSectionsScreen> {
  String _searchQuery = '';
  late TextEditingController _searchController;
  Timer? _debounce;

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
          'Downloads',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('downloadedSections').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download_outlined,
                    size: 72,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads yet',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download acts, chapters, or sections\nto read offline',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Browse Acts',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          // Build grouped structure from box
          final Map<String, Map<String, List<Map<String, dynamic>>>> grouped =
              {};
          for (var key in box.keys) {
            final raw = box.get(key);
            if (raw == null) continue;
            final data = Map<String, dynamic>.from(raw);
            final actName =
                data['actName']?.toString() ?? 'Unknown Act';
            final chapterName =
                data['chapterName']?.toString() ?? 'Unknown Chapter';
            grouped.putIfAbsent(actName, () => {});
            grouped[actName]!.putIfAbsent(chapterName, () => []);
            grouped[actName]![chapterName]!.add(data);
          }

          // Apply search filter
          final query = _searchQuery;
          final filteredGrouped =
              <String, Map<String, List<Map<String, dynamic>>>>{};
          grouped.forEach((actName, chapters) {
            chapters.forEach((chapterName, sections) {
              final matchingSections = sections.where((s) {
                if (query.isEmpty) return true;
                return actName.toLowerCase().contains(query) ||
                    chapterName.toLowerCase().contains(query) ||
                    (s['title']?.toString().toLowerCase() ?? '')
                        .contains(query) ||
                    (s['content']?.toString().toLowerCase() ?? '')
                        .contains(query);
              }).toList();
              if (matchingSections.isNotEmpty) {
                filteredGrouped.putIfAbsent(actName, () => {});
                filteredGrouped[actName]![chapterName] = matchingSections;
              }
            });
          });

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search downloads...',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.muted,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.saffron),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (filteredGrouped.isEmpty && query.isNotEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 56,
                                color: AppColors.divider,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No downloads match "$query"',
                                style: GoogleFonts.inter(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      for (int actIndex = 0;
                          actIndex < filteredGrouped.entries.length;
                          actIndex++) ...[
                        Builder(builder: (context) {
                          final actEntry =
                              filteredGrouped.entries.elementAt(actIndex);
                          final actName = actEntry.key;
                          return SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.nearBlack,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.gavel,
                                    color: AppColors.saffron,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      actName,
                                      style: GoogleFonts.inter(
                                        color: AppColors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      for (var key in box.keys.toList()) {
                                        final d = box.get(key);
                                        if (d != null &&
                                            Map<String, dynamic>.from(
                                                    d)['actName'] ==
                                                actName) {
                                          await box.delete(key);
                                        }
                                      }
                                    },
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        for (final chapterEntry
                            in filteredGrouped.entries
                                .firstWhere((e) =>
                                    e.key ==
                                    filteredGrouped.entries
                                        .elementAt(actIndex)
                                        .key)
                                .value
                                .entries) ...[
                          Builder(builder: (context) {
                            final chapterName = chapterEntry.key;

                            return SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                color: AppColors.surface,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.menu_book,
                                      color: AppColors.muted,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        chapterName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          Builder(builder: (context) {
                            final actName =
                                filteredGrouped.entries.elementAt(actIndex).key;
                            final chapterName = chapterEntry.key;
                            final matchingSections = chapterEntry.value;

                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  final sectionData = matchingSections[i];
                                  final isLast =
                                      i == matchingSections.length - 1;
                                  return Container(
                                    margin: EdgeInsets.fromLTRB(
                                        16, 0, 16, isLast ? 4 : 0),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      border: Border(
                                        bottom: BorderSide(
                                            color: AppColors.divider),
                                      ),
                                      borderRadius: isLast
                                          ? const BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            )
                                          : BorderRadius.zero,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.success
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: AppColors.success,
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(
                                        sectionData['title']?.toString() ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Section ${sectionData['sectionNumber']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              for (var key
                                                  in box.keys.toList()) {
                                                final d = box.get(key);
                                                if (d != null) {
                                                  final dm =
                                                      Map<String, dynamic>.from(
                                                          d);
                                                  if (dm['actName'] ==
                                                          actName &&
                                                      dm['chapterName'] ==
                                                          chapterName &&
                                                      dm['sectionNumber'] ==
                                                          sectionData[
                                                              'sectionNumber']) {
                                                    await box.delete(key);
                                                    break;
                                                  }
                                                }
                                              }
                                            },
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: AppColors.muted,
                                          ),
                                        ],
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SectionDetailScreen(
                                            section: SectionModel(
                                              id: '',
                                              sectionNumber:
                                                  sectionData['sectionNumber'] ??
                                                      0,
                                              title:
                                                  sectionData['title'] ?? '',
                                              content:
                                                  sectionData['content'] ?? '',
                                            ),
                                            actId:
                                                sectionData['actId'] ?? '',
                                            actName: actName,
                                            chapterName: chapterName,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: matchingSections.length,
                              ),
                            );
                          }),
                        ],

                        // Spacer between acts
                        if (actIndex < filteredGrouped.length - 1)
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 8),
                          ),
                      ],

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
