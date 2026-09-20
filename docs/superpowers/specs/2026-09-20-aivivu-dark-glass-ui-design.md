# AIVIVU Dark Glass UI Redesign

## Goal

Refresh every existing AIVIVU screen with one responsive, dark glassmorphism
visual system while preserving all routes, callbacks, data, services, and
screen flow.

## Scope and constraints

- UI only: no service, model, provider, persistence, localization-key, or
  navigation-flow change.
- Work remains on the current `feature/ui-redesign` branch. Nothing is pushed
  or merged to `master` without the user's separate approval.
- Use Plus Jakarta Sans (with the app's existing CJK fallbacks) throughout.
- Use the dark palette: base `#06070B` through `#10131A`, cyan `#00E5FF`,
  magenta `#FF3366`, and violet `#8B5CF6`.
- Cards use translucent dark glass, a thin white border, 16--24px radii, and
  restrained shadows. Primary actions use a cyan--violet--magenta gradient.
- The wordmark is exactly `AIVIVU`, uppercase, bold, italic, letter-spaced,
  and given a subtle cyan-violet glow everywhere it is shown.
- Header and lower navigation are reusable shared components. Lower navigation
  has exactly three equal destinations and a stable layout across all screens;
  only active state may vary.
- Layouts must adapt cleanly from narrow mobile screens to tablets and desktop
  widths without changing interaction behavior.

## Visual architecture

`AppTheme` becomes the source of truth for color tokens, radii, gradients,
glass surface colors, text styles, and Material component defaults. The
existing shared `GlassCard` and `GradientButton` consume those tokens so
screen-specific cards and actions inherit the new visual language.

Three new visual primitives keep screens consistent:

1. `AivivuWordmark` renders the branded text treatment without duplicating
   shaders or shadows in screens.
2. `AivivuHeader` supplies a transparent/glass app header, the wordmark, and
   optional existing actions/back navigation. It must not own route logic.
3. The revised `BottomNavBar` owns the fixed geometry, iconography, labels,
   active indicator, and safe-area padding of the three destinations. Each
   screen continues to supply its current index and its existing `onTap`.

Screens retain their widgets, callbacks, state, and navigation calls. Their
presentation is normalized by replacing local app bars/brand text with the
shared primitives and by using theme tokens rather than legacy pink/orange
colors. Screens with the existing out-of-range navigation index will map the
same contextual destination to one of the three canonical indices; callbacks
and destinations stay unchanged.

## Component behavior

### Theme and surfaces

- The app background is a near-black vertical/ambient gradient between
  `#06070B` and `#10131A`; individual pages may layer low-opacity cyan/violet
  accents only when they do not reduce legibility.
- Glass surfaces use a white overlay at low opacity, 1px white border at low
  opacity, backdrop blur, and 16px default radius (24px for feature panels).
- Body text is near-white, secondary text is cool gray, and muted text remains
  readable against the background.
- The primary gradient is cyan to violet to magenta. Glow is limited to the
  wordmark, selected navigation indicator, and high-priority actions.

### Header

- All authenticated/content screens render one shared header treatment.
- It supports leading back navigation when a screen already provides it,
  optional trailing actions, and the AIVIVU wordmark without moving or
  replacing the existing actions.
- Auth and splash retain their existing full-screen composition but use the
  shared wordmark styling.

### Bottom navigation

- Destinations are AI Planner (index 0), Explore (index 1), and Saved (index
  2), preserving the current labels/localization and existing tap callback.
- Each item occupies one third of the available width, has the same 48px
  interaction height, same icon size, and same label position.
- Active item uses the cyan accent and a compact translucent pill; inactive
  items use the shared muted color. The overall bar is a glass surface with
  safe-area-aware padding.

### Responsive behavior

- Content uses a centered max-width on large displays and shared horizontal
  padding that scales from 16px on phones to 24px on wider displays.
- Existing vertical lists remain scrollable. Cards expand in width rather than
  changing content order or actions.
- Touch targets remain at least 44px tall/wide where controls are interactive.

## Screen application

The visual layer covers splash, authentication, Smart Planner, Explore,
Suggestions, Destination Detail, Destination Plan, Saved, Chat, AI Tools,
Compare, Cultural Tips, Best Time, Friends, and Profile. Existing imagery,
localized strings, form state, async loading/error states, and service calls
remain intact. Profile is included visually even though its persistence logic
is outside this work.

## Verification

- Add widget tests for wordmark styling contract, the three-item navigation
  contract, and responsive/shared visual primitives where practical.
- Run `flutter analyze` and `flutter test` after the UI changes.
- Manually review representative narrow and wide layouts for planner, explore,
  detail, saved, auth, and profile, checking no callback or screen flow has
  changed.
