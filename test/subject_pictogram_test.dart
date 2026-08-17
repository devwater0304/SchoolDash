import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_dash/widgets/subject_pictogram.dart';

void main() {
  test('categorises detailed subject names with the matching pictogram', () {
    expect(subjectIcon('화법과 작문'), Icons.menu_book_rounded);
    expect(subjectIcon('확률과 통계'), Icons.functions_rounded);
    expect(subjectIcon('영어 회화'), Icons.translate_rounded);
    expect(subjectIcon('생명과학'), Icons.science_outlined);
    expect(subjectIcon('한국사'), Icons.public_rounded);
    expect(subjectIcon('체육'), Icons.sports_soccer_rounded);
    expect(subjectIcon('음악'), Icons.music_note_rounded);
    expect(subjectIcon('미술'), Icons.palette_outlined);
    expect(subjectIcon('정보'), Icons.code_rounded);
  });

  test('uses a learning pictogram for an unknown subject', () {
    expect(subjectIcon('진로와 직업'), Icons.auto_stories_outlined);
  });
}
