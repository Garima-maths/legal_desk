import 'package:cloud_firestore/cloud_firestore.dart';

class ActModel {
  final String id;
  final String title;
  final int year;
  final String? pdfUrl;

  const ActModel({
    required this.id,
    required this.title,
    required this.year,
    this.pdfUrl,
  });

  factory ActModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      pdfUrl: data['pdfUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'year': year,
        if (pdfUrl != null) 'pdfUrl': pdfUrl!,
      };
}
