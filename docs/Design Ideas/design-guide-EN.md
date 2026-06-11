# PlaySnapp — Designer Handover Guide

*For the designer joining the PlaySnapp project.*
*Companion document: `design-ideas-EN.md` (the catalog of what to design).*

---

## Welcome — what you're working on

PlaySnapp is a private sports social app for squads of friends. Think: a small group of people who play volleyball / basketball / pickup soccer together, want to track their matches, share photos, and run friendly tournaments.

The app is iOS-first, built in SwiftUI. We have ~30 screens already functional but visually generic — they look like a default Apple template right now. Your work will transform them into a branded product that:
- Attracts users in international markets (English-speaking sport squads)
- Looks legitimate to Vietnamese B2B buyers (schools, clubs, athletic departments)
- Can be screenshot for App Store listings and sales decks

---

## The visual direction (already decided)

We chose **Mood 1 — Athletic Pro** as the working baseline. Think Strava / Hudl / Whoop — confident, sport-canonical, internationally familiar.

**Core feeling**: Modern athletic app. Confident, not corporate. Energetic on win moments, calm on everyday surfaces. Photo-forward (user match photos are the hero).

**See it live**: Open the project in Xcode → navigate to `PlaySnapp/Shared/Design/MoodboardSamples.swift` → open the Canvas pane → select the "Mood 1 Athletic Pro" preview. This is your starting reference.

**Working palette**:

```
Primary    #1E40AF  Cobalt        — main CTAs, tab bar active
Accent     #10B981  Emerald       — wins, success
Energy     #FB923C  Orange        — live, streaks
Champion   #FACC15  Gold          — trophy moments only
Loss       #F87171  Coral         — losses (soft, not aggressive)
Surface    #FAFAF9  Warm White    — app background
Card       #FFFFFF  White         — cards, sheets
Text       #0F172A  Near-Black    — headings, body
Meta       #64748B  Slate         — captions, timestamps
```

You can refine these but keep the *relationships* (primary stays in the cobalt family, accent stays in the emerald family, etc.).

---

## How to work — your day-by-day path

This is the suggested path. You don't have to follow it exactly, but the order minimizes blocking.

### Day 1 — Tokens (the foundation, 2.5 hours)

Lock down the smallest decisions that everything else depends on.

#### Step 1.1: Finalize the color palette

- Open Figma. Create a file called `PlaySnapp Design System`.
- Create a page called `01 — Tokens`.
- Drop down the 9 colors from the palette above as Figma color styles. Name them:
  - `color/primary`
  - `color/accent`
  - `color/energy`
  - `color/champion`
  - `color/loss`
  - `color/surface`
  - `color/card`
  - `color/text-primary`
  - `color/text-secondary`
- For each color, also create a dark-mode variant. (Figma supports this via variables or by adding a `/dark` suffix.)
- **Deliverable**: a list of 18 hex codes (9 light + 9 dark) in a table.

#### Step 1.2: Spacing scale

Decide a 6-value spacing scale. Standard iOS-friendly scale is:
```
4, 8, 12, 16, 24, 32
```
This is a 4-pt grid. You'll use these for padding, gaps, margins. **Deliverable**: confirm the values (or propose adjusted ones).

#### Step 1.3: Corner radius scale

Decide 4 values. Suggested:
```
4   — pills, small badges
8   — small chips, status indicators
12  — cards, buttons
16  — sheets, modals
```
**Deliverable**: confirm or propose.

#### Step 1.4: Shadow / elevation system

3 levels:
```
low     y: 2,  blur: 4,  opacity: 0.04   — pressed states
mid     y: 4,  blur: 12, opacity: 0.06   — cards, default
high    y: 8,  blur: 24, opacity: 0.10   — sheets, modals
```
**Deliverable**: confirm or propose.

#### Step 1.5: Typography ladder

Use **SF Pro Rounded** (free, ships with iOS — picks up the Apple Watch / fitness app vibe) for the display weight, **SF Pro** for body. Roles:

| Role | Font | Weight | Size | Line height | Usage |
|---|---|---|---|---|---|
| Display | SF Pro Rounded | Bold | 32 | 36 | Hero headlines (champion banner, big titles) |
| Title | SF Pro Rounded | Semibold | 20 | 24 | Section headers, screen titles |
| Body | SF Pro | Regular | 15 | 20 | Default text, paragraphs |
| Caption | SF Pro | Medium | 12 | 16 | Labels, timestamps, meta |
| Meta | SF Pro | Medium | 11 | 14 | Tiny labels, footnotes |
| Numeric | SF Pro Mono | Semibold | 15 | 20 | Scores, set scores, stats |

**Deliverable**: confirm the table or propose adjustments. Test that diacritics (Vietnamese accents like ă, ơ, ế) render well at all sizes.

---

### Day 2 — App icon + wordmark (1 day)

