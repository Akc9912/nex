---
name: frontend-design
description: Use when building, changing, or reviewing user interfaces, screens, components, or forms. Prevents generic AI-looking UI and enforces design-system consistency, hierarchy, states, responsiveness, and accessibility.
---

# Frontend design

The goal is an interface that looks like part of this product, not a template.
Every element needs a reason to exist.

## Before designing

1. Inspect the existing design system: tokens (color, type, spacing), components,
   layout primitives. Check the project `AGENTS.md` for its location.
2. Read the related screens and their interaction patterns.
3. Answer, in one line each:
   - What is the user trying to get done here?
   - What information do they need first? What is secondary?
   - What is the primary action? Which actions are secondary?
   - What mistakes can they make, and how do they recover?
   - Which steps can be removed?
4. Do not design a screen in isolation when it belongs to an existing app.

## Avoid AI slop by default

These are not banned; each needs a design or functional reason:

- decorative gradients, glow backgrounds, indiscriminate glassmorphism
- cards inside cards; every section as a card; tables turned into card grids
- heavy borders and shadows; many accent colors
- badges for plain text; decorative icons; emojis instead of icons
- oversized type, giant buttons, padding used to fill space
- generic headings ("Overview", "Welcome back!") that add no context
- invented metrics or sample data to decorate dashboards
- repeated elements that carry no information
- modals for actions that could happen inline

## Hierarchy

- Rank content: key information, primary action, secondary actions, states and
  warnings, supplementary information. Not everything competes for attention.
- Express rank with size, weight, contrast, position, and spacing, using the
  existing scale rather than new values.

## Components

- Reuse design-system components first. Do not create near-duplicates or
  variants that differ only cosmetically.
- Extract a component when there is real reuse or a clear responsibility; avoid
  both monoliths and over-fragmentation.
- Separate presentation from logic when it improves maintainability.

## Responsive

- Design for desktop, tablet, and mobile. Adapt layout, navigation, hierarchy,
  tables, forms, and actions; do not just shrink elements.
- No accidental horizontal scroll or overflowing content.

## States

Handle the relevant ones: loading, empty, error, success, disabled, pending,
partial data.

- Empty states explain what is happening and, when useful, what to do next.
- Errors are understandable and offer a reasonable recovery action.

## Forms

- Visible labels; placeholders never replace them.
- Group related fields; mark required vs optional; do not ask for data the
  system already knows.
- Validate consistently; show errors next to the field; preserve user input.

## Accessibility

Semantic HTML, keyboard navigation, visible focus, sufficient contrast,
accessible names, screen-reader behavior, adequate target sizes, and
`prefers-reduced-motion`.

## Consistency and performance

- The app should read as one product. Check for an existing style before adding
  one; no per-module color schemes without a real need.
- Do not change global design tokens to fix a local problem.
- Avoid unnecessary re-renders, oversized bundles, and heavy dependencies for
  small features.
- Use user-facing language, not internal system terms.

## Review checklist

- Respects the design system and related screens?
- Clear hierarchy with one obvious primary action?
- Every element has a function; no slop pattern without a reason?
- No unnecessary components, variants, or modals?
- Generic pattern applied without considering the product?
- Any invented data or features?
- States, responsive behavior, and accessibility covered?
