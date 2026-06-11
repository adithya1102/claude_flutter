import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/enums/booking_status.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/empty_state_widget.dart';

class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final today = DateTime.now();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Host Dashboard'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                AppDateUtils.formatDate(today),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _TodayTab(hostId: user.id),
                  _ActiveTab(hostId: user.id),
                  _HistoryTab(hostId: user.id),
                ],
              ),
      ),
    );
  }
}

final _todayBookingsProvider = FutureProvider.autoDispose
    .family<List<BookingEntity>, String>((ref, hostId) {
  return ref.watch(bookingRepoProvider).getTodaysHostBookings(hostId);
});

class _TodayTab extends ConsumerWidget {
  final String hostId;
  const _TodayTab({required this.hostId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_todayBookingsProvider(hostId));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyStateWidget(
            emoji: '🏠',
            title: 'No bookings today',
            subtitle: 'Your terrace bookings will appear here',
          );
        }
        final expected = bookings.fold(
            0.0, (sum, b) => sum + b.totalPaid);
        return Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  Text(
                    '${bookings.length} bookings today  •  ${CurrencyUtils.formatINR(expected)} expected',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _HostBookingCard(booking: bookings[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HostBookingCard extends ConsumerWidget {
  final BookingEntity booking;
  const _HostBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestProfileAsync = ref.watch(userProfileProvider(booking.guestId));

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
              const Icon(Icons.person, size: 16,
                  color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: guestProfileAsync.when(
                  loading: () => const Text('Loading guest...', style: TextStyle(fontWeight: FontWeight.w600)),
                  error: (_, __) => Text(
                    booking.guestId.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  data: (user) => Text(
                    user?.fullName.isNotEmpty == true
                        ? (user!.kycVerifiedName ?? user.fullName)
                        : booking.guestId.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user,
                          size: 12, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text('KYC',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.purpose.displayName,
                  style: const TextStyle(
                      color: AppColors.secondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          booking.hostCheckedIn
              ? const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text('Checked In',
                        style: TextStyle(color: AppColors.primary)),
                  ],
                )
              : ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(bookingRepoProvider)
                        .checkInGuest(booking.id);
                    ref.invalidate(_todayBookingsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Check In Guest'),
                ),
        ],
      ),
    );
  }
}

class _ActiveTab extends ConsumerWidget {
  final String hostId;
  const _ActiveTab({required this.hostId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_todayBookingsProvider(hostId));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        final active = bookings
            .where((b) =>
                b.status == BookingStatus.active ||
                b.status == BookingStatus.extended)
            .toList();
        if (active.isEmpty) {
          return const EmptyStateWidget(
            emoji: '🌙',
            title: 'No active sessions',
            subtitle: 'Active terrace sessions will appear here',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ActiveHostCard(booking: active[i]),
        );
      },
    );
  }
}

class _ActiveHostCard extends ConsumerStatefulWidget {
  final BookingEntity booking;
  const _ActiveHostCard({required this.booking});

  @override
  ConsumerState<_ActiveHostCard> createState() =>
      _ActiveHostCardState();
}

class _ActiveHostCardState extends ConsumerState<_ActiveHostCard> {
  void _reportDamage() {
    final descController = TextEditingController();
    final List<XFile> photos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Damage',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the damage…',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage();
                  if (picked.isNotEmpty) {
                    setModalState(() {
                      photos.addAll(picked.take(5 - photos.length));
                    });
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: Text('Add Photos (${photos.length}/5)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final client =
                      ref.read(supabaseClientProvider);
                  await client.from('damage_reports').insert({
                    'booking_id': widget.booking.id,
                    'description': descController.text,
                    'reported_at': DateTime.now().toIso8601String(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Damage report submitted')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle,
                  color: AppColors.primary, size: 10),
              const SizedBox(width: 6),
              const Text('Active',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${widget.booking.timeRemaining.inHours}h ${widget.booking.timeRemaining.inMinutes.remainder(60)}m left',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppDateUtils.formatTime(widget.booking.startTime)} – ${AppDateUtils.formatTime(widget.booking.endTime)}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _reportDamage,
            icon: const Icon(Icons.report_problem_outlined,
                color: AppColors.error, size: 18),
            label: const Text('Report Damage',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  final String hostId;
  const _HistoryTab({required this.hostId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_allHostBookingsProvider(hostId));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        final completed = bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
        final monthEarnings = completed.fold(
            0.0, (sum, b) => sum + b.totalTimeCost);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  Text(
                    '${CurrencyUtils.formatINR(monthEarnings)} earned this month',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: completed.isEmpty
                  ? const EmptyStateWidget(
                      emoji: '📊',
                      title: 'No history yet',
                      subtitle: 'Completed bookings will appear here',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: completed.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppDateUtils.formatDate(
                                        completed[i].startTime),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${AppDateUtils.formatTime(completed[i].startTime)} – ${AppDateUtils.formatTime(completed[i].endTime)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyUtils.formatINR(
                                  completed[i].totalTimeCost),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

final _allHostBookingsProvider = FutureProvider.autoDispose
    .family<List<BookingEntity>, String>((ref, hostId) {
  return ref.watch(bookingRepoProvider).getHostBookings(hostId);
});
