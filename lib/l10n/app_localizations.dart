import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('vi'),
  ];

  /// Application title used in MaterialApp
  ///
  /// In en, this message translates to:
  /// **'AIVIVU - AI Travel Advisor'**
  String get appTitle;

  /// Short app brand name
  ///
  /// In en, this message translates to:
  /// **'AIVIVU'**
  String get appName;

  /// Splash screen subtitle
  ///
  /// In en, this message translates to:
  /// **'AI POWERED TRAVEL'**
  String get aiPowered;

  /// App version shown on splash
  ///
  /// In en, this message translates to:
  /// **'VERSION 1.0.0'**
  String get appVersion;

  /// Profile tab/screen label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Language settings section heading
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Vietnamese language option
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// Korean language option
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get korean;

  /// Sign in button / label
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Snackbar after successful language change
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get languageSaved;

  /// Generic error fallback message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// Generic save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Bottom nav item for planner tab
  ///
  /// In en, this message translates to:
  /// **'AI Planner'**
  String get home;

  /// Bottom nav item for explore tab
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Bottom nav item for saved tab
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTrips;

  /// Bottom nav item for friends tab
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// Sign out action in account menu
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Generic loading indicator label
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Back navigation tooltip
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Smart planner screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Smart Planner'**
  String get smartPlanner;

  /// Auth screen greeting when logging in
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Auth screen greeting when registering
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Switch to login mode link
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get haveAccountLogin;

  /// Switch to register mode link
  ///
  /// In en, this message translates to:
  /// **'Need an account? Register'**
  String get needAccountRegister;

  /// Validation: email and password required
  ///
  /// In en, this message translates to:
  /// **'Enter an email and a password with at least 6 characters.'**
  String get emailPasswordRequired;

  /// Validation: username required
  ///
  /// In en, this message translates to:
  /// **'Enter your username.'**
  String get usernameRequired;

  /// Validation: passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Password confirmation does not match.'**
  String get passwordMismatch;

  /// Success message after registration requiring email confirm
  ///
  /// In en, this message translates to:
  /// **'Account created. Please check your email or login to continue.'**
  String get accountCreated;

  /// Error when account creation fails
  ///
  /// In en, this message translates to:
  /// **'Could not create account. Please try again.'**
  String get accountCreationFailed;

  /// Profile card heading
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// Profile card subtitle
  ///
  /// In en, this message translates to:
  /// **'Avatar and email are retained after each login.'**
  String get profileSubtitle;

  /// Button to upload avatar image
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// Zoom slider label in avatar editor
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// Horizontal offset slider label
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get horizontal;

  /// Vertical offset slider label
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get vertical;

  /// Reset avatar adjustments button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Button label while avatar is being saved
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// Snackbar after successful avatar save
  ///
  /// In en, this message translates to:
  /// **'Avatar saved.'**
  String get avatarSaved;

  /// Info note about avatar storage
  ///
  /// In en, this message translates to:
  /// **'The image is stored in Supabase Storage bucket \'avatars\' and the URL is written to user metadata.'**
  String get avatarStorageNote;

  /// Error when avatar upload not supported on platform
  ///
  /// In en, this message translates to:
  /// **'Avatar upload is currently available on web only.'**
  String get avatarUploadWebOnly;

  /// Error when avatar editing not supported on platform
  ///
  /// In en, this message translates to:
  /// **'Avatar editing is currently available on web only.'**
  String get avatarEditingWebOnly;

  /// Display name info row label
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// Placeholder when display name is empty
  ///
  /// In en, this message translates to:
  /// **'No display name set'**
  String get noDisplayName;

  /// Change password card heading
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// Validation: password too short
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters.'**
  String get passwordMinLength;

  /// Success snackbar after password change
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// Button label while updating password
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// Generic update action
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Destination input field label
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// Placeholder when no date is selected
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get addDate;

  /// Budget input field label
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// Budget field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 5000000'**
  String get budgetHint;

  /// Budget tier section label
  ///
  /// In en, this message translates to:
  /// **'Budget Tier'**
  String get budgetTier;

  /// Economy budget tier
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get budgetTierEconomy;

  /// Moderate budget tier
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get budgetTierModerate;

  /// Premium budget tier
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get budgetTierPremium;

  /// Luxury budget tier
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get budgetTierLuxury;

  /// Currency field label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Number of participants field label
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// Interests section heading
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// AI prompt field label
  ///
  /// In en, this message translates to:
  /// **'Describe your dream trip'**
  String get aiPrompt;

  /// AI prompt field hint
  ///
  /// In en, this message translates to:
  /// **'Tell AI what kind of trip you want...'**
  String get aiPromptHint;

  /// Main CTA button on smart planner
  ///
  /// In en, this message translates to:
  /// **'Get AI Suggestions'**
  String get getAiSuggestions;

  /// Planner primary button label while the extraction request is in flight
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzingTrip;

  /// Validation snackbar when the AI prompt box is empty
  ///
  /// In en, this message translates to:
  /// **'Please describe your trip first'**
  String get describeTripRequired;

  /// Explore screen section heading
  ///
  /// In en, this message translates to:
  /// **'Trending Destinations'**
  String get trendingDestinations;

  /// Label for AI insight text on destination card
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get aiInsight;

  /// Badge on top-matched destination
  ///
  /// In en, this message translates to:
  /// **'TOP MATCH'**
  String get topMatch;

  /// Suffix after match percentage e.g. '92% match'
  ///
  /// In en, this message translates to:
  /// **'match'**
  String get match;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Retry button label on error state
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Empty state heading on saved screen
  ///
  /// In en, this message translates to:
  /// **'No saved items yet'**
  String get noSavedItems;

  /// Empty state subtitle on saved screen
  ///
  /// In en, this message translates to:
  /// **'Save destinations you love and they\'ll appear here.'**
  String get noSavedItemsHint;

  /// Snackbar after removing a saved item
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get savedItemRemoved;

  /// Save trip button on destination detail
  ///
  /// In en, this message translates to:
  /// **'Save Trip'**
  String get saveTrip;

  /// Snackbar when trip is already saved
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get tripAlreadySaved;

  /// Snackbar after successfully saving a trip
  ///
  /// In en, this message translates to:
  /// **'Trip saved!'**
  String get tripSaved;

  /// Button to open the itinerary plan screen
  ///
  /// In en, this message translates to:
  /// **'View Itinerary'**
  String get viewItinerary;

  /// Snackbar when share link is copied
  ///
  /// In en, this message translates to:
  /// **'Share link copied!'**
  String get shareLinkCopied;

  /// Section heading for budget breakdown
  ///
  /// In en, this message translates to:
  /// **'Budget Breakdown'**
  String get budgetBreakdown;

  /// Total budget label
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get totalBudget;

  /// Weather info label
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// Travel dates label
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// Pro tip section heading in itinerary
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get proTip;

  /// Itinerary screen heading
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// Day prefix in itinerary e.g. 'Day 1'
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// Loading message while itinerary is being generated
  ///
  /// In en, this message translates to:
  /// **'Generating your itinerary…'**
  String get generatingItinerary;

  /// Suggestions screen heading
  ///
  /// In en, this message translates to:
  /// **'AI Suggestions'**
  String get aiSuggestions;

  /// Loading message on suggestions screen
  ///
  /// In en, this message translates to:
  /// **'Finding best destinations for you…'**
  String get loadingSuggestions;

  /// Empty state on suggestions screen
  ///
  /// In en, this message translates to:
  /// **'No suggestions found'**
  String get noSuggestions;

  /// Greeting headline on smart planner screen
  ///
  /// In en, this message translates to:
  /// **'Where do you\nwant to go? 🌍'**
  String get plannerGreeting;

  /// Explore screen heading
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// Explore screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Trending destinations'**
  String get exploreSubtitle;

  /// Loading message on explore screen
  ///
  /// In en, this message translates to:
  /// **'Finding interesting destinations...'**
  String get loadingExplore;

  /// Error heading when data cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Cannot load data'**
  String get cannotLoadData;

  /// Empty state when no data is available
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// Saved screen heading
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Badge label for saved trip
  ///
  /// In en, this message translates to:
  /// **'Saved Trip'**
  String get savedTrip;

  /// Badge label for wishlist item
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// Snackbar suffix when item is removed
  ///
  /// In en, this message translates to:
  /// **'removed'**
  String get removed;

  /// Empty state subtitle on saved screen
  ///
  /// In en, this message translates to:
  /// **'Explore destinations and save them\nto see them here.'**
  String get emptySavedHint;

  /// Empty state heading on saved screen
  ///
  /// In en, this message translates to:
  /// **'No saved items yet'**
  String get noSavedYet;

  /// Loading message on destination detail screen
  ///
  /// In en, this message translates to:
  /// **'Loading details...'**
  String get loadingDetail;

  /// Error heading on destination detail screen
  ///
  /// In en, this message translates to:
  /// **'Cannot load details'**
  String get cannotLoadDetail;

  /// Fallback error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Go back button label
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Snackbar after saving trip info
  ///
  /// In en, this message translates to:
  /// **'Trip info saved! Check your Saved tab.'**
  String get tripInfoSaved;

  /// Snackbar when trip is already saved
  ///
  /// In en, this message translates to:
  /// **'{name} is already saved!'**
  String alreadySavedMessage(String name);

  /// Loading message on itinerary screen
  ///
  /// In en, this message translates to:
  /// **'AI is planning your itinerary...'**
  String get loadingItinerary;

  /// Error heading on itinerary screen
  ///
  /// In en, this message translates to:
  /// **'Cannot create itinerary'**
  String get cannotCreateItinerary;

  /// Share button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Tab label for itinerary day
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String dayLabel(int n);

  /// CTA button on destination detail to plan itinerary
  ///
  /// In en, this message translates to:
  /// **'Generate AI Itinerary'**
  String get generateAiItinerary;

  /// Button to save trip info on destination detail
  ///
  /// In en, this message translates to:
  /// **'Save Info'**
  String get saveInfo;

  /// Remove button label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Budget section heading on destination detail
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED BUDGET'**
  String get estimatedBudget;

  /// Book now button label
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// Hot badge label for trending destinations
  ///
  /// In en, this message translates to:
  /// **'HOT'**
  String get hot;

  /// Price label suffix per person
  ///
  /// In en, this message translates to:
  /// **'/ person'**
  String get perPerson;

  /// Prefix label for AI insight box
  ///
  /// In en, this message translates to:
  /// **'💡 AI Insight: '**
  String get aiInsightPrefix;

  /// Default AI insight text when saving trip
  ///
  /// In en, this message translates to:
  /// **'Perfect for your wellness budget. Dry season now.'**
  String get defaultAiInsight;

  /// Vietnamese Dong currency symbol
  ///
  /// In en, this message translates to:
  /// **'VNĐ'**
  String get vnd;

  /// Error when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in.'**
  String get loginRequired;

  /// Error when AI returns no response
  ///
  /// In en, this message translates to:
  /// **'No response received from AI.'**
  String get noAiResponse;

  /// Error when API key is missing
  ///
  /// In en, this message translates to:
  /// **'GEMINI_API_KEY is not set. Please add your key to .env file.'**
  String get apiKeyNotSet;

  /// Error when login credentials are invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid login credentials. Please check your email and password.'**
  String get invalidLoginCredentials;

  /// Error when email is not confirmed
  ///
  /// In en, this message translates to:
  /// **'Email not confirmed. Please check your inbox.'**
  String get emailNotConfirmed;

  /// Error when user already exists
  ///
  /// In en, this message translates to:
  /// **'User already exists. Please sign in instead.'**
  String get userAlreadyExists;

  /// Beach interest label
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get beach;

  /// Adventure interest label
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get adventure;

  /// Culture interest label
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get culture;

  /// Food interest label
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// Wellness interest label
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellness;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// Phone number field hint text
  ///
  /// In en, this message translates to:
  /// **'+84 912 345 678'**
  String get phoneHint;

  /// Phone validation error for invalid characters
  ///
  /// In en, this message translates to:
  /// **'Phone number can only contain digits, spaces, +, -, (, ).'**
  String get phoneInvalidChars;

  /// Phone validation error for minimum digits
  ///
  /// In en, this message translates to:
  /// **'Phone number needs at least 8 digits.'**
  String get phoneMinDigits;

  /// Snackbar after saving contact info
  ///
  /// In en, this message translates to:
  /// **'Contact info saved.'**
  String get contactInfoSaved;

  /// Button label to save contact information
  ///
  /// In en, this message translates to:
  /// **'Save contact info'**
  String get saveContactInfo;

  /// Button label while saving contact info
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingContactInfo;

  /// Cultural tips screen title
  ///
  /// In en, this message translates to:
  /// **'Cultural Tips'**
  String get culturalTips;

  /// Section heading for do's
  ///
  /// In en, this message translates to:
  /// **'Do\'s'**
  String get culturalDos;

  /// Section heading for don'ts
  ///
  /// In en, this message translates to:
  /// **'Don\'ts'**
  String get culturalDonts;

  /// Section heading for basic phrases
  ///
  /// In en, this message translates to:
  /// **'Basic Phrases'**
  String get basicPhrases;

  /// Section heading for dining etiquette
  ///
  /// In en, this message translates to:
  /// **'Dining Etiquette'**
  String get diningEtiquette;

  /// Section heading for sacred site rules
  ///
  /// In en, this message translates to:
  /// **'Sacred Sites'**
  String get sacredSites;

  /// Loading message for cultural tips
  ///
  /// In en, this message translates to:
  /// **'Loading cultural tips...'**
  String get loadingCulturalTips;

  /// Error message when cultural tips fail to load
  ///
  /// In en, this message translates to:
  /// **'Cannot load cultural tips'**
  String get cannotLoadCulturalTips;

  /// Button label to navigate to cultural tips
  ///
  /// In en, this message translates to:
  /// **'🎭 Cultural Tips'**
  String get culturalTipsButton;

  /// Chat screen app bar title
  ///
  /// In en, this message translates to:
  /// **'AI Travel Chat'**
  String get chatTitle;

  /// Welcome message shown when chat screen opens
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your AI travel assistant. Ask me anything about travel destinations, tips, or planning your next adventure! 🌍'**
  String get chatWelcome;

  /// Message shown after chat history is cleared
  ///
  /// In en, this message translates to:
  /// **'Chat cleared. How can I help you?'**
  String get chatCleared;

  /// Loading indicator text while AI is replying
  ///
  /// In en, this message translates to:
  /// **'AI is typing...'**
  String get chatAiReply;

  /// Hint text in the chat input field
  ///
  /// In en, this message translates to:
  /// **'Ask me about any destination...'**
  String get chatInputHint;

  /// Compare screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Compare Destinations'**
  String get compareTitle;

  /// Header for the compare input section
  ///
  /// In en, this message translates to:
  /// **'Enter destinations to compare'**
  String get compareInputHeader;

  /// Hint for the first destination input
  ///
  /// In en, this message translates to:
  /// **'e.g. Phu Quoc'**
  String get compareDest1Hint;

  /// Hint for the second destination input
  ///
  /// In en, this message translates to:
  /// **'e.g. Da Nang'**
  String get compareDest2Hint;

  /// Hint for the optional third destination input
  ///
  /// In en, this message translates to:
  /// **'e.g. Hoi An (optional)'**
  String get compareDest3Hint;

  /// Button label while compare is loading
  ///
  /// In en, this message translates to:
  /// **'Comparing...'**
  String get compareLoading;

  /// Button label to trigger comparison
  ///
  /// In en, this message translates to:
  /// **'Compare Destinations'**
  String get compareButton;

  /// Error when fewer than 2 destinations are entered
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 2 destinations.'**
  String get compareMinError;

  /// Section heading for AI recommendation in compare results
  ///
  /// In en, this message translates to:
  /// **'AI Recommendation'**
  String get compareRecommendation;

  /// Section heading for comparison detail table
  ///
  /// In en, this message translates to:
  /// **'Comparison Details'**
  String get compareDetail;

  /// Label for pros list in compare results
  ///
  /// In en, this message translates to:
  /// **'Pros'**
  String get comparePros;

  /// Label for cons list in compare results
  ///
  /// In en, this message translates to:
  /// **'Cons'**
  String get compareCons;

  /// Best time screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Best Time to Travel'**
  String get bestTimeTitle;

  /// Header for the best time input section
  ///
  /// In en, this message translates to:
  /// **'Find the best time to visit'**
  String get bestTimeInputHeader;

  /// Hint text for the best time destination input
  ///
  /// In en, this message translates to:
  /// **'e.g. Bali, Tokyo, Paris...'**
  String get bestTimeHint;

  /// Button label while best time is loading
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get bestTimeLoading;

  /// Button label to trigger best time analysis
  ///
  /// In en, this message translates to:
  /// **'Find Best Time'**
  String get bestTimeButton;

  /// Error when destination is empty in best time screen
  ///
  /// In en, this message translates to:
  /// **'Please enter a destination.'**
  String get bestTimeMinError;

  /// Best month label with month name
  ///
  /// In en, this message translates to:
  /// **'Best month: {month}'**
  String bestTimeBestMonth(String month);

  /// Section heading for seasons in best time results
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get bestTimeSeasons;

  /// Error when the Gemini API returns 429 / quota exceeded
  ///
  /// In en, this message translates to:
  /// **'The AI free quota (Gemini) is used up. Wait about 1 minute and try again, or pick another AI model in Profile.'**
  String get aiQuotaExceeded;

  /// Error when Gemini rejects or has blocked the API key
  ///
  /// In en, this message translates to:
  /// **'The Gemini API key is invalid or was blocked by Google. Replace the key.'**
  String get aiKeyInvalid;

  /// Error when Gemini returns a 5xx server error
  ///
  /// In en, this message translates to:
  /// **'The AI server is overloaded or has a problem. Please try again in a few minutes.'**
  String get aiServerBusy;

  /// Error when the AI JSON cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'The AI returned data in a wrong format. Please try again.'**
  String get aiInvalidResponse;

  /// Error when the device cannot reach the server
  ///
  /// In en, this message translates to:
  /// **'No network connection. Check the Internet and try again.'**
  String get networkError;

  /// Section heading for monthly data in best time results
  ///
  /// In en, this message translates to:
  /// **'Monthly Overview'**
  String get bestTimeMonthly;

  /// Section heading for travel tips in best time results
  ///
  /// In en, this message translates to:
  /// **'Travel Tips'**
  String get bestTimeTips;

  /// AI Tools hub screen title
  ///
  /// In en, this message translates to:
  /// **'AI Travel Tools'**
  String get aiToolsTitle;

  /// AI Tools hub screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Discover powerful AI tools to plan your perfect trip'**
  String get aiToolsSubtitle;

  /// Chatbot tool card title
  ///
  /// In en, this message translates to:
  /// **'AI Chatbot'**
  String get aiChatbotTitle;

  /// Chatbot tool card subtitle
  ///
  /// In en, this message translates to:
  /// **'Chat with AI'**
  String get aiChatbotSubtitle;

  /// Chatbot tool card description
  ///
  /// In en, this message translates to:
  /// **'Ask any travel question and get instant AI-powered answers about destinations, tips, and more.'**
  String get aiChatbotDesc;

  /// Compare tool card title
  ///
  /// In en, this message translates to:
  /// **'Compare Destinations'**
  String get aiCompareTitle;

  /// Compare tool card subtitle
  ///
  /// In en, this message translates to:
  /// **'Side-by-side comparison'**
  String get aiCompareSubtitle;

  /// Compare tool card description
  ///
  /// In en, this message translates to:
  /// **'Compare 2-3 destinations on cost, weather, activities, and more to find your perfect match.'**
  String get aiCompareDesc;

  /// Best time tool card title
  ///
  /// In en, this message translates to:
  /// **'Best Time to Travel'**
  String get aiBestTimeTitle;

  /// Best time tool card subtitle
  ///
  /// In en, this message translates to:
  /// **'Seasonal analysis'**
  String get aiBestTimeSubtitle;

  /// Best time tool card description
  ///
  /// In en, this message translates to:
  /// **'Find the ideal months to visit any destination based on weather, crowds, and local events.'**
  String get aiBestTimeDesc;

  /// Action to analyze the best time for the current destination
  ///
  /// In en, this message translates to:
  /// **'When should I go?'**
  String get contextBestTime;

  /// Action to open AI chat with the current destination context
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this place'**
  String get contextAskAboutDestination;

  /// Action to optimize an itinerary for the user's budget
  ///
  /// In en, this message translates to:
  /// **'More Activities (Budget Optimized)'**
  String get refineForBudget;

  /// Action to make an itinerary more suitable for children or older adults
  ///
  /// In en, this message translates to:
  /// **'Better for children or seniors'**
  String get refineForFamily;

  /// Action to reduce travel time between itinerary stops
  ///
  /// In en, this message translates to:
  /// **'Less travel between stops'**
  String get refineLessTravel;

  /// Title of the display currency picker
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get currencySelectorTitle;

  /// Description in the display currency picker
  ///
  /// In en, this message translates to:
  /// **'Prices throughout Voyz are converted using the latest available reference rate.'**
  String get currencySelectorDescription;

  /// No description provided for @currencyVietnameseDong.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese đồng'**
  String get currencyVietnameseDong;

  /// No description provided for @currencyUsDollar.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get currencyUsDollar;

  /// No description provided for @currencyEuro.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyEuro;

  /// No description provided for @currencyKoreanWon.
  ///
  /// In en, this message translates to:
  /// **'South Korean won'**
  String get currencyKoreanWon;

  /// No description provided for @currencyJapaneseYen.
  ///
  /// In en, this message translates to:
  /// **'Japanese yen'**
  String get currencyJapaneseYen;

  /// No description provided for @currencyThaiBaht.
  ///
  /// In en, this message translates to:
  /// **'Thai baht'**
  String get currencyThaiBaht;

  /// No description provided for @currencyBritishPound.
  ///
  /// In en, this message translates to:
  /// **'British pound'**
  String get currencyBritishPound;

  /// No description provided for @currencyAustralianDollar.
  ///
  /// In en, this message translates to:
  /// **'Australian dollar'**
  String get currencyAustralianDollar;

  /// No description provided for @currencySingaporeDollar.
  ///
  /// In en, this message translates to:
  /// **'Singapore dollar'**
  String get currencySingaporeDollar;

  /// No description provided for @currencyCanadianDollar.
  ///
  /// In en, this message translates to:
  /// **'Canadian dollar'**
  String get currencyCanadianDollar;

  /// Profile section heading for the Gemini model picker
  ///
  /// In en, this message translates to:
  /// **'AI model'**
  String get aiModel;

  /// Helper text under the AI model picker
  ///
  /// In en, this message translates to:
  /// **'Which Gemini model answers your travel questions. Larger models think longer and may reach the free quota sooner.'**
  String get aiModelDescription;

  /// Snackbar after the AI model is changed
  ///
  /// In en, this message translates to:
  /// **'AI model saved'**
  String get aiModelSaved;

  /// No description provided for @quickPromptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick ideas:'**
  String get quickPromptsLabel;

  /// No description provided for @quickPromptTokyo.
  ///
  /// In en, this message translates to:
  /// **'Tokyo during cherry blossom season'**
  String get quickPromptTokyo;

  /// No description provided for @quickPromptDaLat.
  ///
  /// In en, this message translates to:
  /// **'Đà Lạt for 3 days and 2 nights'**
  String get quickPromptDaLat;

  /// No description provided for @quickPromptBali.
  ///
  /// In en, this message translates to:
  /// **'Relaxing in Bali'**
  String get quickPromptBali;

  /// No description provided for @quickPromptPhuQuoc.
  ///
  /// In en, this message translates to:
  /// **'Watch the sunset in Phú Quốc'**
  String get quickPromptPhuQuoc;

  /// Planner chat button that asks the AI for trip options right away
  ///
  /// In en, this message translates to:
  /// **'Suggest now'**
  String get suggestNow;

  /// Hint of the planner chat input
  ///
  /// In en, this message translates to:
  /// **'Tell the AI more...'**
  String get plannerChatHint;

  /// Send button of the planner chat
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get plannerSend;

  /// Tooltip of the button that restarts the planner chat
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newPlannerChat;

  /// Title and tooltip for the saved AI planner conversation history
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get plannerConversationHistory;

  /// Title and tooltip for saved AI trip suggestions
  ///
  /// In en, this message translates to:
  /// **'Suggestion history'**
  String get plannerSuggestionHistory;

  /// Empty state for the AI planner conversation history
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet'**
  String get noPlannerConversations;

  /// Label after a conversation's message count
  ///
  /// In en, this message translates to:
  /// **'messages'**
  String get messagesLabel;

  /// Action that permanently removes a saved AI planner conversation
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get deletePlannerConversation;

  /// Tooltip of the button that saves the current AI planner conversation
  ///
  /// In en, this message translates to:
  /// **'Save conversation'**
  String get savePlannerConversation;

  /// Confirmation after saving the current AI planner conversation
  ///
  /// In en, this message translates to:
  /// **'Conversation saved'**
  String get plannerConversationSaved;

  /// Label under an AI generated price
  ///
  /// In en, this message translates to:
  /// **'AI estimate'**
  String get aiEstimateLabel;

  /// Button on a trip option card
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendRequests;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// No description provided for @noFriendsYetHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email or display name to add someone.'**
  String get noFriendsYetHint;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @noPendingRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Incoming and outgoing requests appear here.'**
  String get noPendingRequestsHint;

  /// No description provided for @findFriends.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get findFriends;

  /// No description provided for @friendSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Email or display name'**
  String get friendSearchHint;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriend;

  /// No description provided for @friendStatus.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendStatus;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @wantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect'**
  String get wantsToConnect;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get friendRequestSent;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @removeFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get removeFriendTitle;

  /// No description provided for @removeFriendMessage.
  ///
  /// In en, this message translates to:
  /// **'You will remove {name} from your friends. The conversation for both of you will also be deleted.'**
  String removeFriendMessage(String name);

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get removeFriend;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @messageInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get messageInputHint;

  /// No description provided for @messageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get messageOptions;

  /// No description provided for @cancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get cancelReply;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWith(String name);

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Send a quick greeting to get started!'**
  String get noMessagesYet;

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi'**
  String get sayHi;

  /// No description provided for @planTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip'**
  String get planTrip;

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you?'**
  String get howAreYou;

  /// No description provided for @quickHiMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi there!'**
  String get quickHiMessage;

  /// No description provided for @quickTripMessage.
  ///
  /// In en, this message translates to:
  /// **'Want to plan a trip together?'**
  String get quickTripMessage;

  /// No description provided for @quickHowAreYouMessage.
  ///
  /// In en, this message translates to:
  /// **'How are you doing today?'**
  String get quickHowAreYouMessage;

  /// No description provided for @reviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Review saved'**
  String get reviewSaved;

  /// No description provided for @communityReviews.
  ///
  /// In en, this message translates to:
  /// **'Community reviews'**
  String get communityReviews;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share a quick tip for other travelers'**
  String get reviewHint;

  /// No description provided for @postReview.
  ///
  /// In en, this message translates to:
  /// **'Post review'**
  String get postReview;

  /// No description provided for @randomDestination.
  ///
  /// In en, this message translates to:
  /// **'Explore a random new destination'**
  String get randomDestination;

  /// No description provided for @shareDestination.
  ///
  /// In en, this message translates to:
  /// **'Share destination'**
  String get shareDestination;

  /// No description provided for @shareNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get shareNoteHint;

  /// No description provided for @selectFriends.
  ///
  /// In en, this message translates to:
  /// **'Choose friends in the app:'**
  String get selectFriends;

  /// No description provided for @noConnectedFriends.
  ///
  /// In en, this message translates to:
  /// **'You do not have any connected friends in the app yet.'**
  String get noConnectedFriends;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @destinationLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Destination link copied!'**
  String get destinationLinkCopied;

  /// No description provided for @shareDestinationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shared \"{name}\" with {count} friends!'**
  String shareDestinationSuccess(String name, int count);

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send: {error}'**
  String sendFailed(String error);

  /// No description provided for @tripWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Trip workspace'**
  String get tripWorkspace;

  /// No description provided for @workspaceSummary.
  ///
  /// In en, this message translates to:
  /// **'{workspaceCount} workspaces / {wishlistCount} wishlists'**
  String workspaceSummary(int workspaceCount, int wishlistCount);

  /// No description provided for @unableToLoadSaved.
  ///
  /// In en, this message translates to:
  /// **'Unable to load saved places. Try again'**
  String get unableToLoadSaved;

  /// No description provided for @aiMatch.
  ///
  /// In en, this message translates to:
  /// **'AI match'**
  String get aiMatch;

  /// No description provided for @costEstimate.
  ///
  /// In en, this message translates to:
  /// **'Cost estimate'**
  String get costEstimate;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'reference'**
  String get reference;

  /// No description provided for @budgetTbd.
  ///
  /// In en, this message translates to:
  /// **'Budget TBD'**
  String get budgetTbd;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @notesSaved.
  ///
  /// In en, this message translates to:
  /// **'Notes saved'**
  String get notesSaved;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get saveName;

  /// No description provided for @uploadImageTab.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImageTab;

  /// No description provided for @presetAvatarTab.
  ///
  /// In en, this message translates to:
  /// **'Preset avatar'**
  String get presetAvatarTab;

  /// No description provided for @uploadFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Upload from device'**
  String get uploadFromDevice;

  /// No description provided for @uploadImageHelp.
  ///
  /// In en, this message translates to:
  /// **'JPG and PNG are supported. You can crop and edit after selecting.'**
  String get uploadImageHelp;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @plannerAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your interests and preferences...'**
  String get plannerAnalyzing;

  /// No description provided for @plannerFinding.
  ///
  /// In en, this message translates to:
  /// **'Exploring and selecting suitable destinations...'**
  String get plannerFinding;

  /// No description provided for @plannerCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating an optimized itinerary and estimated budget...'**
  String get plannerCalculating;

  /// No description provided for @plannerFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing great travel options...'**
  String get plannerFinishing;

  /// No description provided for @flexibleDates.
  ///
  /// In en, this message translates to:
  /// **'Flexible dates'**
  String get flexibleDates;

  /// No description provided for @itineraryReady.
  ///
  /// In en, this message translates to:
  /// **'Itinerary ready'**
  String get itineraryReady;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

  /// No description provided for @deleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteForMe;

  /// No description provided for @deleteForMeHint.
  ///
  /// In en, this message translates to:
  /// **'This message is only deleted from your device'**
  String get deleteForMeHint;

  /// No description provided for @recallForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Recall for everyone'**
  String get recallForEveryone;

  /// No description provided for @recallForEveryoneHint.
  ///
  /// In en, this message translates to:
  /// **'This message will disappear for both people'**
  String get recallForEveryoneHint;

  /// No description provided for @messageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Message notifications'**
  String get messageNotifications;

  /// No description provided for @chatAppearance.
  ///
  /// In en, this message translates to:
  /// **'Chat appearance'**
  String get chatAppearance;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get clearConversation;

  /// No description provided for @conversationCleared.
  ///
  /// In en, this message translates to:
  /// **'Conversation cleared for you'**
  String get conversationCleared;

  /// No description provided for @messageRecalled.
  ///
  /// In en, this message translates to:
  /// **'Message recalled for everyone'**
  String get messageRecalled;

  /// No description provided for @emoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @changeDestination.
  ///
  /// In en, this message translates to:
  /// **'Change destination'**
  String get changeDestination;

  /// No description provided for @compareOptions.
  ///
  /// In en, this message translates to:
  /// **'Compare options'**
  String get compareOptions;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNow;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @activeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {count} min ago'**
  String activeMinutesAgo(int count);

  /// No description provided for @activeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {count} hr ago'**
  String activeHoursAgo(int count);

  /// No description provided for @activeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Active yesterday'**
  String get activeYesterday;

  /// No description provided for @activeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {count} days ago'**
  String activeDaysAgo(int count);

  /// No description provided for @activeOnDate.
  ///
  /// In en, this message translates to:
  /// **'Active {date}'**
  String activeOnDate(String date);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @seen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seen;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @chatTheme.
  ///
  /// In en, this message translates to:
  /// **'Chat theme'**
  String get chatTheme;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose a theme'**
  String get chooseTheme;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get music;

  /// No description provided for @musicDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn music on or off while using the app'**
  String get musicDescription;

  /// No description provided for @travelPreferences.
  ///
  /// In en, this message translates to:
  /// **'Travel preferences'**
  String get travelPreferences;

  /// No description provided for @preferredCurrency.
  ///
  /// In en, this message translates to:
  /// **'Preferred currency'**
  String get preferredCurrency;

  /// No description provided for @travelStyles.
  ///
  /// In en, this message translates to:
  /// **'Travel styles'**
  String get travelStyles;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save preferences'**
  String get savePreferences;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get chooseAvatar;

  /// No description provided for @destinationEstimate.
  ///
  /// In en, this message translates to:
  /// **'AI estimate at destination · 1 person · excludes tickets and transport'**
  String get destinationEstimate;

  /// No description provided for @iconicSights.
  ///
  /// In en, this message translates to:
  /// **'ICONIC SIGHTS & REAL PHOTOS'**
  String get iconicSights;

  /// No description provided for @previewMessageOne.
  ///
  /// In en, this message translates to:
  /// **'Hi! Where are you? 😊'**
  String get previewMessageOne;

  /// No description provided for @previewMessageTwo.
  ///
  /// In en, this message translates to:
  /// **'I\'m in Da Nang ✈️ It\'s wonderful!'**
  String get previewMessageTwo;

  /// No description provided for @previewMessageThree.
  ///
  /// In en, this message translates to:
  /// **'That sounds great! I really want to go 🌊'**
  String get previewMessageThree;

  /// No description provided for @previewMessageFour.
  ///
  /// In en, this message translates to:
  /// **'Let\'s plan a trip together!'**
  String get previewMessageFour;

  /// No description provided for @criterion.
  ///
  /// In en, this message translates to:
  /// **'Criterion'**
  String get criterion;

  /// No description provided for @sharedDestination.
  ///
  /// In en, this message translates to:
  /// **'Shared destination'**
  String get sharedDestination;

  /// No description provided for @performAction.
  ///
  /// In en, this message translates to:
  /// **'Take action'**
  String get performAction;

  /// No description provided for @anonymousReviewer.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousReviewer;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @reviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewCount(int count);

  /// No description provided for @exploreCategoryRandom.
  ///
  /// In en, this message translates to:
  /// **'🎲 Random'**
  String get exploreCategoryRandom;

  /// No description provided for @exploreCategoryBeach.
  ///
  /// In en, this message translates to:
  /// **'🏖️ Islands & beaches'**
  String get exploreCategoryBeach;

  /// No description provided for @exploreCategoryMountain.
  ///
  /// In en, this message translates to:
  /// **'🏔️ Mountains & passes'**
  String get exploreCategoryMountain;

  /// No description provided for @exploreCategoryHeritage.
  ///
  /// In en, this message translates to:
  /// **'🏯 Heritage'**
  String get exploreCategoryHeritage;

  /// No description provided for @exploreCategoryCity.
  ///
  /// In en, this message translates to:
  /// **'🏙️ Vibrant cities'**
  String get exploreCategoryCity;

  /// No description provided for @exploreCategoryWellness.
  ///
  /// In en, this message translates to:
  /// **'🌿 Nature retreat'**
  String get exploreCategoryWellness;

  /// No description provided for @exploreCategoryHiddenGems.
  ///
  /// In en, this message translates to:
  /// **'💎 Hidden gems'**
  String get exploreCategoryHiddenGems;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @luxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get luxury;

  /// No description provided for @slowTravel.
  ///
  /// In en, this message translates to:
  /// **'Slow travel'**
  String get slowTravel;

  /// No description provided for @workspaceReady.
  ///
  /// In en, this message translates to:
  /// **'{doneCount}/{totalCount} ready'**
  String workspaceReady(int doneCount, int totalCount);

  /// Trip duration badge
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String tripDays(int n);

  /// No description provided for @themeAivivu.
  ///
  /// In en, this message translates to:
  /// **'AIVIVU'**
  String get themeAivivu;

  /// No description provided for @themeTwilight.
  ///
  /// In en, this message translates to:
  /// **'Twilight'**
  String get themeTwilight;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// No description provided for @themeSakura.
  ///
  /// In en, this message translates to:
  /// **'Sakura'**
  String get themeSakura;

  /// No description provided for @themeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

  /// No description provided for @themeGolden.
  ///
  /// In en, this message translates to:
  /// **'Golden Hour'**
  String get themeGolden;

  /// No description provided for @themeRoadGrip.
  ///
  /// In en, this message translates to:
  /// **'Road Grip'**
  String get themeRoadGrip;

  /// No description provided for @chatThemeChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} changed the theme to {theme}'**
  String chatThemeChanged(String name, String theme);

  /// No description provided for @budgetTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get budgetTransport;

  /// No description provided for @budgetStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get budgetStay;

  /// No description provided for @budgetFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get budgetFood;

  /// No description provided for @budgetActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get budgetActivities;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
