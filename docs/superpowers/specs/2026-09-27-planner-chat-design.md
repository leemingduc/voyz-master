# Planner chat with trip option cards

Date: 2026-09-27
Status: Approved in discussion, ready for plan
Roadmap: `docs/project_phase3_roadmap_ai_first.md` section 2.6

## Context

Today the planner sends one prompt, extracts `TripData`, and opens `SuggestionsScreen`, which asks Gemini for 8 destinations. Two problems came up in testing:

1. **Accuracy.** "Du lịch Côn Đảo" returns Đà Nẵng and Phú Quốc. The suggestions prompt forces exactly 8 city level items and treats the destination as a preference, so the model pads the list with other places.
2. **Shape.** Users usually know where they want to go ("4 ngày 3 đêm Nha Trang", "1 tuần Côn Đảo"). They want to see what the trip looks like, not a list of single places.

## Goal

The planner becomes an agent first chat, like Gemini. The user describes the trip, the agent asks a short question when something important is missing, then shows 3 trip options inside the chat. Each option is an overview: a theme, a duration, and a route of 3 to 5 named stops. Tapping an option opens the existing `DestinationDetailScreen`, exactly like tapping a suggestion today.

## Decisions (agreed in discussion)

1. Only the planner and the suggestion list change. `DestinationDetailScreen`, `DestinationPlanScreen` and everything after them stay untouched.
2. One structured Gemini call per turn (`planTurn`) with a `responseSchema`. No `firebase_ai`, no function calling, no streaming.
3. The code, not the model, decides when options are forced: the user taps "Gợi ý luôn", or the agent already asked 2 questions since the last options.
4. If the user names a destination, all 3 options stay inside it and differ by theme or pace. If not, options may be different destinations.
5. Trip length comes from whatever the user gives: dates, or a duration such as "1 tuần" or "4 ngày 3 đêm". `TripData` stores it as `numDays`.
6. Option images: each option names an `imageStop`; the code looks it up through the existing `ImageService` and never shows the same photo on two cards.
7. The conversation lives only in screen state. It is not saved.
8. Price on the card and price on the detail screen come from different AI calls and may differ. Both are labeled estimates. Accepted for now.
9. Keep the students' UI: same hero, same prompt box style, bubble style from `ChatScreen`, card style from the old `_DestinationCard`.

## User flow

```text
Hero (today's planner) -> user sends first message
  -> screen switches to chat mode: message list + input dock
  -> agent reply: either one short question, or a short intro + 3 option cards
  -> user answers, refines ("rẻ hơn"), or taps "Gợi ý luôn"
  -> user taps an option card
  -> TripData written to SavedTripsProvider, search recorded
  -> DestinationDetailScreen(destinationName: option.destination)   (unchanged)
```

The header in chat mode has a "new chat" button that clears the messages and returns to the hero.

## Components

### 1. `TripData.numDays` (`lib/data/trip_data.dart`)

- New field `int? numDays`, included in the constructor, `fromMap`, `toMap`, `copyWith`.
- `dayCount({int fallback = 3})`: dates first (as today), else `numDays` if it is above 0, else `fallback`. The result is clamped to 1..7 in every case.
- No migration: `trip_data` on Supabase and Hive are free form maps.

### 2. Models (`lib/models/plan_turn.dart`, new)

```dart
class TripOption {
  final String title;        // theme, e.g. "Biển & lặn ngắm san hô"
  final String destination;  // base place, e.g. "Côn Đảo, Việt Nam"
  final int numDays;
  final List<String> stops;  // 3-5 named places in visiting order
  final String imageStop;    // most representative stop for the photo
  final String price;        // AI estimate string, e.g. "~6.5M VND"
  final String aiInsight;
  final String imageUrl;     // filled later, '' until then
  TripOption copyWith({String? imageUrl});
}

class PlanTurn {
  final String reply;
  final TripData trip;             // everything known so far
  final List<TripOption> options;  // empty while the agent is asking
  final String raw;                // original JSON, sent back as history
  bool get hasOptions => options.isNotEmpty;
  PlanTurn copyWith({List<TripOption>? options});
}

class PlannerMessage {
  final String text;     // user text, or turn.reply for the agent
  final PlanTurn? turn;  // null for user messages
  bool get isUser => turn == null;
  factory PlannerMessage.user(String text);
  factory PlannerMessage.agent(PlanTurn turn);
}

/// TripData to hand to the detail screen when an option is picked.
TripData tripForOption(PlanTurn turn, TripOption option, List<String> userMessages);
```

`tripForOption` sets `destination = option.destination`, `numDays = option.numDays`, and `aiPrompt` to the user messages joined by newlines, followed by one line:
`Phương án đã chọn: {title}, {numDays} ngày, lộ trình: {stops joined by ", "}.`
The detail and itinerary prompts already read `trip.aiPrompt` (and it is in their cache keys), so the itinerary follows the chosen route without changing those screens.

### 3. `GeminiService` changes (`lib/services/gemini_service.dart`)

