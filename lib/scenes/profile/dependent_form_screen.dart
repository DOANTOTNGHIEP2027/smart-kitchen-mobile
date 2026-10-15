import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../data/network/dio_client.dart';
import '../../demo/fixtures/demo_fixtures.dart';
import '../../widgets/app_scaffold.dart';

/// Màn hình thêm / sửa hồ sơ người phụ thuộc.
class DependentFormScreen extends StatefulWidget {
  const DependentFormScreen({super.key});

  @override
  State<DependentFormScreen> createState() => _DependentFormScreenState();
}

class _DependentFormScreenState extends State<DependentFormScreen> {
  final _nameController = TextEditingController();
  DateTime _dateOfBirth = DateTime(2022, 1, 1);
  String _dietType = 'NONE';
  final Set<int> _selectedAllergens = <int>{};
  bool _isSaving = false;

  final _dietOptions = const <Map<String, String>>[
    {'value': 'NONE', 'label': 'Bình thường'},
    {'value': 'VEGETARIAN', 'label': 'Ăn chay trứng sữa'},
    {'value': 'VEGAN', 'label': 'Ăn chay thuần'},
    {'value': 'PESCATARIAN', 'label': 'Ăn cá & hải sản'},
  ];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.sage,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên người phụ thuộc')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = Get.find<DioClient>().dio;
      final dobStr = DateFormat('yyyy-MM-dd').format(_dateOfBirth);

      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/dependents',
        data: <String, dynamic>{
          'displayName': name,
          'dateOfBirth': dobStr,
        },
      );

      final depId = response.data?['data']?['id'] as String?;
      if (depId != null) {
        // Save allergens & health profile
        if (_selectedAllergens.isNotEmpty) {
          await dio.put<Map<String, dynamic>>(
            '/api/v1/dependents/$depId/allergens',
            data: <String, dynamic>{
              'allergenIds': _selectedAllergens.toList(),
            },
          );
        }

        if (_dietType != 'NONE') {
          await dio.put<Map<String, dynamic>>(
            '/api/v1/dependents/$depId/health-profile',
            data: <String, dynamic>{
              'dietType': _dietType,
            },
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi lưu hồ sơ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Thêm người phụ thuộc',
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.lg),
        children: <Widget>[
          // Header info
          Text(
            'Thông tin cơ bản',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.sm),

          // Name Field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên hoặc biệt danh *',
              hintText: 'Ví dụ: Bé An, Bé Miu, Ông nội...',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.md),

          // Date of Birth Field
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Ngày sinh',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_dateOfBirth),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.xl),

          // Diet type section
          Text(
            'Chế độ ăn',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            'Chọn chế độ ăn đặc thù nếu thành viên có yêu cầu dinh dưỡng riêng.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietOptions.map((opt) {
              final selected = _dietType == opt['value'];
              return ChoiceChip(
                label: Text(opt['label']!),
                selected: selected,
                selectedColor: AppColors.sageLight,
                labelStyle: TextStyle(
                  color: selected ? AppColors.sageDark : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (val) {
                  if (val) setState(() => _dietType = opt['value']!);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimens.xl),

          // Allergens section
          Text(
            'Dị ứng thực phẩm',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            'Tích chọn các thực phẩm mà thành viên bị dị ứng để ứng dụng cảnh báo.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DemoFixtures.allergens.map((allergen) {
              final id = allergen['id'] as int;
              final name = allergen['name'] as String;
              final isChecked = _selectedAllergens.contains(id);

              return FilterChip(
                label: Text(name),
                selected: isChecked,
                selectedColor: AppColors.error.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isChecked ? AppColors.error : AppColors.textPrimary,
                  fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                ),
                checkmarkColor: AppColors.error,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedAllergens.add(id);
                    } else {
                      _selectedAllergens.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimens.xxl),

          // Save button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sage,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Lưu hồ sơ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
