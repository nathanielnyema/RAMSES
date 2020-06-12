function [F1, Precision, Recall, Mdl] = ...
    random_Forest(Xtrain_cell, Ytrain_cell, Xtest_cell, Ytest_cell)

% build train and test sets
Xtrain = [];
Ytrain = [];
for i = 1:length(Ytrain_cell)
    Xtrain = [Xtrain; Xtrain_cell{i}];
    Ytrain = [Ytrain; Ytrain_cell{i}];
end

Xtest = [];
Ytest = [];
for i = 1:length(Ytest_cell)
    Xtest = [Xtest; Xtest_cell{i}];
    Ytest = [Ytest; Ytest_cell{i}];
end
% indices = randsample(size(X,1),floor(size(X,1)*testCut),false);
% Xtest = X(indices,:);
% Ytest = Y(indices);
% Xtrain = X;
% Ytrain = Y;
% Xtrain(indices,:) = [];
% Ytrain(indices) = [];

% train and cross-validate model
Mdl = TreeBagger(300, Xtrain, Ytrain, 'Cost', [0 0.01; 0.99 0], ...
    'MinLeafSize', 100);
[Yhat, p] = Mdl.predict(Xtest);
kfold(Mdl, Xtrain, Ytrain, 5);
Yhat = str2double(Yhat);
IsolateInstances = sum(Yhat == 1) ./ size(Ytest, 2);
TPrate = sum(Yhat & Ytest) ./ sum(Ytest == 1);
TNrate = sum(~(Yhat | Ytest)) ./ sum(Ytest == 0);
Precision = sum(Yhat & Ytest) ./ sum(Yhat == 1);
Recall = sum(Yhat & Ytest) ./ sum(Ytest == 1);
F1 = 2*Precision*Recall/(Recall + Precision);

end
