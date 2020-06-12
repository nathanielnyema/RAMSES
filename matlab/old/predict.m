function y_hat = predict(clip, fs)
%   predict
%   
%   Inputs: 
%       clip:       raw clip to classify (n_samples x n_channels)
%       fs:         sampling frequency in Hz
%    
%   Output:
%       y_hat:  0 if non-seizure,
%               1 if unsure,
%               2 if likely seizure
    global model

    % TODO: tune these thresholds
    THRESH1 = 0.2; % threshold for non-seizure
    THRESH2 = 0.8; % threshold for probable seizure

    % Extract features
    features = get_Features(clip, fs);
    
    % Run classifier
    [~,p1p2] = model.predict(features);
    p = p1p2(:,1); % probability of seizure
    y_hat = (p >= THRESH1) + (p >= THRESH2);
end
