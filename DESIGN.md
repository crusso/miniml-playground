# Design Brief

## Direction

Brutalist Code Terminal — A scholarly ML interpreter that reads like a mathematician's notebook, not a generic dashboard.

## Tone

Intellectual minimalism with zero visual decoration. Sharp corners, high contrast monochrome, electric cyan accent only for active state and type information. Every pixel serves function.

## Differentiation

Monospace as the primary visual identity across headings and UI. Code is the hero; interface steps aside. Result type hints glow in cyan, creating a moment of clarity when type inference succeeds.

## Color Palette

| Token      | OKLCH         | Role                              |
| ---------- | ------------- | --------------------------------- |
| background | 0.12 0 0      | Deep charcoal, terminal darkness  |
| foreground | 0.9 0 0       | Near-white, high contrast         |
| card       | 0.16 0 0      | Slightly elevated surface         |
| primary    | 0.75 0.2 180  | Electric cyan, active accent      |
| muted      | 0.2 0 0       | Subdued grays for secondary text  |
| border     | 0.25 0 0      | Subtle separation lines           |

## Typography

- Display: Geist Mono — Heading hierarchy, code blocks, emphasized labels
- Body: General Sans — Descriptions, helper text, UI labels
- Scale: hero `text-2xl md:text-4xl font-bold tracking-tight font-display`, h2 `text-xl font-bold font-display`, label `text-label-upper`, body `text-sm text-muted-foreground`

## Elevation & Depth

No shadows. Depth through layering and opacity. Input boxes have 1px sharp borders; results render as cyan accents on dark fields.

## Structural Zones

| Zone    | Background  | Border              | Notes                               |
| ------- | ----------- | ------------------- | ----------------------------------- |
| Header  | card        | border-b border-muted | Title + subtitle + hint             |
| REPL    | card        | border border-border | Input area with monospace font      |
| Results | background  | —                   | Type (cyan), value, error (red)     |
| Gallery | background  | —                   | Grid of example cards with accents  |

## Spacing & Rhythm

8px base. Large vertical gaps (24px) between sections. Compact micro-spacing (4px) within component groups. Input + output bundled as 12px gaps.

## Component Patterns

- Buttons: Primary cyan, no rounding (1px), uppercase label `text-xs tracking-widest`
- Cards: 1px border `border-border`, no shadow, 1px inner radius
- Input: `border-border`, monospace font, cyan focus ring, code-input shadow on focus
- Badges: Cyan text on transparent background, monospace, `text-xs`

## Motion

- Entrance: Subtle fade-in (200ms ease-out) for result blocks
- Hover: No hover animation; focus state only. Border shift to accent on input focus.
- Decorative: None. Clean and direct.

## Constraints

- Absolute zero rounded corners except 1px (card-input separation)
- Never use drop-shadow; only border and background depth
- Monospace dominates visual hierarchy; sans-serif is always secondary
- No gradients, no opacity-based depth tricks

## Signature Detail

Cyan type hints glowing on dark terminals — a moment of mathematical clarity when inference succeeds. The interface celebrates the computation, not itself.
