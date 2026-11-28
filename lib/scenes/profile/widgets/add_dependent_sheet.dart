import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../dependent_error_l10n.dart';
import '../stores/dependent_store.dart';
import '../stores/form_status.dart';
import '../../../widgets/feedback/app_toast.dart';

/// Giới hạn `displayName` của BE (OAS `maxLength: 255`, Java đếm UTF-16).
const int kDependentNameMax = 255;

/// Bottom-sheet tạo hồ sơ phụ thuộc (§9.2, §16.9) — CHỈ tên + ngày sinh tuỳ
/// chọn. Chế độ ăn/dị ứng thiết lập ở màn chi tiết (2 API có quyền riêng).
class AddDependentSheet extends StatefulWidget {
  const AddDependentSheet({super.key, required this.store});

  final DependentStore store;

  @override
  State<AddDependentSheet> createState() => _AddDependentSheetState();
}

class _AddDependentSheetState extends State<AddDependentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();

  /// Không có giá trị mặc định (prototype gửi cứng 2022-01-01 — bỏ).
  DateTime? _dob;

  DependentStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _nameCtl.addListener(() => setState(() {}));
  }

  /// Reset ở `dispose` (sau animation đóng) — đang gửi thì store tự bỏ qua.
  @override
  void dispose() {
    _nameCtl.dispose();
    _store.clearCreateStatus();
    super.dispose();
  }

  /// KHÔNG đặt `maxLength` cho TextField: Flutter đếm grapheme và chặn nhập,
  /// còn BE đếm UTF-16 (L1). `String.length` của Dart = UTF-16, khớp Java.
  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return context.l10n.dependentNameRequired;
    if (v.length > kDependentNameMax) return context.l10n.dependentNameTooLong;
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final ok = await _store.createDependent(
        displayName: _nameCtl.text, dateOfBirth: _dob);
    if (!ok || !mounted) return;
    final toast = context.l10n.dependentCreatedToast;
    Navigator.of(context).pop();
    AppToast.show(toast, type: AppToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final submitting = _store.createStatus == FormStatus.submitting;
      final error =
          _store.createStatus == FormStatus.failure ? _store.createError : null;
      final dob = _dob;
      return PopScope(
        canPop: !submitting,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppDimens.md,
            right: AppDimens.md,
            top: AppDimens.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.dependentFormTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimens.md),
                if (error != null)
                  FeatureBanner(
                    key: const ValueKey<String>('add-dependent-error'),
                    message: dependentErrorMessage(l10n, error,
                        fallback: l10n.dependentSaveFailed),
                    margin: const EdgeInsets.only(bottom: AppDimens.md),
                  ),
                TextFormField(
                  key: const ValueKey<String>('add-dependent-name'),
                  controller: _nameCtl,
                  enabled: !submitting,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  decoration: InputDecoration(
                    labelText: l10n.dependentNameLabel,
                    hintText: l10n.dependentNameHint,
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                InkWell(
                  key: const ValueKey<String>('add-dependent-dob'),
                  onTap: submitting ? null : _pickDob,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.dependentDateOfBirth,
                      helperText: l10n.dependentDobHint,
                      enabled: !submitting,
                      suffixIcon: dob == null
                          ? const Icon(Icons.calendar_today_outlined)
                          : IconButton(
                              key: const ValueKey<String>(
                                  'add-dependent-dob-clear'),
                              tooltip: l10n.dependentDobClear,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: submitting
                                  ? null
                                  : () => setState(() => _dob = null),
                            ),
                    ),
                    child: Text(
                      dob == null
                          ? ''
                          : DateFormat.yMd(
                                  Localizations.localeOf(context).toString())
                              .format(dob),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                AppButton(
                  key: const ValueKey<String>('add-dependent-save'),
                  label: l10n.dependentSave,
                  isLoading: submitting,
                  onPressed: _nameCtl.text.trim().isEmpty ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