- `Future<PlanTurn> planTurn(List<PlannerMessage> messages, {bool forceOptions = false, String languageCode = 'vi'})`
  - `force = forceOptions || questionsSinceLastOptions(messages) >= 2`.
  - Builds one prompt with `buildPlanTurnPrompt(messages, forceOptions: force, languageCode:, today:)`. The conversation is rendered into that prompt as a transcript: user lines as text, agent lines as their `raw` JSON. This avoids role alternation rules and matches how every other prompt builder in the file works.
  - Uses a model built with `_createModel` and a `GenerationConfig` with `responseMimeType: 'application/json'`, the `responseSchema` below, temperature 0.7 and the same `maxOutputTokens` as `_gemini`.
  - Not cached.
- `static int questionsSinceLastOptions(List<PlannerMessage>)`: counts agent turns without options after the last agent turn with options.
- `PlanTurn parsePlanTurn(String text)`: pure, tolerant parser.
  - `trip` goes through `parseTripMap` (below).
  - Options missing `title`, `destination` or `stops` are dropped. Stops are trimmed, empty ones removed, at most 5 kept. `imageStop` falls back to the first stop. `numDays` falls back to `trip.numDays`, then 3. At most 3 options kept.
  - Unparseable text returns a turn with an empty reply and no options (the screen treats that as a failure).
- `TripData parseTripMap(Map<String, dynamic> map, {String originalPrompt = ''})`: the body of today's `parseExtractedTripData`, taking a map, and now always keeping `numDays` (also when there is no depart date).
- `Future<List<TripOption>> enrichOptionsWithImages(List<TripOption> options)` calls `static Future<List<TripOption>> pickOptionImages(options, Future<String> Function(String query) lookup)` with `ImageService.instance.getImageUrl`.
  - Note: `ImageService.getImageUrl` looks up only the part before the first comma; the full query is still its cache key. This matches `getLandmarkPhotos`.
  - For each option in order, candidates are `imageStop`, then the other stops, then the destination itself. The query is `"{candidate}, {destination}"` (just `destination` for the last one).
  - The first non empty URL not already used by an earlier card wins. If none, `imageUrl` stays `''` and `DestinationImage` draws its placeholder.
  - Lookup errors are treated as an empty result.

Prompt rules (Vietnamese, per convention; language line from `languageInstruction`):

- Today's date, so relative dates ("tuần sau") can be resolved.
- Needed before giving options: a destination or a trip style, and a trip length. If either is missing, ask one short question and return `options: []`. If both are known, give options now and do not ask.
- One question per turn at most.
- When `force` is set: options are mandatory this turn; state assumptions in `reply` ("Mình giả định 3N2Đ, 2 người").
- When the user named a destination, every option must be inside that destination.
- Exactly 3 options. `stops` 3 to 5 proper place names, never generic ("bãi biển", "chợ đêm"). `imageStop` different across the 3 options.
- `price` is a realistic estimate per person for the whole trip, with the currency code.
- Carry forward everything already known in `trip`; never drop a value the user gave.

Response schema:

```text
object (required: reply, trip, options)
  reply: string
  trip: object
    destination: string, nullable
    departDate: string (yyyy-MM-dd), nullable
    returnDate: string (yyyy-MM-dd), nullable
    numDays: integer, nullable
    budgetTier: string, nullable (economy | moderate | premium | luxury)
    participants: integer, nullable
    ageRange: string, nullable
    interests: array of string (beach | adventure | culture | food | wellness)
  options: array of object (required: title, destination, numDays, stops, imageStop, price, aiInsight)
```

Removed from `GeminiService`: `getSuggestions`, `buildSuggestionsPrompt`, `_formatDate` (only used there), `extractTripData`, `buildExtractPrompt`, `parseExtractedTripData` (replaced by `parseTripMap`). Kept: `parseSuggestionsSync`, `enrichSuggestionsWithImages`, `_withImages` (Explore uses them), `_describeBudgetTier` (detail uses it).

### 4. Planner screen (`lib/screens/smart_planner_screen.dart`)

State: `List<PlannerMessage> _messages`, `bool _isSending`, `Object? _error`, the prompt controller, and the profile interests.

- **Hero mode** (`_messages.isEmpty`): unchanged layout. The action button sends the first message.
- **Chat mode**: header row (wordmark, "new chat" icon button, account button), then an `Expanded` message list centered with `maxWidth: 760`, then the input dock. The bottom nav stays.
- **Input dock**: the existing `_AiPromptBox`, generalized so its secondary outlined button is configurable. Hero mode: secondary = Explore, action = "Nhận gợi ý AI". Chat mode: secondary = "Gợi ý luôn" (calls send with `forceOptions: true`, sending the typed text or, if empty, no new user message), action = "Gửi" (`plannerSend`). In chat mode the text field is 1 to 3 lines with the chat hint.
- **Sending**: append `PlannerMessage.user(text)`, clear the field, call `planTurn`. On success append `PlannerMessage.agent(turn)`; if the turn has options, call `enrichOptionsWithImages` and replace that turn's options when the images arrive. While waiting show the same "AI đang nhập..." row as `ChatScreen`.
- **Errors**: a failed call or an empty reply sets `_error`. Below the list show `ErrorLocalizer.getLocalizedMessage` text and a "Thử lại" button that repeats the call with the same messages (the user message is not added twice).
- **Picking an option**: `tripForOption(...)`, then as today: currency from `CurrencyProvider`, interests fall back to profile interests, `provider.updateTrip`, `SearchHistoryService.recordTripSearch`, then push `DestinationDetailScreen(destinationName: option.destination)`. The chat stays in place when the user comes back.
- **Leaving for Saved**: `_savePrompt` keeps today's behavior only in hero mode.
- Scrolling: the list scrolls to the bottom after each new message.

