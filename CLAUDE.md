# CLAUDE.md — UAV search-and-rescue simulation (SE5207)

Course team project for **System Simulation Technology (SE5207)**: a discrete-time Monte Carlo
simulation, in MATLAB, of a small UAV fleet searching a 40 × 40 grid for one missing person. The
deliverables are a ≥ 5,000-word paper and a ~10-minute, 12-slide talk. The code and its results are
**frozen inputs**; most work in this repo is writing about them.

## Sources of truth

Look facts up here; this file only caches what those files don't say.

| Need | Source |
|---|---|
| Model, detection law, strategies, N\* rule, experiments, limitations | `docs/requirement.md` (the spec) |
| *Why* each design choice was made, with evidence | `docs/research-notes.md` |
| Every tunable number | `matlab/config.m` (no other file holds a constant) |
| Reported numbers | `matlab/results/exp1..exp4*.csv` |
| Figures 1–5 | `matlab/figures/fig1..fig5*.png` |
| Citations `[1]`–`[13]` and where each is used | `docs/references/README.md` (`references.bib` mirrors it) |
| Paper structure, word budgets, member split | `docs/UAV_SAR_Paper_Outline.docx` |
| Talk | `docs/UAV_SAR_Slides.pptx` (12 slides, speaker notes) |

The full paper draft (`UAV_SAR_Simulation_Paper.docx`) and the team's working docs are kept
off-repo (Google Docs, linked from `readme.md`). `archive/` is a superseded first-draft stub; it is
never part of the simulation or the paper.

## Writing the paper or slides

- **Numbers come from the CSVs, never re-derived.** Quote probabilities to 3 decimals with their
  Wilson 95% interval (the `*_ci` column is the half-width). Name the figure or table each number
  comes from.
- **Significance, not ordering.** At saturation the two planned strategies (parallel track,
  probability-based) are statistically tied on every terrain; conclusions rest on overlapping
  intervals, not on which bar is taller.
- **The three research questions are fixed** (verbatim in the outline, §1.3). Keep exactly three.
- **Cite only the 13 numbered sources**, by their fixed number. A new source is a group decision.
- **Call the detection law what it is**: Koopman's random-search curve, a *conservative lower bound*
  for a systematic sweep (definite-range result `erf(πW/2S)` is better). Examiners probe this.
- **Nominal sweep width = 1 cell is a modelling unit**, chosen so track spacing = sweep width
  (C = 1). It is not a calibrated sensor figure; no drone sweep-width table exists [13].
- **N\* is defined, not discovered**: 3-point moving average → plateau = mean of last three smoothed
  points → smallest N reaching 95% of plateau. Accurate to about ±2 drones. The "< 2 pp per extra
  drone" rule was rejected because ±3 pp CI noise at P ≈ 0.9 swamps it.
- Outline writing rules: one claim per paragraph, no bullet lists in the body.

## Headline results (400 replications, from the CSVs)

| | Parallel track | Probability-based | Random walk |
|---|---|---|---|
| P(found), N = 1 | 0.040 | 0.365 | 0.048 |
| P(found), N = 20 | 0.943 | 0.963 | 0.540 |
| N\* | 14 | 15 | 18 |

- RQ1: the prior pays off only for small fleets; the N = 20 difference is not significant.
- RQ2: terrain lowers the planned strategies by **7.5–15.5 pp** vs open (parallel: forest −12.2,
  urban −13.5, mixed −7.5; probability-based: −10.2, −15.5, −7.5) without reordering them. Random
  walk is last everywhere except urban.
- RQ3: halving sweep width costs ~19 pp (parallel −18.8, probability-based −18.5, random −8.8) —
  larger than any strategy difference.

## Running the code

MATLAB only; set the current folder to `matlab/`.

```matlab
validate_sim     % must end "6 / 6 checks passed."
run_all          % verification, Exp 1–3, convergence (fig4) and sampling (fig5) checks
search_app       % interactive GUI: animate a mission, run a statistical analysis
```

- Seeds are fixed (map 7, targets 1000), so `run_all` reproduces every table and figure exactly on
  the same MATLAB version. Re-running it overwrites `results/` and `figures/` — only do that when a
  model change is agreed, because the paper quotes those numbers.
- `run_experiment2/3` load `results/exp1_fleet_size.mat` for N\*. `*.mat` is gitignored, so on a
  fresh clone run `run_experiment1` (or `run_all`) first.
- Each experiment script begins with `clear`, which wipes the caller's workspace; `run_all`
  recomputes its paths after every call for this reason.
- Strategy keys in code: `'parallel'`, `'prior'`, `'random'`. Map kinds: `'open'`, `'forest'`,
  `'urban'`, `'mixed'`. Terrain codes 1–4 = open, forest, urban, water.
- Common random numbers: the same target indices are reused across strategies and fleet sizes;
  keep that when adding any comparison.
- Missions always run the full 300 steps, even after detection, so `coverage` is not censored.
- The independence bound `1 − (1 − P₁)^N` applies to the random walk only. Parallel track beating
  it is expected (bands shrink with N), not a bug.

- `simulate_once.m` accepts `nTargets` so `search_app` can demo 1–5 people. That path is outside
  the verified study (its `validate_sim` checks were reverted in `8d74fb9`); every reported result
  is single-target.

## When prose and code disagree

Code and CSVs win. Fix the prose in the same change, so the docs, outline, slides and README stay in
step with `matlab/`.
