import 'package:flutter/material.dart';

/// Design token — icon dùng chung của widget library (design-system.md §4.4).
abstract class AppIcons {
  static const IconData empty = Icons.inbox_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData retry = Icons.refresh;
  static const IconData back = Icons.arrow_back;
  static const IconData close = Icons.close;
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData lightMode = Icons.light_mode_outlined;
  static const IconData darkMode = Icons.dark_mode_outlined;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData success = Icons.check_circle_outline;
  static const IconData info = Icons.info_outline;
}
