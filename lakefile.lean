import Lake
open Lake DSL

package «plausible-witness-dag» where
  -- Pure Lean library; no native build steps.

require plausible from git
  "https://github.com/leanprover-community/plausible" @ "v4.30.0"

@[default_target] lean_lib PlausibleWitnessDag where
  globs := #[.one `PlausibleWitnessDag, .submodules `PlausibleWitnessDag]

lean_exe «plausible-witness-dag-sample» where
  root := `PlausibleWitnessDag.Examples
