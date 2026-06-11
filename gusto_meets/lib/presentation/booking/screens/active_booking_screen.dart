import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../common/providers/supabase_provider.dart';

class ActiveBookingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const ActiveBookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ActiveBookingScreen> createState() =>
      _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends ConsumerState<ActiveBookingScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  BookingEntity? _booking;
  bool _loading = true;
  bool _tminus15Shown = false;
  late Razorpay _razorpay;
  int? _extendMinutes;
  double? _extendCost;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS, _handleExtendSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleExtendError);
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final b = await ref
          .read(bookingRepoProvider)
          .getBooking(widget.bookingId);
      setState(() {
        _booking = b;
        _loading = false;
      });
      if (b != null) _startTimer(b);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startTimer(BookingEntity booking) {
    _timer?.cancel();
    _updateRemaining(booking);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(booking);
    });
  }

  void _updateRemaining(BookingEntity booking) {
    final r = booking.endTime.difference(DateTime.now());
    setState(() => _remaining = r.isNegative ? Duration.zero : r);
    if (!_tminus15Shown &&
        r.inMinutes <= AppConstants.tMinus15AlertMinutes &&
        r.inMinutes > 0) {
      _tminus15Shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showTMinus15();
      });
    }
  }

  void _showTMinus15() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, color: AppColors.warning, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Ending soon!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your session ends in 15 minutes. Would you like to extend?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No thanks'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExtendSheet();
                    },
                    child: const Text('Extend'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendSheet() {
    final booking = _booking;
    if (booking == null) return;
    final hourlyRate = booking.hourlyRateApplied;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Extend session',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _extendChip(
                    30, hourlyRate * 0.5, '+30 min', booking),
                const SizedBox(width: 8),
                _extendChip(60, hourlyRate, '+1 hr', booking),
                const SizedBox(width: 8),
                _extendChip(
                    120, hourlyRate * 2, '+2 hrs', booking),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _extendChip(
      int mins, double cost, String label, BookingEntity booking) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _payForExtension(mins, cost, booking);
        },
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(CurrencyUtils.formatINR(cost),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  void _payForExtension(int mins, double cost, BookingEntity booking) {
    setState(() {
      _extendMinutes = mins;
      _extendCost = cost;
    });
    final user = ref.read(currentUserProvider).value;
    final options = {
      'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
      'amount': (cost * 100).toInt(),
      'name': 'Gusto Meets',
      'description': 'Session extension',
      'prefill': {'contact': '+91${user?.phoneNumber ?? ''}'},
      'theme': {'color': '#10B981'},
    };
    _razorpay.open(options);
  }

  void _handleExtendSuccess(PaymentSuccessResponse response) async {
    final mins = _extendMinutes;
    final cost = _extendCost;
    if (mins == null || cost == null) return;
    try {
      final updated = await ref
          .read(bookingRepoProvider)
          .extendBooking(widget.bookingId, mins, cost);
      setState(() => _booking = updated);
      _startTimer(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extension update failed: $e')),
        );
      }
    }
  }

  void _handleExtendError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extension payment failed: ${response.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _checkoutEarly() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Check out early?'),
        content: const Text(
            'Unused time is non-refundable. Are you sure you want to check out now?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(bookingRepoProvider)
                  .checkoutBooking(widget.bookingId);
              if (mounted) context.go('/bookings');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terraceAsync = ref.watch(terraceDetailsProvider(_booking?.terraceId ?? ''));

    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final booking = _booking;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Booking')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final totalDuration = booking.endTime.difference(booking.startTime);
    final elapsed = totalDuration - _remaining;
    final progress = totalDuration.inSeconds > 0
        ? elapsed.inSeconds / totalDuration.inSeconds
        : 0.0;
    final isEndingSoon = _remaining.inMinutes <= 15 && _remaining.inSeconds > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Session'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: booking.isActive
                  ? AppColors.primary
                  : AppColors.textDisabled,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booking.status.dbValue,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEndingSoon
                      ? [
                          const Color(0xFFF59E0B),
                          const Color(0xFFEF4444)
                        ]
                      : [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (isEndingSoon)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '⚠️ Ending soon',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Text(
                    _remaining.inSeconds > 0
                        ? AppDateUtils.formatCountdown(_remaining)
                        : 'Session ended',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('remaining',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session Details',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (booking.hostCheckedIn)
                    const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text('Host checked you in',
                            style:
                                TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  const SizedBox(height: 8),
                  terraceAsync.when(
                    loading: () => const SizedBox(
                      height: 36,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, __) => TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://maps.google.com/?q=${booking.terraceId}'),
                      ),
                      icon: const Icon(Icons.directions),
                      label: const Text('Navigate'),
                    ),
                    data: (terrace) {
                      final query = terrace != null
                          ? (terrace.geoLat != null && terrace.geoLng != null
                              ? '${terrace.geoLat},${terrace.geoLng}'
                              : terrace.addressLine)
                          : booking.terraceId;
                      return TextButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse('https://maps.google.com/?q=$query'),
                        ),
                        icon: const Icon(Icons.directions),
                        label: const Text('Navigate'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (booking.extensionsCount < AppConstants.maxExtensions)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Extend session',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _extendChip(30,
                            booking.hourlyRateApplied * 0.5,
                            '+30 min',
                            booking),
                        const SizedBox(width: 8),
                        _extendChip(60, booking.hourlyRateApplied,
                            '+1 hr', booking),
                        const SizedBox(width: 8),
                        _extendChip(120,
                            booking.hourlyRateApplied * 2,
                            '+2 hrs',
                            booking),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _checkoutEarly,
                child: const Text(
                  'Check Out Early',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
