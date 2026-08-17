enum HomeSituationType {
  beforeClasses,
  duringClass,
  breakTime,
  lunchSoon,
  lunchTime,
  afterLunchBreak,
  afterClasses,
  dayOff,
  noClasses,
}

class HomeSituation {
  const HomeSituation({required this.type});

  final HomeSituationType type;

  bool get showsDailyDashboard =>
      type != HomeSituationType.dayOff &&
      type != HomeSituationType.afterClasses;

  bool get showsMealFirst =>
      type == HomeSituationType.lunchSoon ||
      type == HomeSituationType.lunchTime;
}
