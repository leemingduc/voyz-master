# AI-First Smart Planner Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify `SmartPlannerScreen` to an AI-first, 1-touch experience (Prompt box + Inspiration chips + single CTA button), and introduce an editable `TripChips` bar in `SuggestionsScreen` for quick parameter adjustments.

**Architecture:** 
- `SmartPlannerScreen` drops 7 manual input form controls, focusing purely on free-form prompt input and quick inspiration chips.
- Bypasses intermediate form reviews: tapping "Gợi ý chuyến đi" calls `GeminiService.extractTripData(prompt)` and pushes straight to `SuggestionsScreen`.
- A new modular widget `TripChips` displays the structured trip parameters (Destination, Dates/Duration, Budget tier, Participants) at the top of `SuggestionsScreen`, allowing users to adjust any parameter via quick bottom sheets and reload suggestions.

**Tech Stack:** Flutter / Dart, `GeminiService`, `SavedTripsProvider`, `SearchHistoryService`, `AppTheme`.

## Global Constraints

- Never commit or push directly to `master`. Work on feature branch `planner-ai-first`.
- All AI calls go through `GeminiService`.
- No image hardcoding.
- Maintain localization support (`AppLocalizations`).
- `flutter analyze` must pass with 0 new issues and `flutter test` must pass 100%.

---

### Task 1: Create `TripChips` Widget & Widget Test

**Files:**
- Create: `lib/widgets/shared/trip_chips.dart`
- Create: `test/widgets/trip_chips_test.dart`

**Interfaces:**
- Consumes: `TripData` (`lib/data/trip_data.dart`), `AppLocalizations`, `AppTheme`
- Produces:
```dart
class TripChips extends StatelessWidget {
  final TripData trip;
  final ValueChanged<TripData> onTripChanged;

  const TripChips({
    super.key,
    required this.trip,
    required this.onTripChanged,
  });
}
```

- [ ] **Step 1: Write the failing test for `TripChips`**

Create `test/widgets/trip_chips_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/widgets/shared/trip_chips.dart';

void main() {
  Widget buildTestWidget({
    required TripData trip,
    required ValueChanged<TripData> onTripChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TripChips(
          trip: trip,
          onTripChanged: onTripChanged,
        ),
      ),
    );
  }

  testWidgets('renders all chips with provided trip data', (tester) async {
    final trip = TripData(
      destination: 'Đà Lạt',
      departDate: DateTime(2026, 10, 1),
      returnDate: DateTime(2026, 10, 4),
      budget: 'economy',
      participants: '3',
    );

    await tester.pumpWidget(buildTestWidget(trip: trip, onTripChanged: (_) {}));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đà Lạt'), findsOneWidget);
    expect(find.textContaining('01/10 - 04/10'), findsOneWidget);
    expect(find.textContaining('3'), findsOneWidget);
  });

  testWidgets('renders dimmed placeholder when destination is empty', (tester) async {
    final trip = TripData(destination: '');

    await tester.pumpWidget(buildTestWidget(trip: trip, onTripChanged: (_) {}));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI gợi ý'), findsOneWidget);
  });

  testWidgets('tapping budget chip opens sheet and invokes onTripChanged', (tester) async {
    TripData? updated;
    final trip = TripData(budget: 'moderate');

    await tester.pumpWidget(buildTestWidget(
      trip: trip,
      onTripChanged: (newTrip) => updated = newTrip,
    ));
    await tester.pumpAndSettle();

    // Tap the budget chip
    final budgetFinder = find.byKey(const ValueKey('trip_chip_budget'));
    expect(budgetFinder, findsOneWidget);
    await tester.tap(budgetFinder);
    await tester.pumpAndSettle();

    // Select luxury in bottom sheet
    final luxuryOption = find.byKey(const ValueKey('budget_option_luxury'));
    expect(luxuryOption, findsOneWidget);
    await tester.tap(luxuryOption);
    await tester.pumpAndSettle();

    expect(updated, isNotNull);
    expect(updated!.budget, 'luxury');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/trip_chips_test.dart`
Expected: Compilation failure because `TripChips` does not exist yet.

- [ ] **Step 3: Implement `TripChips` widget**

