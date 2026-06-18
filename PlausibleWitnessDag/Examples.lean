import PlausibleWitnessDag

/-! # Plausible witness DAG examples

This module provides a common puzzle as a concrete deterministic walk paired with
the candidate predicate expected by `PlausibleWitnessDag.resolve`.

The sample is the classic 3- and 5-gallon water-jug puzzle: start with both jugs
empty, use fill/empty/pour moves, and reach exactly four gallons in the 5-gallon
jug. The shallow level cannot search enough moves, so it reports a budget hit.
The second level reaches the target and resolves the witness.
-/

namespace PlausibleWitnessDag.Examples

open PlausibleWitnessDag

abbrev JugState := Nat × Nat

/-- A deliberately tiny two-rung ladder for the jug puzzle.

L0 can inspect only four moves, while L1 can inspect eight. The standard 3/5 jug
solution to `(0, 4)` needs six moves, so L0 is unresolved and L1 resolves. -/
def jugLevels : Array Level := #[
  { idx := 0, walkSteps := 4, finBound := 256, numInst := 200 },
  { idx := 1, walkSteps := 8, finBound := 256, numInst := 200 }]

/-- Small stable encoding for plausible's natural-number candidate space. -/
def encodeJugState (s : JugState) : Nat :=
  s.1 * 10 + s.2

/-- Legal next states for the 3- and 5-gallon water-jug puzzle. -/
def jugSuccessors (s : JugState) : List JugState :=
  let a := s.1
  let b := s.2
  let pour3to5 :=
    let moved := min a (5 - b)
    (a - moved, b + moved)
  let pour5to3 :=
    let moved := min b (3 - a)
    (a + moved, b - moved)
  [ (3, b),      -- fill 3-gallon jug
    (a, 5),      -- fill 5-gallon jug
    (0, b),      -- empty 3-gallon jug
    (a, 0),      -- empty 5-gallon jug
    pour3to5,
    pour5to3 ].eraseDups

/-- Deterministic breadth-first walk for the jug puzzle.

Returns the first path to `target` whose length is at most `steps` moves. Paths
are stored in start-to-target order. -/
def jugWalk (steps : Nat) (target : JugState) : Option (List JugState) := Id.run do
  let start : JugState := (0, 0)
  let mut frontier : List (List JugState) := [[start]]
  let mut seen : List JugState := [start]
  let mut depth := 0
  let mut found : Option (List JugState) := none
  while found.isNone && depth <= steps && !frontier.isEmpty do
    let mut next : List (List JugState) := []
    for path in frontier do
      let current := path.getLastD start
      if current == target then
        found := some path
      else if depth < steps then
        for s' in jugSuccessors current do
          if !seen.contains s' then
            seen := s' :: seen
            next := next ++ [path ++ [s']]
    frontier := next
    depth := depth + 1
  found

/-- Plausible-facing candidate predicate for the jug puzzle.

A candidate is a witness at a given level iff it names the target state and the
level's deterministic walk budget can reach that state. -/
def jugCandidate (target : JugState) (lvl : Level) (candidate : Nat) : Bool :=
  candidate == encodeJugState target && (jugWalk lvl.walkSteps target).isSome

/-- Deterministic read-back for the jug puzzle. -/
def jugReadback (target : JugState) (steps : Nat) : Readback (List JugState) :=
  match jugWalk steps target with
  | some path =>
      { value := path, found := true, witnessIdx := encodeJugState target,
        budgetHit := false }
  | none =>
      { value := [], found := false, witnessIdx := 0,
        budgetHit := (jugWalk 100 target).isSome }

/-- Run the jug puzzle through the generic resolver. -/
def runJugSample (target : JugState := (0, 4)) : IO (List JugState × Nat × TraceEntry) :=
  resolve s!"3/5 water-jug puzzle to {target}" (jugCandidate target)
    (jugReadback target) jugLevels

def runSmokeTest : IO Unit := do
  let (path, lvl, trace) ← runJugSample (0, 4)
  IO.println s!"resolved level: L{lvl}"
  IO.println s!"path: {path}"
  IO.println s!"trace: {repr trace}"
  if lvl != 1 || path.getLast? != some (0, 4) then
    throw <| IO.userError "water-jug sample did not resolve at L1"

end PlausibleWitnessDag.Examples

/-- Executable smoke test for `lake build plausible-witness-dag-sample` and the
built binary. Lake executables need a top-level `main`. -/
def main (_args : List String) : IO Unit :=
  PlausibleWitnessDag.Examples.runSmokeTest
