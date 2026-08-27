import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/class_schedule.dart';
import '../models/school_dash_status_snapshot.dart';
import '../models/school_profile.dart';
import '../models/timetable_load_result.dart';
import '../services/app_clock.dart';
import '../services/ios_live_activity_service.dart';
import '../services/school_dash_status_snapshot_resolver.dart';
import '../services/timetable_load_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/school_water_painter.dart';
import '../widgets/subject_pictogram.dart';

/// QA-only Flutter rendering of the compact information hierarchy intended for
/// a future Live Activity. The card renders a [SchoolDashStatusSnapshot] only.
class LiveActivityPreviewScreen extends StatefulWidget {
  const LiveActivityPreviewScreen({
    required this.profile,
    required this.timetableLoadService,
    required this.dateController,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final AppDateController dateController;

  @override
  State<LiveActivityPreviewScreen> createState() =>
      _LiveActivityPreviewScreenState();
}

class _LiveActivityPreviewScreenState extends State<LiveActivityPreviewScreen> {
  static const _resolver = SchoolDashStatusSnapshotResolver();
  static const _iosLiveActivityService = IosLiveActivityService();

  late DateTime _now;
  TimetableLoadResult? _result;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _now = widget.dateController.now();
    widget.dateController.addListener(_onDateChanged);
    _loadSnapshotData(_now);
  }

  @override
  void dispose() {
    widget.dateController.removeListener(_onDateChanged);
    super.dispose();
  }

  void _onDateChanged() {
    final now = widget.dateController.now();
    final dateChanged = _dateOnly(now) != _dateOnly(_now);
    setState(() => _now = now);
    if (dateChanged) {
      _loadSnapshotData(now);
    }
  }

  Future<void> _loadSnapshotData(DateTime date) async {
    setState(() => _isLoading = true);
    final result = await widget.timetableLoadService.loadDay(
      profile: widget.profile,
      date: date,
    );
    if (!mounted || _dateOnly(_now) != _dateOnly(date)) return;
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final snapshot = _resolver.resolve(
      now: _now,
      schedule: result?.timetable?.classes ?? const <ClassSchedule>[],
      schoolDay: result?.schoolDay,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Activity Preview'),
        actions: [
          IconButton(
            tooltip: '기준 시간 변경',
            onPressed: () => showAppDatePicker(context, widget.dateController),
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('잠금 화면 미리보기', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 6),
                  const Text(
                    '기준 시간에 맞춘 SchoolDash 상태를 표시해요.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  if (_isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LiveActivityPreviewCard(snapshot: snapshot),
                        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                          const SizedBox(height: AppSpacing.medium),
                          FilledButton.icon(
                            onPressed: snapshot.timeStatus.currentClass == null
                                ? null
                                : () => _iosLiveActivityService.show(snapshot),
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('iPhone Live Activity에 표시'),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact, animation-light preview for a future app-outside surface.
class LiveActivityPreviewCard extends StatelessWidget {
  const LiveActivityPreviewCard({required this.snapshot, super.key});

  final SchoolDashStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final currentClass = snapshot.timeStatus.currentClass;
    final nextClass = snapshot.timeStatus.nextClass;
    final isDuringClass = currentClass != null;
    final progress = snapshot.classProgress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Live Activity Preview',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isDuringClass ? progress : 0),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, waterProgress, _) => Container(
          key: const ValueKey('live-activity-preview-card'),
          width: double.infinity,
          height: 158,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.skyPale, AppColors.skySoft],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (waterProgress > 0.001)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('live-activity-water'),
                      painter: SchoolWaterPainter(
                        progress: waterProgress,
                        phase: 0.28,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: isDuringClass
                          ? SubjectPictogram(
                              subject: currentClass.subject,
                              size: 20,
                            )
                          : const Icon(
                              Icons.schedule_rounded,
                              color: AppColors.skyDark,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isDuringClass ? '수업 중' : '현재 상태',
                            style: AppTextStyles.overline,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDuringClass
                                ? '${currentClass.period}교시 ${currentClass.subject}'
                                : _statusTitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isDuringClass
                                ? '종료까지 ${_durationLabel(snapshot.timeStatus.remaining)} · ${(progress * 100).round()}%'
                                : _statusDetail(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.skyDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isDuringClass && nextClass != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '다음 ${nextClass.period}교시 ${nextClass.subject}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusTitle() => '현재 수업 중이 아니에요';

  String _statusDetail() => '수업 중 기준 시간으로 미리볼 수 있어요';

  String _durationLabel(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes분';
    return '${duration.inHours}시간 ${minutes.remainder(60)}분';
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
