# SchoolDash

학교생활에서 지금 필요한 정보를 빠르게 확인할 수 있는 Flutter 앱입니다.
앱을 열면 오늘의 시간표와 현재 학교 상태를 바로 보여주는 것을 첫 목표로 합니다.

## 현재 기능

- 하늘색 포인트의 홈 화면과 오늘의 시간표
- 현재 시간에 따른 수업 전 / 수업 중 / 쉬는 시간 / 점심시간 / 수업 종료 상태 계산
- 날짜별 시간표와 학교 일정에 따른 수업일 판단
- 학교·학년·반 설정을 위한 로컬 SchoolProfile 저장 기반
- 가까운 학교 선택, 학교명 검색, 학년·반 설정 온보딩
- NEIS 학교기본정보 API를 이용한 실제 학교명 검색
- 지난 교시·현재 교시·예정 교시의 시각적 구분
- 매분 현재 상태와 시간표 표시 자동 갱신
- 샘플 시간표 데이터로 동작하는 초기 프로토타입

## 프로젝트 구조

```text
lib/
  data/           샘플 시간표·일정·학교 검색 데이터와 로컬 저장 구현
  models/         날짜별 시간표, 일정, 사용자 설정, 학교 검색 모델
  repositories/   학교 데이터·검색·사용자 설정 공통 인터페이스
  services/       학교일 판단과 현재 시간 기반 상태 계산
  screens/    화면 조립
  widgets/    재사용 UI 컴포넌트
  theme/      색상, 간격, 텍스트 스타일
```

데이터는 `SchoolRepository`를 통해 요청합니다. 현재는 `SampleSchoolRepository`가 샘플 데이터를 제공하고, 실제 NEIS 연동 시에는 `NeisSchoolRepository`처럼 같은 인터페이스를 구현한 데이터 소스로 교체할 수 있습니다.

수업 여부는 `SchoolCalendarService`가 주말과 학교 일정을 기준으로 판단합니다. 수업일인 경우에만 날짜별 `DailyTimetable`을 가져와 `SchoolTimeService`로 전달하므로, 시간 계산 로직은 교시 시간 계산만 담당합니다. 이 흐름은 홈 위젯이나 Apple Watch에서도 그대로 재사용할 수 있습니다.

학교 이름·지역·학년·반은 `SchoolProfile`로 표현하며, 앱 설정에 적합한 `shared_preferences`에 JSON으로 저장합니다. 앱 시작 시 `SchoolProfileRepository`가 저장된 설정을 먼저 확인하고, 있으면 Home으로 진입합니다.

첫 실행에는 `SchoolOnboardingScreen`에서 가까운 학교 목록을 먼저 보여주고, 이름 검색으로 다른 학교를 찾을 수 있습니다. 현재 `SampleSchoolSearchRepository`가 개발용 목록을 제공하며, GPS는 사용하지 않습니다. 위치 기능을 붙일 때는 가까운 목록을 제공하는 구현체를, NEIS 학교 검색을 붙일 때는 `SchoolSearchRepository` 구현체를 각각 교체하면 됩니다.

`다른 학교 찾기`는 `NeisSchoolSearchRepository`를 통해 NEIS `schoolInfo` API를 호출합니다. API 키는 소스나 Git에 저장하지 않고 실행 시에만 전달합니다.

```bash
flutter run --dart-define=NEIS_API_KEY=발급받은_키
```

키가 없을 때는 앱이 멈추지 않고 검색 화면에서 설정 안내와 재시도 경로를 보여줍니다. NEIS 응답은 DTO와 mapper를 거쳐 SchoolDash의 `SchoolSearchResult`로 변환되며, 선택한 학교의 교육청 코드와 행정표준 학교코드는 기존 `SchoolProfile`에 함께 저장됩니다.

## 실행

```bash
flutter pub get
flutter run
```

## 검증

```bash
flutter analyze
flutter test
flutter build web
```

## 다음 단계

- 실제 학교 시간표 데이터를 입력·저장하는 기능
- 요일별 시간표 화면
- 급식 정보 화면
