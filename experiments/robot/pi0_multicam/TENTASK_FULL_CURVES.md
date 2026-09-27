# pi0.5 + RoboTwin - complete 5-task × 4-budget frontier (norm/ADP/FastV/Team)

Extends the task-expansion with the full keep-ratio sweep (0.25 / 0.375 / 0.5 / 0.625) on all usable
tasks. Usable tasks (base SR > 0 under fixed noise): click_bell, click_alarmclock, place_empty_cup,
grab_roller, place_object_stand (5). 12 ep/task, fixed noise. Core methods: base + norm/ADP/FastV/Team.
(SigLIP / SigLIP-SAM were run at 0.625 only; norm is the T3R representative.)

## 5-task average SR (base = 33.3)

Rates pool integer successes across the five tasks (60 episodes per method/budget),
using one final matched 12-episode record per task and rounding only the aggregate.

| tok/cam (keep) | norm | ADP | FastV | Team |
|---|---|---|---|---|
| 64 (0.25) | 13.3 | 13.3 | 11.7 | 3.3 |
| 96 (0.375) | 25.0 | 13.3 | 23.3 | 11.7 |
| 128 (0.5) | 33.3 | 21.7 | 18.3 | 15.0 |
| 160 (0.625) | **38.3** | 25.0 | 28.3 | 15.0 |

**Norm matches base at keep 0.5 and exceeds it at keep 0.625 (+5.0 pp); below base at 0.375/0.25.
ADP/FastV/Team are below base at EVERY budget. norm dominates the other reducers throughout.**

**Numerical correction (2026-09-26):** The earlier 128-token competitor averages
included both preliminary and final `click_bell` records. Keeping one record per
task gives ADP 13/60 (21.7%), FastV 11/60 (18.3%), and TeamVLA 9/60 (15.0%).
The baseline is 20/60 (33.3%), computed before rounding the task percentages.
T3R's counts and all raw result files are unchanged.

## Per-task norm curve (task-dependence)

| task | base | 0.25 | 0.375 | 0.5 | 0.625 |
|---|---|---|---|---|---|
| click_bell | 41.7 | 33.3 | 58.3 | 66.7 | 75.0 |
| click_alarmclock | 41.7 | 16.7 | 41.7 | 50.0 | 58.3 |
| place_empty_cup | 41.7 | 16.7 | 25.0 | 41.7 | 50.0 |
| grab_roller | 25.0 | 0.0 | 0.0 | 8.3 | 8.3 |
| place_object_stand | 16.7 | 0.0 | 0.0 | 0.0 | 0.0 |

norm scales cleanly and beats base on the 3 reach/press/place-cup tasks (from keep ~0.5 up), but
**collapses to 0-8% on grab_roller and place_object_stand at every budget** - pruning destroys the fine
visual detail those tasks need.

## Full per-task method values at each budget (base row per task)

| task | budget | base | norm | ADP | FastV | Team |
|---|---|---|---|---|---|---|
| place_empty_cup | 0.25 | 41.7 | 16.7 | 25.0 | 16.7 | 0.0 |
| place_empty_cup | 0.375 | 41.7 | 25.0 | 8.3 | 25.0 | 0.0 |
| place_empty_cup | 0.5 | 41.7 | 41.7 | 33.3 | 16.7 | 0.0 |
| place_empty_cup | 0.625 | 41.7 | 50.0 | 33.3 | 50.0 | 0.0 |
| grab_roller | 0.25 | 25.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| grab_roller | 0.375 | 25.0 | 0.0 | 0.0 | 33.3 | 25.0 |
| grab_roller | 0.5 | 25.0 | 8.3 | 0.0 | 8.3 | 16.7 |
| grab_roller | 0.625 | 25.0 | 8.3 | 0.0 | 8.3 | 16.7 |
| place_object_stand | 0.25 | 16.7 | 0.0 | 0.0 | 0.0 | 0.0 |
| place_object_stand | 0.375 | 16.7 | 0.0 | 16.7 | 8.3 | 0.0 |
| place_object_stand | 0.5 | 16.7 | 0.0 | 25.0 | 16.7 | 0.0 |
| place_object_stand | 0.625 | 16.7 | 0.0 | 25.0 | 16.7 | 0.0 |

(click_bell / click_alarmclock full curves are in prior commits / pi0_multicam.)

## Conclusion (fully characterized)
On a diverse 5-task set, pi0 token-pruning gives at best a **small average win (+5) and only at low
pruning (keep >= 0.625)**; it is neutral at keep 0.5 and **harmful below that**, and is **strongly
task-dependent** - big gains on reach/press/place-cup, total collapse on grasp/place-on-stand. The
baselines (ADP/FastV/Team) never beat base at any budget. The original pi0 "+25 over base" was an
artifact of the two favorable click tasks; the honest cross-task result is a modest, conditional gain.

Raw: `compare_k50norm_results.csv`, `t3rfill_results.csv`, and `fulltable_results.csv`
for the two click tasks; `tentask_results.csv` for the other three tasks.
Historical SQL `pi0_multicam` contains duplicate records and must not be averaged
without selecting one final matched record per task/method/budget.
Budget scope: 0.25-0.625 core methods (0.75 not filled on new tasks; each cell ~8 min
and the pod must hold an SSH channel to run).
