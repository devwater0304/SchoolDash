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
- 학교급별 NEIS 시간표 API로 가져온 오늘의 실제 과목 표시
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

`다른 학교 찾기`는 `NeisSchoolSearchRepository`를 통해 NEIS `schoolInfo` API를 호출합니다. API 키는 소스나 Git에 저장하지 않고 실행 시에만 전달합니다. 처음 한 번만 아래처럼 개인 설정 파일을 만들고 키를 넣으면 됩니다.

```bash
cp .env.example .env
# .env 파일의 NEIS_API_KEY 값을 발급받은 키로 바꾼 뒤 실행
flutter run --dart-define-from-file=.env
```

`.env`는 Git에서 제외됩니다. CI나 배포 빌드에서는 같은 키를 안전한 비밀 변수로 주입하거나, 아래처럼 직접 전달하면 됩니다.

```bash
flutter build web --dart-define=NEIS_API_KEY=발급받은_키
```

키가 없을 때는 앱이 멈추지 않고 검색 화면에서 간단한 설정 안내와 재시도 경로를 보여줍니다. NEIS 응답은 DTO와 mapper를 거쳐 SchoolDash의 `SchoolSearchResult`로 변환되며, 선택한 학교의 교육청 코드와 행정표준 학교코드는 기존 `SchoolProfile`에 함께 저장됩니다.

## NEIS 시간표

Home은 저장된 SchoolProfile의 교육청 코드, 학교 코드, 학교급, 학년, 반과 오늘 날짜를 사용해 NEIS 시간표를 요청합니다. 초등학교는 `elsTimetable`, 중학교는 `misTimetable`, 고등학교는 `hisTimetable`을 사용합니다.

NEIS는 과목명과 교시 번호만 제공하고, 실제 시작·종료 시각은 현재 `sample_timetable.dart`에 있는 로컬 교시 시간 설정을 계속 사용합니다. 두 데이터는 교시 번호를 기준으로 합쳐져 기존 `SchoolTimeService`에 전달됩니다. 따라서 현재 교시·쉬는 시간 계산 방식은 바꾸지 않습니다.

NEIS 응답에 오늘 시간표가 없으면 수업이 없는 날이라고 단정하지 않고 “오늘 시간표가 없어요”로 표시합니다. 네트워크나 API 문제가 생기면 Home을 막지 않고 기존 샘플 시간표를 임시로 보여줍니다.

## 화면 구성

- 홈: 현재 교시, 남은 시간, 오늘 시간표
- 시간표: 월요일부터 금요일까지의 주간 시간표와 이전/다음 주 이동
- 급식: 추후 NEIS 급식 연동 전까지 안내 화면

홈과 주간 시간표는 같은 `TimetableLoadService`를 사용합니다. 이 서비스가 날짜별 NEIS 조회, 시간표 없음, 그리고 API 실패 시 샘플 fallback을 한 곳에서 처리합니다.

## 개발용 날짜 테스트

VS Code의 `SchoolDash (NEIS · test date)` 실행 구성을 선택하면 `2026-06-15`를 앱의 오늘 날짜로 사용합니다. 날짜를 바꾸려면 [.vscode/launch.json](.vscode/launch.json)의 `SCHOOLDASH_DEBUG_DATE=YYYY-MM-DD` 값만 수정하면 됩니다.

이 값은 디버그/프로파일 실행에서만 적용되며 Release 빌드에서는 항상 실제 기기 날짜를 사용합니다.

## 글꼴

앱 전체 기본 글꼴은 SUIT입니다. Thin부터 Heavy까지 제공된 9개 굵기를 모두 등록했으므로 제목과 강조 텍스트는 실제 굵기 파일을 사용합니다. 학교 검색 입력창에는 운영체제의 한국어 글꼴 fallback도 지정해 한글 조합 입력을 안정적으로 처리합니다.

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
