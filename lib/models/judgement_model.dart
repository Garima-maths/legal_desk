import 'package:cloud_firestore/cloud_firestore.dart';

class JudgementModel {
  final String id;
  final String title;
  final String snippet;
  final String date;
  final int year;
  final String court;
  final String? pdfUrl;

  const JudgementModel({
    required this.id,
    required this.title,
    required this.snippet,
    required this.date,
    required this.year,
    required this.court,
    this.pdfUrl,
  });

  factory JudgementModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JudgementModel(
      id:      doc.id,
      title:   data['title']   as String? ?? '',
      snippet: data['snippet'] as String? ?? '',
      date:    data['date']    as String? ?? '',
      year:    (data['year']   as num?)?.toInt() ?? 0,
      court:   data['court']   as String? ?? '',
      pdfUrl:  data['pdfUrl']  as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title':   title,
    'snippet': snippet,
    'date':    date,
    'year':    year,
    'court':   court,
    'docId':   id,
    if (pdfUrl != null) 'pdfUrl': pdfUrl,
  };
}
