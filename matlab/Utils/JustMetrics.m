function [IsolateInstances,TPrate,TNrate,Precision,Recall,F1,Adv_r] = ...
    JustMetrics(Yhat,Ytest)
%   author: ola

    % Ignoring Adv_r and IsolateInstances for now
    IsolateInstances = NaN;
    Adv_r = NaN;

    TPrate = sum(Yhat & Ytest) ./ sum(Ytest == 1);
    TNrate = sum(~(Yhat | Ytest)) ./ sum(Ytest == 0);
    Precision = sum(Yhat & Ytest) ./ sum(Yhat == 1);
    Recall = sum(Yhat & Ytest) ./ sum(Ytest == 1);
    F1 = 2 * Precision * Recall / (Recall + Precision);

end