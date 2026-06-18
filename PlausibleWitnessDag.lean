import Plausible

/-! # Plausible witness DAG

A reusable iterative-deepening driver for searches whose existence check is posed
to `plausible` and whose concrete witness set is read back by a deterministic
caller-provided walk.

Domain packages provide:

* a candidate predicate `Nat → Bool`, where `true` means the candidate is a
  witness;
* a deterministic reader for each walk-step budget, returning the recovered
  domain value plus whether a witness was found and whether the walk budget was
  exhausted.

This package owns the generic ladder, plausible `Fin`-bounded certification,
trace entries, and escalation policy.
-/

open Plausible

namespace PlausibleWitnessDag

/-- One rung of the iterative-deepening ladder. -/
structure Level where
  idx       : Nat       -- L0, L1, L2, …
  walkSteps : Nat       -- caller-defined deterministic walk budget
  finBound  : Nat       -- plausible `Fin N` candidate window
  numInst   : Nat       -- plausible instance count
  deriving Repr, Inhabited

/-- Default escalation ladder. L0 is cheap; higher rungs widen every budget. -/
def ladder : Array Level := #[
  { idx := 0, walkSteps := 64,    finBound := 256,   numInst := 200  },
  { idx := 1, walkSteps := 512,   finBound := 1024,  numInst := 800  },
  { idx := 2, walkSteps := 4000,  finBound := 4096,  numInst := 2000 } ]

/-- Outcome of one plausible query at a given level. -/
inductive Outcome
  | found        (witnessIdx : Nat)
  | provablyNone
  | budgetHit
  deriving Repr, DecidableEq, Inhabited

/-- A trace entry: which query resolved at which level, with what outcome. -/
structure TraceEntry where
  query   : String
  level   : Nat
  outcome : Outcome
  deriving Repr

/-- Deterministic read-back result for a caller-specific witness query. -/
structure Readback (α : Type u) where
  value       : α
  found       : Bool
  witnessIdx  : Nat := 0
  budgetHit   : Bool
  deriving Repr

/-- Run plausible at one ladder level.

Returns `true` when plausible found a counterexample to
`∀ w, ¬ candidateIsWitness w`, i.e. when a witness exists inside the level's
candidate window. -/
def certify (lvl : Level) (candidateIsWitness : Nat → Bool) : IO Bool := do
  let cfg : Plausible.Configuration := { numInst := lvl.numInst, quiet := true }
  match lvl.finBound with
  | 256 =>
      let p := NamedBinder "w" (∀ w : Fin 256, (! candidateIsWitness w.val) = true)
      let res ← Testable.checkIO p cfg
      pure res.isFailure
  | 1024 =>
      let p := NamedBinder "w" (∀ w : Fin 1024, (! candidateIsWitness w.val) = true)
      let res ← Testable.checkIO p cfg
      pure res.isFailure
  | _ =>
      let p := NamedBinder "w" (∀ w : Fin 4096, (! candidateIsWitness w.val) = true)
      let res ← Testable.checkIO p cfg
      pure res.isFailure

/-- Resolve one query across the ladder.

The candidate predicate gives plausible an existence problem. The deterministic
`readback` function, parameterized by the current `walkSteps`, recovers the
caller-specific result and tells the driver whether a missing witness is a real
negative or only a budget hit. -/
def resolve [Inhabited α] (query : String) (candidateIsWitness : Nat → Bool)
    (readback : Nat → Readback α) (levels : Array Level := ladder)
    : IO (α × Nat × TraceEntry) := do
  let mut chosen : α := default
  let mut lvlIdx := 0
  let mut outcome : Outcome := .provablyNone
  let mut resolved := false
  for lvl in levels do
    if ¬ resolved then
      let _failure ← certify lvl candidateIsWitness
      let rb := readback lvl.walkSteps
      lvlIdx := lvl.idx
      chosen := rb.value
      if rb.found then
        outcome := .found rb.witnessIdx
        resolved := true
      else if ¬ rb.budgetHit then
        outcome := .provablyNone
        resolved := true
      else
        outcome := .budgetHit
  pure (chosen, lvlIdx, { query, level := lvlIdx, outcome })

end PlausibleWitnessDag
