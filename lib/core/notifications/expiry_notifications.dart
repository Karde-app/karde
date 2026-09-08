import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../security/system_interaction_guard.dart';
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
  ///
  /// Raised from 24 when reminders became a ladder rather than a single warning:
  /// each item can now want up to eight days of its own, so the old figure was
  /// spent on the nearest three items and the rest waited for a later run. These
  /// are counted in days, not items — everything falling due on the same day
  /// shares one reminder — so this is a generous window, not a per-card budget.
  static const int _maxScheduled = 48;

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
  /// The request is wrapped in [SystemInteractionGuard] because Android's
  /// permission dialog takes the foreground, and the auto-lock timer cannot tell
  /// that apart from the user walking away. Without it, saying yes to
  /// notifications locked the vault and dropped the user on the PIN screen —
  /// which is exactly what happened on the phone, one card into a fresh vault.
  Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await SystemInteractionGuard.run(
      () async => await android.requestNotificationsPermission() ?? false,
    );
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
    required String Function(int count) expiringBody,
    required String Function(int count) expiredBody,
  }) async {
    try {
      await _ensureReady();
      await _plugin.cancelAll();
      if (!enabled) return;

      // Asked once here, then used for every reminder in this rebuild.
      await _refreshExactAllowed();

      final now = DateTime.now();
      // Two tallies per day: things entering their warning window, and things
      // running out. Kept apart because "2 have expired" and "2 expire soon" are
      // different sentences and merging them would make one of them untrue.
      final soonByDay = <DateTime, int>{};
      final expiredByDay = <DateTime, int>{};

      for (final thing in [...cards, ...documents]) {
        final expiry = _dayOf(thing.expiresOn);

        // A ladder rather than a single warning. One reminder a month out
        // arrives when there is nothing to do about it and is gone by the time
        // there is; these tighten as the date approaches. See
        // [Expiry.reminderDaysBefore].
        for (final daysBefore in Expiry.reminderOffsetsFor(thing.noticeDays)) {
          final day = expiry.subtract(Duration(days: daysBefore));
          // Compared against the moment it would actually be sent, not against
          // midnight of that day. These are days, but they go out at [_hour],
          // and testing the day meant the whole of it counted as past from
          // midnight onwards. The schedule is rebuilt every time Karde opens, so
          // opening the app at eight in the morning on a day a card was due to
          // be mentioned cancelled that morning's reminder and did not put it
          // back — and nine o'clock came and went in silence.
          if (_sendTimeOf(day).isAfter(now)) {
            soonByDay[day] = (soonByDay[day] ?? 0) + 1;
          }
        }

        // The day after it stops being valid, because on the last valid day it
        // still works and saying otherwise would be wrong.
        final gone = expiry.add(const Duration(days: 1));
        if (_sendTimeOf(gone).isAfter(now)) {
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
          await _schedule(id++, day, expiredBody(expired));
          scheduled++;
        }
        if (soon > 0 && scheduled < _maxScheduled) {
          await _schedule(id++, day, expiringBody(soon));
          scheduled++;
        }
      }
    } catch (e) {
      // A phone that will not schedule notifications is not a broken vault. The
      // bell inside the app says everything these would have said.
      debugPrint('Karde: could not schedule expiry reminders ($e)');
    }
  }

  /// Whether the phone will let Karde ask for a reminder at an exact minute.
  ///
  /// Worked out once per rebuild of the schedule rather than per reminder, so a
  /// vault full of cards does not ask the same question thirty times.
  bool _exactAllowed = false;

  AndroidScheduleMode get _mode => _exactAllowed
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Asks the phone whether exact alarms are permitted, and remembers it.
  ///
  /// This started as inexact everywhere, on the reasoning that a reminder
  /// arriving at ten past nine instead of nine is not worse in any way a user
  /// could notice. That reasoning was sound and the behaviour was not: on a
  /// Galaxy S23 an inexact reminder sat undelivered for its entire one-hour
  /// window — device awake, charging, not dozing, app in Android's active
  /// standby bucket — and then expired having never been shown. A reminder that
  /// might simply not arrive is not a reminder.
  ///
  /// Falling back rather than failing: if the permission is refused the
  /// reminders are still scheduled, just inexactly. The bell inside Karde says
  /// everything these would have said, so a refusal costs punctuality and not
  /// the feature.
  Future<void> _refreshExactAllowed() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      _exactAllowed = false;
      return;
    }
    try {
      _exactAllowed = await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      _exactAllowed = false;
    }
  }

  /// Sends the user to Android's "Alarms & reminders" screen.
  ///
  /// Asked where it explains itself — the moment somebody turns expiry reminders
  /// on — and never at launch.
  Future<void> requestExactAlarms() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    try {
      await SystemInteractionGuard.run(
        () async => android.requestExactAlarmsPermission(),
      );
    } catch (_) {
      // A phone that will not show the screen is not worth an error message;
      // the reminders simply stay inexact.
    }
  }

  /// One line and no title.
  ///
  /// There used to be a title — "Something in Karde is running out" — above the
  /// sentence. It said nothing the sentence did not, on top of a header that
  /// already reads "Karde", so a glance at the lock screen cost three lines to
  /// learn one thing. Android is happy with a null title and simply shows the
  /// text under the app's own name.
  Future<void> _schedule(
    int id,
    DateTime day,
    String body,
  ) {
    return _plugin.zonedSchedule(
      id,
      null,
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
      androidScheduleMode: _mode,
    );
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// The instant a reminder for [day] actually goes out.
  ///
  /// Kept next to [_schedule], which builds the same instant in the local zone,
  /// so the test that decides whether a reminder is still in the future and the
  /// code that sends it cannot drift apart again.
  @visibleForTesting
  static DateTime sendTimeOf(DateTime day) => _sendTimeOf(day);

  static DateTime _sendTimeOf(DateTime day) =>
      DateTime(day.year, day.month, day.day, _hour);
}
