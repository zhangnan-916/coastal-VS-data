function T = compute_neural_avalanche(preprocessed_set, participant_id, condition)
%COMPUTE_NEURAL_AVALANCHE Reference implementation of ACI analysis.
%
% Manuscript-aligned settings:
% - 4 samples per bin at 128 Hz = 31.25 ms
% - channel-specific threshold
% - avalanche = consecutive non-empty bins
% - minimum size >= 2
% - minimum duration >= 2 bins
% - ACI = abs((lambda2 - 1)/(lambda1 - 1) - lambda3)
%
% Important:
% The manuscript wording is not sufficient to reconstruct every numerical
% detail of lambda3. This implementation defines lambda3 from the scaling
% relation between mean avalanche size and duration using log-log linear
% regression. Confirm this against the actual method used by the authors.

cfg = config_study();
EEG = pop_loadset(preprocessed_set);
EEG = eeg_checkset(EEG);

X = double(EEG.data);

if isfield(EEG.etc, 'reference_pipeline') && ...
        isfield(EEG.etc.reference_pipeline, 'keep_sample_mask')
    mask = EEG.etc.reference_pipeline.keep_sample_mask;
    if numel(mask) == size(X,2)
        X = X(:, mask);
    end
end

bin_n = cfg.avalanche.bin_samples;
n_bins = floor(size(X,2) / bin_n);
X = X(:, 1:n_bins*bin_n);
Xb = reshape(X, size(X,1), bin_n, n_bins);

% Channel-specific threshold based on mean absolute amplitude
switch cfg.avalanche.threshold_method
    case 'channel_mean_abs'
        threshold = mean(abs(X), 2);
    otherwise
        error('Unknown threshold method.');
end

% Active channel if any sample in the bin exceeds that channel's threshold
active = squeeze(any(abs(Xb) > reshape(threshold, [], 1, 1), 2));
if isvector(active)
    active = reshape(active, size(X,1), n_bins);
end

events_per_bin = sum(active, 1);
nonempty = events_per_bin > 0;

% Detect runs of consecutive non-empty bins
d = diff([false, nonempty, false]);
starts = find(d == 1);
stops  = find(d == -1) - 1;

sizes = [];
durations = [];

for i = 1:numel(starts)
    idx = starts(i):stops(i);
    duration = numel(idx);
    avalanche_size = sum(events_per_bin(idx));

    if avalanche_size >= cfg.avalanche.min_size && ...
            duration >= cfg.avalanche.min_duration_bins
        sizes(end+1,1) = avalanche_size; %#ok<AGROW>
        durations(end+1,1) = duration; %#ok<AGROW>
    end
end

lambda1 = fit_powerlaw_mle(sizes, cfg.avalanche.min_size);
lambda2 = fit_powerlaw_mle(durations, cfg.avalanche.min_duration_bins);

% lambda3: scaling exponent of mean avalanche size by duration
unique_d = unique(durations);
mean_s = nan(size(unique_d));
for i = 1:numel(unique_d)
    mean_s(i) = mean(sizes(durations == unique_d(i)));
end

valid = unique_d > 0 & mean_s > 0;
if nnz(valid) >= 3
    p = polyfit(log(unique_d(valid)), log(mean_s(valid)), 1);
    lambda3 = p(1);
else
    lambda3 = NaN;
end

if isfinite(lambda1) && isfinite(lambda2) && isfinite(lambda3) && lambda1 ~= 1
    lambda4 = (lambda2 - 1) / (lambda1 - 1);
    ACI = abs(lambda4 - lambda3);
else
    lambda4 = NaN;
    ACI = NaN;
end

T = table(string(participant_id), string(condition), numel(sizes), ...
          lambda1, lambda2, lambda3, lambda4, ACI, ...
    'VariableNames', {'participant_id','condition','n_avalanches', ...
                      'lambda_size','lambda_duration', ...
                      'lambda_mean_size_duration','lambda_predicted', ...
                      'ACI'});

[~, name] = fileparts(preprocessed_set);
writetable(T, fullfile(cfg.paths.results, [name '_avalanche_metrics.csv']));

save(fullfile(cfg.paths.results, [name '_avalanche_details.mat']), ...
     'sizes', 'durations', 'events_per_bin', 'T');
end