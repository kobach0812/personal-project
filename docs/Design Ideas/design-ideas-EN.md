# PlaySnapp — Design Ideas Catalog

*Working direction as of 2026-05-27*
*Status: Mood 1 (Athletic Pro) selected as working baseline. Final moodboard pending.*

---

## 1. Strategic context

PlaySnapp is a private sports social app for squads. iOS-first, with a **Vietnam B2B-leading + international B2C-supporting** market strategy.

### Why this strategy shapes the design

- **Vietnam B2B buyers** (private schools, athletic clubs, university sports departments, corporate wellness programs) want products that feel *internationally credible*. They want to feel they're buying something globally legitimate, not a domestic-only tool.
- **International B2C users** (English-speaking amateur sport squads) want something modern, fun, and share-worthy.
- The design must serve both audiences without compromising either.

### Visual direction: Mood 1 — Athletic Pro

References: Strava, Hudl, Whoop, Garmin Connect.

Personality: *Confident, sport-canonical, internationally familiar.*

Why this mood won:
- Cobalt + emerald palette doesn't read as regionally coded — works globally
- High retention potential through emerald accents on wins/achievements
- Tokens can be recolored later for white-label B2B contracts
- Builds on existing brand cues already in the app (the "PlaySnap" rounded display font in AuthView)

A live SwiftUI preview at `PlaySnapp/Shared/Design/MoodboardSamples.swift` renders this mood on real iPhone-sized surfaces. Open in Xcode Canvas to see the working baseline.

---

## 2. Mood 1 working palette

These hex values are the starting point. The designer may refine but should keep the relationships (e.g., primary stays cobalt, accent stays emerald).

### Light mode

| Role | Hex | Where it's used |
|---|---|---|
| **Primary** | `#1E40AF` Cobalt | Tab bar active state, primary CTA buttons, focus states, links |
| **Accent** | `#10B981` Emerald | Wins, "Win" pills, success states, score-up indicators |
| **Energy** | `#FB923C` Warm Orange | "Live now" indicators, streaks, attention badges |
| **Champion** | `#FACC15` Gold | Trophy moments, M25 final winner banner only |
| **Loss** | `#F87171` Coral | Losses, errors (soft, not aggressive — squads are friends) |
| **Surface** | `#FAFAF9` Warm White | App background — never pure white |
| **Card** | `#FFFFFF` White | Cards, sheets, modals |
| **Text Primary** | `#0F172A` Near-Black | Headlines, body text |
| **Text Secondary** | `#64748B` Slate | Captions, meta, timestamps |

### Dark mode (proposed — designer to finalize)

| Role | Hex | Notes |
|---|---|---|
| **Primary** | `#60A5FA` Light Cobalt | Brighter for dark backgrounds |
| **Accent** | `#34D399` Light Emerald | |
| **Energy** | `#FDBA74` Light Orange | |
| **Champion** | `#FDE047` Light Gold | |
| **Loss** | `#FCA5A5` Light Coral | |
| **Surface** | `#0F172A` Deep Navy | App background — never pure black |
| **Card** | `#1E293B` Slate-800 | |
| **Text Primary** | `#F8FAFC` Off-White | |
| **Text Secondary** | `#94A3B8` Light Slate | |

---

## 3. Deliverables organized in 4 tiers

Each tier builds on the previous. **Tier 1 is blocking** — no UI work can start until those are decided.

### Tier 1 — Foundation tokens (BLOCKING)

The smallest deliverables but every other piece depends on them.

| # | Item | What to deliver | Format | Effort |
|---|---|---|---|---|
| 1.1 | Color tokens (light mode) | 9 finalized hex codes | List | 30 min |
| 1.2 | Color tokens (dark mode) | 9 hex codes, dark variants | List | 30 min |
| 1.3 | Spacing scale | 6 values: e.g. `4, 8, 12, 16, 24, 32` (pt) | List | 15 min |
| 1.4 | Corner radius scale | 4 values: e.g. `4, 8, 12, 16` (pt) | List | 15 min |
| 1.5 | Shadow / elevation system | 3 levels (low/mid/high), each with y-offset, blur, opacity | Spec list | 30 min |
| 1.6 | Typography ladder | 6 roles (display, title, body, caption, meta, numeric) — font + weight + size + line-height for each | Spec table | 1 hr |

**Total Tier 1 effort: ~2.5 hours.**

### Tier 2 — Brand identity (HIGH PRIORITY)

Creates the first impression. Critical for App Store + retention.

