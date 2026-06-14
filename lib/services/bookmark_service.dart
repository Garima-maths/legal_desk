import 'package:hive/hive.dart';
import '../models/act_model.dart';
import '../models/judgement_model.dart';

/// Device-local bookmark store, kept fully separate from [DownloadService].
///
/// Downloads persist full section *content* for offline reading; bookmarks
/// persist only the tiny card metadata needed to pin a saved Act/Judgement to
/// the top of its list and re-open it. Backed by its own Hive box.
class BookmarkService {
  BookmarkService._();

  static Box get _box => Hive.box('bookmarks');

  static const _actPrefix = 'act_';
  static const _judgementPrefix = 'judgement_';

  static String _actKey(String id) => '$_actPrefix$id';
  static String _judgementKey(String id) => '$_judgementPrefix$id';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  static bool isActBookmarked(String id) => _box.containsKey(_actKey(id));

  static bool isJudgementBookmarked(String id) =>
      _box.containsKey(_judgementKey(id));

  /// All bookmarked acts, most recently saved first.
  static List<ActModel> getActs() => _readSorted(_actPrefix, _actFromMap);

  /// All bookmarked judgements, most recently saved first.
  static List<JudgementModel> getJudgements() =>
      _readSorted(_judgementPrefix, _judgementFromMap);

  // ---------------------------------------------------------------------------
  // Toggle
  // ---------------------------------------------------------------------------

  static Future<void> toggleAct(ActModel act) async {
    final key = _actKey(act.id);
    if (_box.containsKey(key)) {
      await _box.delete(key);
    } else {
      await _box.put(key, {
        ...act.toMap(),
        'id': act.id,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> toggleJudgement(JudgementModel j) async {
    final key = _judgementKey(j.id);
    if (_box.containsKey(key)) {
      await _box.delete(key);
    } else {
      await _box.put(key, {
        ...j.toMap(),
        'id': j.id,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static List<T> _readSorted<T>(
    String prefix,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    final entries = _box.keys
        .where((k) => k.toString().startsWith(prefix))
        .map((k) => Map<String, dynamic>.from(_box.get(k) as Map))
        .toList();
    entries.sort((a, b) =>
        ((b['savedAt'] as int?) ?? 0).compareTo((a['savedAt'] as int?) ?? 0));
    return entries.map(fromMap).toList();
  }

  static ActModel _actFromMap(Map<String, dynamic> m) => ActModel(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        year: (m['year'] as num?)?.toInt() ?? 0,
        pdfUrl: m['pdfUrl'] as String?,
      );

  static JudgementModel _judgementFromMap(Map<String, dynamic> m) =>
      JudgementModel(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        snippet: m['snippet'] as String? ?? '',
        date: m['date'] as String? ?? '',
        year: (m['year'] as num?)?.toInt() ?? 0,
        court: m['court'] as String? ?? '',
        pdfUrl: m['pdfUrl'] as String?,
      );
}
