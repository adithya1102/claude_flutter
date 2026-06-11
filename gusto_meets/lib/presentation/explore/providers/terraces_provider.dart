import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/terrace_entity.dart';
import '../../../domain/enums/booking_purpose.dart';
import '../../common/providers/supabase_provider.dart';

final selectedAreaProvider = StateProvider<String>((_) => 'All');

final selectedPurposesProvider =
    StateProvider<List<BookingPurpose>>((_) => []);

final terracesProvider = FutureProvider.autoDispose
    .family<List<TerraceEntity>, Map<String, dynamic>>((ref, params) async {
  final city = params['city'] as String? ?? AppConstants.defaultCity;
  final area = params['area'] as String?;
  final purposes = params['purposes'] as List<BookingPurpose>?;
  return ref
      .watch(terraceRepoProvider)
      .getActiveTerraces(city, area: area, purposes: purposes);
});
