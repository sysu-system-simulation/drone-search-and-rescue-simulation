# Research grounding — UAV SAR simulation

Purpose: replace assumption-driven design — the first AI-generated draft and an earlier Python
prototype — with something a reviewer can check. Every claim below has a source.

This is the evidence trail behind the design decisions, not a citation list. The canonical, numbered
references used by the paper are in [`docs/references/`](references/).

---

## Finding 1 — Only ONE of the proposed strategies is valid for multiple aircraft

IAMSAR Volume II, Chapter 5 is the governing doctrine for maritime/aeronautical search.

| Pattern | Geometry | Who it is for |
|---|---|---|
| Parallel track (PS) | parallel legs along the long side of a rectangle | **explicitly designed for several searchers** — the area is split into sub-areas |
| Creeping line (CS) | parallel legs along the short side | aircraft + vessel coordination |
| Expanding square (SS) | legs S, S, 2S, 2S, 3S… from a datum | **single facility**; IAMSAR states it must not be run by several aircraft at similar altitude |
| Sector (VS) | radial legs with 120° turns around a datum | **single aircraft** (one aircraft + one vessel may pair) |
| Trackline (TS) | along the missing craft's route | one or several units |

**Consequence:** running one expanding square or one sector search across the whole fleet is not
IAMSAR-valid. A fleet version needs a redefinition (split the datum area and give each aircraft its
own expanding square), which is a research contribution that cannot be defended in a course project.

## Finding 2 — Track spacing is equal to sweep width, not twice it

Coverage ratio C = W/S, where W is the effective sweep width and S the distance between tracks.
USCG doctrine uses **C = 1.0, i.e. S = W**. A worked source example: 1 NM sweep width, 2 NM spacing
→ C = 0.5.

Sweep width is defined as the integral of the lateral range curve, W = ∫p(x)dx — it is not a
"vision radius" and not a made-up probability.

My earlier note claiming "S ≈ 2W is standard" was wrong: 2W is simply the half-coverage case.

## Finding 3 — The detection formula we should use, and the one we must not mislabel

Random search (Koopman): **P = 1 − exp(−W·v·t / A)** with C = W·v·t/A.

That formula is a *lower bound*, valid for poorly informed effort. A well-spread systematic parallel
sweep does better — Koopman's definite-range result is P = erf(πW/2S), about 78% at C = 1, versus
63% for 1 − e^−C.

**Consequence:** we may use 1 − e^−C, but we must call it the conservative/poor-conditions curve and
not "the POD of a systematic search". This distinction is exactly what a picky examiner probes.

Cell-level implementation: with cell size equal to track spacing S, the per-pass detection
probability is p = 1 − exp(−W_terrain/S), and k passes give 1 − (1−p)^k = 1 − exp(−k·C). This makes
every detection number traceable to one cited formula instead of invented values.

## Finding 4 — Terrain as a multiplier on sweep width is legitimate

IAMSAR supplies sweep-width tables by object, sensor, altitude, visibility and terrain, with
multiplicative correction factors (Tables N-4 … N-10). So modelling terrain as a scalar that
scales W is faithful practice, not a shortcut.

**Reject:** terrain that changes UAV speed but not W. That inverts the physics.

## Finding 5 — There is no closed-form optimal fleet size

Published data points:

- 4 drones → >91% of victims, 8 → >99% (Haddad et al., *Sensors* 2023)
- 20 UAVs → 19.9/20 targets, 99.8% coverage (Shao et al., EURASIP JASP 2021)
- improvement rate falls beyond N ≈ 20 (Ghassemi & Chowdhury 2019)
- +1 UAV cuts median find time ≈23%, gains "likely marginal" for large teams (arXiv:2107.08834)

So "optimal fleet size" must be *defined* by us, not discovered. Implemented definition (in
`optimal_n.m`): **N\* is the smallest fleet size whose detection probability reaches 95% of the
plateau P(Nmax)**, where the curve is smoothed with a 3-point moving average and the plateau is the
mean of the last three smoothed points. A confidence interval is reported with every point. The
smoothing keeps N\* from jumping between neighbouring values when one fleet size happens to receive
a lucky or unlucky sample.

Why not the stricter "every further drone adds < 2 percentage points" rule: with 400 replications
the 95% interval near P = 0.9 is about ±3 pp, so a 2 pp marginal-gain test is inside the noise, and a slowly
rising curve never satisfies it. The 95%-of-plateau rule uses all points and is stable. The
marginal-gain curve is still plotted as supporting evidence.

Sanity check available in closed form: if every drone runs the *same* whole-map search independently,
P_N = 1 − (1 − P_1)^N. Two independent searchers therefore cannot beat that bound (with a common
target the bound is an upper bound by Jensen, because hard-to-find targets are hard for everyone).
`validate_sim.m` applies it to the random-walk baseline.

**The bound does NOT apply to parallel track.** There the map is partitioned, so each drone's band —
and therefore its per-drone detection probability — changes with N. In practice P_N for parallel
track rises far faster than 1 − (1 − P1)^N. Treating that as a bug would be a mistake; it is a
consequence of the experimental design.

---

## Finding 6 — The nominal sweep width cannot be calibrated from published tables

IAMSAR gives sweep widths by object, sensor and visibility, but those tables are for manned assets:
a person in the water viewed from a vessel at a conventional eye height is about 0.2 NM.