| # | Item | Deliverable | Format | Notes |
|---|---|---|---|---|
| 2.1 | **App icon** | 1024×1024 master | PNG or full `.appiconset` | First thing users see on home screen |
| 2.2 | **Wordmark / logo** | "PlaySnapp" logotype | SVG + PNG @2x @3x | Used in splash, onboarding, marketing |
| 2.3 | **Splash screen** | Launch screen layout | Image or layout spec | Brand-background + wordmark |
| 2.4 | **Avatar placeholder** | Default avatar pattern (initials? icon? abstract?) | SVG or rule | Used everywhere users have no photo |
| 2.5 | **Champion celebration** | Trophy / podium illustration for bracket finale | SVG + PNG @2x @3x | M25 finale moment — screenshotable, shareable |

**Total Tier 2 effort: ~1–2 days** depending on illustration scope.

### Tier 3 — Component patterns (MEDIUM PRIORITY)

Reusable atoms that compose into every screen. Mostly mechanical once Tiers 1+2 are set.

| # | Component | States to design | Reusability |
|---|---|---|---|
| 3.1 | Primary button | Default, pressed, disabled, loading | Used on every CTA |
| 3.2 | Secondary button | Default, pressed, disabled | "Cancel", "Skip" |
| 3.3 | Text input field | Default, focus, error, with helper | Auth, score entry, profile edit |
| 3.4 | Card | Default, with photo, with header, pressed | Feed, brackets |
| 3.5 | Pill / chip / badge | Default, selected, with count | Reactions, seed badges, status |
| 3.6 | Reaction button | Default, my-reaction, pressed | Feed cards |
| 3.7 | Status indicator | Live, Scheduled, Completed, Cancelled | Game days, brackets |
| 3.8 | Tab bar item | Inactive, active, with badge | Bottom nav |
| 3.9 | Navigation header | With back, title only, with action | Every screen |
| 3.10 | Empty state container | Icon + headline + body + optional CTA | 7 empty states in app |
| 3.11 | Loading spinner | Inline + full-screen | Async operations |
| 3.12 | Error banner / toast | Error, warning, success | Feedback moments |
| 3.13 | Sheet / modal | Drag handle, header, content | Score entry, configure knockout |
| 3.14 | Score display | Large (hero), medium (cards), small (lists) | Mono font, weight variants |

**Total Tier 3 effort: ~1 day** if designed as a Figma library with variants.

**Quick win**: Components 3.1, 3.4, 3.5, 3.8 alone unlock ~80% of the visual restyling. Prioritize these.

### Tier 4 — Illustrations & motifs (LOW PRIORITY / ONGOING)

The "delight" layer. Ship without them, add later for retention boost.

| # | Item | Quantity | Notes |
|---|---|---|---|
| 4.1 | Empty state illustrations | 5 needed | Empty feed · No squad · No friends · No bracket · No notifications |
| 4.2 | Onboarding illustrations | 3 panels | Hero panels for first-launch onboarding |
| 4.3 | Confetti / celebration particles | Color/shape spec only | Implementation in SwiftUI; designer provides colors |
| 4.4 | Court motif background | Optional ambiance | Subtle line pattern (volleyball net, basketball key, etc.) for headers |
| 4.5 | Custom icons | Only what SF Symbols can't cover | Likely candidates: `roster`, `bracket-visual`, `fair-play-rotation` |
| 4.6 | App Store screenshots | 10 hero shots | Marketing — needed before public launch |

**Total Tier 4 effort: variable.** Each line-style illustration = 1–4 hours.

---

## 4. What gets built in SwiftUI code (designer does NOT design these)

To save design time, these are handled directly in code using the Tier 1 tokens. **No need to mock these in Figma**:

- Layouts (HStack, VStack, paddings) — token-driven, mechanical
- Most SF Symbol icons — free, system-managed, themable
- Standard animations (button press, fade, spring) — SwiftUI defaults
- Tap haptics — `UIImpactFeedbackGenerator`
- Pull-to-refresh — native
- Confetti animation — SwiftUI Canvas + particles (designer provides colors only)
- Sheet drag handles — native
- Material/blur backgrounds — `.regularMaterial`
- Light/dark mode switching — automatic if tokens defined per color scheme

---

## 5. Suggested sequence for the designer

```
Day 1: Tier 1 — all 6 token decisions          → unblocks code infrastructure
Day 2: Tier 2.1 (app icon) + 2.2 (wordmark)    → unblocks splash + brand presence
Day 3: Tier 3.1, 3.4, 3.5, 3.8 (4 components)  → unblocks 80% of UI restyling
Day 4–5: Remaining Tier 3 components           → polish phase
Week 2+: Tier 4 illustrations as time allows    → retention layer
```

**A fully themed app can ship at end of Day 3.** Tier 4 is iterative.

---