Create `lib/widgets/shared/trip_chips.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/theme/app_theme.dart';

class TripChips extends StatelessWidget {
  final TripData trip;
  final ValueChanged<TripData> onTripChanged;

  const TripChips({
    super.key,
    required this.trip,
    required this.onTripChanged,
  });

  String _formatDates(DateTime? depart, DateTime? ret) {
    final formatter = DateFormat('dd/MM');
    if (depart != null && ret != null) {
      return '${formatter.format(depart)} - ${formatter.format(ret)}';
    } else if (depart != null) {
      return 'Từ ${formatter.format(depart)}';
    }
    return 'Thời gian linh hoạt';
  }

  String _getBudgetLabel(String tier, AppLocalizations l10n) {
    switch (tier) {
      case 'economy':
        return l10n.budgetEconomy;
      case 'moderate':
        return l10n.budgetModerate;
      case 'premium':
        return l10n.budgetPremium;
      case 'luxury':
        return l10n.budgetLuxury;
      default:
        return tier.isNotEmpty ? tier : l10n.budgetModerate;
    }
  }

  void _showDestinationSheet(BuildContext context) {
    final controller = TextEditingController(text: trip.destination);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Điểm đến',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập điểm đến...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onTripChanged(trip.copyWith(destination: controller.text.trim()));
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetSheet(BuildContext context, AppLocalizations l10n) {
    final tiers = ['economy', 'moderate', 'premium', 'luxury'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ngân sách',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tiers.map((tier) {
                final isSelected = trip.budget == tier;
                return ChoiceChip(
                  key: ValueKey('budget_option_$tier'),
                  label: Text(_getBudgetLabel(tier, l10n)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      Navigator.pop(ctx);
                      onTripChanged(trip.copyWith(budget: tier));
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsSheet(BuildContext context) {
    final currentCount = int.tryParse(trip.participants) ?? 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Số người tham gia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    onPressed: currentCount > 1
                        ? () {
                            Navigator.pop(ctx);
                            onTripChanged(trip.copyWith(participants: '${currentCount - 1}'));
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$currentCount',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onTripChanged(trip.copyWith(participants: '${currentCount + 1}'));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDateRange: trip.departDate != null && trip.returnDate != null
          ? DateTimeRange(start: trip.departDate!, end: trip.returnDate!)
          : null,
    );
    if (picked != null) {
      onTripChanged(trip.copyWith(
        departDate: picked.start,
        returnDate: picked.end,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDest = trip.destination.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
      child: Row(
        children: [
          // Destination Chip
          ActionChip(
            key: const ValueKey('trip_chip_destination'),
            avatar: const Icon(Icons.location_on_outlined, size: 16),
            label: Text(
              hasDest ? trip.destination : 'Điểm đến: AI gợi ý',
              style: TextStyle(
                color: hasDest ? Colors.white : Colors.white60,
                fontStyle: hasDest ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            onPressed: () => _showDestinationSheet(context),
          ),
          const SizedBox(width: 8),

          // Date Chip
          ActionChip(
            key: const ValueKey('trip_chip_dates'),
            avatar: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(_formatDates(trip.departDate, trip.returnDate)),
            onPressed: () => _pickDateRange(context),
          ),
          const SizedBox(width: 8),

          // Budget Chip
          ActionChip(
            key: const ValueKey('trip_chip_budget'),
            avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: Text(_getBudgetLabel(trip.budget, l10n)),
            onPressed: () => _showBudgetSheet(context, l10n),
          ),
          const SizedBox(width: 8),

          // Participants Chip
          ActionChip(
            key: const ValueKey('trip_chip_participants'),
            avatar: const Icon(Icons.people_outline, size: 16),
            label: Text('${trip.participants.isNotEmpty ? trip.participants : "1"} người'),
            onPressed: () => _showParticipantsSheet(context),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/trip_chips_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/trip_chips.dart test/widgets/trip_chips_test.dart
git commit -m "feat: add editable TripChips widget and tests"
```

---

### Task 2: Simplify `SmartPlannerScreen` to AI-First Experience

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart`
- Create: `test/screens/smart_planner_screen_test.dart`

**Interfaces:**
- Consumes: `GeminiService.instance.extractTripData`, `SavedTripsProvider`, `SearchHistoryService`, `SuggestionsScreen`
- Produces: Streamlined AI-First screen with Prompt Box, Inspiration Chips, and single 1-touch CTA button.

- [ ] **Step 1: Write widget tests for simplified `SmartPlannerScreen`**

Create `test/screens/smart_planner_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/smart_planner_screen.dart';

