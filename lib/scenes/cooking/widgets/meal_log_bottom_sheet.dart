import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List;

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../inventory/ocr/data/ocr_image_service.dart'
    show DeviceOcrImagePicker, FlutterOcrImageCompressor,
        OcrImageInvalidException, OcrImageTooLargeException,
        OcrPermissionDeniedException;
import '../../inventory/ocr/domain/ocr_scan_result.dart' show OcrImageSource;
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/meal_type.dart';

/// Bottom sheet "ghi bữa ăn" (meal-log-screen §9).
///
/// Chọn meal type (luôn có đúng 1 chọn — Guard #9), mô tả optional, ảnh tuỳ
/// chọn. Nút "Lưu" fire-and-forget → đóng sheet ngay, không chờ response
/// (Decision D4, #77 tối đa ~32s).
class MealLogBottomSheet extends StatefulWidget {
  const MealLogBottomSheet({super.key, required this.onSubmit});

  /// Hàm do scene truyền vào — gọi `store.submitLog(...)`.
  final Future<void> Function({
    required MealType mealType,
    String? userDescription,
    Uint8List? imageBytes,
  }) onSubmit;

  @override
  State<MealLogBottomSheet> createState() => _MealLogBottomSheetState();
}

class _MealLogBottomSheetState extends State<MealLogBottomSheet> {
  final TextEditingController _descController = TextEditingController();
  MealType _mealType = MealType.lunch;
  Uint8List? _imageBytes;
  String? _localPhotoError;
  bool _photoTooLarge = false;

  void _defaultMealTypeByHour() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) {
      _mealType = MealType.breakfast;
    } else if (hour >= 10 && hour < 14) {
      _mealType = MealType.lunch;
    } else if (hour >= 17 && hour < 21) {
      _mealType = MealType.dinner;
    } else {
      _mealType = MealType.snack;
    }
  }

  @override
  void initState() {
    super.initState();
    _defaultMealTypeByHour();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_imageBytes != null) return;
    setState(() {
      _localPhotoError = null;
      _photoTooLarge = false;
    });
    try {
      final raw =
          await DeviceOcrImagePicker().pick(OcrImageSource.camera);
      if (raw == null) return;
      final bytes = await const FlutterOcrImageCompressor().compress(raw);
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } on OcrPermissionDeniedException {
      if (!mounted) return;
      setState(
          () => _localPhotoError = context.l10n.mealLogCameraPermissionDenied);
    } on OcrImageTooLargeException {
      if (!mounted) return;
      setState(() {
        _photoTooLarge = true;
        _imageBytes = null;
      });
    } on OcrImageInvalidException {
      if (!mounted) return;
      setState(() => _localPhotoError = context.l10n.mealLogPhotoInvalid);
    }
  }

  Future<void> _save() async {
    await widget.onSubmit(
      mealType: _mealType,
      userDescription: _descController.text,
      imageBytes: _imageBytes,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.mealLogMealType,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimens.sm),
            Wrap(
              spacing: 8,
              children: MealType.values
                  .map((t) => ChoiceChip(
                        label: Text(_chipLabel(t)),
                        selected: _mealType == t,
                        onSelected: (_) => setState(() => _mealType = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppDimens.md),
            TextField(
              controller: _descController,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.mealLogDescriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            _photoSection(context),
            if (_photoTooLarge) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              _photoError(l10n.mealLogPhotoTooLarge, l10n.mealLogChooseAnother),
            ] else if (_localPhotoError != null) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              Text(_localPhotoError!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error)),
            ],
            const SizedBox(height: AppDimens.md),
            AppButton(
              label: l10n.mealLogLogMeal,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  String _chipLabel(MealType t) => switch (t) {
        MealType.breakfast => context.l10n.mealLogBreakfast,
        MealType.lunch => context.l10n.mealLogLunch,
        MealType.dinner => context.l10n.mealLogDinner,
        MealType.snack => context.l10n.mealLogSnack,
      };

  Widget _photoSection(BuildContext context) {
    final bytes = _imageBytes;
    if (bytes != null) {
      return Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: Image.memory(
              bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: TextButton(
              onPressed: () => setState(() {
                _imageBytes = null;
                _photoTooLarge = false;
              }),
              child: Text(context.l10n.mealLogDelete),
            ),
          ),
        ],
      );
    }
    return TextButton.icon(
      onPressed: _addPhoto,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: Text(context.l10n.mealLogAddPhoto),
    );
  }

  Widget _photoError(String message, String action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(message,
            style: const TextStyle(fontSize: 13, color: AppColors.error)),
        TextButton(
          onPressed: () => setState(() {
            _photoTooLarge = false;
            _imageBytes = null;
          }),
          child: Text(action),
        ),
      ],
    );
  }
}