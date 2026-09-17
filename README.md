# T3R: Training-Free Two-Stage Token Refinement Towards Efficient and Robust VLA Models

Official implementation and experiment repository for **T3R** (ASP-DAC 2027),
a training-free inference-time framework that combines segmentation-guided
visual-token pruning with instruction-saliency attention biasing.

**Project website:** https://midotronn.github.io/t3r/

**OpenVLA-OFT implementation fork:** https://github.com/midotronn/openvla-oft/tree/t3r

**Base OpenVLA-OFT paper:** https://arxiv.org/abs/2502.19645

## Repository layout

The release is split into two repositories:

- **This repository (`midotronn/t3r`)** is the main entry point. It contains
  evaluation scripts, configs, analysis utilities, cross-backbone experiments,
  and recorded results.
- **`midotronn/openvla-oft`** is a fork of the original OpenVLA-OFT repository.
  Its `t3r` branch keeps the OpenVLA-OFT integration in one commit on top of the
  upstream branch and is pinned here as the `openvla-oft` submodule.

Clone the exact release with:

```bash
git clone --recurse-submodules https://github.com/midotronn/t3r.git T3R
cd T3R
source scripts/activate.sh
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

The gitlink records the implementation revision used by this release. Avoid
`git submodule update --remote` when reproducing the reported results.

## Method

T3R is applied at inference time on top of a pretrained VLA checkpoint without
retraining:

1. **SigLIP-SAM token pruning** uses text-image similarity to select
   task-relevant point prompts, generates a segmentation mask with EfficientTAM,
   and removes irrelevant visual patches before decoder entry.
2. **IG attention biasing** computes Integrated Gradients saliency over the
   instruction once per episode and applies an additive attention bias in
   middle decoder layers.

## Results reported in the paper

### OpenVLA-OFT on LIBERO-Spatial

Ten tasks with ten episodes per task. Reduction refers to scene-camera tokens
removed before decoder execution.

| Method | Token reduction | Success rate | Runtime |
|---|---:|---:|---:|
| Baseline | 0% | **97%** | 107.5 ms |
| TeamVLA | ~15% | 94% | 102.6 ms |
| FastV | 85% | 14% | Not reported |
| ADP | 85% | 66% | Not reported |
| **T3R** | **85%** | **96%** | **92.5 ms** |

T3R also matches the unpruned baseline within one percentage point on
LIBERO-Goal (98% versus 99%). Under object-position perturbations, it leads the
baseline by up to seven percentage points at 4 cm.

### Cross-backbone transfer

CogACT is evaluated zero-shot on single-camera SIMPLER. Each method is shown at
its native operating point.

| Method (keep ratio) | Google Robot | WidowX/Bridge |
|---|---:|---:|
| Baseline (100%) | **73.2%** | 10.4% |
| ADP (75% / ~87%) | 71.0% | **16.7%** |
| FastV (~60%) | 73.3% | 15.6% |
| TeamVLA (31.25%) | 69.5% | 12.5% |
| **T3R (60%)** | 67.7% | 10.4% |

The π0.5 transfer is evaluated zero-shot on five RoboTwin tasks with three
cameras. The unpruned baseline averages 33.4% success.

| Tokens/camera | Keep ratio | T3R | ADP | FastV | TeamVLA |
|---:|---:|---:|---:|---:|---:|
| 64 | 25% | **13.3%** | 13.3% | 11.7% | 3.3% |
| 96 | 37.5% | **25.0%** | 13.3% | 23.3% | 11.7% |
| 128 | 50% | **33.3%** | 19.4% | 18.1% | 13.9% |
| 160 | 62.5% | **38.3%** | 25.0% | 28.3% | 15.0% |
| 192 | 75% | **62.5%** | 33.4% | 37.5% | 20.9% |

## OpenVLA-OFT reproduction

The following environment was tested for the OpenVLA-OFT/LIBERO-Spatial
evaluation:

- 1x NVIDIA L40S 48 GB
- `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- at least 50 GB of disk space

### Install dependencies

Run these steps from the T3R repository root:

```bash
set -e

# OpenVLA-OFT requires this Transformers fork for bidirectional attention in
# the parallel decoder.
pip install git+https://github.com/moojink/transformers-openvla-oft.git

# Avoid the TensorFlow 2.15 / NumPy 2.x conflict in the tested RunPod image.
pip uninstall tensorflow tensorflow-datasets tensorflow-graphics -y 2>/dev/null || true

# json_numpy needs a type guard in this environment.
pip install json-numpy
python3 -c "
import inspect
import json_numpy

path = inspect.getfile(json_numpy)
content = open(path).read()
content = content.replace(
    '    if \"__numpy__\" in dct:',
    '    if isinstance(dct, dict) and \"__numpy__\" in dct:',
)
open(path, 'w').write(content)
print('Patched json_numpy')
"

pip install timm==0.9.16 captum scikit-learn draccus
pip install -e openvla-oft
```

Install LIBERO:

