# CHANGELOG

## Conventions

- This package stays domain-neutral: callers provide candidate predicates and deterministic witness readers.
- Plausible remains the only theorem-search dependency.

## 2026-06-18 — Initial scaffold

- Extracted the iterative-deepening witness ladder, plausible certification, trace entries, and generic resolver into a standalone Lean/Lake package.
- Verified the package with `lake build` before publishing.
