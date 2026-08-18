import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

IconData subjectIcon(String subject) {
  if (RegExp(r'수학|미적|확률|기하|대수').hasMatch(subject)) {
    return Icons.functions_rounded;
  }
  if (RegExp(r'국어|문학|화법|독서|작문').hasMatch(subject)) {
    return Icons.menu_book_rounded;
  }
  if (subject.contains('영어')) {
    return Icons.translate_rounded;
  }
  if (RegExp(r'과학|물리|화학|생명|지구').hasMatch(subject)) {
    return Icons.science_outlined;
  }
  if (RegExp(r'사회|역사|한국사|세계사|지리|윤리|문화|정치|경제').hasMatch(subject)) {
    return Icons.public_rounded;
  }
  if (RegExp(r'체육|스포츠').hasMatch(subject)) {
    return Icons.sports_soccer_rounded;
  }
  if (subject.contains('음악')) {
    return Icons.music_note_rounded;
  }
  if (RegExp(r'미술|디자인').hasMatch(subject)) {
    return Icons.palette_outlined;
  }
  if (RegExp(r'정보|코딩|컴퓨터|프로그래밍').hasMatch(subject)) {
    return Icons.code_rounded;
  }
  return Icons.auto_stories_outlined;
}

class SubjectPictogram extends StatelessWidget {
  const SubjectPictogram({
    required this.subject,
    this.size = 18,
    this.color,
    super.key,
  });

  final String subject;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ?? (isDark ? AppColors.ink : AppColors.skyDark);
    return Icon(subjectIcon(subject), size: size, color: resolvedColor);
  }
}
