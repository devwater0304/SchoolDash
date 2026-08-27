import 'package:flutter/services.dart';

import '../models/school_dash_status_snapshot.dart';

/// Sends an already-calculated snapshot to the iOS Live Activity host.
class IosLiveActivityService {
  const IosLiveActivityService();

  static const _channel = MethodChannel('school_dash/live_activity');

  Future<void> show(SchoolDashStatusSnapshot snapshot) {
    final current = snapshot.timeStatus.currentClass;
    if (current == null) return Future.value();
    final next = snapshot.timeStatus.nextClass;
    return _channel.invokeMethod<void>('show', {
      'period': current.period,
      'subject': current.subject,
      'remainingMinutes': snapshot.timeStatus.remaining.inMinutes,
      'progress': snapshot.classProgress,
      'nextPeriod': next?.period,
      'nextSubject': next?.subject,
    });
  }
}
