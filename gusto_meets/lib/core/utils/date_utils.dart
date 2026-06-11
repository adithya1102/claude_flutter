import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime dt) =>
      DateFormat('d MMM yyyy').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static Duration timeUntil(DateTime endTime) {
    final now = DateTime.now();
    if (endTime.isBefore(now)) return Duration.zero;
    return endTime.difference(now);
  }

  static String formatCountdown(Duration d) {
    if (d <= Duration.zero) return '00:00:00';
    final h  = d.inHours.toString().padLeft(2, '0');
    final m  = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s  = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String formatShortDate(DateTime dt) => DateFormat('EEE, d MMM').format(dt);

  static String formatDayName(DateTime dt) => DateFormat('EEE').format(dt);

  static String formatDayNumber(DateTime dt) => DateFormat('d').format(dt);

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('d MMM yyyy').format(d);
  }
}

// Alias expected by generated code and screens
typedef GustoDateUtils = AppDateUtils;
