import 'dart:async';

import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../models/school_search_failure.dart';
import '../models/school_search_result.dart';
import '../repositories/school_profile_repository.dart';
import '../repositories/school_search_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/choice_selection_card.dart';
import '../widgets/school_selection_card.dart';

enum _OnboardingStep { school, classInfo }

class SchoolOnboardingScreen extends StatefulWidget {
  const SchoolOnboardingScreen({
    required this.profileRepository,
    required this.onProfileSaved,
    required this.nearbySchoolRepository,
    required this.schoolSearchRepository,
    super.key,
  });

  final SchoolProfileRepository profileRepository;
  final SchoolSearchRepository nearbySchoolRepository;
  final SchoolSearchRepository schoolSearchRepository;
  final VoidCallback onProfileSaved;

  @override
  State<SchoolOnboardingScreen> createState() => _SchoolOnboardingScreenState();
}

class _SchoolOnboardingScreenState extends State<SchoolOnboardingScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  _OnboardingStep _step = _OnboardingStep.school;
  List<SchoolSearchResult> _schools = const [];
  SchoolSearchResult? _selectedSchool;
  int? _selectedGrade;
  int? _selectedClassNumber;
  bool _isLoadingSchools = true;
  bool _isSearching = false;
  bool _isSaving = false;
  String? _schoolLoadError;
  String? _saveError;
  String _searchQuery = '';
  var _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadNearbySchools();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbySchools() async {
    setState(() {
      _isLoadingSchools = true;
      _schoolLoadError = null;
    });
    try {
      final schools = await widget.nearbySchoolRepository.getNearbySchools();
      if (!mounted) return;
      setState(() => _schools = schools);
    } catch (_) {
      if (!mounted) return;
      setState(() => _schoolLoadError = '학교 목록을 불러오지 못했어요. 검색으로 찾아볼까요?');
    } finally {
      if (mounted) setState(() => _isLoadingSchools = false);
    }
  }

  Future<void> _searchSchools(String query) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _isLoadingSchools = true;
      _schoolLoadError = null;
    });
    try {
      final schools = await widget.schoolSearchRepository.searchSchools(query);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() => _schools = schools);
    } on SchoolSearchFailure catch (failure) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() => _schoolLoadError = _messageForSearchFailure(failure));
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() => _schoolLoadError = '검색 결과를 불러오지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isLoadingSchools = false);
      }
    }
  }

  void _queueSearch(String query) {
    _searchDebounce?.cancel();
    _searchQuery = query;
    if (query.trim().isEmpty) {
      setState(() {
        _schools = const [];
        _schoolLoadError = null;
        _isLoadingSchools = false;
      });
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchSchools(query),
    );
  }

  String _messageForSearchFailure(SchoolSearchFailure failure) {
    switch (failure.type) {
      case SchoolSearchFailureType.notConfigured:
        return '학교 검색을 사용하려면 NEIS API 키를 설정해 주세요.';
      case SchoolSearchFailureType.network:
        return '연결을 확인한 뒤 다시 검색해 주세요.';
      case SchoolSearchFailureType.invalidResponse:
        return '학교 정보를 읽지 못했어요. 다시 시도해 주세요.';
      case SchoolSearchFailureType.api:
        return '학교 검색을 잠시 사용할 수 없어요. 다시 시도해 주세요.';
    }
  }

  void _selectSchool(SchoolSearchResult school) {
    setState(() {
      _selectedSchool = school;
      _step = _OnboardingStep.classInfo;
      _saveError = null;
    });
  }

  Future<void> _saveProfile() async {
    final school = _selectedSchool;
    final grade = _selectedGrade;
    final classNumber = _selectedClassNumber;
    if (school == null || grade == null || classNumber == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.profileRepository.saveProfile(
        SchoolProfile(
          schoolName: school.name,
          schoolId: school.schoolId,
          region: school.region,
          grade: grade,
          classNumber: classNumber,
          educationOfficeCode: school.educationOfficeCode,
          standardSchoolCode: school.standardSchoolCode,
        ),
      );
      if (mounted) widget.onProfileSaved();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveError = '설정을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _OnboardingStep.classInfo) {
      return _ClassInfoStep(
        school: _selectedSchool!,
        selectedGrade: _selectedGrade,
        selectedClassNumber: _selectedClassNumber,
        isSaving: _isSaving,
        errorMessage: _saveError,
        onBack: () => setState(() => _step = _OnboardingStep.school),
        onGradeSelected: (grade) {
          setState(() => _selectedGrade = grade);
        },
        onClassSelected: (classNumber) {
          setState(() => _selectedClassNumber = classNumber);
        },
        onSave: _saveProfile,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _SchoolStep(
          isSearching: _isSearching,
          isLoading: _isLoadingSchools,
          schools: _schools,
          errorMessage: _schoolLoadError,
          searchController: _searchController,
          onSearchModeChanged: (isSearching) {
            _searchDebounce?.cancel();
            setState(() {
              _isSearching = isSearching;
              _schools = const [];
              _schoolLoadError = null;
              _isLoadingSchools = false;
              _searchQuery = '';
            });
            _searchController.clear();
            if (!isSearching) _loadNearbySchools();
          },
          onQueryChanged: _queueSearch,
          onSchoolSelected: _selectSchool,
          onRetry: () => _searchSchools(_searchQuery),
        ),
      ),
    );
  }
}

