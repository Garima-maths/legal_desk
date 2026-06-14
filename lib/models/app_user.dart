import 'package:cloud_firestore/cloud_firestore.dart';

/// An advocate's registration profile, stored at `users/{uid}` in Firestore.
///
/// The password is never stored here — it is held only by Firebase Auth.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String chamberNumber;
  final String barNumber;
  final String organization;
  final String city;
  final String pincode;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    required this.chamberNumber,
    required this.barNumber,
    required this.organization,
    required this.city,
    required this.pincode,
    this.createdAt,
  });

  factory AppUser.fromSnapshot(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      chamberNumber: data['chamberNumber'] as String? ?? '',
      barNumber: data['barNumber'] as String? ?? '',
      organization: data['organization'] as String? ?? '',
      city: data['city'] as String? ?? '',
      pincode: data['pincode'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'mobile': mobile,
        'chamberNumber': chamberNumber,
        'barNumber': barNumber,
        'organization': organization,
        'city': city,
        'pincode': pincode,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
