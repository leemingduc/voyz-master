// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'AIVIVU - Cố vấn du lịch AI';

  @override
  String get appName => 'AIVIVU';

  @override
  String get aiPowered => 'DU LỊCH ĐƯỢC HỖ TRỢ AI';

  @override
  String get appVersion => 'PHIÊN BẢN 1.0.0';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get korean => '한국어';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get languageSaved => 'Đã lưu ngôn ngữ';

  @override
  String get genericError => 'Đã có lỗi xảy ra. Vui lòng thử lại.';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get home => 'Lập KH AI';

  @override
  String get explore => 'Khám phá';

  @override
  String get savedTrips => 'Đã lưu';

  @override
  String get friends => 'Bạn bè';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get loading => 'Đang tải...';

  @override
  String get back => 'Quay lại';

  @override
  String get smartPlanner => 'Lập kế hoạch thông minh';

  @override
  String get welcomeBack => 'Chào mừng trở lại';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get username => 'Tên người dùng';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get login => 'Đăng nhập';

  @override
  String get register => 'Đăng ký';

  @override
  String get haveAccountLogin => 'Đã có tài khoản? Đăng nhập';

  @override
  String get needAccountRegister => 'Chưa có tài khoản? Đăng ký';

  @override
  String get emailPasswordRequired => 'Nhập email và mật khẩu ít nhất 6 ký tự.';

  @override
  String get usernameRequired => 'Vui lòng nhập tên người dùng.';

  @override
  String get passwordMismatch => 'Xác nhận mật khẩu không khớp.';

  @override
  String get accountCreated =>
      'Tài khoản đã được tạo. Vui lòng kiểm tra email hoặc đăng nhập để tiếp tục.';

  @override
  String get accountCreationFailed =>
      'Không thể tạo tài khoản. Vui lòng thử lại.';

  @override
  String get userProfile => 'Hồ sơ người dùng';

  @override
  String get profileSubtitle =>
      'Ảnh đại diện và email được lưu giữ sau mỗi lần đăng nhập.';

  @override
  String get uploadPhoto => 'Tải ảnh lên';

  @override
  String get zoom => 'Thu phóng';

  @override
  String get horizontal => 'Ngang';

  @override
  String get vertical => 'Dọc';

  @override
  String get reset => 'Đặt lại';

  @override
  String get saving => 'Đang lưu…';

  @override
  String get avatarSaved => 'Đã lưu ảnh đại diện.';

  @override
  String get avatarStorageNote =>
      'Ảnh được lưu trong Supabase Storage bucket \'avatars\' và URL được ghi vào metadata người dùng.';

  @override
  String get avatarUploadWebOnly =>
      'Tải ảnh đại diện hiện chỉ khả dụng trên web.';

  @override
  String get avatarEditingWebOnly =>
      'Chỉnh sửa ảnh đại diện hiện chỉ khả dụng trên web.';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get noDisplayName => 'Chưa có tên hiển thị';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get passwordMinLength => 'Mật khẩu mới cần ít nhất 6 ký tự.';

  @override
  String get passwordUpdated => 'Đã cập nhật mật khẩu.';

  @override
  String get updating => 'Đang cập nhật…';

  @override
  String get update => 'Cập nhật';

  @override
  String get destination => 'Điểm đến';

  @override
  String get addDate => 'Thêm ngày';

  @override
  String get budget => 'Ngân sách';

  @override
  String get budgetHint => 'vd. 5000000';

  @override
  String get budgetTier => 'Phân khúc ngân sách';

  @override
  String get budgetTierEconomy => 'Bình dân';

  @override
  String get budgetTierModerate => 'Trung bình';

  @override
  String get budgetTierPremium => 'Cao cấp';

  @override
  String get budgetTierLuxury => 'Hạng sang';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get participants => 'Số người';

  @override
  String get interests => 'Sở thích';

  @override
  String get aiPrompt => 'Mô tả chuyến đi trong mơ';

  @override
  String get aiPromptHint => 'Hãy nói với AI về chuyến đi bạn muốn...';

  @override
  String get getAiSuggestions => 'Nhận gợi ý AI';

  @override
  String get analyzingTrip => 'Đang phân tích...';

  @override
  String get describeTripRequired => 'Hãy mô tả chuyến đi của bạn trước';

  @override
  String get trendingDestinations => 'Điểm đến thịnh hành';

  @override
  String get aiInsight => 'Nhận xét AI';

  @override
  String get topMatch => 'PHÙ HỢP NHẤT';

  @override
  String get match => 'phù hợp';

  @override
  String get refresh => 'Làm mới';

  @override
  String get retry => 'Thử lại';

  @override
  String get noSavedItems => 'Chưa có mục đã lưu';

  @override
  String get noSavedItemsHint =>
      'Lưu các điểm đến bạn yêu thích và chúng sẽ xuất hiện tại đây.';

  @override
  String get savedItemRemoved => 'Đã xóa khỏi mục đã lưu';

  @override
  String get saveTrip => 'Lưu chuyến đi';

  @override
  String get tripAlreadySaved => 'Đã lưu trước đó';

  @override
  String get tripSaved => 'Đã lưu chuyến đi!';

  @override
  String get viewItinerary => 'Xem lịch trình';

  @override
  String get shareLinkCopied => 'Đã sao chép liên kết chia sẻ!';

  @override
  String get budgetBreakdown => 'Chi tiết ngân sách';

  @override
  String get totalBudget => 'Tổng ngân sách';

  @override
  String get weather => 'Thời tiết';

  @override
  String get dates => 'Ngày';

  @override
  String get proTip => 'Mẹo hay';

  @override
  String get itinerary => 'Lịch trình';

  @override
  String get day => 'Ngày';

  @override
  String get generatingItinerary => 'Đang tạo lịch trình của bạn…';

  @override
  String get aiSuggestions => 'Gợi ý AI';

  @override
  String get loadingSuggestions => 'Đang tìm điểm đến phù hợp nhất cho bạn…';

  @override
  String get noSuggestions => 'Không tìm thấy gợi ý';

  @override
  String get plannerGreeting => 'Bạn muốn\nđi đến đâu? 🌍';

  @override
  String get exploreTitle => 'Khám phá';

  @override
  String get exploreSubtitle => 'Điểm đến đang thịnh hành';

  @override
  String get loadingExplore => 'Đang tìm điểm đến thú vị...';

  @override
  String get cannotLoadData => 'Không thể tải dữ liệu';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get saved => 'Đã lưu';

  @override
  String get savedTrip => 'Chuyến đi đã lưu';

  @override
  String get wishlist => 'Yêu thích';

  @override
  String get removed => 'đã xóa';

  @override
  String get emptySavedHint =>
      'Khám phá các điểm đến và lưu chúng\nđể xem tại đây.';

  @override
  String get noSavedYet => 'Chưa có mục nào được lưu';

  @override
  String get loadingDetail => 'Đang tải thông tin chi tiết...';

  @override
  String get cannotLoadDetail => 'Không thể tải thông tin';

  @override
  String get unknownError => 'Lỗi không xác định';

  @override
  String get goBack => 'Quay lại';

  @override
  String get tripInfoSaved =>
      'Đã lưu thông tin chuyến đi! Kiểm tra tab Đã lưu.';

  @override
  String alreadySavedMessage(String name) {
    return '$name đã được lưu trước đó!';
  }

  @override
  String get loadingItinerary => 'AI đang lên lịch trình...';

  @override
  String get cannotCreateItinerary => 'Không thể tạo lịch trình';

  @override
  String get share => 'Chia sẻ';

  @override
  String dayLabel(int n) {
    return 'Ngày $n';
  }

  @override
  String get generateAiItinerary => 'Tạo lịch trình AI';

  @override
  String get saveInfo => 'Lưu thông tin';

  @override
  String get remove => 'Xóa';

  @override
  String get estimatedBudget => 'NGÂN SÁCH DỰ KIẾN';

  @override
  String get bookNow => 'Đặt ngay';

  @override
  String get hot => 'HOT';

  @override
  String get perPerson => '/ người';

  @override
  String get aiInsightPrefix => '💡 Thông tin AI: ';

  @override
  String get defaultAiInsight =>
      'Phù hợp với ngân sách chăm sóc sức khỏe của bạn. Hiện đang mùa khô.';

  @override
  String get vnd => 'VNĐ';

  @override
  String get loginRequired => 'Bạn cần đăng nhập.';

  @override
  String get noAiResponse => 'Không nhận được phản hồi từ AI.';

  @override
  String get apiKeyNotSet =>
      'GEMINI_API_KEY chưa được thiết lập. Vui lòng thêm khóa vào file .env.';

  @override
  String get invalidLoginCredentials =>
      'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra email và mật khẩu.';

  @override
  String get emailNotConfirmed =>
      'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư đến.';

  @override
  String get userAlreadyExists => 'Người dùng đã tồn tại. Vui lòng đăng nhập.';

  @override
  String get beach => 'Biển';

  @override
  String get adventure => 'Phiêu lưu';

  @override
  String get culture => 'Văn hóa';

  @override
  String get food => 'Ẩm thực';

  @override
  String get wellness => 'Chăm sóc sức khỏe';

  @override
  String get phoneNumber => 'Số điện thoại';

  @override
  String get phoneHint => '+84 912 345 678';

  @override
  String get phoneInvalidChars =>
      'Số điện thoại chỉ gồm số, khoảng trắng, +, -, (, ).';

  @override
  String get phoneMinDigits => 'Số điện thoại cần ít nhất 8 chữ số.';

  @override
  String get contactInfoSaved => 'Thông tin liên hệ đã được lưu.';

  @override
  String get saveContactInfo => 'Lưu thông tin';

  @override
  String get savingContactInfo => 'Đang lưu…';

  @override
  String get culturalTips => 'Mẹo văn hóa';

  @override
  String get culturalDos => 'Nên làm';

  @override
  String get culturalDonts => 'Không nên làm';

  @override
  String get basicPhrases => 'Cụm từ cơ bản';

  @override
  String get diningEtiquette => 'Phép tắc ăn uống';

  @override
  String get sacredSites => 'Địa điểm linh thiêng';

  @override
  String get loadingCulturalTips => 'Đang tải mẹo văn hóa...';

  @override
  String get cannotLoadCulturalTips => 'Không thể tải mẹo văn hóa';

  @override
  String get culturalTipsButton => '🎭 Mẹo văn hóa';

  @override
  String get chatTitle => 'Chat AI Du Lịch';

  @override
  String get chatWelcome =>
      'Xin chào! Tôi là trợ lý du lịch AI. Hãy hỏi tôi về điểm đến, mẹo du lịch hoặc lên kế hoạch cho chuyến đi tiếp theo của bạn! 🌍';

  @override
  String get chatCleared =>
      'Cuộc trò chuyện đã xóa. Tôi có thể giúp gì cho bạn?';

  @override
  String get chatAiReply => 'AI đang nhập...';

  @override
  String get chatInputHint => 'Hỏi tôi về bất kỳ điểm đến nào...';

  @override
  String get compareTitle => 'So sánh điểm đến';

  @override
  String get compareInputHeader => 'Nhập các điểm đến để so sánh';

  @override
  String get compareDest1Hint => 'VD: Phú Quốc';

  @override
  String get compareDest2Hint => 'VD: Đà Nẵng';

  @override
  String get compareDest3Hint => 'VD: Hội An (tùy chọn)';

  @override
  String get compareLoading => 'Đang so sánh...';

  @override
  String get compareButton => 'So sánh điểm đến';

  @override
  String get compareMinError => 'Vui lòng nhập ít nhất 2 điểm đến.';

  @override
  String get compareRecommendation => 'Đề xuất từ AI';

  @override
  String get compareDetail => 'Chi tiết so sánh';

  @override
  String get comparePros => 'Ưu điểm';

  @override
  String get compareCons => 'Nhược điểm';

  @override
  String get bestTimeTitle => 'Thời điểm tốt nhất để du lịch';

  @override
  String get bestTimeInputHeader => 'Tìm thời điểm tốt nhất để đến';

  @override
  String get bestTimeHint => 'VD: Bali, Tokyo, Paris...';

  @override
  String get bestTimeLoading => 'Đang phân tích...';

  @override
  String get bestTimeButton => 'Tìm thời điểm tốt nhất';

  @override
  String get bestTimeMinError => 'Vui lòng nhập điểm đến.';

  @override
  String bestTimeBestMonth(String month) {
    return 'Tháng tốt nhất: $month';
  }

  @override
  String get bestTimeSeasons => 'Các mùa';

  @override
  String get aiQuotaExceeded =>
      'AI đã hết lượt miễn phí (quota Gemini). Đợi khoảng 1 phút rồi thử lại, hoặc đổi Mô hình AI trong Hồ sơ.';

  @override
  String get aiKeyInvalid =>
      'Khoá Gemini API không hợp lệ hoặc đã bị Google khoá. Cần thay khoá mới.';

  @override
  String get aiServerBusy =>
      'Máy chủ AI đang quá tải hoặc gặp sự cố. Vui lòng thử lại sau ít phút.';

  @override
  String get aiInvalidResponse =>
      'AI trả về dữ liệu sai định dạng. Vui lòng thử lại.';

  @override
  String get networkError =>
      'Không có kết nối mạng. Kiểm tra Internet rồi thử lại.';

  @override
  String get bestTimeMonthly => 'Tổng quan theo tháng';

  @override
  String get bestTimeTips => 'Mẹo du lịch';

  @override
  String get aiToolsTitle => 'Công cụ AI Du lịch';

  @override
  String get aiToolsSubtitle =>
      'Khám phá các công cụ AI mạnh mẽ để lên kế hoạch cho chuyến đi hoàn hảo';

  @override
  String get aiChatbotTitle => 'AI Chatbot';

  @override
  String get aiChatbotSubtitle => 'Trò chuyện với AI';

  @override
  String get aiChatbotDesc =>
      'Đặt bất kỳ câu hỏi du lịch nào và nhận câu trả lời AI ngay lập tức về điểm đến, mẹo và nhiều hơn nữa.';

  @override
  String get aiCompareTitle => 'So sánh điểm đến';

  @override
  String get aiCompareSubtitle => 'So sánh song song';

  @override
  String get aiCompareDesc =>
      'So sánh 2-3 điểm đến về chi phí, thời tiết, hoạt động và nhiều hơn để tìm điểm đến hoàn hảo.';

  @override
  String get aiBestTimeTitle => 'Thời điểm tốt nhất';

  @override
  String get aiBestTimeSubtitle => 'Phân tích theo mùa';

  @override
  String get aiBestTimeDesc =>
      'Tìm tháng lý tưởng để đến bất kỳ điểm đến nào dựa trên thời tiết, lượng khách và sự kiện địa phương.';

  @override
  String get contextBestTime => 'Khi nào nên đi?';

  @override
  String get contextAskAboutDestination => 'Hỏi AI về nơi này';

  @override
  String get refineForBudget => 'Hoạt động nhiều hơn (Tối ưu ngân sách)';

  @override
  String get refineForFamily => 'Phù hợp trẻ em/người lớn tuổi';

  @override
  String get refineLessTravel => 'Ít di chuyển hơn';

  @override
  String get currencySelectorTitle => 'Tiền tệ hiển thị';

  @override
  String get currencySelectorDescription =>
      'Giá trong Voyz được quy đổi theo tỉ giá tham chiếu mới nhất.';

  @override
  String get currencyVietnameseDong => 'Đồng Việt Nam';

  @override
  String get currencyUsDollar => 'Đô la Mỹ';

  @override
  String get currencyEuro => 'Euro';

  @override
  String get currencyKoreanWon => 'Won Hàn Quốc';

  @override
  String get currencyJapaneseYen => 'Yên Nhật';

  @override
  String get currencyThaiBaht => 'Baht Thái';

  @override
  String get currencyBritishPound => 'Bảng Anh';

  @override
  String get currencyAustralianDollar => 'Đô la Úc';

  @override
  String get currencySingaporeDollar => 'Đô la Singapore';

  @override
  String get currencyCanadianDollar => 'Đô la Canada';

  @override
  String get aiModel => 'Mô hình AI';

  @override
  String get aiModelDescription =>
      'Mô hình Gemini trả lời các câu hỏi du lịch của bạn. Mô hình lớn hơn suy nghĩ lâu hơn và có thể hết hạn mức miễn phí sớm hơn.';

  @override
  String get aiModelSaved => 'Đã lưu mô hình AI';

  @override
  String get quickPromptsLabel => 'Gợi ý nhanh:';

  @override
  String get quickPromptTokyo => 'Tokyo mùa hoa anh đào';

  @override
  String get quickPromptDaLat => 'Đà Lạt 3 ngày 2 đêm';

  @override
  String get quickPromptBali => 'Bali nghỉ dưỡng';

  @override
  String get quickPromptPhuQuoc => 'Phú Quốc ngắm hoàng hôn';

  @override
  String get suggestNow => 'Gợi ý luôn';

  @override
  String get plannerChatHint => 'Nhắn thêm cho AI...';

  @override
  String get plannerSend => 'Gửi';

  @override
  String get newPlannerChat => 'Cuộc trò chuyện mới';

  @override
  String get plannerConversationHistory => 'Lịch sử hội thoại';

  @override
  String get plannerSuggestionHistory => 'Lịch sử gợi ý';

  @override
  String get noPlannerConversations => 'Chưa có hội thoại đã lưu';

  @override
  String get messagesLabel => 'tin nhắn';

  @override
  String get deletePlannerConversation => 'Xóa hội thoại';

  @override
  String get savePlannerConversation => 'Lưu hội thoại';

  @override
  String get plannerConversationSaved => 'Đã lưu hội thoại';

  @override
  String get aiEstimateLabel => 'Ước tính AI';

  @override
  String get viewDetails => 'Xem chi tiết';

  @override
  String get friendsTitle => 'Bạn bè';

  @override
  String get friendRequests => 'Lời mời';

  @override
  String get noFriendsYet => 'Chưa có bạn bè';

  @override
  String get noFriendsYetHint =>
      'Tìm bằng email hoặc tên hiển thị để thêm bạn.';

  @override
  String get noPendingRequests => 'Chưa có lời mời kết bạn';

  @override
  String get noPendingRequestsHint => 'Lời mời đến và đi sẽ hiển thị ở đây.';

  @override
  String get findFriends => 'Tìm bạn bè';

  @override
  String get friendSearchHint => 'Email hoặc tên hiển thị';

  @override
  String get addFriend => 'Thêm bạn';

  @override
  String get friendStatus => 'Đã là bạn bè';

  @override
  String get accept => 'Chấp nhận';

  @override
  String get wantsToConnect => 'Muốn kết bạn';

  @override
  String get friendRequestSent => 'Đã gửi lời mời';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get removeFriendTitle => 'Xóa bạn bè?';

  @override
  String removeFriendMessage(String name) {
    return 'Bạn sẽ xóa $name khỏi danh sách bạn bè. Cuộc trò chuyện của hai người cũng sẽ bị xóa.';
  }

  @override
  String get removeFriend => 'Xóa bạn';

  @override
  String get typing => 'Đang nhập...';

  @override
  String get messageInputHint => 'Viết tin nhắn...';

  @override
  String get messageOptions => 'Tùy chọn tin nhắn';

  @override
  String get cancelReply => 'Hủy trả lời';

  @override
  String replyingTo(String name) {
    return 'Trả lời $name';
  }

  @override
  String chatWith(String name) {
    return 'Trò chuyện với $name';
  }

  @override
  String get noMessagesYet => 'Chưa có tin nhắn. Hãy gửi lời chào để bắt đầu!';

  @override
  String get sayHi => 'Chào bạn';

  @override
  String get planTrip => 'Lên kế hoạch chuyến đi';

  @override
  String get howAreYou => 'Bạn khỏe không?';

  @override
  String get quickHiMessage => 'Chào bạn!';

  @override
  String get quickTripMessage => 'Cùng lên kế hoạch du lịch nhé?';

  @override
  String get quickHowAreYouMessage => 'Hôm nay bạn thế nào?';

  @override
  String get reviewSaved => 'Đã lưu đánh giá';

  @override
  String get communityReviews => 'Đánh giá cộng đồng';

  @override
  String get reviewHint => 'Chia sẻ một mẹo nhanh cho những người du lịch khác';

  @override
  String get postReview => 'Đăng đánh giá';

  @override
  String get randomDestination => 'Khám phá ngẫu nhiên địa điểm mới';

  @override
  String get shareDestination => 'Chia sẻ địa điểm';

  @override
  String get shareNoteHint => 'Thêm lời nhắn...';

  @override
  String get selectFriends => 'Chọn bạn bè trong ứng dụng:';

  @override
  String get noConnectedFriends =>
      'Bạn chưa có danh sách bạn bè kết nối trong ứng dụng.';

  @override
  String get copyLink => 'Sao chép liên kết';

  @override
  String get destinationLinkCopied => 'Đã sao chép liên kết địa điểm!';

  @override
  String shareDestinationSuccess(String name, int count) {
    return 'Đã chia sẻ \"$name\" cho $count người bạn!';
  }

  @override
  String sendFailed(String error) {
    return 'Lỗi khi gửi: $error';
  }

  @override
  String get tripWorkspace => 'Không gian chuyến đi';

  @override
  String workspaceSummary(int workspaceCount, int wishlistCount) {
    return '$workspaceCount không gian / $wishlistCount danh sách mong muốn';
  }

  @override
  String get unableToLoadSaved =>
      'Không thể tải địa điểm đã lưu. Vui lòng thử lại';

  @override
  String get aiMatch => 'Phù hợp với AI';

  @override
  String get costEstimate => 'Ước tính chi phí';

  @override
  String get reference => 'tham khảo';

  @override
  String get budgetTbd => 'Chưa có ngân sách';

  @override
  String get noNotes => 'Chưa có ghi chú';

  @override
  String get notesSaved => 'Đã lưu ghi chú';

  @override
  String get saveName => 'Lưu tên';

  @override
  String get uploadImageTab => 'Tải ảnh lên';

  @override
  String get presetAvatarTab => 'Avatar có sẵn';

  @override
  String get uploadFromDevice => 'Tải ảnh từ thiết bị';

  @override
  String get uploadImageHelp =>
      'Hỗ trợ JPG, PNG. Bạn có thể cắt và chỉnh sửa sau khi chọn.';

  @override
  String get chooseImage => 'Chọn ảnh';

  @override
  String get plannerAnalyzing =>
      'Đang phân tích sở thích và mong muốn của bạn...';

  @override
  String get plannerFinding =>
      'Đang khám phá và chọn lọc các điểm đến phù hợp nhất...';

  @override
  String get plannerCalculating =>
      'Đang tính toán lộ trình tối ưu và dự toán ngân sách...';

  @override
  String get plannerFinishing =>
      'Đang hoàn tất các phương án du lịch tuyệt vời...';

  @override
  String get flexibleDates => 'Ngày linh hoạt';

  @override
  String get itineraryReady => 'Đã có lịch trình';

  @override
  String get notes => 'Ghi chú';

  @override
  String get reply => 'Trả lời';

  @override
  String get copyMessage => 'Sao chép tin nhắn';

  @override
  String get messageCopied => 'Đã sao chép tin nhắn';

  @override
  String get deleteForMe => 'Xóa ở phía bạn';

  @override
  String get deleteForMeHint => 'Tin nhắn chỉ bị xóa trên thiết bị của bạn';

  @override
  String get recallForEveryone => 'Thu hồi cho cả hai bên';

  @override
  String get recallForEveryoneHint => 'Tin nhắn sẽ biến mất với cả hai người';

  @override
  String get messageNotifications => 'Thông báo tin nhắn';

  @override
  String get chatAppearance => 'Giao diện chat';

  @override
  String get clearConversation => 'Xóa toàn bộ cuộc trò chuyện';

  @override
  String get conversationCleared => 'Đã xóa cuộc trò chuyện ở phía bạn';

  @override
  String get messageRecalled => 'Đã thu hồi tin nhắn cho cả hai bên';

  @override
  String get emoji => 'Biểu cảm';

  @override
  String get changeDestination => 'Đổi địa điểm';

  @override
  String get compareOptions => 'So sánh các lựa chọn';

  @override
  String get activeNow => 'Đang hoạt động';

  @override
  String get inactive => 'Không hoạt động';

  @override
  String activeMinutesAgo(int count) {
    return 'Hoạt động $count phút trước';
  }

  @override
  String activeHoursAgo(int count) {
    return 'Hoạt động $count giờ trước';
  }

  @override
  String get activeYesterday => 'Hoạt động hôm qua';

  @override
  String activeDaysAgo(int count) {
    return 'Hoạt động $count ngày trước';
  }

  @override
  String activeOnDate(String date) {
    return 'Hoạt động $date';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get seen => 'Đã xem';

  @override
  String get delivered => 'Đã nhận';

  @override
  String get view => 'Xem';

  @override
  String get chatTheme => 'Giao diện chat';

  @override
  String get apply => 'Áp dụng';

  @override
  String get chooseTheme => 'Chọn giao diện';

  @override
  String get music => 'Nhạc nền';

  @override
  String get musicDescription => 'Bật hoặc tắt nhạc khi sử dụng ứng dụng';

  @override
  String get travelPreferences => 'Tùy chọn du lịch';

  @override
  String get preferredCurrency => 'Tiền tệ ưu tiên';

  @override
  String get travelStyles => 'Phong cách du lịch';

  @override
  String get savePreferences => 'Lưu tùy chọn';

  @override
  String get chooseAvatar => 'Chọn ảnh đại diện';

  @override
  String get destinationEstimate =>
      'Ước tính AI tại điểm đến · 1 người · không gồm vé/xe';

  @override
  String get iconicSights => 'THẮNG CẢNH BIỂU TƯỢNG & ẢNH THỰC TẾ';

  @override
  String get previewMessageOne => 'Chào! Bạn đang ở đâu vậy? 😊';

  @override
  String get previewMessageTwo => 'Mình đang ở Đà Nẵng nè ✈️ Tuyệt lắm!';

  @override
  String get previewMessageThree => 'Ôi hay quá! Mình muốn đến đó lắm 🌊';

  @override
  String get previewMessageFour => 'Cùng lên kế hoạch chuyến đi nhé!';

  @override
  String get criterion => 'Tiêu chí';

  @override
  String get sharedDestination => 'Địa điểm được chia sẻ';

  @override
  String get performAction => 'Thực hiện ngay';

  @override
  String get anonymousReviewer => 'Ẩn danh';

  @override
  String get noReviews => 'Chưa có đánh giá';

  @override
  String reviewCount(int count) {
    return '$count lượt đánh giá';
  }

  @override
  String get exploreCategoryRandom => '🎲 Ngẫu nhiên';

  @override
  String get exploreCategoryBeach => '🏖️ Biển đảo';

  @override
  String get exploreCategoryMountain => '🏔️ Vùng núi & Đèo';

  @override
  String get exploreCategoryHeritage => '🏯 Cổ kính & Di sản';

  @override
  String get exploreCategoryCity => '🏙️ Đô thị sôi động';

  @override
  String get exploreCategoryWellness => '🌿 Nghỉ dưỡng thiên nhiên';

  @override
  String get exploreCategoryHiddenGems => '💎 Độc lạ';

  @override
  String get nature => 'Thiên nhiên';

  @override
  String get luxury => 'Cao cấp';

  @override
  String get slowTravel => 'Du lịch chậm';

  @override
  String workspaceReady(int doneCount, int totalCount) {
    return 'Đã sẵn sàng $doneCount/$totalCount';
  }

  @override
  String tripDays(int n) {
    return '$n ngày';
  }

  @override
  String get themeAivivu => 'AIVIVU';

  @override
  String get themeTwilight => 'Chạng vạng';

  @override
  String get themeOcean => 'Đại dương';

  @override
  String get themeSakura => 'Hoa anh đào';

  @override
  String get themeForest => 'Rừng xanh';

  @override
  String get themeGolden => 'Giờ vàng';

  @override
  String get themeRoadGrip => 'Vệt bánh xe';

  @override
  String chatThemeChanged(String name, String theme) {
    return '$name đã đổi giao diện thành $theme';
  }

  @override
  String get budgetTransport => 'Di chuyển';

  @override
  String get budgetStay => 'Lưu trú';

  @override
  String get budgetFood => 'Ẩn uống';

  @override
  String get budgetActivities => 'Hoạt động';
}
