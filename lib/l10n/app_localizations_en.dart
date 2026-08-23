// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AIVIVU - AI Travel Advisor';

  @override
  String get appName => 'AIVIVU';

  @override
  String get aiPowered => 'AI POWERED TRAVEL';

  @override
  String get appVersion => 'VERSION 1.0.0';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get korean => '한국어';

  @override
  String get signIn => 'Sign in';

  @override
  String get languageSaved => 'Language saved';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get home => 'AI Planner';

  @override
  String get explore => 'Explore';

  @override
  String get savedTrips => 'Saved';

  @override
  String get signOut => 'Sign out';

  @override
  String get loading => 'Loading...';

  @override
  String get back => 'Back';

  @override
  String get smartPlanner => 'Smart Planner';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccount => 'Create your account';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get haveAccountLogin => 'Already have an account? Login';

  @override
  String get needAccountRegister => 'Need an account? Register';

  @override
  String get emailPasswordRequired =>
      'Enter an email and a password with at least 6 characters.';

  @override
  String get usernameRequired => 'Enter your username.';

  @override
  String get passwordMismatch => 'Password confirmation does not match.';

  @override
  String get accountCreated =>
      'Account created. Please check your email or login to continue.';

  @override
  String get accountCreationFailed =>
      'Could not create account. Please try again.';

  @override
  String get userProfile => 'User Profile';

  @override
  String get profileSubtitle =>
      'Avatar and email are retained after each login.';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get zoom => 'Zoom';

  @override
  String get horizontal => 'X';

  @override
  String get vertical => 'Y';

  @override
  String get reset => 'Reset';

  @override
  String get saving => 'Saving…';

  @override
  String get avatarSaved => 'Avatar saved.';

  @override
  String get avatarStorageNote =>
      'The image is stored in Supabase Storage bucket \'avatars\' and the URL is written to user metadata.';

  @override
  String get avatarUploadWebOnly =>
      'Avatar upload is currently available on web only.';

  @override
  String get avatarEditingWebOnly =>
      'Avatar editing is currently available on web only.';

  @override
  String get displayName => 'Display name';

  @override
  String get noDisplayName => 'No display name set';

  @override
  String get changePassword => 'Change password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordMinLength => 'New password must be at least 6 characters.';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get updating => 'Updating…';

  @override
  String get update => 'Update';

  @override
  String get requiredInfo => 'REQUIRED INFO';

  @override
  String get optionalInfo => 'OPTIONAL INFO';

  @override
  String get destination => 'Destination';

  @override
  String get destinationHint => 'e.g. Phu Quoc, Paris, Bali...';

  @override
  String get departDate => 'Departure';

  @override
  String get returnDate => 'Return';

  @override
  String get addDate => 'Add date';

  @override
  String get budget => 'Budget';

  @override
  String get budgetHint => 'e.g. 5000000';

  @override
  String get budgetTier => 'Budget Tier';

  @override
  String get budgetTierEconomy => 'Economy';

  @override
  String get budgetTierModerate => 'Moderate';

  @override
  String get budgetTierPremium => 'Premium';

  @override
  String get budgetTierLuxury => 'Luxury';

  @override
  String get currency => 'Currency';

  @override
  String get participants => 'Participants';

  @override
  String get participantsHint => 'e.g. 2 adults';

  @override
  String get ageRange => 'Age range';

  @override
  String get ageRangeHint => 'e.g. 25-35';

  @override
  String get interests => 'Interests';

  @override
  String get additionalNotes => 'Additional notes';

  @override
  String get notesHint => 'Any special requests, accessibility needs...';

  @override
  String get aiPrompt => 'Describe your dream trip';

  @override
  String get aiPromptHint => 'Tell AI what kind of trip you want...';

  @override
  String get getAiSuggestions => 'Get AI Suggestions';

  @override
  String get fillAllRequired => 'Please fill in all required info';

  @override
  String get trendingDestinations => 'Trending Destinations';

  @override
  String get aiInsight => 'AI Insight';

  @override
  String get topMatch => 'TOP MATCH';

  @override
  String get match => 'match';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get noSavedItems => 'No saved items yet';

  @override
  String get noSavedItemsHint =>
      'Save destinations you love and they\'ll appear here.';

  @override
  String get savedItemRemoved => 'Removed from saved';

  @override
  String get saveTrip => 'Save Trip';

  @override
  String get tripAlreadySaved => 'Already saved';

  @override
  String get tripSaved => 'Trip saved!';

  @override
  String get viewItinerary => 'View Itinerary';

  @override
  String get shareLinkCopied => 'Share link copied!';

  @override
  String get budgetBreakdown => 'Budget Breakdown';

  @override
  String get totalBudget => 'Total Budget';

  @override
  String get weather => 'Weather';

  @override
  String get dates => 'Dates';

  @override
  String get proTip => 'Pro Tip';

  @override
  String get itinerary => 'Itinerary';

  @override
  String get day => 'Day';

  @override
  String get generatingItinerary => 'Generating your itinerary…';

  @override
  String get aiSuggestions => 'AI Suggestions';

  @override
  String get loadingSuggestions => 'Finding best destinations for you…';

  @override
  String get noSuggestions => 'No suggestions found';

  @override
  String get optional => '(optional)';

  @override
  String get plannerGreeting => 'Where do you\nwant to go? 🌍';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSubtitle => 'Trending destinations';

  @override
  String get loadingExplore => 'Finding interesting destinations...';

  @override
  String get cannotLoadData => 'Cannot load data';

  @override
  String get noData => 'No data';

  @override
  String get travelSuggestions => 'Travel Suggestions';

  @override
  String get loadingSuggestionsDetail => 'AI is searching destinations...';

  @override
  String get cannotLoadSuggestions => 'Cannot load suggestions';

  @override
  String get noSuggestionsFound => 'No suggestions found.';

  @override
  String get saved => 'Saved';

  @override
  String get savedTrip => 'Saved Trip';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get reviewsCount => 'reviews';

  @override
  String get removed => 'removed';

  @override
  String get emptySavedHint =>
      'Explore destinations and save them\nto see them here.';

  @override
  String get noSavedYet => 'No saved items yet';

  @override
  String get loadingDetail => 'Loading details...';

  @override
  String get cannotLoadDetail => 'Cannot load details';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get goBack => 'Go back';

  @override
  String get tripInfoSaved => 'Trip info saved! Check your Saved tab.';

  @override
  String alreadySavedMessage(String name) {
    return '$name is already saved!';
  }

  @override
  String get loadingItinerary => 'AI is planning your itinerary...';

  @override
  String get cannotCreateItinerary => 'Cannot create itinerary';

  @override
  String get share => 'Share';

  @override
  String dayLabel(int n) {
    return 'Day $n';
  }

  @override
  String get generateAiItinerary => 'Generate AI Itinerary';

  @override
  String get saveInfo => 'Save Info';

  @override
  String get remove => 'Remove';

  @override
  String get estimatedBudget => 'ESTIMATED BUDGET';

  @override
  String get bookNow => 'Book Now';

  @override
  String get addToWishlist => 'Add to Wishlist';

  @override
  String get addedToWishlist => 'added to wishlist!';

  @override
  String get alreadySaved => 'is already saved!';

  @override
  String get hot => 'HOT';

  @override
  String get perPerson => '/ person';

  @override
  String get aiInsightPrefix => '💡 AI Insight: ';

  @override
  String get defaultAiInsight =>
      'Perfect for your wellness budget. Dry season now.';

  @override
  String get vnd => 'VNĐ';

  @override
  String get loginRequired => 'You need to be logged in.';

  @override
  String get noAiResponse => 'No response received from AI.';

  @override
  String get apiKeyNotSet =>
      'GEMINI_API_KEY is not set. Please add your key to .env file.';

  @override
  String get invalidLoginCredentials =>
      'Invalid login credentials. Please check your email and password.';

  @override
  String get emailNotConfirmed =>
      'Email not confirmed. Please check your inbox.';

  @override
  String get userAlreadyExists =>
      'User already exists. Please sign in instead.';

  @override
  String get beach => 'Beach';

  @override
  String get adventure => 'Adventure';

  @override
  String get culture => 'Culture';

  @override
  String get food => 'Food';

  @override
  String get wellness => 'Wellness';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => '+84 912 345 678';

  @override
  String get phoneInvalidChars =>
      'Phone number can only contain digits, spaces, +, -, (, ).';

  @override
  String get phoneMinDigits => 'Phone number needs at least 8 digits.';

  @override
  String get contactInfoSaved => 'Contact info saved.';

  @override
  String get saveContactInfo => 'Save contact info';

  @override
  String get savingContactInfo => 'Saving…';

  @override
  String get culturalTips => 'Cultural Tips';

  @override
  String get culturalDos => 'Do\'s';

  @override
  String get culturalDonts => 'Don\'ts';

  @override
  String get basicPhrases => 'Basic Phrases';

  @override
  String get diningEtiquette => 'Dining Etiquette';

  @override
  String get sacredSites => 'Sacred Sites';

  @override
  String get loadingCulturalTips => 'Loading cultural tips...';

  @override
  String get cannotLoadCulturalTips => 'Cannot load cultural tips';

  @override
  String get culturalTipsButton => '🎭 Cultural Tips';

  @override
  String get chatTitle => 'AI Travel Chat';

  @override
  String get chatWelcome =>
      'Hi! I\'m your AI travel assistant. Ask me anything about travel destinations, tips, or planning your next adventure! 🌍';

  @override
  String get chatError => 'Sorry, I couldn\'t respond. Please try again.';

  @override
  String get chatCleared => 'Chat cleared. How can I help you?';

  @override
  String get chatAiReply => 'AI is typing...';

  @override
  String get chatInputHint => 'Ask me about any destination...';

  @override
  String get compareTitle => 'Compare Destinations';

  @override
  String get compareInputHeader => 'Enter destinations to compare';

  @override
  String get compareDest1Hint => 'e.g. Phu Quoc';

  @override
  String get compareDest2Hint => 'e.g. Da Nang';

  @override
  String get compareDest3Hint => 'e.g. Hoi An (optional)';

  @override
  String get compareLoading => 'Comparing...';

  @override
  String get compareButton => 'Compare Destinations';

  @override
  String get compareMinError => 'Please enter at least 2 destinations.';

  @override
  String get compareRecommendation => 'AI Recommendation';

  @override
  String get compareDetail => 'Comparison Details';

  @override
  String get comparePros => 'Pros';

  @override
  String get compareCons => 'Cons';

  @override
  String get bestTimeTitle => 'Best Time to Travel';

  @override
  String get bestTimeInputHeader => 'Find the best time to visit';

  @override
  String get bestTimeHint => 'e.g. Bali, Tokyo, Paris...';

  @override
  String get bestTimeLoading => 'Analyzing...';

  @override
  String get bestTimeButton => 'Find Best Time';

  @override
  String get bestTimeMinError => 'Please enter a destination.';

  @override
  String bestTimeBestMonth(String month) {
    return 'Best month: $month';
  }

  @override
  String get bestTimeSeasons => 'Seasons';

  @override
  String get bestTimeMonthly => 'Monthly Overview';

  @override
  String get bestTimeTips => 'Travel Tips';

  @override
  String get aiToolsTitle => 'AI Travel Tools';

  @override
  String get aiToolsSubtitle =>
      'Discover powerful AI tools to plan your perfect trip';

  @override
  String get aiChatbotTitle => 'AI Chatbot';

  @override
  String get aiChatbotSubtitle => 'Chat with AI';

  @override
  String get aiChatbotDesc =>
      'Ask any travel question and get instant AI-powered answers about destinations, tips, and more.';

  @override
  String get aiCompareTitle => 'Compare Destinations';

  @override
  String get aiCompareSubtitle => 'Side-by-side comparison';

  @override
  String get aiCompareDesc =>
      'Compare 2-3 destinations on cost, weather, activities, and more to find your perfect match.';

  @override
  String get aiBestTimeTitle => 'Best Time to Travel';

  @override
  String get aiBestTimeSubtitle => 'Seasonal analysis';

  @override
  String get aiBestTimeDesc =>
      'Find the ideal months to visit any destination based on weather, crowds, and local events.';

  @override
  String get contextCompareSuggestions => 'Compare these suggestions';

  @override
  String get contextBestTime => 'When should I go?';

  @override
  String get contextAskAboutDestination => 'Ask AI about this place';

  @override
  String get refineForBudget => 'Optimize for budget';

  @override
  String get refineForFamily => 'Better for children or seniors';

  @override
  String get refineLessTravel => 'Less travel between stops';

  @override
  String get currencySelectorTitle => 'Display currency';

  @override
  String get currencySelectorDescription =>
      'Prices throughout Voyz are converted using the latest available reference rate.';

  @override
  String get currencyVietnameseDong => 'Vietnamese đồng';

  @override
  String get currencyUsDollar => 'US dollar';

  @override
  String get currencyEuro => 'Euro';

  @override
  String get currencyKoreanWon => 'South Korean won';

  @override
  String get currencyJapaneseYen => 'Japanese yen';

  @override
  String get currencyThaiBaht => 'Thai baht';

  @override
  String get currencyBritishPound => 'British pound';

  @override
  String get currencyAustralianDollar => 'Australian dollar';

  @override
  String get currencySingaporeDollar => 'Singapore dollar';

  @override
  String get currencyCanadianDollar => 'Canadian dollar';
}
