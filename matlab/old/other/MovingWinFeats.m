function features = MovingWinFeats(x, fs, winLen, winDisp, featFn)

    % INPUTS
    % x = input data to be processed
    % fs = sampling frequency of the input data
    % winLen = observation window length
    % winDisp = displacement between consecutive windows
    % featFn = handle to a function implementing the featFn
    %
    % OUTPUTS
    % features = a vector where each entry is the calculated feature
    
    xLen = length(x); % length of signal
    numWins = ceil(((xLen/fs)-(winLen-winDisp))/winDisp); % max number of full windows

    samplesWin = winLen * fs; % number of samples in each window
    samplesDisp = winDisp * fs; % number of samples in each displacement window

    n=1; % initialize window counting
    firstSample = 1; % initialize sample counting
    features = []; % initialize array to store features
    while n <= numWins-1
        values = x(firstSample:(firstSample+samplesWin-1)); % determine signal values for window
        res = featFn(values,fs);
        features = [features res']; % calculate features for window

        n = n+1; % advance window counter
        firstSample = firstSample + samplesDisp; % advance sample counter
    end
end