# Karde — Brand & UI Guide
**A 100% offline, zero-knowledge digital vault.**
Version 1.0

---

## 1. Brand Positioning

Karde is not a wallet app pretending to be a bank. It's a **vault** — the digital
equivalent of a safe-deposit box that never talks to a server. Every design
decision should reinforce three feelings, in this order:

1. **Impenetrable** — nothing about the interface should look soft, playful,
   or disposable. Depth, precision, and restraint over friendliness.
2. **Premium** — materials-driven visual language (metal, glass, brushed
   surfaces) rather than flat "fintech SaaS" cards and drop shadows.
3. **Calm** — because the data inside is sensitive, the UI itself should
   never feel busy, loud, or attention-seeking. One accent moment per screen.

**Tagline:** *Your secure, offline digital wallet.*

---

## 2. Logo

Three concepts are provided in `02_branding_sheet.svg` — full rationale below.

| Mark | Concept | Primary use |
|---|---|---|
| **A — Vault Monogram** | The letterform "K" is built from three strokes that leave a keyhole-shaped negative space at the center, ringed by a dashed circular track (a vault-door motif). This is the app icon and splash mark. | App icon, splash screen, favicon |
| **B — Shield & Lock** | A rounded shield silhouette with an integrated padlock shackle rendered in teal. Reads instantly as "security" without relying on a literal padlock icon alone. | In-app security badges, onboarding, empty states |
| **C — Stacked Cards** | Two overlapping card outlines, echoing the in-app stacked-card motif used on the Home dashboard. | Marketing site, social avatars, app store feature graphic |

**Construction notes**
- Keep a minimum clear-space around the mark equal to the width of one "K" stroke.
- The mark should never be recolored outside the palette below — gold on
  dark is the only approved combination for the primary mark.
- Do not place the mark on busy photography or light backgrounds; it is
  designed for the Obsidian surface.

---

## 3. Color Palette

Avoid generic "fintech blue." Karde's palette is built around **materials that
signal security and value** — brushed gunmetal, vault-door obsidian, and a
champagne-gold accent that reads as "premium metal," not "corporate trust
blue." A single cool teal is reserved exclusively for biometric and
confirmation moments, so it never competes with gold for attention.

| Color | Hex | Role |
|---|---|---|
| **Obsidian** | `#0A0C11` | App background |
| **Graphite** | `#161A23` | Cards, surfaces, sheets |
| **Champagne Gold** | `#C9A961` (gradient to `#E7D4A0` / `#9C7C41`) | Primary accent — CTAs, active states, security iconography |
| **Signal Teal** | `#2BD1C4` | Biometrics, success states, confirmations only |
| **Ember** | `#E5555C` | Destructive actions, validation errors |
| **Warm Ivory** | `#F4F1EA` | Primary text |
| **Slate** (secondary text) | `#9AA1B0` | Secondary/supporting text |
| **Graphite Text** (tertiary) | `#5C6472` | Placeholder text, disabled states, hairlines |

**Usage rule:** every screen gets *one* accent moment. If gold is doing the
work (a save button, a highlighted field), teal stays quiet, and vice versa.
Never mix gold and teal in the same call-to-action.

---

## 4. Typography

