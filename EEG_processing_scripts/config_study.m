function cfg = config_study()
%CONFIG_STUDY Study-level parameters for the EEG processing pipeline.

cfg.fs = 128;

% Filtering
cfg.highpass_hz = 1;
cfg.lowpass_hz  = 30;
cfg.line_noise_hz = 50;

% Epoch/segment labels: replace with the exact event codes in the dataset.
cfg.conditions = {
    'baseline'
    'S1_wave_boardwalk'
    'S2_wave_park'
    'S3_wave_square'
    'S4_wave_beach'
    'S5_music_boardwalk'
    'S6_music_park'
    'S7_music_square'
    'S8_music_beach'
};

% Analysis duration in seconds. The manuscript reports:
% baseline = 3 min, recovery exposure = 7 min.
cfg.baseline_duration_s = 180;
cfg.recovery_duration_s = 420;

% Spectral bands
cfg.bands.delta = [1 4];
cfg.bands.theta = [4 8];
cfg.bands.alpha = [8 14];
cfg.bands.beta  = [14 30];

% Residual artifact rejection
cfg.max_abs_amplitude_uv = 150;
cfg.max_rejected_fraction = 0.20;

% ICA / ICLabel thresholds
cfg.use_iclabel = true;
cfg.iclabel_eye_threshold    = 0.80;
cfg.iclabel_muscle_threshold = 0.80;
cfg.iclabel_heart_threshold  = 0.80;
cfg.iclabel_line_threshold   = 0.90;
cfg.iclabel_channel_threshold = 0.90;

% Neural avalanche settings
cfg.avalanche.bin_samples = 4;       % 4 samples at 128 Hz = 31.25 ms
cfg.avalanche.min_size = 2;
cfg.avalanche.min_duration_bins = 2;
cfg.avalanche.threshold_method = 'channel_mean_abs';

% Paths
root = fileparts(mfilename('fullpath'));
cfg.paths.raw = fullfile(root, 'raw_eeg');
cfg.paths.processed = fullfile(root, 'processed_eeg');
cfg.paths.results = fullfile(root, 'results');

if ~exist(cfg.paths.processed, 'dir'), mkdir(cfg.paths.processed); end
if ~exist(cfg.paths.results, 'dir'), mkdir(cfg.paths.results); end
end