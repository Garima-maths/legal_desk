import 'package:cloud_firestore/cloud_firestore.dart';

class SectionModel {
  final String id;
  final int sectionNumber;
  final String title;
  /// Full text with the YouTube URL stripped — used for search and download.
  final String content;
  /// YouTube URL found in the content field, if any.
  final String? videoUrl;
  /// Text before the YouTube URL (empty string if URL was at the start).
  /// Null when there is no video.
  final String? contentBeforeVideo;
  /// Text after the YouTube URL (empty string if URL was at the end).
  /// Null when there is no video.
  final String? contentAfterVideo;

  const SectionModel({
    required this.id,
    required this.sectionNumber,
    required this.title,
    required this.content,
    this.videoUrl,
    this.contentBeforeVideo,
    this.contentAfterVideo,
  });

  factory SectionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // 'order' is the canonical field; 'sectionNumber' is a legacy fallback
    final orderVal =
        (data['order'] as num?) ?? (data['sectionNumber'] as num?) ?? 0;

    final rawContent = data['content'] as String? ?? '';
    final match = RegExp(
      r'https?://(?:www\.)?(?:youtube\.com/watch\?[^\s]*v=|youtu\.be/)[\w-]+[^\s]*',
    ).firstMatch(rawContent);

    String content;
    String? videoUrl;
    String? contentBeforeVideo;
    String? contentAfterVideo;

    if (match != null) {
      videoUrl = match[0];
      contentBeforeVideo = rawContent.substring(0, match.start).trim();
      contentAfterVideo = rawContent.substring(match.end).trim();
      // Full stripped text (for search / download storage)
      content = [contentBeforeVideo, contentAfterVideo]
          .where((s) => s.isNotEmpty)
          .join(' ');
    } else {
      content = rawContent;
    }

    return SectionModel(
      id: doc.id,
      sectionNumber: orderVal.toInt(),
      title: data['title'] as String? ?? '',
      content: content,
      videoUrl: videoUrl,
      contentBeforeVideo: contentBeforeVideo,
      contentAfterVideo: contentAfterVideo,
    );
  }

  Map<String, dynamic> toMap() => {
        'order': sectionNumber,
        'title': title,
        'content': content,
        if (videoUrl != null) 'videoUrl': videoUrl,
      };
}