```bash
git clone https://github.com/Lifelong-Robot-Learning/LIBERO.git /workspace/LIBERO
pip install -e /workspace/LIBERO
pip install -r openvla-oft/experiments/robot/libero/libero_requirements.txt

mkdir -p ~/.libero
cat > ~/.libero/config.yaml <<'EOF'
benchmark_root: /workspace/LIBERO/libero/libero
bddl_files: /workspace/LIBERO/libero/libero/bddl_files
init_states: /workspace/LIBERO/libero/libero/init_files
datasets: /workspace/LIBERO/libero/datasets
assets: /workspace/LIBERO/libero/libero/assets
EOF
```

Install EfficientTAM:

```bash
git clone https://github.com/yformer/EfficientTAM.git /workspace/EfficientTAM
pip install hydra-core
mkdir -p /workspace/EfficientTAM/checkpoints
wget -q -O /workspace/EfficientTAM/checkpoints/efficienttam_s.pt \
  https://huggingface.co/yunyangx/efficient-track-anything/resolve/main/efficienttam_s.pt
```

For headless LIBERO rendering:

```bash
apt-get update -qq
apt-get install -y -qq libosmesa6-dev libgl1-mesa-glx libglfw3 patchelf
```

Update `sam_checkpoint` and `efficienttam_base_dir` in
`experiments/robot/configs/config_full_pipeline.yaml` if your paths differ from
the defaults.

### Activate the repository paths

Before each run:

```bash
source scripts/activate.sh
export CUDA_VISIBLE_DEVICES=0
export MUJOCO_GL=osmesa
export PYOPENGL_PLATFORM=osmesa
export PYTHONUNBUFFERED=1
export TOKENIZERS_PARALLELISM=false
```

`scripts/activate.sh` adds both this repository and the pinned OpenVLA-OFT
submodule to `PYTHONPATH`. Set `LIBERO_ROOT`, `EFFICIENTTAM_ROOT`, or
`COGACT_ROOT` before sourcing it to override their `/workspace` defaults.

### Run evaluations

T3R full pipeline:

```bash
python experiments/robot/run_libero_eval_with_sam.py \
  --config experiments/robot/configs/config_full_pipeline.yaml
```

OpenVLA-OFT baseline:

```bash
python experiments/robot/run_libero_eval_with_sam.py \
  --config experiments/robot/configs/config_baseline.yaml
```

TeamVLA:

```bash
python experiments/robot/team/run_libero_eval_team.py \
  --config experiments/robot/configs/config_teamvla.yaml
```

The first EfficientTAM episode can spend several minutes compiling Triton
kernels. Verify that pruning is active by checking for the EfficientTAM load
message and a nonzero patch-pruning ratio.

## Cross-backbone experiments and research record

- **CogACT/SIMPLER:** scripts are under `experiments/robot/`, including
  `t3r_cogact.py`, `run_cogact_libero_eval.py`, and the supporting baselines.
  Recorded outputs and analysis drivers are under
  `experiments/robot/t3r_results/`.
- **π0.5/RoboTwin:** scripts, configs, recorded CSVs, and experiment notes are
  under `experiments/robot/pi0_multicam/`.

These directories preserve the exact public research artifacts from the former
backbone-specific release branches. Some scripts retain `/workspace` defaults
for the machines used to run the experiments; override those paths for a
different environment.

Historical shell launchers from the former combined repository are retained
under `archive/legacy-openvla-scripts/`. They reference intermediate configs
that were intentionally removed during the earlier reproducibility cleanup and
are preserved for provenance rather than as supported entry points.

## Structure

```text
t3r/
├── openvla-oft/                       # Pinned implementation fork (submodule)
├── experiments/robot/
│   ├── run_libero_eval_with_sam.py    # T3R and OpenVLA-OFT baseline runner
│   ├── team/                          # TeamVLA runner
│   ├── configs/                       # Release evaluation configs
│   ├── t3r_cogact.py                  # CogACT integration
│   ├── t3r_results/                   # CogACT/SIMPLER records and drivers
│   └── pi0_multicam/                  # π0.5/RoboTwin scripts and results
├── scripts/activate.sh                # Repository path bootstrap
└── archive/legacy-openvla-scripts/    # Preserved intermediate launchers
```

The OpenVLA-OFT fork contains the model/runtime changes:

```text
openvla-oft/
├── prismatic/extern/hf/modeling_prismatic.py
├── prismatic/models/attention_bias.py
├── prismatic/models/siglip_guided_sam.py
├── prismatic/models/token_pruning.py
└── experiments/robot/{openvla_utils.py,robot_utils.py}
```

## Citation

If you use this code, please cite both T3R and OpenVLA-OFT:

```bibtex
@inproceedings{hassan2027t3r,
  title={T3R: Training-Free Two-Stage Token Refinement Towards Efficient and Robust VLA Models},
  author={Hassan, Mohammed and Chen, Zhenyang and Wang, Zheng and Zhu, Zhixin and Chen, Tianlong and Lin, Yingyan and Li, Chaojian},
  booktitle={Proceedings of the 32nd Asia and South Pacific Design Automation Conference (ASP-DAC)},
  year={2027}
}

@article{kim2025fine,
  title={Fine-Tuning Vision-Language-Action Models: Optimizing Speed and Success},
  author={Kim, Moo Jin and Finn, Chelsea and Liang, Percy},
  journal={arXiv preprint arXiv:2502.19645},
  year={2025}
}
```

The OpenVLA-OFT submodule retains its upstream history and license.
