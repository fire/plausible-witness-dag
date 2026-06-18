# plausible-witness-dag

A small Lean/Lake library for plausible-driven iterative-deepening witness searches.

The library factors the reusable search ladder, plausible `Fin`-bounded witness certification, and trace/outcome types out of Flowref. Domain packages provide their own deterministic walk and candidate predicate; this package owns the generic DAG-shaped escalation driver.

## Build

```sh
lake update
lake build
```

## Sample deterministic walk

`PlausibleWitnessDag.Examples` contains a minimal deterministic walk and matching
candidate predicate for the classic 3- and 5-gallon water-jug puzzle:

- `jugCandidate target lvl candidate` is the plausible-facing predicate.
- `jugReadback target steps` is the deterministic breadth-first walk/read-back.
- `runJugSample` runs both through the generic resolver.

Run the smoke test:

```sh
lake build plausible-witness-dag-sample
.lake/build/bin/plausible-witness-dag-sample
```
