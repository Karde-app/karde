import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/expiry.dart';

/// One thing that runs out, reduced to the two facts a reminder needs.
class ExpiringThing {
  const ExpiringThing({required this.expiresOn, required this.noticeDays});

  final DateTime expiresOn;

  /// How far ahead this kind of thing deserves warning about. Thirty days for a
  /// card, ninety for a document — see [Expiry].
  final int noticeDays;
}

/// Reminders that arrive when Karde is closed.
///
/// **Local, not push.** Karde has no INTERNET permission and is not getting one:
/// a push notification needs a server that knows when your passport expires,
/// which is exactly the thing this app promises does not exist. These are
/// scheduled by the phone, for the phone, out of dates the phone already has.
///
/// **They say a number, never a name.** "2 things in Karde expire this month"
/// rather than "Your passport expires this month". A notification lands on the
/// lock screen, where anyone holding the phone can read it, and the whole point
/// of a vault is that the answer to "what is in it" is not casually available.
/// The count is enough to make somebody open the app, and the app is where the
/// names live, behind the lock.
///
/// **Nothing is scheduled that has no reason to fire.** Every reminder
/// corresponds to a real date on a real item: the day something enters its
/// warning window, and the day it runs out. There is no weekly nudge, no
/// "haven't seen you in a while". An app people should rarely need to open does
/// not get to manufacture reasons to open it.
class ExpiryNotifications {
  ExpiryNotifications._();

  static final ExpiryNotifications instance = ExpiryNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const String _channelId = 'karde_expiry';

  /// The hour reminders arrive, in local time.
  ///
  /// Nine in the morning: late enough not to wake anybody, early enough that
  /// "renew this today" is still actionable when it is read.
  static const int _hour = 9;

  /// The furthest ahead anything is scheduled.
  ///
  /// Android caps how many alarms an app may have pending, and a passport bought
  /// today might not need a word said about it for nine years. Anything beyond
  /// this window is picked up on a later run — the schedule is rebuilt every time
  /// the app opens or the vault changes.
  static const int _maxScheduled = 24;

  Future<void> _ensureReady() async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    try {
      // Without this, `tz.local` is UTC and a nine-in-the-morning reminder
      // arrives at whatever nine UTC happens to be where the user lives.
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // An unrecognised zone name is not worth losing reminders over. UTC is
      // wrong by hours, not by days, and the reminder still lands on its day.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
    );
    _ready = true;
  }

  /// Asks Android for permission to show notifications.
  ///
  /// Returns whether Karde may post them. Asked at the moment the user turns
  /// expiry reminders on, rather than at first launch: a permission request that
  /// arrives before the user knows what it is for is refused by reflex, and on
  /// Android there is no second chance to ask.
  Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Throws away every pending reminder and works out the schedule again.
  ///
  /// Rebuilt wholesale rather than patched. The alternative is tracking which
  /// notification belongs to which item and cancelling exactly the right ones
  /// when a card is edited or deleted — bookkeeping whose failure mode is a
  /// reminder about a card that no longer exists. Rebuilding is a handful of
  /// cheap calls and cannot drift.
  ///
  /// [enabled] false simply cancels everything, which is what the Settings
  /// switch does.
  Future<void> reschedule({
    required bool enabled,
    required List<ExpiringThing> cards,
    required List<ExpiringThing> documents,
    required String expiringTitle,
    required String Function(int count) expiringBody,
    required String expiredTitle,
    required String Function(int count) expiredBody,
  }) async {
    try {
      await _ensureReady();
      await _plugin.cancelAll();
      if (!enabled) return;

      final now = DateTime.now();
      // Two tallies per day: things entering their warning window, and things
      // running out. Kept apart because "2 have expired" and "2 expire soon" are
      // different sentences and merging them would make one of them untrue.
      final soonByDay = <DateTime, int>{};
      final expiredByDay = <DateTime, int>{};

      for (final thing in [...cards, ...documents]) {
        final expiry = _dayOf(thing.expiresOn);
        final notice = expiry.subtract(Duration(days: thing.noticeDays));

        if (notice.isAfter(now)) {
          soonByDay[notice] = (soonByDay[notice] ?? 0) + 1;
        }
        // The day after it stops being valid, because on the last valid day it
        // still works and saying otherwise would be wrong.
        final gone = expiry.add(const Duration(days: 1));
        if (gone.isAfter(now)) {
          expiredByDay[gone] = (expiredByDay[gone] ?? 0) + 1;
        }
      }

      final days = {...soonByDay.keys, ...expiredByDay.keys}.toList()..sort();

      var scheduled = 0;
      var id = 0;
      for (final day in days) {
        if (scheduled >= _maxScheduled) break;

        final expired = expiredByDay[day] ?? 0;
        final soon = soonByDay[day] ?? 0;

        if (expired > 0) {
          await _schedule(id++, day, expiredTitle, expiredBody(expired));
          scheduled++;
        }
        if (soon > 0 && scheduled < _maxScheduled) {
          await _schedule(id++, day, expiringTitle, expiringBody(soon));
          scheduled++;
        }
      }
    } catch (e) {
      // A phone that will not schedule notifications is not a broken vault. The
      // bell inside the app says everything these would have said.
      debugPrint('Karde: could not schedule expiry reminders ($e)');
    }
  }

  Future<void> _schedule(
    int id,
    DateTime day,
    String title,
    String body,
  ) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime(tz.local, day.year, day.month, day.day, _hour),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Expiry reminders',
          channelDescription:
              'Tells you before a card or document in Karde runs out.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          // The text is already a bare count, but this is belt and braces: on a
          // locked screen Android shows only that Karde has something to say.
          visibility: NotificationVisibility.private,
        ),
      ),
      // Inexact on purpose. An exact alarm needs a permission Google reviews
      // separately and grants for alarm clocks and calendars, and a reminder
      // that arrives at ten past nine instead of nine is not worse in any way a
      // user could notice.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
