# plausible-witness-dag

A small Lean/Lake library for plausible-driven iterative-deepening witness searches.

The library factors the reusable search ladder, plausible `Fin`-bounded witness certification, and trace/outcome types out of Flowref. Domain packages provide their own deterministic walk and candidate predicate; this package owns the generic DAG-shaped escalation driver.