class _SchoolStep extends StatelessWidget {
  const _SchoolStep({
    required this.isSearching,
    required this.isLoading,
    required this.schools,
    required this.errorMessage,
    required this.searchController,
    required this.onSearchModeChanged,
    required this.onQueryChanged,
    required this.onSchoolSelected,
    required this.onRetry,
  });

  final bool isSearching;
  final bool isLoading;
  final List<SchoolSearchResult> schools;
  final String? errorMessage;
  final TextEditingController searchController;
  final ValueChanged<bool> onSearchModeChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SchoolSearchResult> onSchoolSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final title = isSearching ? '학교를 검색하세요' : '학교를 선택하세요';
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        36,
        AppSpacing.page,
        AppSpacing.large,
      ),
      children: [
        Text(title, style: AppTextStyles.appTitle.copyWith(fontSize: 30)),
        const SizedBox(height: 8),
        Text(
          isSearching ? '학교 이름 일부만 입력해도 찾을 수 있어요.' : '가까운 학교를 바로 찾아드릴게요.',
          style: AppTextStyles.caption.copyWith(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.large),
        if (isSearching)
          TextField(
            controller: searchController,
            autofocus: true,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: '학교 이름 입력',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  searchController.clear();
                  onSearchModeChanged(false);
                },
              ),
              filled: true,
              fillColor: AppColors.skySoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          )
        else
          const _LocationHint(),
        if (!isSearching)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onSearchModeChanged(true),
              icon: const Icon(Icons.search_rounded),
              label: const Text('다른 학교 찾기'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.skyDark,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.large),
        Text(
          isSearching ? '검색 결과' : '현재 위치 근처',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorMessage != null)
          _EmptySchoolState(message: errorMessage!, onRetry: onRetry)
        else if (schools.isEmpty)
          const _EmptySchoolState(message: '검색 결과가 없어요. 다른 이름으로 찾아보세요.')
        else
          ...schools.map(
            (school) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SchoolSelectionCard(
                school: school,
                onTap: () => onSchoolSelected(school),
              ),
            ),
          ),
      ],
    );
  }
}

class _LocationHint extends StatelessWidget {
  const _LocationHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyPale,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on_outlined, color: AppColors.skyDark),
          SizedBox(width: 10),
          Expanded(
            child: Text('위치는 학교를 찾는 데만 사용돼요.', style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _EmptySchoolState extends StatelessWidget {
  const _EmptySchoolState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _ClassInfoStep extends StatelessWidget {
  const _ClassInfoStep({
    required this.school,
    required this.selectedGrade,
    required this.selectedClassNumber,
    required this.isSaving,
    required this.errorMessage,
    required this.onBack,
    required this.onGradeSelected,
    required this.onClassSelected,
    required this.onSave,
  });

  final SchoolSearchResult school;
  final int? selectedGrade;
  final int? selectedClassNumber;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onBack;
  final ValueChanged<int> onGradeSelected;
  final ValueChanged<int> onClassSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final canSave = selectedGrade != null && selectedClassNumber != null;
    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: FilledButton(
          onPressed: canSave && !isSaving ? onSave : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.sky,
            disabledBackgroundColor: AppColors.line,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('설정 완료'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          16,
          AppSpacing.page,
          AppSpacing.large,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '학년과 반을 알려주세요',
            style: AppTextStyles.appTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 8),
          Text(
            '시간표를 정확히 보여드릴게요.',
            style: AppTextStyles.caption.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.large),
          SchoolSelectionCard(school: school, onTap: null, selected: true),
          const SizedBox(height: AppSpacing.section),
          const Text('몇 학년인가요?', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(3, (index) {
              final grade = index + 1;
              return ChoiceSelectionCard(
                label: '$grade학년',
                selected: selectedGrade == grade,
                onTap: () => onGradeSelected(grade),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          const Text('몇 반인가요?', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: selectedClassNumber,
            isExpanded: true,
            hint: const Text('반을 선택하세요'),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.skySoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
            items: List.generate(
              20,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}반'),
              ),
            ),
            onChanged: (classNumber) {
              if (classNumber != null) onClassSelected(classNumber);
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.medium),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}
