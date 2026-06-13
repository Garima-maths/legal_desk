import 'package:cloud_firestore/cloud_firestore.dart';

class DraftDocument {
  final String id;
  final String name;
  final String categoryId;
  final String fileType;
  final String downloadUrl;

  const DraftDocument({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.fileType,
    required this.downloadUrl,
  });

  factory DraftDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DraftDocument(
      id: doc.id,
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      fileType: data['fileType'] as String? ?? 'rtf',
      downloadUrl: data['downloadUrl'] as String? ?? '',
    );
  }
}
