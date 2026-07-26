% RUN_ALL Example driver script.
%
% Edit file names, participant IDs, and event segmentation according to the
% real dataset. This script demonstrates the expected workflow only.

clear; clc;
cfg = config_study();

input_file = fullfile(cfg.paths.raw, 'sub001.set');

qc = run_preprocessing(input_file);
disp(qc);

if ~qc.valid_dataset
    error('Dataset rejected because more than 20%% of samples were marked as bad.');
end

% IMPORTANT:
% Before computing condition-level metrics, segment the continuous dataset
% according to the actual event codes and save one .set file per condition.
%
% Example placeholder:
condition_file = qc.output_file;
participant_id = 'sub001';
condition = 'baseline';

spectral_table = compute_spectral_metrics(condition_file, participant_id, condition);
avalanche_table = compute_neural_avalanche(condition_file, participant_id, condition);

disp(spectral_table);
disp(avalanche_table);