# Math Dash — Product Requirements Document

**Math Dash** is a mobile game for Android and iOS that makes math practice fun for kids. Multiple players can share a single device, each with their own profile and progress.

**Target audience:** Kids ages 6–14, with math content spanning grades K–8.

**Platform:** [To confirm: Flutter recommended for cross-platform coverage]

**Business model:** Completely free — no ads, no in-app purchases, no subscriptions. All content, assets, and libraries used must be compatible with free, non-commercial educational use (open licenses preferred).

---

## Success Metrics

These focus on learning outcomes, not time-on-app:

- **Skill progression:** % of players who advance at least one skill from "challenging" to "comfortable" within their first 5 sessions
- **Accuracy improvement:** wrong-answer rate per skill decreases over successive attempts (player is actually learning, not just guessing)
- **Breadth of practice:** average number of distinct skill categories practiced per week (kids are exploring, not grinding one skill)
- **Challenge engagement:** % of correct answers that are 5-star (challenging-band) questions — higher = player is being appropriately stretched
- **Retention through learning:** D14 retention among players who advanced at least one skill level (learning = reason to return)

---

## Player Creation & Profile

When the app opens, the player selects their profile or creates a new one.

**Creating a new player:**
- Enter a name
- Select starting school grade (K–8)
- Customize basic appearance: skin tone, hair style/color, eye color, basic clothing. [Simple 2D avatar — no 3D required initially]

**Advanced customization** (hats, accessories, special clothing, gadgets, pets, vehicles) must be **earned** via points ("stars") — see *Redeeming Stars* section.

Multiple player profiles can exist on one device with no login required. [Assumption: no account/auth on first version; cloud save is opt-in — see *Saving User Data*]

---

## Gameplay Loop

Each **round** follows this sequence:

1. **Player select** — The current player can hand the device to another player at the start of any round.
2. **Spin the wheel** — A colorful wheel displays 4–8 math skills (selected from a larger pool, weighted toward skills the player needs to practice). Player taps to spin.
3. **Answer a question** — A question in the landed skill category appears at the player's current level for that skill.
4. **Result:**
   - **Correct answer at regular difficulty:** +3 stars, celebratory animation/sound.
   - **Correct answer at challenge difficulty** (near the edge of their ability): +5 stars, bigger celebration.
   - **Wrong answer:** 0 stars. A friendly step-by-step explanation guides the player to the correct answer. No penalty — the game stays encouraging.
5. Return to step 1.

### Answer Input

Input method is tied to the player's proficiency band for that skill:

- **Challenging band** → **Multiple choice** (4 options). Distractors are plausible (e.g. off-by-one, common conceptual mistakes). Reduces friction when the concept is unfamiliar.
- **Comfortable band** → **Typed numeric answer**. No hints from distractors; tests genuine recall and reinforces fluency.

This means the same player might type answers for skills they've mastered and pick from options for skills they're still developing.

### Timer [To confirm]
[Assumption: no hard timer by default, but a soft "thinking" animation plays after ~20 seconds to gently nudge the player. Confirm whether a countdown timer mode should exist as a toggle.]

### Multiplayer Turn Structure
When multiple players share a device, they **alternate rounds** in a single session (Player A spins → Player B spins → ...). Each player's stars and skill data update independently. A per-session leaderboard shows how many stars each player earned this session.

---

## Skill System & Adaptive Difficulty

The game tracks each player's proficiency **per skill** independently. A player's grade level is just the starting point — actual skill levels diverge over time.

### Skill Categories (examples — full list TBD)
- **Number sense:** counting, place value, comparing numbers
- **Addition & subtraction:** single-digit, multi-digit, mental math
- **Multiplication & division:** times tables, long multiplication/division
- **Fractions:** identifying, comparing, adding, multiplying
- **Decimals & percentages**
- **Geometry:** shapes, area, perimeter, angles
- **Measurement:** time, length, weight, volume
- **Word problems:** single-step, multi-step
- **Algebra basics:** patterns, simple equations, variables (grades 6–8)

### Adaptive Logic

Each skill has a **proficiency level** (e.g. 0.0–1.0) per player, updated after every answer:
- Correct answer → proficiency increases
- Wrong answer → proficiency decreases slightly (floor at 0)

Based on proficiency, each skill is classified into one of four bands:

| Band | Condition | Action |
|---|---|---|
| **Mastered** | Way above current level | Excluded from wheel (e.g. counting for a grade 5 player) |
| **Comfortable** | At or slightly above level | Included; correct = 3 stars |
| **Challenging** | Noticeably above current level | Included with lower probability; correct = 5 stars |
| **Not yet** | Far above current level | Excluded from wheel (e.g. calculus for grade 4) |

The wheel at any given round contains a **mix of comfortable + challenging** skills so the player always has a chance to earn 5-star questions but isn't overwhelmed.

### Question Generation

Questions must feel **infinite and varied** — repetitive or mechanical questions erode engagement. Two approaches to evaluate (not mutually exclusive):

