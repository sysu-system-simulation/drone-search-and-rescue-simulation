# UAV Search and Rescue Simulation (MATLAB)

Discrete-time Monte Carlo simulation of a small UAV fleet searching for one missing person on a
gridded map. Three search strategies are compared across four terrain types.

Course project for **System Simulation Technology (SE5207)**.

## Model

- 40 x 40 grid, 100 m cells (4 km x 4 km), 300 steps of 20 s per mission.
- Detection of one pass: `p = 1 - exp(-W_eff / S)`, with `W_eff` the sweep width multiplied by a
  terrain factor (open 1.00, forest 0.55, urban 0.45, water 0.20). Repeated passes compound as
  `1 - (1-p)^k`.
- Strategies: parallel track, probability-based (blocks ranked by the search prior), random walk.
- 400 replications per configuration, Wilson 95% confidence intervals.

## Run

To open the interactive interface, set MATLAB's current folder to `matlab/` and run:

```matlab
search_app
```

Choose terrain, strategy, drone count, number of people (1–5), playback delay,
and a random seed. **Run animated mission** shows one search, the number of
people found, the time to find everyone when successful, and coverage. Targets
are visible in red before detection and turn green when found; these locations
are shown for visualization and are not given to the search strategies.
**Run statistical analysis** runs the selected number of independent missions
and reports the rate of finding everyone, its Wilson 95% confidence interval,
the average number of people found, and average coverage. Each person is sampled
independently from the same prior, so multiple people may occupy the same cell.
Mission and analysis results appear in separate tables with their run settings.
The same seed and settings reproduce a run; **New seed** chooses a
fresh one. Pause and resume playback, adjust its delay while it runs, or stop
playback or analysis. The map key identifies terrain and search markers; use
**Show target-likelihood contours** to toggle the red prior contours. These
contours show likely locations, not the person's actual position. The map is
fixed for each terrain type; the seed controls mission randomness.

To run the command-line experiments:

1. Open MATLAB and set the current folder to `matlab/`.
2. Run the self-checks first:

   ```matlab
   validate_sim
   ```

   It must print `6 / 6 checks passed`.

3. Run the three experiments:

   ```matlab
   run_all
   ```

4. Optional scenario figure:

   ```matlab
   plot_scenario('mixed', 5)
   ```

5. Watch one simulated mission:

   ```matlab
   animate_search('mixed', 'parallel', 5)
   ```

   The map shows the drones, visited cells, and the person once detected. Red
   contours show likely target locations. Choose `open`, `forest`, `urban`, or
   `mixed` terrain and `parallel`, `prior`, or `random` search. A fourth argument
   controls the pause per step in seconds, for example `animate_search('mixed',
   'prior', 5, 0.02)`. The mission continues after detection to show full coverage.

Outputs are written to `results/` (CSV and MAT) and `figures/` (PNG).

## Results (400 replications per point)

| | Parallel track | Probability-based | Random walk |
|---|---|---|---|
| N = 1 | 0.040 | 0.365 | 0.048 |
| N = 20 | 0.943 | 0.963 | 0.540 |
| N* | 14 | 15 | 18 |

Detection probability at each strategy's own N*, by terrain:

| Terrain | Parallel | Probability-based | Random |
|---|---|---|---|
| Open | 0.895 | 0.885 | 0.525 |
| Forest | 0.773 | 0.783 | 0.458 |
| Urban | 0.760 | 0.730 | 0.635 |
| Mixed | 0.820 | 0.810 | 0.573 |

Sweep width x0.5 / x1 / x2: parallel 0.708 / 0.895 / 0.985, probability-based
0.700 / 0.885 / 0.983, random 0.438 / 0.525 / 0.603.

Three findings: prior-guided search wins only for small fleets; the two planned strategies are
statistically tied at saturation on every terrain; sensor quality matters more than strategy choice.

N* is defined, not discovered: the curve is smoothed with a 3-point moving average, the plateau is
the mean of the last three points, and N* is the smallest fleet reaching 95% of that plateau.

## Figures

| File | Content |
|---|---|
| `figures/fig1_fleet_size.png` | detection probability vs fleet size, three strategies, N* marked |
| `figures/fig2_terrain.png` | strategy comparison across four terrains |
| `figures/fig3_sweep_width.png` | sensitivity to sweep width |
| `figures/fig4_convergence.png` | running estimate and 1/sqrt(n) half-width |
| `figures/fig5_prior_sampling.png` | inverse-transform validation |

## Related documents

The writing outline and the slide deck are in [`../docs/`](../docs). The paper draft is kept
off-repo; see the top-level README for the collaboration links.

## Files

| File | Purpose |
|---|---|
| `config.m` | all parameters |
| `make_scenario.m` | terrain, search prior, detection map |
| `boustrophedon.m` | lawn-mower path over a rectangle |
| `rank_blocks.m` | map blocks sorted by prior mass |
| `simulate_once.m` | one mission of the fleet |
| `animate_search.m` | animate one mission using the simulation's recorded positions |
| `search_app.m` | interactive mission animation and statistical analysis |
| `optimal_n.m` | saturation fleet size N* (95%-of-plateau rule) |
| `wilson_ci.m` | 95% confidence interval |
| `run_experiment1.m` | fleet-size saturation |
| `run_experiment2.m` | strategy comparison across terrain |
| `run_experiment3.m` | sweep-width sensitivity |
| `run_convergence.m` | Monte Carlo convergence: running estimate and 1/sqrt(n) uncertainty |
| `check_sampling.m` | inverse-transform validation: simulated vs analytical prior |
| `validate_sim.m` | six model self-checks |
| `plot_scenario.m` | scenario figure |
| `style_figure.m` | light, print-friendly figure styling |
| `run_all.m` | verification + the three experiments + course-method checks |

## References

- IAMSAR Manual, Vol. II, Ch. 5 (search patterns and sweep width), 2019.
- B. O. Koopman, "The theory of search II", *Operations Research* 4(5), 1956.
- L. D. Stone, *Theory of Optimal Search*, Academic Press, 1975.
- M. N. Haddad et al., *Sensors* 23(23):9540, 2023.
- R. Shao et al., *EURASIP J. Adv. Signal Process.*, 2021.
- A. Sulaiman & K. Pierce, arXiv:2304.00983, 2023 (no drone sweep-width tables exist).
