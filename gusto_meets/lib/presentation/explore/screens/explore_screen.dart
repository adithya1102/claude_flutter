import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/terrace_entity.dart';
import '../../../domain/enums/booking_purpose.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/loading_shimmer.dart';
import '../../common/widgets/permission_badge.dart';
import '../providers/terraces_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedArea = ref.watch(selectedAreaProvider);
    final selectedPurposes = ref.watch(selectedPurposesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final walletBalance =
        userAsync.value?.walletBalance ?? 0.0;

    final params = <String, dynamic>{
      'city': AppConstants.defaultCity,
      if (selectedArea != 'All') 'area': selectedArea,
      if (selectedPurposes.isNotEmpty) 'purposes': selectedPurposes,
    };
    final terracesAsync = ref.watch(terracesProvider(params));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 70,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Row(
                children: [
                  const Text(
                    'Gusto Meets',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/wallet'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        CurrencyUtils.formatINR(walletBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AppConstants.areas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final area = AppConstants.areas[i];
                      final selected = area == selectedArea;
                      return GestureDetector(
                        onTap: () => ref
                            .read(selectedAreaProvider.notifier)
                            .state = area,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.secondary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            area,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: BookingPurpose.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final purpose = BookingPurpose.values[i];
                      final selected =
                          selectedPurposes.contains(purpose);
                      return GestureDetector(
                        onTap: () {
                          final current = ref
                              .read(selectedPurposesProvider.notifier)
                              .state;
                          ref
                              .read(selectedPurposesProvider.notifier)
                              .state = selected
                              ? current
                                  .where((p) => p != purpose)
                                  .toList()
                              : [...current, purpose];
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${purpose.emoji} ${purpose.displayName}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          terracesAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const TerraceCardShimmer(),
                childCount: 3,
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error: $e'),
                ),
              ),
            ),
            data: (terraces) => terraces.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No terraces found.\nTry a different area or filter.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => TerraceCard(terrace: terraces[i]),
                      childCount: terraces.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class TerraceCard extends StatelessWidget {
  final TerraceEntity terrace;
  const TerraceCard({super.key, required this.terrace});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/explore/${terrace.id}', extra: terrace),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: terrace.photos.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: terrace.photos.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                if (terrace.area != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        terrace.area!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Up to ${terrace.maxCapacity}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          terrace.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${CurrencyUtils.formatINR(terrace.baseHourlyRate)}/hr',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (terrace.permissions != null) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (terrace.permissions!.allowAlcohol)
                          const PermissionBadge(
                            label: 'Alcohol',
                            icon: Icons.local_bar,
                            allowed: true,
                            color: AppColors.badgeAlcohol,
                          ),
                        if (terrace.permissions!.allowOutsideFood)
                          const PermissionBadge(
                            label: 'Outside Food',
                            icon: Icons.restaurant,
                            allowed: true,
                            color: AppColors.badgeFood,
                          ),
                        if (terrace.permissions!.allowLoudMusic)
                          const PermissionBadge(
                            label: 'Music',
                            icon: Icons.music_note,
                            allowed: true,
                            color: AppColors.badgeMusic,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.home, size: 48, color: AppColors.textDisabled),
    );
  }
}