| Typeface | Google Font | Role |
|---|---|---|
| **Outfit** | [fonts.google.com/specimen/Outfit](https://fonts.google.com/specimen/Outfit) | Display — screen titles, headlines, empty-state headings. Weights 500/600. A geometric grotesk that feels modern and confident without being cold. |
| **Inter** | [fonts.google.com/specimen/Inter](https://fonts.google.com/specimen/Inter) | Interface & body — labels, buttons, descriptions, settings rows. Weights 400/500/600. Extremely legible at small sizes, the workhorse of the UI. |
| **Roboto Mono** | [fonts.google.com/specimen/Roboto+Mono](https://fonts.google.com/specimen/Roboto+Mono) | Sensitive data — card numbers, CVV, expiry, PIN digits. Monospaced with tabular figures so masked/unmasked digits never shift width, which matters when toggling the reveal-eye on a 16-digit number. |

**Type scale (base 16px / 1rem):**
- Screen title: Outfit 24–27px / 600
- Section header: Outfit 16–17px / 600
- Body / labels: Inter 14–15.5px / 400–600
- Field labels (all-caps micro-label): Inter 11–12px / 500, letter-spacing 1px
- Card numbers / mono data: Roboto Mono 15–17px, letter-spacing 1–2px

---

## 5. Core Components

- **Glass panel** — `rgba(255,255,255,0.045)` fill, `1px` hairline stroke at
  `rgba(255,255,255,0.10)`, 16–22px corner radius. Used for every list row,
  card, and sheet. Never stack more than one blur/glass layer on top of
  another — flat depth reads cleaner than nested glass.
- **Primary button** — Champagne Gold gradient fill, dark (Obsidian) text,
  16–18px corner radius, soft drop shadow. Reserved for the single most
  important action per screen ("Save to Vault," "Add your first item").
- **Destructive button** — Ember at 10–12% fill with a 1.3px Ember stroke and
  Ember text/icon. Never solid-filled — the outline treatment keeps it
  serious without looking alarming at rest.
- **Masked field** — Roboto Mono value with a trailing eye icon. Default
  state is always masked; tapping the eye reveals the value and auto-hides
  again after the timer set in Settings (15s/30s/60s).
- **Toggle** — Signal Teal when on, `rgba(255,255,255,0.10)` track when off.
  Teal is used here (not gold) because a toggle is a confirmation-adjacent
  control, not a primary CTA.

---

## 6. Screens Delivered

All mockups are 390×844pt (iPhone-class safe area) SVG files, presented in a
device frame for context. Files are vector — they can be scaled to any
resolution without quality loss, opened directly in Figma/Illustrator, or
used as a visual spec for Flutter implementation.

| File | Screen |
|---|---|
| `01_app_icon.svg` | App icon mark |
| `02_branding_sheet.svg` | Full brand guide poster (logo, palette, type, principles) |
| `03_pin_lock.svg` | Custom App PIN lock screen |
| `04_biometric_prompt.svg` | Biometric (fingerprint/Face ID) prompt overlay |
| `05_home_dashboard.svg` | Home — Tab 1 |
| `06_vault_list.svg` | Vault / items list — Tab 2 |
| `07_vault_empty.svg` | Vault — empty state |
| `08_item_detail.svg` | Secure item detail view |
| `09_add_edit_form.svg` | Add/Edit item form — default state |
| `10_add_edit_form_validation.svg` | Add/Edit item form — "Other" network + validation errors |
| `11_settings.svg` | Settings — Tab 3 |

---

## 7. UX Notes & Rationale

- **Offline badge on Home** exists purely for trust reinforcement — it's the
  first thing a security-conscious user looks for, so it's placed directly
  under the greeting, not buried in Settings.
- **Quick Access cards are intentionally overlapping/rotated (isometric-ish)**
  rather than a flat carousel — this is the one "hero" visual moment on the
  Home screen and it's meant to feel like glancing into an open drawer of cards.
- **The Ad Placeholder uses a dashed border and muted tone by design** — it
  should read as "reserved space," not compete with real content. When real
  ad content is wired in, keep the same dashed-frame treatment for a native
  ad unit if possible, or replace with a matching-radius card at the same
  position.
- **Empty vault state is the make-or-break screen** for new users — three
  fanned, dashed blank cards plus gold sparkle accents turn "you have
  nothing yet" into an invitation rather than a dead end.
- **Validation is real-time and specific.** A field never just turns red —
  it pairs the red state with an icon and a one-line, plain-English reason
  ("Card number can only contain digits") directly beneath the field.
- **"Other" network selection reveals a new field with a connecting dotted
  line and a "NEW FIELD" tag** — a small motion/attention cue so users
  don't miss that a new input just appeared below the dropdown.
- **Delete is never a single tap** — the mockup shows the destructive button
  at rest; implementation should require a confirmation dialog before
  permanently removing an encrypted item.

---

## 8. Implementation Notes for Flutter

- Load Outfit, Inter, and Roboto Mono via `google_fonts` or bundle as
  static assets for the fully-offline requirement (no network font fetch).
- Use `BackdropFilter` + low-opacity `Container` for the glass-panel effect;
  keep blur sigma modest (8–12) to preserve battery/performance on
  lower-end Android devices.
- Respect system reduced-motion settings — the biometric pulse and
  card-stack entrance should be the only two animated moments in the app;
  everything else should be instant or a simple 150–200ms fade.
- Card network logos: this guide intentionally uses text wordmarks
  ("VISA," "MASTERCARD," "AMEX") rather than reproducing trademarked
  network logos — source official brand assets directly from each network's
  press/brand-guidelines page before shipping.

---

*Karde Brand Guide v1.0 — 100% offline, zero-knowledge digital vault.*
