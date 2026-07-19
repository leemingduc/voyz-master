// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'AIVIVU - AI 여행 어드바이저';

  @override
  String get appName => 'AIVIVU';

  @override
  String get aiPowered => 'AI 기반 여행';

  @override
  String get appVersion => '버전 1.0.0';

  @override
  String get profile => '프로필';

  @override
  String get language => '언어';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get korean => '한국어';

  @override
  String get signIn => '로그인';

  @override
  String get languageSaved => '언어가 저장되었습니다';

  @override
  String get genericError => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get home => 'AI 플래너';

  @override
  String get explore => '탐색';

  @override
  String get savedTrips => '저장됨';

  @override
  String get signOut => '로그아웃';

  @override
  String get loading => '로딩 중...';

  @override
  String get back => '뒤로';

  @override
  String get smartPlanner => '스마트 플래너';

  @override
  String get welcomeBack => '다시 오셨군요';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get username => '사용자 이름';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get login => '로그인';

  @override
  String get register => '회원가입';

  @override
  String get haveAccountLogin => '이미 계정이 있으신가요? 로그인';

  @override
  String get needAccountRegister => '계정이 없으신가요? 회원가입';

  @override
  String get emailPasswordRequired => '이메일과 6자 이상의 비밀번호를 입력하세요.';

  @override
  String get usernameRequired => '사용자 이름을 입력해 주세요.';

  @override
  String get passwordMismatch => '비밀번호 확인이 일치하지 않습니다.';

  @override
  String get accountCreated => '계정이 생성되었습니다. 이메일을 확인하거나 로그인하여 계속하세요.';

  @override
  String get accountCreationFailed => '계정을 만들 수 없습니다. 다시 시도해 주세요.';

  @override
  String get userProfile => '사용자 프로필';

  @override
  String get profileSubtitle => '아바타와 이메일은 로그인할 때마다 유지됩니다.';

  @override
  String get uploadPhoto => '사진 업로드';

  @override
  String get zoom => '확대/축소';

  @override
  String get horizontal => '가로';

  @override
  String get vertical => '세로';

  @override
  String get reset => '초기화';

  @override
  String get saving => '저장 중…';

  @override
  String get avatarSaved => '아바타가 저장되었습니다.';

  @override
  String get avatarStorageNote =>
      '이미지는 Supabase Storage 버킷 \'avatars\'에 저장되며 URL은 사용자 메타데이터에 기록됩니다.';

  @override
  String get avatarUploadWebOnly => '아바타 업로드는 현재 웹에서만 사용할 수 있습니다.';

  @override
  String get avatarEditingWebOnly => '아바타 편집은 현재 웹에서만 사용할 수 있습니다.';

  @override
  String get displayName => '표시 이름';

  @override
  String get noDisplayName => '표시 이름이 없습니다';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get passwordMinLength => '새 비밀번호는 6자 이상이어야 합니다.';

  @override
  String get passwordUpdated => '비밀번호가 업데이트되었습니다.';

  @override
  String get updating => '업데이트 중…';

  @override
  String get update => '업데이트';

  @override
  String get requiredInfo => '필수 정보';

  @override
  String get optionalInfo => '선택 정보';

  @override
  String get destination => '목적지';

  @override
  String get destinationHint => '예: 푸꾸옥, 파리, 발리...';

  @override
  String get departDate => '출발일';

  @override
  String get returnDate => '귀국일';

  @override
  String get addDate => '날짜 추가';

  @override
  String get budget => '예산';

  @override
  String get budgetHint => '예: 5000000';

  @override
  String get currency => '통화';

  @override
  String get participants => '참가자';

  @override
  String get participantsHint => '예: 성인 2명';

  @override
  String get ageRange => '연령대';

  @override
  String get ageRangeHint => '예: 25-35';

  @override
  String get interests => '관심사';

  @override
  String get additionalNotes => '추가 메모';

  @override
  String get notesHint => '특별 요청, 접근성 필요 사항...';

  @override
  String get aiPrompt => '꿈의 여행을 설명하세요';

  @override
  String get aiPromptHint => '원하는 여행에 대해 AI에게 알려주세요...';

  @override
  String get getAiSuggestions => 'AI 추천 받기';

  @override
  String get fillAllRequired => '필수 정보를 모두 입력해 주세요';

  @override
  String get trendingDestinations => '인기 여행지';

  @override
  String get aiInsight => 'AI 인사이트';

  @override
  String get topMatch => '최고 매칭';

  @override
  String get match => '매칭';

  @override
  String get refresh => '새로고침';

  @override
  String get retry => '다시 시도';

  @override
  String get noSavedItems => '저장된 항목이 없습니다';

  @override
  String get noSavedItemsHint => '좋아하는 여행지를 저장하면 여기에 표시됩니다.';

  @override
  String get savedItemRemoved => '저장된 항목에서 제거되었습니다';

  @override
  String get saveTrip => '여행 저장';

  @override
  String get tripAlreadySaved => '이미 저장됨';

  @override
  String get tripSaved => '여행이 저장되었습니다!';

  @override
  String get viewItinerary => '일정 보기';

  @override
  String get shareLinkCopied => '공유 링크가 복사되었습니다!';

  @override
  String get budgetBreakdown => '예산 내역';

  @override
  String get totalBudget => '총 예산';

  @override
  String get weather => '날씨';

  @override
  String get dates => '날짜';

  @override
  String get proTip => '전문가 팁';

  @override
  String get itinerary => '여행 일정';

  @override
  String get day => '일';

  @override
  String get generatingItinerary => '일정을 생성하고 있습니다…';

  @override
  String get aiSuggestions => 'AI 추천';

  @override
  String get loadingSuggestions => '최적의 여행지를 찾고 있습니다…';

  @override
  String get noSuggestions => '추천을 찾을 수 없습니다';

  @override
  String get optional => '(선택사항)';

  @override
  String get plannerGreeting => '어디로 가고\n싶으신가요? 🌍';

  @override
  String get exploreTitle => '탐색';

  @override
  String get exploreSubtitle => '인기 여행지';

  @override
  String get loadingExplore => '흥미로운 여행지를 찾고 있습니다...';

  @override
  String get cannotLoadData => '데이터를 로드할 수 없습니다';

  @override
  String get noData => '데이터 없음';

  @override
  String get travelSuggestions => '여행 추천';

  @override
  String get loadingSuggestionsDetail => 'AI가 여행지를 검색하고 있습니다...';

  @override
  String get cannotLoadSuggestions => '추천을 로드할 수 없습니다';

  @override
  String get noSuggestionsFound => '추천을 찾을 수 없습니다.';

  @override
  String get saved => '저장됨';

  @override
  String get savedTrip => '저장된 여행';

  @override
  String get wishlist => '위시리스트';

  @override
  String get reviewsCount => '리뷰';

  @override
  String get removed => '제거됨';

  @override
  String get emptySavedHint => '여행지를 탐색하고 저장하면\n여기에 표시됩니다.';

  @override
  String get noSavedYet => '저장된 항목이 없습니다';

  @override
  String get loadingDetail => '세부 정보를 로드하고 있습니다...';

  @override
  String get cannotLoadDetail => '정보를 로드할 수 없습니다';

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get goBack => '돌아가기';

  @override
  String get tripInfoSaved => '여행 정보가 저장되었습니다! 저장된 탭을 확인하세요.';

  @override
  String alreadySavedMessage(String name) {
    return '$name은(는) 이미 저장되어 있습니다!';
  }

  @override
  String get loadingItinerary => 'AI가 일정을 계획하고 있습니다...';

  @override
  String get cannotCreateItinerary => '일정을 생성할 수 없습니다';

  @override
  String get share => '공유';

  @override
  String dayLabel(int n) {
    return '$n일차';
  }

  @override
  String get generateAiItinerary => 'AI 일정 생성';

  @override
  String get saveInfo => '정보 저장';

  @override
  String get remove => '삭제';

  @override
  String get estimatedBudget => '예상 예산';

  @override
  String get bookNow => '지금 예약';

  @override
  String get addToWishlist => '위시리스트에 추가';

  @override
  String get addedToWishlist => '위시리스트에 추가됨!';

  @override
  String get alreadySaved => '이미 저장되어 있습니다!';

  @override
  String get hot => '인기';

  @override
  String get perPerson => '/ 인당';

  @override
  String get aiInsightPrefix => '💡 AI 인사이트: ';

  @override
  String get defaultAiInsight => '웰니스 예산에 완벽합니다. 현재 건기입니다.';

  @override
  String get vnd => 'VNĐ';

  @override
  String get loginRequired => '로그인이 필요합니다.';

  @override
  String get noAiResponse => 'AI로부터 응답을 받지 못했습니다.';

  @override
  String get apiKeyNotSet => 'GEMINI_API_KEY가 설정되지 않았습니다. .env 파일에 키를 추가해 주세요.';

  @override
  String get invalidLoginCredentials => '잘못된 로그인 정보입니다. 이메일과 비밀번호를 확인해 주세요.';

  @override
  String get emailNotConfirmed => '이메일이 확인되지 않았습니다. 받은 편지함을 확인해 주세요.';

  @override
  String get userAlreadyExists => '이미 존재하는 사용자입니다. 로그인해 주세요.';

  @override
  String get beach => '해변';

  @override
  String get adventure => '모험';

  @override
  String get culture => '문화';

  @override
  String get food => '음식';

  @override
  String get wellness => '웰니스';
}
