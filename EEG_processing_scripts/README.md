# EEG Processing Scripts for Coastal Audiovisual VR Study

These scripts provide a reproducible **reference pipeline** aligned with the methods described in the manuscript:

- 32-channel EEG
- Sampling rate: 128 Hz
- Band-pass filtering: 1–30 Hz
- 50 Hz line-noise removal
- Bad-channel inspection/interpolation
- ICA-based removal of ocular, muscular, and motion-related components
- Rejection of residual bad segments
- Exclusion if more than 20% of data are rejected
- Spectral outcomes:
  - overall log power
  - alpha relative power (8–14 Hz)
- Exploratory neural avalanche outcomes:
  - avalanche size
  - avalanche duration
  - power-law exponents
  - avalanche criticality index (ACI)

## Important

These are not claimed to be the exact original scripts used in the study. They are a transparent, manuscript-aligned implementation that should be checked against the actual preprocessing decisions, channel layout, file format, event markers, epoch definitions, and software versions used in the experiment.

## Requirements

- MATLAB
- EEGLAB
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Optional: ICLabel EEGLAB plugin

## Folder structure

```text
project/
├─ raw_eeg/
├─ processed_eeg/
├─ results/
├─ config_study.m
├─ run_preprocessing.m
├─ compute_spectral_metrics.m
├─ compute_neural_avalanche.m
├─ fit_powerlaw_mle.m
└─ run_all.m
```

## Expected input

The preprocessing script assumes EEGLAB-readable EEG files such as `.set`. For other formats, replace the import section in `run_preprocessing.m`.

The script expects event markers that identify the experimental periods. Edit the condition labels in `config_study.m` so that they match the real dataset.

## Suggested public-repository deposit

At minimum, deposit:

1. These or the actual finalized scripts.
2. A codebook describing participant ID, condition, period, and all processed variables.
3. An anonymized condition-level CSV containing:
   - participant ID
   - sound type
   - visual condition
   - TMD
   - RCS
   - HRV summaries
   - overall EEG power
   - alpha relative power
   - ACI
4. A README documenting exclusions and software versions.

Raw EEG/ECG may be withheld when consent or ethics approval does not permit public sharing, but that restriction should be stated explicitly.