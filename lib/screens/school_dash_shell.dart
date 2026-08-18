import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../services/app_clock.dart';
import '../services/app_appearance.dart';
import '../services/meal_load_service.dart';
import '../services/timetable_load_service.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';
import 'meal_screen.dart';
import 'settings_screen.dart';
import 'weekly_timetable_screen.dart';

class SchoolDashShell extends StatefulWidget {
  const SchoolDashShell({
    required this.profile,
    required this.timetableLoadService,
    this.mealLoadService,
    this.dateController,
    this.profileRepository,
    this.nearbySchoolRepository,
    this.schoolSearchRepository,
    this.onProfileChanged,
    this.appearanceController,
    required this.clock,
    super.key,
  });

  final SchoolProfile profile;
  final TimetableLoadService timetableLoadService;
  final MealLoadService? mealLoadService;
  final AppClock clock;
  final AppDateController? dateController;
  final SchoolProfileRepository? profileRepository;
  final SchoolSearchRepository? nearbySchoolRepository;
  final SchoolSearchRepository? schoolSearchRepository;
  final Future<void> Function()? onProfileChanged;
  final AppAppearanceController? appearanceController;

  @override
  State<SchoolDashShell> createState() => _SchoolDashShellState();
}

class _SchoolDashShellState extends State<SchoolDashShell> {
  static const _swipeThreshold = 0.25;
  static const _lastTabIndex = 2;

  var _selectedIndex = 1;
  late final PageController _pageController;
  late final ValueNotifier<int?> _dragStartPage;
  late final ValueNotifier<double?> _dragDistancePixels;
  late final _QuickPageScrollPhysics _pagePhysics;
  int? _dragStartIndex;
  int? _pointerGestureStartIndex;
  double? _pointerStartX;
  double _viewportWidth = 0;
  var _pageGestureActive = false;
  var _isSnapping = false;
  int? _navigationTarget;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _dragStartPage = ValueNotifier(null);
    _dragDistancePixels = ValueNotifier(null);
    _pagePhysics = _QuickPageScrollPhysics(
      dragStartPage: _dragStartPage,
      dragDistancePixels: _dragDistancePixels,
      threshold: _swipeThreshold,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dragStartPage.dispose();
    _dragDistancePixels.dispose();
    super.dispose();
  }

