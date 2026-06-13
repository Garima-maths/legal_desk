import 'package:cloud_firestore/cloud_firestore.dart';

class DictionaryTermModel {
  final String id;
  final String term;
  final String definition;
  final String letter;
  final List<String> crossReferences;

  const DictionaryTermModel({
    required this.id,
    required this.term,
    required this.definition,
    required this.letter,
    required this.crossReferences,
  });

  factory DictionaryTermModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DictionaryTermModel(
      id: doc.id,
      term: data['term'] as String? ?? '',
      definition: data['definition'] as String? ?? '',
      letter: data['letter'] as String? ?? '',
      crossReferences: List<String>.from(
          (data['crossReferences'] as List<dynamic>?) ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'term': term,
        'definition': definition,
        'letter': letter,
        'crossReferences': crossReferences,
      };
}
