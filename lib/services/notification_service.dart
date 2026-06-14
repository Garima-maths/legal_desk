import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../repositories/firestore_repository.dart';
import '../screens/chapters_screen.dart';
import '../screens/judgement_detail_screen.dart';

/// Topic every install subscribes to; broadcasts are sent here from the
/// Firebase Console.
const String _broadcastTopic = 'all';

/// Android notification channel id. Must match the
/// `default_notification_channel_id` metadata in AndroidManifest.xml so
/// background/system-tray notifications use the same channel.
const String _channelId = 'legal_desk_default';
const String _channelName = 'General';
const String _channelDescription = 'Announcements and legal content updates';

/// Background/terminated-state message handler.
///
/// Must be a top-level (or static) function annotated with `vm:entry-point`
/// because it runs in a separate isolate with no access to app state. We only
/// need Firebase initialized here; the system tray renders the notification
/// itself, and tap routing is handled by [FirebaseMessaging.onMessageOpenedApp]
/// / `getInitialMessage` once the app is back in the foreground.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Owns all Firebase Cloud Messaging + local-notification behaviour.
///
/// Singleton, matching the convention of [AuthService] /
/// [FirestoreRepository]. Call [init] once from `main()` after
/// `Firebase.initializeApp`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Global navigator key so notification taps — which fire outside the widget
  /// tree — can push routes without a [BuildContext]. Wired to [MaterialApp].
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Ask for permission (required on iOS and Android 13+).
    final settings = await _messaging.requestPermission();
    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    // 2. Set up the local-notifications plugin (used to display messages that
    //    arrive while the app is in the foreground) and its tap callback.
    await _initLocalNotifications();

    // Diagnostic: print the registration token so we can send a direct test
    // message to this device (bypasses topic propagation). Remove once verified.
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }

    // 3. Subscribe everyone to the broadcast topic. Wrapped so a failure here
    //    (e.g. no network at launch) never blocks the rest of init.
    try {
      await _messaging.subscribeToTopic(_broadcastTopic);
      debugPrint('FCM subscribed to topic: $_broadcastTopic');
    } catch (e) {
      debugPrint('FCM topic subscription failed: $e');
    }

    // 4. Foreground messages → render via local notifications.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // 5. Background handler for data delivery in the terminated/background state.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Taps that bring a backgrounded app to the foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

    // 7. A tap that cold-started the app from a terminated state. Deferred to
    //    the next frame so the navigator is mounted before we push.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleTap(initial.data),
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleTap(_decodePayload(payload));
        }
      },
    );

    // Create the Android channel up-front so foreground notifications and
    // system-tray notifications share one high-importance channel.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // data-only message: nothing to show

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  /// Routes a notification's data payload to the relevant screen.
  ///
  /// Payload contract:
  ///   `{ "type": "judgement", "id": "<docId>" }`
  ///   `{ "type": "act", "id": "<actId>", "title": "<actTitle>" }`
  ///   `{ "type": "home" }`  // or anything unknown → no-op (app opens to home)
  Future<void> _handleTap(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] as String?;
    final id = data['id'] as String?;

    switch (type) {
      case 'judgement':
        if (id == null || id.isEmpty) return;
        try {
          final judgement =
              await FirestoreRepository.instance.getJudgementById(id);
          if (judgement == null) return;
          navigator.push(MaterialPageRoute(
            builder: (_) => JudgementDetailScreen(judgement: judgement),
          ));
        } catch (e) {
          debugPrint('Notification deep-link (judgement) failed: $e');
        }
        break;
      case 'act':
        if (id == null || id.isEmpty) return;
        navigator.push(MaterialPageRoute(
          builder: (_) => ChaptersScreen(
            actId: id,
            actTitle: (data['title'] as String?) ?? '',
          ),
        ));
        break;
      default:
        // 'home' or unknown — the app already opens to the home screen.
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Payload (de)serialization — the local-notifications payload is a String, so
  // we round-trip the FCM data map through a compact key=value encoding rather
  // than pulling in a json dependency for two or three fields.
  // ---------------------------------------------------------------------------

  String _encodePayload(Map<String, dynamic> data) => data.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}')
      .join('&');

  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      if (pair.isEmpty) continue;
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      map[Uri.decodeComponent(pair.substring(0, idx))] =
          Uri.decodeComponent(pair.substring(idx + 1));
    }
    return map;
  }
}