  Future<void> _openSettings(BuildContext context) async {
    final profileRepository = widget.profileRepository;
    final nearbySchoolRepository = widget.nearbySchoolRepository;
    final schoolSearchRepository = widget.schoolSearchRepository;
    final dateController = widget.dateController;
    if (profileRepository == null ||
        nearbySchoolRepository == null ||
        schoolSearchRepository == null ||
        dateController == null) {
      return;
    }
    final profileChanged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          profile: widget.profile,
          profileRepository: profileRepository,
          nearbySchoolRepository: nearbySchoolRepository,
          schoolSearchRepository: schoolSearchRepository,
          dateController: dateController,
          appearanceController: widget.appearanceController,
        ),
      ),
    );
    if (profileChanged == true) await widget.onProfileChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    _viewportWidth = MediaQuery.sizeOf(context).width;
    final mealLoadService = widget.mealLoadService;
    final mealPage = mealLoadService == null
        ? const _MealPlaceholder()
        : MealScreen(
            profile: widget.profile,
            mealLoadService: mealLoadService,
            timetableLoadService: widget.timetableLoadService,
            clock: widget.clock,
            dateController: widget.dateController,
            isActive: _selectedIndex == 2,
          );
    return Scaffold(
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: NotificationListener<ScrollNotification>(
          onNotification: _limitPageDrag,
          child: PageView(
            controller: _pageController,
            physics: _pagePhysics,
            onPageChanged: _onPageChanged,
            children: [
              _KeepAlivePage(
                child: WeeklyTimetableScreen(
                  profile: widget.profile,
                  timetableLoadService: widget.timetableLoadService,
                  clock: widget.clock,
                  dateController: widget.dateController,
                  isActive: _selectedIndex == 0,
                ),
              ),
              _KeepAlivePage(
                child: HomeScreen(
                  profile: widget.profile,
                  timetableLoadService: widget.timetableLoadService,
                  clock: widget.clock,
                  dateController: widget.dateController,
                  mealLoadService: widget.mealLoadService,
                  isActive: _selectedIndex == 1,
                  onProfileTap: () => _openSettings(context),
                ),
              ),
              _KeepAlivePage(child: mealPage),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == _selectedIndex) return;
          _animateToPage(index, duration: const Duration(milliseconds: 240));
        },
      ),
    );
  }

  bool _limitPageDrag(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (_navigationTarget != null) return false;
    if (notification is ScrollStartNotification) {
      // Touch drags are locked by Listener before PageView receives them.
      // This branch covers trackpad/wheel scrolling, which has no pointer drag.
      if (notification.dragDetails != null ||
          _pointerGestureStartIndex != null) {
        return false;
      }
      if (_isSnapping || _pageGestureActive) return false;
      _beginPageGesture();
      return false;
    }
    if (notification is ScrollEndNotification) {
      if (_pageGestureActive && _pointerGestureStartIndex == null) {
        final page = _pageController.page;
        final startPage = _dragStartIndex;
        if (page != null && startPage != null) {
          final target = _targetForDisplacement(page - startPage, startPage);
          _pageGestureActive = false;
          _snapTo(target);
          return false;
        }
      }
      _pageGestureActive = false;
      return false;
    }
    if (notification is! ScrollUpdateNotification ||
        _dragStartIndex == null ||
        !_pageController.hasClients) {
      return false;
    }

    final page = _pageController.page;
    if (page == null) return false;
    final minPage = (_dragStartIndex! - 1).clamp(0, _lastTabIndex).toDouble();
    final maxPage = (_dragStartIndex! + 1).clamp(0, _lastTabIndex).toDouble();
    final constrainedPage = page.clamp(minPage, maxPage);
    if (constrainedPage != page) {
      _pageController.jumpToPage(constrainedPage.round());
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerStartX = event.position.dx;
    _pointerGestureStartIndex = _selectedIndex;
    _beginPageGesture();
    _dragDistancePixels.value = 0;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final startX = _pointerStartX;
    if (startX == null) return;
    _dragDistancePixels.value = startX - event.position.dx;
  }

  void _onPointerUp(PointerUpEvent event) {
    final startPage = _dragStartIndex;
    final distance = _dragDistancePixels.value;
    if (startPage == null || distance == null || _viewportWidth <= 0) {
      _pageGestureActive = false;
      return;
    }
    final targetPage = _targetForDisplacement(
      distance / _viewportWidth,
      startPage,
    );
    _pageGestureActive = false;
    _snapTo(targetPage);
  }

  void _onPageChanged(int index) {
    final startIndex =
        _pointerGestureStartIndex ??
        (_pageGestureActive ? _dragStartIndex : null);
    if (startIndex != null && (index - startIndex).abs() > 1) {
      final constrainedIndex = index > startIndex
          ? startIndex + 1
          : startIndex - 1;
      _pageController.jumpToPage(constrainedIndex.clamp(0, _lastTabIndex));
      setState(() => _selectedIndex = constrainedIndex.clamp(0, _lastTabIndex));
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _beginPageGesture() {
    if (_isSnapping || _pageGestureActive) return;
    _pageGestureActive = true;
    _dragStartIndex = _selectedIndex;
    _dragStartPage.value = _selectedIndex;
    _dragDistancePixels.value = null;
  }

  void _snapTo(int targetPage) {
    _isSnapping = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pageController.hasClients) {
        _isSnapping = false;
        _pointerStartX = null;
        _pointerGestureStartIndex = null;
        return;
      }
      await _animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 180),
      );
      if (mounted) {
        _pointerStartX = null;
        _pointerGestureStartIndex = null;
        _isSnapping = false;
      }
    });
  }

  int _targetForDisplacement(double displacement, int startPage) =>
      (displacement.abs() >= _swipeThreshold
              ? startPage + (displacement.isNegative ? -1 : 1)
              : startPage)
          .clamp(0, _lastTabIndex)
          .toInt();

  Future<void> _animateToPage(
    int targetPage, {
    required Duration duration,
  }) async {
    final target = targetPage.clamp(0, _lastTabIndex);
    if (_navigationTarget == target || !_pageController.hasClients) return;
    _navigationTarget = target;
    try {
      await _pageController.animateToPage(
        target,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
      if (mounted && _selectedIndex != target) {
        setState(() => _selectedIndex = target);
      }
    } finally {
      if (_navigationTarget == target) _navigationTarget = null;
    }
  }
}

class _QuickPageScrollPhysics extends PageScrollPhysics {
  const _QuickPageScrollPhysics({
    required this.dragStartPage,
    required this.dragDistancePixels,
    required this.threshold,
    super.parent,
  });

  final ValueListenable<int?> dragStartPage;
  final ValueListenable<double?> dragDistancePixels;
  final double threshold;

  @override
  _QuickPageScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _QuickPageScrollPhysics(
        dragStartPage: dragStartPage,
        dragDistancePixels: dragDistancePixels,
        threshold: threshold,
        parent: buildParent(ancestor),
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, 0);
    }
    final page = position.pixels / position.viewportDimension;
    final startPage = dragStartPage.value?.toDouble() ?? page.roundToDouble();
    final displacement = dragDistancePixels.value == null
        ? page - startPage
        : dragDistancePixels.value! / position.viewportDimension;
    final targetPage =
        (displacement >= threshold
                ? startPage + 1
                : displacement <= -threshold
                ? startPage - 1
                : startPage)
            .clamp(
              0,
              (position.maxScrollExtent / position.viewportDimension).round(),
            )
            .toDouble();
    final targetPixels = targetPage * position.viewportDimension;
    if (targetPixels == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      0,
      tolerance: toleranceFor(position),
    );
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.45, stiffness: 460, damping: 38);
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _MealPlaceholder extends StatelessWidget {
  const _MealPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text('급식 기능은 곧 준비할게요.', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
