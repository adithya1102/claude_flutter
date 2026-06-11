import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/verhoeff.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/gusto_button.dart';
import '../providers/kyc_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _aadhaarController = TextEditingController();
  final _nameController = TextEditingController();
  bool _consentChecked = false;
  bool _aadhaarValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.fullName.isNotEmpty) {
        _nameController.text = user.fullName;
      }
    });
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _aadhaarValid && _consentChecked;

  void _onAadhaarChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _aadhaarValid = VerhoeffValidator.validate(digits);
    });
  }

  void _submit() async {
    final digits =
        _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
    await ref
        .read(kycProvider.notifier)
        .submitKyc(digits, _nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);
    final aadhaarDigits =
        _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
    final showValidation = aadhaarDigits.length == 12;

    ref.listen<KycState>(kycProvider, (prev, next) {
      if (next is KycSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity verified successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/explore');
      } else if (next is KycError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.message),
              backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.secondary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your Aadhaar number is never stored — only a verification token.',
                      style: TextStyle(
                          color: AppColors.secondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Aadhaar Number',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              maxLength: 14,
              inputFormatters: [
                _AadhaarFormatter(),
              ],
              onChanged: _onAadhaarChanged,
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX-XXXX',
                counterText: '',
                suffixIcon: showValidation
                    ? Icon(
                        _aadhaarValid ? Icons.check_circle : Icons.cancel,
                        color: _aadhaarValid
                            ? AppColors.primary
                            : AppColors.error,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Full Name (as on Aadhaar)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'Your full name'),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consentChecked,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _consentChecked = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'I consent to verify my identity using the above Aadhaar number for the purpose of booking terraces on Gusto Meets.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GustoButton(
              onPressed: _canSubmit ? _submit : null,
              label: 'Verify Identity',
              isLoading: kycState is KycLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 12; i++) {
      if (i == 4 || i == 8) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
