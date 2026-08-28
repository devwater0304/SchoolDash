import 'package:flutter/services.dart';

import '../models/school_dash_status_snapshot.dart';
import '../widgets/subject_pictogram.dart';

class IosLiveActivityPayload {
  const IosLiveActivityPayload({
    required this.situation,
    required this.period,
    required this.subject,
    required this.startAt,
    required this.endAt,
    required this.progress,
    required this.pictogramKey,
    this.nextPeriod,
    this.nextSubject,
  });

  final String situation;
  final int period;
  final String subject;
  final DateTime startAt;
  final DateTime endAt;
  final double progress;
  final String pictogramKey;
  final int? nextPeriod;
  final String? nextSubject;

  factory IosLiveActivityPayload.fromSnapshot(
    SchoolDashStatusSnapshot snapshot,
  ) {
    final current = snapshot.timeStatus.currentClass;
    if (current == null || !current.hasBellTime) {
      throw StateError('A current class with bell times is required.');
    }
    final next = snapshot.timeStatus.nextClass;
    return IosLiveActivityPayload(
      situation: snapshot.situation.type.name,
      period: current.period,
      subject: current.subject,
      startAt: _timeOn(snapshot.now, current.startMinute!),
      endAt: _timeOn(snapshot.now, current.endMinute!),
      progress: snapshot.classProgress,
      pictogramKey: subjectPictogramKey(current.subject),
      nextPeriod: next?.period,
      nextSubject: next?.subject,
    );
  }

  Map<String, Object?> toMap() => {
    'situation': situation,
    'period': period,
    'subject': subject,
    'startAt': startAt.toUtc().toIso8601String(),
    'endAt': endAt.toUtc().toIso8601String(),
    'progress': progress,
    'pictogramKey': pictogramKey,
    'nextPeriod': nextPeriod,
    'nextSubject': nextSubject,
  };

  static DateTime _timeOn(DateTime day, int minute) =>
      DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);
}

/// iOS receives a presentation payload only; Dart remains the status authority.
class IosLiveActivityService {
  const IosLiveActivityService();

  static const _channel = MethodChannel('school_dash/live_activity');

  Future<void> show(SchoolDashStatusSnapshot snapshot) =>
      _channel.invokeMethod<void>(
        'showOrUpdate',
        IosLiveActivityPayload.fromSnapshot(snapshot).toMap(),
      );
}
