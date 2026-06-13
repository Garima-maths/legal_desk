import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterModel {
  final String id;
  final String title;
  final int order;
  /// Name of the Firestore subcollection that holds this chapter's sections.
  /// Defaults to "sections" for backward compatibility (Chapter 1 of IPC).
  /// Other chapters stored under a differently-named subcollection must have
  /// this field set in their Firestore document (e.g. sectionsCollection: "chapter2").
  final String sectionsCollection;

  const ChapterModel({
    required this.id,
    required this.title,
    required this.order,
    this.sectionsCollection = 'sections',
  });

  factory ChapterModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChapterModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      sectionsCollection:
          data['sectionsCollection'] as String? ?? 'sections',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'order': order,
        'sectionsCollection': sectionsCollection,
      };
}
