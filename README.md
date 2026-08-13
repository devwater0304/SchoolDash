# SchoolDash

학교생활에서 지금 필요한 정보를 빠르게 확인할 수 있는 Flutter 앱입니다.
앱을 열면 오늘의 시간표와 현재 학교 상태를 바로 보여주는 것을 첫 목표로 합니다.

## 현재 기능

- 하늘색 포인트의 홈 화면과 오늘의 시간표
- 현재 시간에 따른 수업 전 / 수업 중 / 쉬는 시간 / 점심시간 / 수업 종료 상태 계산
- 지난 교시·현재 교시·예정 교시의 시각적 구분
- 매분 현재 상태와 시간표 표시 자동 갱신
- 샘플 시간표 데이터로 동작하는 초기 프로토타입

## 프로젝트 구조

```text
lib/
  data/       샘플 시간표 데이터
  models/     시간표와 학교 상태 모델
  services/   현재 시간 기반 상태 계산
  screens/    화면 조립
  widgets/    재사용 UI 컴포넌트
  theme/      색상, 간격, 텍스트 스타일
```

시간 계산은 `SchoolTimeService`에 분리되어 있어 앱 홈 화면뿐 아니라 향후 홈 위젯이나 Apple Watch 화면에서도 같은 결과를 재사용할 수 있습니다.

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
