import 'section_model.dart';

/// A section returned by global search, carrying the parent ids needed to open
/// [SectionDetailScreen]. Built inside [FirestoreRepository] from a
/// collectionGroup query so the UI never touches cloud_firestore directly.
///
/// [actTitle] is resolved from the acts cache; the chapter title is looked up
/// lazily when the user taps the result (it is not denormalized on the doc).
class SectionSearchResult {
  final SectionModel section;
  final String actId;
  final String chapterId;
  final String sectionsCollection;
  final String actTitle;

  const SectionSearchResult({
    required this.section,
    required this.actId,
    required this.chapterId,
    required this.sectionsCollection,
    this.actTitle = '',
  });

  SectionSearchResult copyWith({String? actTitle}) => SectionSearchResult(
        section: section,
        actId: actId,
        chapterId: chapterId,
        sectionsCollection: sectionsCollection,
        actTitle: actTitle ?? this.actTitle,
      );
}
