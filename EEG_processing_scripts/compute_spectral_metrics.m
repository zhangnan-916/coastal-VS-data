function T = compute_spectral_metrics(preprocessed_set, participant_id, condition)
%COMPUTE_SPECTRAL_METRICS Compute overall log power and alpha relative power.
%
% This function assumes the input file already contains only the period
% corresponding to the requested condition, or that the dataset has first
% been segmented using the actual event markers.

cfg = config_study();
EEG = pop_loadset(preprocessed_set);
EEG = eeg_checkset(EEG);

data = double(EEG.data);

% Apply the retained-sample mask if available.
if isfield(EEG.etc, 'reference_pipeline') && ...
        isfield(EEG.etc.reference_pipeline, 'keep_sample_mask')
    mask = EEG.etc.reference_pipeline.keep_sample_mask;
    if numel(mask) == size(data,2)
        data = data(:, mask);
    end
end

if size(data,2) < EEG.srate * 10
    warning('Less than 10 s of data remain after rejection.');
end

% Welch PSD for each channel
window = round(2 * EEG.srate);
noverlap = round(window / 2);
nfft = max(256, 2^nextpow2(window));

n_ch = size(data,1);
band_power = struct();
fields = fieldnames(cfg.bands);
for k = 1:numel(fields)
    band_power.(fields{k}) = nan(n_ch,1);
end

for ch = 1:n_ch
    [pxx, f] = pwelch(data(ch,:), window, noverlap, nfft, EEG.srate);
    for k = 1:numel(fields)
        band = fields{k};
        limits = cfg.bands.(band);
        band_power.(band)(ch) = bandpower(pxx, f, limits, 'psd');
    end
end

% Overall absolute power: sum across delta, theta, alpha, beta and channels
overall_abs = sum(band_power.delta + band_power.theta + ...
                  band_power.alpha + band_power.beta, 'omitnan');
overall_log10 = log10(overall_abs);

% Alpha relative power
total_by_channel = band_power.delta + band_power.theta + ...
                   band_power.alpha + band_power.beta;
alpha_relative_by_channel = band_power.alpha ./ total_by_channel;
alpha_relative_mean = mean(alpha_relative_by_channel, 'omitnan');

T = table(string(participant_id), string(condition), overall_log10, ...
          alpha_relative_mean, ...
    'VariableNames', {'participant_id','condition', ...
                      'overall_log10_power','alpha_relative_power'});

[~, name] = fileparts(preprocessed_set);
writetable(T, fullfile(cfg.paths.results, [name '_spectral_metrics.csv']));
end