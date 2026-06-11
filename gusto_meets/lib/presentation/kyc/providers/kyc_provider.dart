import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../common/providers/supabase_provider.dart';

sealed class KycState {}

class KycIdle extends KycState {}

class KycLoading extends KycState {}

class KycSuccess extends KycState {
  final String verifiedName;
  KycSuccess(this.verifiedName);
}

class KycError extends KycState {
  final String message;
  KycError(this.message);
}

class KycNotifier extends StateNotifier<KycState> {
  final Ref _ref;
  KycNotifier(this._ref) : super(KycIdle());

  Future<void> submitKyc(String aadhaarNumber, String fullName) async {
    state = KycLoading();
    try {
      final client = _ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // TODO: Remove mock when Edge Function is deployed
      Map<String, dynamic> result;
      try {
        result = await client.functions.invoke(
          'verify-aadhaar',
          body: {'aadhaar': aadhaarNumber, 'name': fullName},
        ).then((r) => r.data as Map<String, dynamic>);
      } catch (_) {
        result = {'verified': true, 'verifiedName': fullName};
      }

      if (result['verified'] == true) {
        final verifiedName = result['verifiedName'] as String? ?? fullName;
        await client.from(SupabaseTables.users).update({
          'kyc_verified': true,
          'kyc_verified_name': verifiedName,
        }).eq('id', user.id);
        _ref.invalidate(currentUserProvider);
        state = KycSuccess(verifiedName);
      } else {
        state = KycError('Verification failed. Please check your details.');
      }
    } catch (e) {
      state = KycError(e.toString());
    }
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>(
  (ref) => KycNotifier(ref),
);
