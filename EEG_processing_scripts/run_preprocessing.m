function qc = run_preprocessing(input_file)
%RUN_PREPROCESSING Manuscript-aligned EEG preprocessing using EEGLAB.
%
% Input:
%   input_file - EEGLAB .set file
%
% Output:
%   qc - quality-control structure
%
% Notes:
% - Check the channel montage and event markers before use.
% - Manual review remains necessary for bad channels and ICA components.

cfg = config_study();

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui'); %#ok<ASGLU>

[folder, name, ext] = fileparts(input_file);
if ~strcmpi(ext, '.set')
    error('This reference implementation currently expects EEGLAB .set files.');
end

EEG = pop_loadset('filename', [name ext], 'filepath', folder);
EEG = eeg_checkset(EEG);

if EEG.srate ~= cfg.fs
    warning('Dataset sampling rate is %.3f Hz, while cfg.fs is %d Hz.', EEG.srate, cfg.fs);
end

% 1) Band-pass filter 1–30 Hz
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.highpass_hz, ...
                          'hicutoff', cfg.lowpass_hz);

% 2) Remove 50 Hz line noise using a narrow notch.
% Since low-pass is 30 Hz, this is technically redundant, but retained to
% mirror the manuscript wording. If filtering order differs in the real
% pipeline, document it exactly.
if cfg.line_noise_hz < EEG.srate / 2
    notch_width = 2;
    EEG = pop_eegfiltnew(EEG, ...
        'locutoff', cfg.line_noise_hz - notch_width/2, ...
        'hicutoff', cfg.line_noise_hz + notch_width/2, ...
        'revfilt', 1);
end

% 3) Identify grossly abnormal channels using robust channel statistics.
% This is an automated suggestion only; visually inspect before finalizing.
original_labels = {EEG.chanlocs.labels};
EEG_clean = pop_clean_rawdata(EEG, ...
    'FlatlineCriterion', 5, ...
    'ChannelCriterion', 0.80, ...
    'LineNoiseCriterion', 4, ...
    'Highpass', 'off', ...
    'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', ...
    'BurstRejection', 'off', ...
    'Distance', 'Euclidian');

remaining_labels = {EEG_clean.chanlocs.labels};
bad_labels = setdiff(original_labels, remaining_labels);

% Interpolate removed channels
if ~isempty(bad_labels)
    EEG_clean = pop_interp(EEG_clean, EEG.chanlocs, 'spherical');
end
EEG = EEG_clean;

% 4) Re-reference to average
EEG = pop_reref(EEG, []);

% 5) ICA
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'off');

removed_components = [];

% 6) Automated ICLabel-assisted component removal
if cfg.use_iclabel && exist('iclabel', 'file') == 2
    EEG = iclabel(EEG);
    classes = EEG.etc.ic_classification.ICLabel.classes;
    probs = EEG.etc.ic_classification.ICLabel.classifications;

    idx_eye = find(strcmpi(classes, 'Eye'));
    idx_muscle = find(strcmpi(classes, 'Muscle'));
    idx_heart = find(strcmpi(classes, 'Heart'));
    idx_line = find(strcmpi(classes, 'Line Noise'));
    idx_chan = find(strcmpi(classes, 'Channel Noise'));

    reject = false(size(probs,1),1);
    if ~isempty(idx_eye),    reject = reject | probs(:,idx_eye) >= cfg.iclabel_eye_threshold; end
    if ~isempty(idx_muscle), reject = reject | probs(:,idx_muscle) >= cfg.iclabel_muscle_threshold; end
    if ~isempty(idx_heart),  reject = reject | probs(:,idx_heart) >= cfg.iclabel_heart_threshold; end
    if ~isempty(idx_line),   reject = reject | probs(:,idx_line) >= cfg.iclabel_line_threshold; end
    if ~isempty(idx_chan),   reject = reject | probs(:,idx_chan) >= cfg.iclabel_channel_threshold; end

    removed_components = find(reject);
    if ~isempty(removed_components)
        EEG = pop_subcomp(EEG, removed_components, 0);
    end
else
    warning(['ICLabel not available. Inspect ICA scalp maps, time series, and spectra ', ...
             'manually and remove ocular, muscular, cardiac, and motion components.']);
end

% 7) Reject residual high-amplitude segments in fixed 1-s windows
window_samples = round(EEG.srate);
n_windows = floor(EEG.pnts / window_samples);
keep_mask = true(1, EEG.pnts);
rejected_windows = false(1, n_windows);

for w = 1:n_windows
    idx = (w-1)*window_samples + (1:window_samples);
    segment = EEG.data(:, idx);
    if any(abs(segment(:)) > cfg.max_abs_amplitude_uv)
        keep_mask(idx) = false;
        rejected_windows(w) = true;
    end
end

rejected_fraction = 1 - mean(keep_mask);

% For reproducibility, preserve the continuous dataset and mark rejected samples.
% A final analysis can remove these samples or exclude affected epochs.
EEG.etc.reference_pipeline.keep_sample_mask = keep_mask;
EEG.etc.reference_pipeline.rejected_fraction = rejected_fraction;
EEG.etc.reference_pipeline.bad_channel_labels = bad_labels;
EEG.etc.reference_pipeline.removed_components = removed_components;

valid_dataset = rejected_fraction <= cfg.max_rejected_fraction;

out_file = fullfile(cfg.paths.processed, [name '_preprocessed.set']);
pop_saveset(EEG, 'filename', out_file);

qc = struct();
qc.input_file = input_file;
qc.output_file = out_file;
qc.bad_channel_labels = bad_labels;
qc.removed_components = removed_components;
qc.rejected_fraction = rejected_fraction;
qc.valid_dataset = valid_dataset;

save(fullfile(cfg.paths.processed, [name '_qc.mat']), 'qc');
end