These are the highest-visibility deliverables. Focus on them once tokens are done.

#### Step 2.1: App icon

- Size: **1024×1024 pixels**, PNG, no transparency, no rounded corners (iOS applies the rounding automatically)
- Concept brief: should suggest sport + community without being literal (avoid: actual basketballs/volleyballs)
- Suggested directions to explore:
  - Abstract "S" mark in cobalt + emerald (S for Snap / Squad / Sport)
  - Stylized sport silhouette in single weight
  - Wordmark-style icon ("PS" lockup)
- Reference apps to study: Strava (orange chevron), Hudl (blue H), Spond (green spond), TeamSnap (red T)
- **Deliverable**: master 1024×1024 PNG. We'll generate all other sizes in code.

#### Step 2.2: Wordmark / logo

- Concept: "PlaySnapp" set in SF Pro Rounded Bold (or a custom-designed wordmark if you have budget/time)
- Create at least 2 variants:
  - **Full lockup**: wordmark + icon together (for splash screen, marketing)
  - **Wordmark only**: just "PlaySnapp" text mark (for in-app headers)
- Color variants needed:
  - On light background (text in primary cobalt or near-black)
  - On dark background (text in white or off-white)
  - Single-color reversed (white on cobalt)
- **Deliverables**: SVG files for each variant + PNG exports at @1x, @2x, @3x.

#### Step 2.3: Splash screen

The launch screen iOS shows while the app loads.

- Layout: brand wordmark centered on the Primary (cobalt) background
- Style: minimal, no extra text, no loading spinner (iOS handles that)
- **Deliverable**: layout spec or asset. Can be done as Xcode storyboard or single image asset.

#### Step 2.4: Avatar placeholder

What shows when a user has no profile photo yet.

- Suggested approach: colored circle with user's initials
- Color: pulled from a small palette (5–7 background colors based on user ID hash, so each user gets a consistent color)
- **Deliverable**: design spec showing 5–7 background color options + initial typography style.

#### Step 2.5: Champion celebration illustration

The big visual moment when a bracket tournament finishes — used on the M25 "🏆 Champion" screen.

- Concept: trophy + winning team name + confetti
- Style: single line-weight illustration, athletic but warm
- Composition: must work as both portrait phone screen and as a shareable / screenshottable image
- **Deliverable**: SVG illustration + PNG @1x @2x @3x

---

### Day 3 — Core components (4 components, 1 day)

These are the "quick win" components. Design them as Figma components with variants. They unlock ~80% of the app's visual restyling.

#### Step 3.1: Primary button

States to design (all using tokens):
- **Default**: cobalt background, white text, 12pt corner radius, 14pt vertical padding, full-width
- **Pressed**: cobalt darkened 10%, slight scale-down (0.97)
- **Disabled**: cobalt at 30% opacity, white text at 70%
- **Loading**: cobalt background, white spinner replacing text

**Deliverable**: Figma component with these 4 variants.

#### Step 3.4: Card

States:
- **Default**: white card on warm-white background, 16pt corner radius, mid-level shadow, 16pt padding
- **With photo**: photo bleeds to card edges minus corner radius, 4:3 or 16:9 aspect
- **With header**: avatar + name + meta at top
- **Pressed**: subtle scale-down (0.98), slightly stronger shadow

**Deliverable**: Figma component with these variants.

#### Step 3.5: Pill / chip / badge

States:
- **Default**: 8pt corner radius, surface color background, caption-sized text in text-primary
- **Selected**: primary color background, white text
- **With count**: pill with emoji + number (used for reactions)
- **Status variants**: Live (energy color), Scheduled (primary), Completed (accent), Cancelled (text-secondary)

**Deliverable**: Figma component with these variants.

#### Step 3.8: Tab bar item

States:
- **Inactive**: icon (24pt) + label (10pt) in text-secondary
- **Active**: icon + label in primary cobalt, slight bounce on transition
- **With badge**: small dot or count in energy color in top-right of icon

**Deliverable**: Figma component with these variants.

---

### Day 4–5 — Remaining components (polish)

Once the first 4 components land in code, design the remaining 10 components from Tier 3 (see `design-ideas-EN.md` for the full list). Same approach: Figma component with variants per state.

---

### Week 2+ — Illustrations (ongoing)

After everything above ships, work on Tier 4 illustrations one at a time:

- Start with **3 onboarding hero panels** (first-launch experience)
- Then **5 empty state illustrations**
- Then **App Store screenshots** before public launch

These are not blocking but significantly improve retention.

---

## How to deliver each file type

This is how to package your work so the developer can integrate quickly.

### Colors

Best: **Figma color styles** in the shared file. Developer pulls them directly via Figma MCP.

Alternative: **a markdown table or .txt file** with role + hex code:
```
color/primary       #1E40AF
color/accent        #10B981
color/energy        #FB923C
...
```