### 5. Widgets (`lib/widgets/planner/`, new)

- `planner_bubble.dart`: `PlannerBubble`, same look as `ChatScreen`'s `_ChatBubble` (avatar circle, rounded bubble, pink tint for user).
- `trip_option_card.dart`: `TripOptionCard(option, onTap)`, restyled from the old `_DestinationCard`:
  - Same container (radius, border, dark fill), image via `DestinationImage` at 2:1, with a duration badge top left (`tripDays(n)`, black 60% background, the old match badge style).
  - Header row: title (20px bold) with destination under it; price on the right with `CurrencyAmountText`, "/ người", and "Ước tính AI".
  - Route row: route icon + stops joined with " → ".
  - Insight box in the old `_AiInsightBox` style (non top match colors).
  - One full width outlined "Xem chi tiết" button in the old wishlist button style. Tapping anywhere on the card does the same.
  - No rating, review count, match percent, share or wishlist.

### 6. Deleted

- `lib/screens/suggestions_screen.dart`. Compare stays reachable from AI tools.
- Tests only for deleted code: `buildSuggestionsPrompt` group; `parseExtractedTripData` tests move to `parseTripMap`.
- l10n keys used only by the suggestions screen: `addToWishlist`, `addedToWishlist`, `alreadySaved`, `cannotLoadSuggestions`, `contextCompareSuggestions`, `loadingSuggestionsDetail`, `noSuggestionsFound`, `reviewsCount`, `travelSuggestions` (each re-checked with grep before removal).

### 7. New l10n keys (en, vi, ko)

| Key | vi | en | ko |
|---|---|---|---|
| `suggestNow` | Gợi ý luôn | Suggest now | 바로 추천 |
| `plannerChatHint` | Nhắn thêm cho AI... | Tell the AI more... | AI에게 더 알려주세요... |
| `newPlannerChat` | Cuộc trò chuyện mới | New chat | 새 대화 |
| `aiEstimateLabel` | Ước tính AI | AI estimate | AI 추정 |
| `viewDetails` | Xem chi tiết | View details | 자세히 보기 |
| `tripDays` (int `n`) | {n} ngày | {n} days | {n}일 |
| `plannerSend` | Gửi | Send | 보내기 |

Reused (errors go through `ErrorLocalizer`, which already maps `noAiResponse` and `apiKeyNotSet`): `aiPromptHint`, `getAiSuggestions`, `analyzingTrip`, `explore`, `chatAiReply`, `retry`, `aiInsightPrefix`, `perPerson`, `describeTripRequired`, `quickPromptsLabel`.

## Error handling

| Case | Behavior |
|---|---|
| Gemini throws (network, key, quota) | Error row with localized message and "Thử lại" |
| Reply parses but is empty | Treated as `Exception('noAiResponse')`, same row as above |
| Forced turn returns no options | Show the reply; user can tap "Gợi ý luôn" again |
| Option missing required fields | Dropped by the parser; if all dropped, the turn is a question turn |
| Image lookup fails or duplicates | Next candidate; finally the shared placeholder |
| User leaves the planner mid chat | Conversation is lost (by design) |

## Testing

- `TripData`: `numDays` round trip through `toMap`/`fromMap`; `dayCount` with dates, with only `numDays`, with neither; dates win over `numDays`.
- `parseTripMap`: existing extraction cases, plus `numDays` kept with no depart date.
- `parsePlanTurn`: a question turn; an options turn; missing keys; bad options dropped; more than 3 options trimmed; `imageStop` fallback; invalid JSON.
- `questionsSinceLastOptions`: counts reset after an options turn.
- `buildPlanTurnPrompt`: contains the destination rule; contains the forced rule only when forced; contains the transcript.
- `pickOptionImages`: 3 options whose `imageStop` resolve to the same URL end with 3 different URLs; all failing gives `''`.
- `tripForOption`: destination, `numDays`, and the "Phương án đã chọn" line.
- Widget test: `TripOptionCard` shows the title, the duration, the route and the estimate label.

## Out of scope

Streaming, saving the chat, `chat_history_service`, merging with `ChatScreen`, changes to the detail or plan screens, new image sources, a strip of stop photos on cards, "more options" or paging, the `firebase_ai` migration, and fixing the two price estimates to agree.

## Acceptance

Same list as roadmap 2.6 "Nghiệm thu".