No equivalent table exists for small multirotor sensors. Sulaiman and Pierce (2023) state this
explicitly while modelling helicopter sweep widths in the visible/infrared bands.

**Consequence:** the nominal width of one grid cell is a *modelling unit*, chosen so that track
spacing equals sweep width (the documented full-coverage convention C = W/S = 1). It is not a
calibrated physical measurement, and the paper says so in §7.2. Using the 0.2 NM figure would make
every pass close to certain and would require a different grid resolution and a full re-run.

---

## What changes as a result

**Strategy set — cut from 5 to 3.** This is the main "less work, more defensible" decision.

| Kept | Why |
|---|---|
| S1 Parallel track | IAMSAR-valid for multiple searchers; the systematic baseline |
| S2 Probability-based | the literature-standard "smart" strategy; uses the search prior |
| S3 Random walk | the null baseline; shows what intelligence buys |

**Cut:** expanding square and IAMSAR sector (not swarm-valid, Finding 1), adaptive cooperative
(needs inter-drone communication and task reallocation — the most code and the least standardised
part of the draft).

**Detection model rewritten:** per-pass p derived from p = 1 − exp(−W/S) with per-terrain W
multipliers, replacing the arbitrary constants 0.55/0.25/0.32/0.05.

**Experiments — cut from 5 to 3:**

1. **Fleet-size saturation on the open map** (N = 1…20, 3 strategies, equal mission time).
   Output: saturation N per strategy, marginal-gain curve, comparison against 1 − (1 − P_1)^N.
2. **Strategy comparison at each strategy's own optimal N, across 4 terrains.**
   Question: does the ranking from Experiment 1 hold when terrain changes?
3. **Sweep-width sensitivity** (W scaled ×0.5 / ×1 / ×2) — cheap, because it only changes one
   multiplier, and it answers the draft's "sensor reliability" experiment.

Deferred: cost-effectiveness (no cost data from the team) and the animation (nice-to-have, not
scored on simulation quality).

---

## Implemented in MATLAB (`matlab/`)

| File | What it encodes |
|---|---|
| `config.m` | every number: grid 40×40, 20 s/step, 300 steps, sweep width 1 cell, terrain multipliers |
| `make_scenario.m` | 4 terrain maps, the search prior, and `detP = 1 − exp(−W_terrain·scale)` |
| `boustrophedon.m` | the lawn-mower sweep of one rectangle (shared by both systematic strategies) |
| `rank_blocks.m` | blocks sorted by prior mass — the only "intelligence" S2 gets |
| `simulate_once.m` | one mission: movement, per-visit detection trial, coverage |
| `optimal_n.m` | N\* = 95% of plateau (definition above) |
| `wilson_ci.m` | 95% confidence interval for a proportion |
| `run_experiment1.m` | fleet-size saturation on the open map (N = 1…20) |
| `run_experiment2.m` | the 3 strategies at their own N\*, on 4 terrains |
| `run_experiment3.m` | sweep width ×0.5 / ×1 / ×2 |
| `validate_sim.m` | 10 self-checks: prior sums to 1, detection MC, independence bound, coverage, reproducibility, N\* rule, multi-target counts, multi-target determinism, single-target contract, target-index validation |
| `plot_scenario.m` | terrain + prior + tracks figure for the paper |
| `run_all.m` | verification, then the three experiments |

The Python package in `uavsar/` is kept only as an archived prototype; it is not part of the
submission.

---

## Sources

- IAMSAR Manual, Vol. II, Ch. 5 (2019 extract):
  https://cranston.independent-inquiry.uk/wp-content/uploads/cranston-evidence/INQ010511_Extract_from_IAMSAR__International_Aeronautical_and_Maritime_Search_and_Rescue__Manual__Chapter_5_of_Volume_II__2019_Edition.pdf
- IAMSAR overview (IMO): https://www.imo.org/en/OurWork/Safety/Pages/IAMSARManual.aspx
- Search pattern geometry: https://www.marineteacher.com/post/iamsar-search-patterns
- NZ Coastguard search techniques (C = W/S worked example):
  https://www.coastguard.net.nz/sartr/modules/pdfs/Module_SearchTechniques.pdf
- Frost & Stone, *Review of Search Theory: Advances and Applications to Search and Rescue* (2001):
  https://static1.squarespace.com/static/66df04513496457821598763/t/6799a10d0dfa7e33f9578e39/1738121487706/Review+of+Search+Theory_Advances+and_Applications_to_Search_and_Rescue_Decision_Support_2001.pdf
- Perkins & Lovelock, lateral range curves (2008):
  https://tcsr.org.uk/media/p2kpnbjo/2008-lateral-range-curves-search-probabilities-and-grid-searching.pdf
- Koopman, "The theory of search II", *Operations Research* 4(5), 1956.
- Haddad et al., *Sensors* 23(23):9540, 2023: https://www.mdpi.com/1424-8220/23/23/9540
- Shao et al., EURASIP JASP 2021: https://asp-eurasipjournals.springeropen.com/articles/10.1186/s13634-021-00807-6
- Ghassemi & Chowdhury 2019: https://arxiv.org/abs/1905.09988
- Sulaiman & Pierce 2023: https://arxiv.org/abs/2304.00983

Unverified: per-pattern IAMSAR paragraph numbers; Vincent & Rubin's N_min formula (second-hand).

The numbered list the paper cites, with a map of what each source supports, is in
[`docs/references/README.md`](references/README.md).
