function [y_hat, conf] = predict(clip, fs)
%   predict
%   
%   Inputs: 
%       clip:   raw clip to classify (n_samples x n_channels)
%       fs:     sampling frequency in Hz
%    
%   Outputs:
%       y_hat:  0 if non-seizure,
%               1 if unsure,
%               2 if likely seizure
%               3 if artifact or missing data
%       conf: confidence score (probability of seizure)
    global model

    % TODO: tune these thresholds
    THRESH1 = 0.2; % threshold for non-seizure
    THRESH2 = 0.8; % threshold for seizure

    % Extract features
    [rejected, features] = get_features(clip, fs);
    
    % Artifact rejection
    if rejected
        y_hat = 3;
        conf = 1.0;
        return
    end

    % TODO: change this to only predict 0 or 2 and label "unsure" cases
    % retroactively based on performance
    % Run classifier
    [~,scores] = model.predict(features);
    conf = scores(:,2); % probability of seizure
    y_hat = (conf >= THRESH1) + (conf >= THRESH2);
end
