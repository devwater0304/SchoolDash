import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

String subjectPictogramKey(String subject) {
  if (RegExp(r'수학|미적|확률|기하|대수').hasMatch(subject)) {
    return 'math';
  }
  if (RegExp(r'국어|문학|화법|독서|작문').hasMatch(subject)) {
    return 'language';
  }
  if (subject.contains('영어')) {
    return 'english';
  }
  if (RegExp(r'과학|물리|화학|생명|지구').hasMatch(subject)) {
    return 'science';
  }
  if (RegExp(r'사회|역사|한국사|세계사|지리|윤리|문화|정치|경제').hasMatch(subject)) {
    return 'social';
  }
  if (RegExp(r'체육|스포츠').hasMatch(subject)) {
    return 'sports';
  }
  if (subject.contains('음악')) {
    return 'music';
  }
  if (RegExp(r'미술|디자인').hasMatch(subject)) {
    return 'art';
  }
  if (RegExp(r'정보|코딩|컴퓨터|프로그래밍').hasMatch(subject)) {
    return 'computer';
  }
  return 'default';
}

IconData subjectIcon(String subject) => switch (subjectPictogramKey(subject)) {
  'math' => Icons.functions_rounded,
  'language' => Icons.menu_book_rounded,
  'english' => Icons.translate_rounded,
  'science' => Icons.science_outlined,
  'social' => Icons.public_rounded,
  'sports' => Icons.sports_soccer_rounded,
  'music' => Icons.music_note_rounded,
  'art' => Icons.palette_outlined,
  'computer' => Icons.code_rounded,
  _ => Icons.auto_stories_outlined,
};

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
