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

  /// Section heading for required planner fields
  ///
  /// In en, this message translates to:
  /// **'REQUIRED INFO'**
  String get requiredInfo;

  /// Section heading for optional planner fields
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL INFO'**
  String get optionalInfo;

  /// Destination input field label
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// Destination field hint text
  ///
  /// In en, this message translates to:
  /// **'e.g. Phu Quoc, Paris, Bali...'**
  String get destinationHint;

  /// Departure date field label
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departDate;

  /// Return date field label
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnDate;

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

  /// Participants field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 adults'**
  String get participantsHint;

  /// Age range field label
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get ageRange;

  /// Age range field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 25-35'**
  String get ageRangeHint;

  /// Interests section heading
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// Additional notes field label
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get additionalNotes;

  /// Notes field hint
  ///
  /// In en, this message translates to:
  /// **'Any special requests, accessibility needs...'**
  String get notesHint;

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

  /// Validation snackbar when required fields are empty
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required info'**
  String get fillAllRequired;

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

  /// Optional field marker
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get optional;

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

  /// Suggestions screen heading
  ///
  /// In en, this message translates to:
  /// **'Travel Suggestions'**
  String get travelSuggestions;

  /// Detailed loading message on suggestions screen
  ///
  /// In en, this message translates to:
  /// **'AI is searching destinations...'**
  String get loadingSuggestionsDetail;

  /// Error heading on suggestions screen
  ///
  /// In en, this message translates to:
  /// **'Cannot load suggestions'**
  String get cannotLoadSuggestions;

  /// Empty state on suggestions screen
  ///
  /// In en, this message translates to:
  /// **'No suggestions found.'**
  String get noSuggestionsFound;

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

  /// Label after review count e.g. '(120 reviews)'
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviewsCount;

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

  /// Add to wishlist button label
  ///
  /// In en, this message translates to:
  /// **'Add to Wishlist'**
  String get addToWishlist;

  /// Snackbar message when item added to wishlist
  ///
  /// In en, this message translates to:
  /// **'added to wishlist!'**
  String get addedToWishlist;

  /// Snackbar message when item already saved
  ///
  /// In en, this message translates to:
  /// **'is already saved!'**
  String get alreadySaved;

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

  /// Error message when chat fails
  ///
  /// In en, this message translates to:
  /// **'Sorry, I couldn\'t respond. Please try again.'**
  String get chatError;

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
