function [rejected, features] = get_features(raw_data, fs)
%   This function preprocesses, checks for artifacts, and computes features.
%   Inputs:
%     raw_data: [n_samples x n_channels]
%     fs: sample rate in Hz
%   Output:
%     rejected: true if artifacts are detected
%     features: [n_samples x n_features], or empty if nans detected

    % artifact rejection criteria
    reject_params.thresholds = [0.25 2000 400 200 200 1000 2e4 40 10 50*10^6];
    reject_params.reject_thresh = 0.5;
    reject_params.num_reject_ch = 3;

    % check for NaNs
    if any(isnan(raw_data), 'all')
        rejected = true;
        features = [];
        return
    end

    % bandpass filtering
    f_low = 1; % Low cutoff frequency (Hz)
    f_high = 20; % High cutoff frequency (Hz)
    filter_chunk_data = filter_channels(raw_data, fs, f_low, f_high);

    % feature extraction and post-processing
    raw_feats = single_ch_features(filter_chunk_data,fs);
    [features, rejected, ~, ~] = post_process_feats(raw_feats, reject_params);
