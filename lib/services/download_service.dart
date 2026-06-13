import 'package:hive/hive.dart';
import '../models/section_model.dart';
import '../repositories/firestore_repository.dart';
import '../utils/firebase_error_handler.dart';

class DownloadService {
  DownloadService._();

  static Box get _box => Hive.box('downloadedSections');
  static final _repo = FirestoreRepository.instance;

  // -------------------------------------------------------------------------
  // Key helpers
  // -------------------------------------------------------------------------

  static String _sectionKey(
          String actName, String chapterName, int sectionNumber) =>
      '${actName}__${chapterName}__$sectionNumber';

  static String _chapterPrefix(String actName, String chapterName) =>
      '${actName}__${chapterName}__';

  // -------------------------------------------------------------------------
  // Read helpers
  // -------------------------------------------------------------------------

  /// Returns true if this specific section is already stored locally.
  static bool isDownloaded(
      String actName, String chapterName, int sectionNumber) {
    return _box.containsKey(_sectionKey(actName, chapterName, sectionNumber));
  }

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Downloads and stores a single [section].
  ///
  /// Throws [FirestoreException] on failure.
  static Future<void> downloadSection({
    required String actId,
    required String actName,
    required String chapterName,
    required SectionModel section,
  }) async {
    try {
      final key = _sectionKey(actName, chapterName, section.sectionNumber);
      await _box.put(key, _sectionToMap(actId, actName, chapterName, section));
    } catch (e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    }
  }

  /// Downloads all sections in a chapter.
  ///
  /// [onProgress] fires after each section is stored — (completed, total).
  /// Throws [FirestoreException] on network failure; partial writes are
  /// rolled back so the box is left in a consistent state.
  static Future<void> downloadChapter({
    required String actId,
    required String actName,
    required String chapterId,
    required String chapterTitle,
    String sectionsCollection = 'sections',
    void Function(int completed, int total)? onProgress,
  }) async {
    final sections = await _repo.fetchSections(actId, chapterId,
        sectionsCollection: sectionsCollection);
    final total = sections.length;
    final batch = <String, Map<String, dynamic>>{};

    for (var i = 0; i < total; i++) {
      final s = sections[i];
      batch[_sectionKey(actName, chapterTitle, s.sectionNumber)] =
          _sectionToMap(actId, actName, chapterTitle, s);
      onProgress?.call(i + 1, total);
    }

    try {
      await _box.putAll(batch);
    } catch (e) {
      // Roll back any keys we may have written
      await _box.deleteAll(batch.keys);
      throw FirebaseErrorHandler.handleUnknown(e);
    }
  }

  /// Downloads every chapter and section in an act.
  ///
  /// [onProgress] fires after each chapter is fully stored —
  /// (chaptersCompleted, totalChapters).
  /// Throws [FirestoreException] on network failure.
  static Future<void> downloadEntireAct({
    required String actId,
    required String actName,
    void Function(int completed, int total)? onProgress,
  }) async {
    final chapters = await _repo.fetchChapters(actId);
    final total = chapters.length;

    for (var i = 0; i < total; i++) {
      final chapter = chapters[i];
      await downloadChapter(
        actId: actId,
        actName: actName,
        chapterId: chapter.id,
        chapterTitle: chapter.title,
        sectionsCollection: chapter.sectionsCollection,
      );
      onProgress?.call(i + 1, total);
    }
  }

  // -------------------------------------------------------------------------
  // Delete operations
  // -------------------------------------------------------------------------

  /// Removes a single downloaded section from local storage.
  static Future<void> deleteSection({
    required String actName,
    required String chapterName,
    required int sectionNumber,
  }) async {
    await _box.delete(_sectionKey(actName, chapterName, sectionNumber));
  }

  /// Removes all downloaded sections belonging to a chapter.
  static Future<void> deleteChapter({
    required String actName,
    required String chapterName,
  }) async {
    final prefix = _chapterPrefix(actName, chapterName);
    final keys = _box.keys.where((k) => k.toString().startsWith(prefix)).toList();
    await _box.deleteAll(keys);
  }

  /// Removes all downloaded sections belonging to an act.
  static Future<void> deleteAct({required String actName}) async {
    final prefix = '${actName}__';
    final keys = _box.keys.where((k) => k.toString().startsWith(prefix)).toList();
    await _box.deleteAll(keys);
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  static Map<String, dynamic> _sectionToMap(
    String actId,
    String actName,
    String chapterName,
    SectionModel section,
  ) =>
      {
        'actId': actId,
        'actName': actName,
        'chapterName': chapterName,
        'sectionNumber': section.sectionNumber,
        'title': section.title,
        'content': section.content,
      };
}