## 6. Delivery format checklist

When delivering, use these formats for cleanest integration:

| Asset type | Preferred format | Alternative |
|---|---|---|
| Colors | Hex codes in list / table | Figma color styles |
| Spacing / radius / typography | Spec table (number + role) | Figma text styles |
| Logo / wordmark | SVG (preferred) + PNG @1x @2x @3x | Single 4× PNG to downscale |
| Illustrations | SVG (preferred) | PNG @3x at intended display size |
| App icon | Single 1024×1024 PNG | Full `.appiconset` folder |
| Component specs | Figma frame (inspectable) | Screenshot + dimensions in description |
| Screen mockups | Figma frame (inspectable) | Screenshot + notes |

If using Figma, share the file URL — we can pull color/spacing/text styles directly via Figma MCP integration.

---

## 7. Component / screen inventory

For reference: here are all the surfaces in the current app that need restyling once tokens land.

### Existing feature areas

| Feature | Key views | Restyling priority |
|---|---|---|
| **Auth** | AuthView | High — first impression |
| **Onboarding** | OnboardingView (multiple) | High — first 5 minutes of user |
| **Feed** | FeedView, PlayCardView, ScheduledDayBanner | Highest — most-seen surface |
| **Camera** | CameraView | Medium — mostly system overlay |
| **Game** (+ Tournament bracket sub-tab) | GameDetailView, GameRoundView, GameBillboardView, BracketKnockoutView, etc. | High — screenshotable moments |
| **Bracket** | BracketListView, BracketDetailView, CreateBracketSheet | High — M21–M25 feature |
| **Friends** | FriendsListView, FriendRequestsView | Medium |
| **Profile** | ProfileView, ProfileEditView | Medium |
| **Notifications** | NotificationsView | Low |

### Total file count

105 Swift source files, 30 view files across 8 feature areas. Design tokens + 5–8 reusable components will cover the vast majority.

---

## 8. Strategic design principles to keep in mind

When making design decisions, weigh against these principles:

1. **B2B credibility from the first screenshot.** App Store screenshots are how schools/clubs/leagues will discover the app. Bracket views, champion banners, leaderboards should look like marketing material on their own.
2. **Avoid regional design cues.** No traditional red/yellow gold combinations, no traditional patterns — these mark the product as Vietnam-only and hurt international appeal.
3. **Photos are the hero, not the chrome.** User-posted match photos are the main content. UI should make photos shine, not compete with them.
4. **Warm grays, not cool grays.** Reads modern + human. Cool grays read corporate + sterile.
5. **Soft loss colors.** Friends shouldn't feel attacked by aggressive red. Use coral.
6. **Reserve gold for genuine champion moments.** Don't dilute the M25 finale by using gold elsewhere.
7. **Design scales to large rosters.** Don't bake "squad of 6" into layouts. Scrolling lists with sticky headers.
8. **Hint at white-label potential.** All brand colors via tokens means league/school recoloring is a 1-file change later.

---

## 9. References & inspiration

For the designer to look at:

| App | What to study |
|---|---|
| **Strava** | Athletic palette, photo-forward feed, achievement moments |
| **Hudl** | B2B sport SaaS aesthetic, dashboard polish |
| **Whoop** | Premium feel, dark mode, data visualization |
| **Garmin Connect** | Sport-credible iconography |
| **Letterboxd** | Card-based feed, social warmth without being too soft |
| **Apple Fitness+** | Hero typography, premium athletic feel |

For illustration style references:
- Strava 2023 onboarding illustrations
- Headspace illustration system (warmth without being childish)
- Apple Watch activity ring celebrations

---

## 10. Open questions to resolve with the founder

Before final design, confirm these:

1. **Localization scope**: Vietnamese-only? English-only? Both? Affects typography choices for diacritics.
2. **B2B contract specifics**: Will there be white-label deployments? If yes, tokens architecture is non-negotiable.
3. **Custom font budget**: SF Pro Rounded (free) covers Mood 1 sufficiently, but if there's budget for ~$200–500, a paid display font (e.g., Tobias, Söhne) could elevate the brand significantly.
### Resolved

- **App name**: confirmed as **PlaySnapp** (two Ps). The AuthView source code currently shows "PlaySnap" (one P) — a typo that needs fixing in code.
- **Mascot character**: **yes** — greenlit 2026-06-11 as a phased, design-led milestone (concept → static poses → celebration moments → animation). See `docs/implementation-plan.md` Milestone 28. The mascot absorbs the Tier 4.1 empty-state and Tier 4.2 onboarding illustration scope rather than adding to it.

---

*End of design ideas catalog. See `design-guide-EN.md` for the practical handover guide.*
