import 'package:cloud_firestore/cloud_firestore.dart';

class DraftCategory {
  final String id;
  final String name;
  final int order;

  const DraftCategory({
    required this.id,
    required this.name,
    required this.order,
  });

  factory DraftCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DraftCategory(
      id: doc.id,
      name: data['name'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}
