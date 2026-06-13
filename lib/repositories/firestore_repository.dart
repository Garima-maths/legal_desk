import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/act_model.dart';
import '../models/chapter_model.dart';
import '../models/section_model.dart';
import '../models/dictionary_term_model.dart';
import '../models/judgement_model.dart';
import '../utils/firebase_error_handler.dart';

/// Single source of truth for all Firestore interactions.
///
/// UI widgets must not import cloud_firestore directly — use this class only.
class FirestoreRepository {
  FirestoreRepository._();
  static final FirestoreRepository instance = FirestoreRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------------------------------------------
  // In-memory acts cache — populated on first searchActs() call.
  // Stays valid for the app session; real-time stream keeps browse up-to-date.
  // -------------------------------------------------------------------------
  List<ActModel>? _actsCache;

  // =========================================================================
  // ACTS
  // =========================================================================

  /// Real-time stream of all acts, ordered by title.
  /// Used by the home screen for live browsing.
  Stream<List<ActModel>> streamActs() {
    return _db
        .collection('acts')
        .orderBy('title')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(ActModel.fromSnapshot).toList())
        .handleError((Object e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    });
  }

  /// Load the next page of acts after [lastAct].
  /// Returns an empty list when there are no more results.
  Future<List<ActModel>> fetchMoreActs(ActModel lastAct) async {
    try {
      final snap = await _db
          .collection('acts')
          .orderBy('title')
          .startAfter([lastAct.title])
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      return snap.docs.map(ActModel.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  /// Search acts by title (case-insensitive substring match).
  ///
  /// Uses an in-session cache so repeated searches over the same dataset
  /// do not incur extra Firestore reads. Forces a server fetch on first call
  /// to guarantee freshness.
  Future<List<ActModel>> searchActs(String query) async {
    try {
      _actsCache ??= await _fetchAllActsFromServer();
      final lower = query.toLowerCase();
      return _actsCache!.where((act) {
        return act.title.toLowerCase().contains(lower) ||
            act.year.toString().contains(lower);
      }).toList();
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    }
  }

  /// Force-invalidates the in-memory acts cache (e.g. after a pull-to-refresh).
  void invalidateActsCache() => _actsCache = null;

  Future<List<ActModel>> _fetchAllActsFromServer() async {
    try {
      final snap = await _db
          .collection('acts')
          .get(const GetOptions(source: Source.server));
      return snap.docs.map(ActModel.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  // =========================================================================
  // CHAPTERS
  // =========================================================================

  /// Real-time stream of chapters for [actId], ordered by the `order` field.
  Stream<List<ChapterModel>> streamChapters(String actId) {
    return _db
        .collection('acts')
        .doc(actId)
        .collection('chapters')
        .snapshots()
        .map((snap) {
          final chapters = snap.docs.map(ChapterModel.fromSnapshot).toList();
          chapters.sort((a, b) => a.order.compareTo(b.order));
          return chapters;
        })
        .handleError((Object e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    });
  }

  /// One-time fetch of chapters — used only by the download service.
  Future<List<ChapterModel>> fetchChapters(String actId) async {
    try {
      final snap = await _db
          .collection('acts')
          .doc(actId)
          .collection('chapters')
          .get(const GetOptions(source: Source.server));
      final chapters = snap.docs.map(ChapterModel.fromSnapshot).toList();
      chapters.sort((a, b) => a.order.compareTo(b.order));
      return chapters;
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  // =========================================================================
  // SECTIONS
  // =========================================================================

  /// Real-time stream of sections for [chapterId] within [actId].
  ///
  /// [sectionsCollection] is the name of the Firestore subcollection that
  /// holds the sections (defaults to "sections"). Pass
  /// [ChapterModel.sectionsCollection] here — some chapters store their
  /// sections under a differently-named subcollection (e.g. "chapter2").
  Stream<List<SectionModel>> streamSections(
      String actId, String chapterId,
      {String sectionsCollection = 'sections'}) {
    return _db
        .collection('acts')
        .doc(actId)
        .collection('chapters')
        .doc(chapterId)
        .collection(sectionsCollection)
        .snapshots()
        .map((snap) {
          final sections = snap.docs.map(SectionModel.fromSnapshot).toList();
          sections.sort((a, b) => a.sectionNumber.compareTo(b.sectionNumber));
          return sections;
        })
        .handleError((Object e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    });
  }

  /// One-time fetch of all sections in a chapter — used only by the download service.
  ///
  /// [sectionsCollection] behaves the same as in [streamSections].
  Future<List<SectionModel>> fetchSections(
      String actId, String chapterId,
      {String sectionsCollection = 'sections'}) async {
    try {
      final snap = await _db
          .collection('acts')
          .doc(actId)
          .collection('chapters')
          .doc(chapterId)
          .collection(sectionsCollection)
          .get(const GetOptions(source: Source.server));
      final sections = snap.docs.map(SectionModel.fromSnapshot).toList();
      sections.sort((a, b) => a.sectionNumber.compareTo(b.sectionNumber));
      return sections;
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  // =========================================================================
  // DICTIONARY
  // =========================================================================

  /// Stream all terms starting with [letter], sorted client-side (avoids composite index).
  Stream<List<DictionaryTermModel>> streamDictionaryByLetter(String letter) {
    return _db
        .collection('dictionary')
        .where('letter', isEqualTo: letter.toUpperCase())
        .snapshots()
        .map((snap) {
          final terms = snap.docs.map(DictionaryTermModel.fromSnapshot).toList();
          terms.sort((a, b) => a.term.compareTo(b.term));
          return terms;
        })
        .handleError((Object e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    });
  }

  /// Search dictionary terms by keyword (client-side filter over cached fetch).
  Future<List<DictionaryTermModel>> searchDictionary(String query) async {
    try {
      _dictCache ??= await _fetchAllDictionaryFromServer();
      final lower = query.toLowerCase();
      return _dictCache!
          .where((t) =>
              t.term.toLowerCase().contains(lower) ||
              t.definition.toLowerCase().contains(lower))
          .toList();
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    }
  }

  List<DictionaryTermModel>? _dictCache;

  void invalidateDictCache() => _dictCache = null;

  Future<List<DictionaryTermModel>> _fetchAllDictionaryFromServer() async {
    try {
      final snap = await _db
          .collection('dictionary')
          .orderBy('term')
          .get(const GetOptions(source: Source.serverAndCache));
      return snap.docs.map(DictionaryTermModel.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  // =========================================================================
  // JUDGEMENTS
  // =========================================================================

  List<JudgementModel>? _judgementsCache;

  /// Real-time stream of the first 50 judgements, ordered by date descending.
  Stream<List<JudgementModel>> streamJudgements() {
    return _db
        .collection('judgements')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(JudgementModel.fromSnapshot).toList())
        .handleError((Object e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    });
  }

  /// Stream all judgements for [year], sorted client-side by date descending.
  /// Uses a single equality filter — no composite index required.
  Stream<List<JudgementModel>> streamJudgementsByYear(int year) {
    return _db
        .collection('judgements')
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(JudgementModel.fromSnapshot).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        })
        .handleError((Object e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    });
  }

  /// Load the next page of judgements after [last].
  Future<List<JudgementModel>> fetchMoreJudgements(JudgementModel last) async {
    try {
      final snap = await _db
          .collection('judgements')
          .orderBy('date', descending: true)
          .startAfter([last.date])
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      return snap.docs.map(JudgementModel.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  /// Client-side search over all judgements (title + snippet).
  Future<List<JudgementModel>> searchJudgements(String query) async {
    try {
      _judgementsCache ??= await _fetchAllJudgementsFromServer();
      final lower = query.toLowerCase();
      return _judgementsCache!.where((j) {
        return j.title.toLowerCase().contains(lower) ||
            j.snippet.toLowerCase().contains(lower) ||
            j.year.toString().contains(lower);
      }).toList();
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirebaseErrorHandler.handleUnknown(e);
    }
  }

  void invalidateJudgementsCache() => _judgementsCache = null;

  Future<List<JudgementModel>> _fetchAllJudgementsFromServer() async {
    try {
      final snap = await _db
          .collection('judgements')
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.server));
      return snap.docs.map(JudgementModel.fromSnapshot).toList();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }

  /// Lazily fetches the full judgement content from the content subcollection.
  ///
  /// Returns a record with [text] (plain text, always present for all years)
  /// and [htmlContent] (cleaned HTML preserving original formatting, present
  /// only for 2025+ judgements). Callers should render HTML when non-null.
  Future<({String text, String? htmlContent})> fetchJudgementContent(
      String judgementId) async {
    try {
      final doc = await _db
          .collection('judgements')
          .doc(judgementId)
          .collection('content')
          .doc('body')
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return (text: '', htmlContent: null);
      final data = doc.data() ?? {};
      return (
        text:        (data['text']        as String?) ?? '',
        htmlContent: (data['htmlContent'] as String?),
      );
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handle(e);
    }
  }
}
