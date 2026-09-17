# Experiment artifacts

This directory preserves the experiment scripts and recorded outputs that were
previously distributed across the `t3r`, `t3r-cogact`, and `t3r-pi0` branches
of the OpenVLA-OFT fork.

The supported OpenVLA-OFT entry points are:

- `robot/run_libero_eval_with_sam.py`
- `robot/team/run_libero_eval_team.py`
- `robot/configs/config_baseline.yaml`
- `robot/configs/config_full_pipeline.yaml`
- `robot/configs/config_teamvla.yaml`

CogACT/SIMPLER and π0.5/RoboTwin files are retained as the exact public
research record. Several use the `/workspace` paths from the original
experiment machines; adjust those paths before running them elsewhere.
