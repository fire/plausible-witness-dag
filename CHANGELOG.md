# CHANGELOG

## Conventions

- This package stays domain-neutral: callers provide candidate predicates and deterministic witness readers.
- Plausible remains the only theorem-search dependency.

## 2026-06-18 — Initial scaffold

- Extracted the iterative-deepening witness ladder, plausible certification, trace entries, and generic resolver into a standalone Lean/Lake package.
- Verified the package with `lake build` before publishing.

## 2026-06-18 — Water-jug sample

- Added a classic 3- and 5-gallon water-jug puzzle sample with a deterministic breadth-first walk and matching plausible candidate predicate.
- Added the `plausible-witness-dag-sample` executable smoke test.
