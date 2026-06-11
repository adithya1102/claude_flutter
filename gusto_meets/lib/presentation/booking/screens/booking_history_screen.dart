import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/enums/booking_status.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/empty_state_widget.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final bookingsAsync = ref.watch(
      _guestBookingsProvider(user.id),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: bookingsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (bookings) {
            final upcoming = bookings
                .where((b) =>
                    b.status == BookingStatus.confirmed ||
                    b.status == BookingStatus.active ||
                    b.status == BookingStatus.extended)
                .toList();
            final past = bookings
                .where((b) =>
                    b.status == BookingStatus.completed ||
                    b.status == BookingStatus.cancelled)
                .toList();

            return TabBarView(
              children: [
                _BookingList(bookings: upcoming, isUpcoming: true),
                _BookingList(bookings: past, isUpcoming: false),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _guestBookingsProvider =
    FutureProvider.autoDispose.family<List<BookingEntity>, String>(
  (ref, guestId) =>
      ref.watch(bookingRepoProvider).getGuestBookings(guestId),
);

class _BookingList extends StatelessWidget {
  final List<BookingEntity> bookings;
  final bool isUpcoming;

  const _BookingList(
      {required this.bookings, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        emoji: isUpcoming ? '📅' : '📋',
        title:
            isUpcoming ? 'No upcoming bookings' : 'No past bookings',
        subtitle: isUpcoming
            ? 'Explore terraces and make a booking'
            : 'Your completed bookings will appear here',
        actionLabel: isUpcoming ? 'Explore terraces' : null,
        onAction:
            isUpcoming ? () => context.go('/explore') : null,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingEntity booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    return switch (booking.status) {
      BookingStatus.active || BookingStatus.extended => AppColors.primary,
      BookingStatus.confirmed => AppColors.warning,
      BookingStatus.completed => AppColors.textSecondary,
      BookingStatus.cancelled => AppColors.error,
      _ => AppColors.textDisabled,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terraceAsync = ref.watch(terraceDetailsProvider(booking.terraceId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: terraceAsync.when(
                  loading: () => const Text('Loading...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  error: (_, __) => Text(
                    booking.terraceId.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  data: (terrace) => Text(
                    terrace?.title ?? booking.terraceId.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.dbValue.replaceAll('_', ' '),
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${AppDateUtils.formatDate(booking.startTime)}  •  '
            '${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                CurrencyUtils.formatINR(booking.totalPaid),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (booking.isActive)
                ElevatedButton(
                  onPressed: () => context
                      .go('/bookings/active/${booking.id}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Resume Session'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