### Spacing / radius / shadows / typography

Best: **Figma text styles + effect styles** in the shared file.

Alternative: **a specification document** like this:
```
spacing/xs    = 4pt
spacing/sm    = 8pt
spacing/md    = 12pt
spacing/lg    = 16pt
spacing/xl    = 24pt
spacing/2xl   = 32pt
```

### App icon

- **File format**: PNG (no JPG)
- **Size**: 1024×1024 (we resize all other sizes in code)
- **Color profile**: sRGB
- **Naming**: `AppIcon-1024.png`

### Wordmark / logo

- **SVG** for vector use (preferred)
- **PNG @1x, @2x, @3x** at intended display sizes
- **Naming**: `wordmark-full-light.svg`, `wordmark-full-light@2x.png`, etc.

### Illustrations

- **SVG** when possible (single line-weight, easy to recolor)
- **PNG @1x, @2x, @3x** otherwise
- **Naming**: descriptive, e.g. `illust-empty-feed.svg`, `illust-onboarding-01-squad.svg`

### Component specs

- Best: **share the Figma file URL** with the developer. We can inspect each component's measurements directly.
- Alternative: **screenshots with annotations** showing dimensions, colors used (by token name, not hex), and state behavior.

### Screen mockups

- Best: **share the Figma file URL**. Annotate each screen with the token names used.
- Alternative: **annotated screenshots** in a PDF or shared doc.

---

## Communication checkpoints

| When | What | Why |
|---|---|---|
| End of Tier 1 | Show the founder all 6 token decisions | They're foundational — small fixes here save big rework later |
| Mid Tier 2 | Share 3 app icon directions | Lets the founder pick before you finalize 1 |
| End of Tier 2 | Full brand identity preview | First time the app gets a brand "feel" |
| Per Tier 3 component | Quick review before next | Catch inconsistencies early |
| Per illustration | Review before final export | Save export time |

For each handoff, expect feedback within 24 hours from the founder.

---

## Common pitfalls to avoid

1. **Don't use cool grays** (gray-blue tints like #6B7280). Use warm grays. Cool grays read corporate; warm grays read human.
2. **Don't make loss / error states bright red.** Use coral (#F87171). This is a friend-to-friend app — aggressive red feels wrong.
3. **Don't over-use gold.** Save it for the M25 champion finale. Otherwise it loses meaning.
4. **Don't bake "squad of 6" into layouts.** Use scrolling lists. B2B clients have rosters of 30+ players.
5. **Don't add traditional Vietnamese / Asian cultural cues** (red+gold combinations, traditional patterns). It marks the product as Vietnam-only and hurts international appeal.
6. **Don't compete with photos.** The Feed is primarily user-posted match photos. Card chrome should be minimal — let the photo be the hero.
7. **Don't design at 100% black or 100% white.** Use #0F172A / #FAFAF9 instead. Pure black/white reads cheap on modern OLED screens.
8. **Don't ship with rounded square photos.** Use the full card width with the photo bleeding to the edge. Modern feel.
9. **Don't use more than 5 colors per screen.** Pick 2–3 brand colors per screen + neutrals. Too many colors = visual chaos.
10. **Don't use thin font weights at small sizes** (under 14pt). They fail accessibility and look weak on small phones.

---

## When you're stuck — questions to ask the founder

- "Is this hex correct, or should I shift it?"
- "Should this component show / hide based on user role?"
- "Should this state be visually loud or subtle?"
- "Is this an organizer-only action or visible to all participants?"
- "Should this scale to larger team rosters (30+)?"

Don't guess on user-flow questions. Ask.

---

## Reference apps to study before you start

Spend 30 minutes each, take notes:

1. **Strava** — palette, achievements, feed
2. **Hudl** — B2B sport SaaS, dashboard polish
3. **Letterboxd** — social warmth, card-based feed
4. **Apple Fitness+** — premium athletic feel, hero typography
5. **Whoop** — dark mode done right, data visualization

For illustration style: study the Strava 2023 onboarding illustrations and Apple Watch activity ring celebrations. Single line-weight, single palette, slightly playful but not cartoonish.

---

## Tools you'll need

- **Figma** (free for individual designers)
- **iOS device or simulator** for testing how things look at actual scale
- **SF Symbols app** (free from Apple) to browse the icon set we use as a base
- **Figma MCP integration** (talk to the developer — lets the dev pull your styles directly from Figma without copy-paste)

---

## Final note

You have permission to push back on any spec in this document. The Mood 1 direction is locked, but everything else (spacing values, exact hex codes, component states) is negotiable if you have a better idea. The principles in section 8 of `design-ideas-EN.md` are the only hard constraints.

The goal is a product that *attracts users* and *converts B2B buyers*. Design accordingly. Good luck.

---

*See `design-ideas-EN.md` for the full catalog of what needs to be designed.*