**Option A — Large open-licensed dataset:**
Use an existing corpus of 1,000+ pre-authored questions (e.g. from open educational resources like Khan Academy's open content, OpenStax, or similar CC-licensed math question banks). Pros: questions feel human-crafted and interesting. Cons: finite; kids who play a lot will eventually see repeats.

**Option B — Batch AI-generated questions:**
Generate a large bank of questions (e.g. 5,000+) offline using an LLM, organized by skill and difficulty. Store them bundled with the app or as a downloadable pack. Questions are **not generated at runtime** — no cloud API calls during play. The batch can be periodically refreshed via app updates. Pros: effectively infinite variety, can be made fun/contextual (word problems with interesting scenarios). Cons: requires an offline generation pipeline.

**Recommended:** Combine both — start with an open licensed dataset for bootstrapping, and supplement with batch AI-generated questions to fill gaps and add variety. For wrong-answer explanations, these too are pre-generated (one explanation per question or per question template).

---

## Redeeming Stars

Stars are the in-game currency earned by answering correctly. Stars are spent on cosmetic upgrades only — no gameplay advantage is purchasable. The app is entirely free; stars cannot be purchased with real money.

### Milestone Unlocks

At certain cumulative star totals, the player **unlocks a new reward category** they can shop from. Milestone thresholds follow a roughly exponential curve:

| Milestone | Stars needed (cumulative) |
|---|---|
| 1 | 10 |
| 2 | 30 |
| 3 | 75 |
| 4 | 150 |
| 5 | 300 |
| 6 | 600 |
| … | … |

When a player hits a milestone, a celebration screen appears and they choose which **reward category** to unlock (they do NOT unlock all categories at once — choosing one makes it feel more personalized). Example categories: Pets, Hats & Accessories, Vehicles (cars, planes, rockets), Houses, Toys, Sports gear.

Items within each category have varying star costs. Cheaper items are available early; rarer/cooler items cost more.

### Shop
A persistent "Shop" or "Wardrobe" screen where players can:
- Browse owned and purchasable items
- Equip items to their character
- See how many stars they need to afford the next item

---

## Sound & Visual Design

- Bright, playful color palette appropriate for kids
- Animated character that reacts to correct/wrong answers (jumps, cheers, looks sad)
- Sound effects for: wheel spin, correct answer, wrong answer, milestone unlock, star collection
- Background music (loopable, upbeat, with a mute toggle)
- All UI copy uses simple language appropriate for the youngest end of the target age range

---

## Engagement Mechanics

- **Daily streak:** Playing at least one round per day maintains a streak. Streak milestones award bonus stars.
- **Daily challenge:** One special skill challenge per day with a bonus star reward.
- Push notifications for streak reminders (v2, requires parental consent flow on iOS/Android).

---

## Player Progress Screen

Each player can view their own progress from their profile — the goal is to **empower the player** to understand where they shine and what they can improve, not to report to an adult.

The screen shows:
- **Skill proficiency chart** — visual breakdown of current level per skill category (e.g. a radar/spider chart or color-coded grid)
- **Strengths** — skills currently in the "comfortable" band, highlighted positively
- **Growing edges** — skills in the "challenging" band, framed as exciting opportunities ("You're leveling up in fractions!")
- **Stars earned** — total and recent history
- **Sessions and questions answered** — simple stats the player can feel proud of
- **Milestones reached** — visual timeline of milestone badges unlocked

No PIN, no adult-only section. The data is the player's own, presented in a way that's motivating rather than evaluative.

---

## Onboarding

First-time experience:
1. "Create your player" screen (name, grade, basic avatar)
2. Brief animated tutorial showing the spin wheel and how to answer (1–2 screens, skippable)
3. First question is intentionally easy to create an early win

---

## Saving User Data

All player data (profiles, proficiency levels, star counts, milestones, equipped items) must be:
- **Stored locally** on the device with no account required for basic use
- **Backed up and restorable** across devices without a custom server

**Recommended approach:** Use platform-native cloud storage:
- **iOS:** iCloud (via `NSUbiquitousKeyValueStore` for small data, or CloudKit for structured data)
- **Android:** Google Play Games Services saved games, or Google Drive App Data

This piggybacks on the user's existing Apple/Google account — no custom auth, no custom server needed. If neither is available, local-only storage is the fallback.

---

## Content & Licensing

All third-party content, assets, and libraries must be compatible with free non-commercial educational distribution:

- **Math questions:** Open educational resources (OER) preferred — Creative Commons licensed datasets, Khan Academy open content, OpenStax, or similar. AI-batch-generated content is acceptable if generated offline and does not require an ongoing paid API subscription for players.
- **Art assets:** CC0 or CC-BY licensed sprite sheets and icons, or custom-created.
- **Music & sound effects:** CC0 or royalty-free with no attribution required (e.g. OpenGameArt.org, Freesound.org with appropriate licenses).
- **Fonts:** OFL (SIL Open Font License) or equivalent.
- **Libraries/frameworks:** MIT, Apache 2.0, BSD, or similar permissive licenses.

---

## Out of Scope (v1)

- Real-time multiplayer over the internet
- Teacher/classroom mode
- Timed quiz mode
- Leaderboards beyond the per-session summary
- Push notifications (v2)
