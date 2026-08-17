import 'package:flutter/material.dart';

import '../services/app_clock.dart';

/// Opens the app-wide date QA controls used by Home and Settings.
Future<void> showAppDatePicker(
  BuildContext context,
  AppDateController controller,
) async {
  final useCurrent = await showModalBottomSheet<bool>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.today_outlined),
            title: const Text('현재 날짜 사용'),
            onTap: () => Navigator.pop(context, true),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('날짜 선택'),
            onTap: () => Navigator.pop(context, false),
          ),
        ],
      ),
    ),
  );
  if (useCurrent == null) return;
  if (useCurrent) {
    controller.useCurrentDate();
    return;
  }
  if (!context.mounted) return;
  final picked = await showDatePicker(
    context: context,
    initialDate: controller.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (picked != null) controller.selectDate(picked);
}