void main() {
  Widget buildScreen() {
    return LocaleProvider(
      child: CurrencyProvider(
        child: SavedTripsProvider(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SmartPlannerScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders prompt box, inspiration chips and cta button without old form fields', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Verify Prompt box and CTA are present
    expect(find.byType(TextField), findsOneWidget); // Only prompt TextField
    expect(find.textContaining('Gợi ý chuyến đi'), findsOneWidget);

    // Verify old form fields are removed
    expect(find.byIcon(Icons.public), findsNothing);
    expect(find.byIcon(Icons.calendar_month), findsNothing);
    expect(find.byIcon(Icons.cake), findsNothing);
  });

  testWidgets('tapping an inspiration chip sets the prompt text', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final inspirationChip = find.textContaining('Đà Lạt');
    if (inspirationChip.evaluate().isNotEmpty) {
      await tester.tap(inspirationChip.first);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, contains('Đà Lạt'));
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/smart_planner_screen_test.dart`
Expected: FAIL because old form fields still exist.

- [ ] **Step 3: Update `SmartPlannerScreen`**

In `lib/screens/smart_planner_screen.dart`:
- Remove old controllers: `_destinationController`, `_participantsController`, `_ageRangeController`, `_notesController`.
- Remove `_tierTouched`, `_interestsTouched`, `_aiFilled`, `_canFill()`, `_applyExtracted()`, `_pickDate()`, `_buildTextField()`, `_buildDateField()`, `_buildBudgetTierSelector()`.
- Add Inspiration Chips:
  ```dart
  final List<String> _inspirationPrompts = [
    'Đi Đà Lạt 3 ngày với gia đình, tiết kiệm',
    'Nghỉ dưỡng biển Phú Quốc 4 ngày cao cấp',
    'Khám phá ẩm thực và văn hóa Hà Nội cuối tuần',
    'Tour trekking Sapa khám phá thiên nhiên',
  ];
  ```
- Update CTA action `_onSubmit()`:
  - Check prompt is not empty.
  - Set `_isAnalyzing = true`.
  - Try calling `GeminiService.instance.extractTripData(prompt, languageCode: currentLocale)`.
  - Fallback cleanly if error occurs to `TripData(aiPrompt: prompt)`.
  - Merge with profile defaults (currency, interests).
  - Update `SavedTripsProvider` & call `SearchHistoryService.instance.recordTripSearch(...)`.
  - Push to `SuggestionsScreen`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/smart_planner_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/smart_planner_screen.dart test/screens/smart_planner_screen_test.dart
git commit -m "refactor: simplify SmartPlannerScreen to AI-first prompt with inspiration chips"
```

---

### Task 3: Integrate `TripChips` in `SuggestionsScreen`

**Files:**
- Modify: `lib/screens/suggestions_screen.dart`
- Modify: `test/screens/suggestions_screen_test.dart` (if existing, or create)

**Interfaces:**
- Consumes: `TripChips` (`lib/widgets/shared/trip_chips.dart`), `SavedTripsProvider`
- Produces: Interactive trip chips bar pinned at the top of `SuggestionsScreen`.

- [ ] **Step 1: Write test verifying `TripChips` exists on `SuggestionsScreen`**

Check/create test in `test/screens/suggestions_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/suggestions_screen.dart';
import 'package:voyz/widgets/shared/trip_chips.dart';

void main() {
  testWidgets('renders TripChips at the top of suggestions', (tester) async {
    final savedTripsProvider = SavedTripsProvider(
      child: LocaleProvider(
        child: CurrencyProvider(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SuggestionsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(savedTripsProvider);
    await tester.pump();

    expect(find.byType(TripChips), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/suggestions_screen_test.dart`
Expected: FAIL (`TripChips` not found in `SuggestionsScreen`).

- [ ] **Step 3: Modify `SuggestionsScreen` to render `TripChips`**

In `lib/screens/suggestions_screen.dart`:
- Import `import 'package:voyz/widgets/shared/trip_chips.dart';`.
- In `build()`, above the `ListView` / suggestions content, render:
  ```dart
  TripChips(
    trip: trip,
    onTripChanged: (newTrip) {
      SavedTripsProvider.of(context).updateTrip(newTrip);
      _loadSuggestions(forceRefresh: true);
    },
  ),
  ```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/suggestions_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/suggestions_screen.dart test/screens/suggestions_screen_test.dart
git commit -m "feat: embed interactive TripChips in SuggestionsScreen"
```

---

### Task 4: Project-wide Verification & Cleanup

**Files:**
- Audit all files: `lib/`, `test/`

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`
Expected: 0 issues. Fix any unused imports or variables if found.

- [ ] **Step 2: Run all test suites**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Commit any cleanup fixes**

```bash
git add .
git commit -m "chore: clean up and pass all tests and analyze"
```
