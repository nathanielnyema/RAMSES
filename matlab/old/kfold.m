function [f1, precision, recall, bce] = kfold(m, X, Y, folds)
    n = length(Y);
    assert(n == size(X, 1));
    assert(n >= folds);
    
    fold_indices = round(linspace(1, n+1, folds+1));
    f1s = zeros(1, folds);
    precisions = zeros(1, folds);
    recalls = zeros(1, folds);
    bces = zeros(1, folds);
    
    % shuffle X/Y
    shuffle = randperm(n);
    X = X(shuffle,:);
    Y = Y(shuffle);

    fprintf('Cross Validation: ');
    for k = 1:folds
        fprintf('Fold %d ... ', k);
        ix = fold_indices(k):fold_indices(k+1) - 1;
        Xtest = X(ix,:);
        Ytest = Y(ix);
        Xtrain = X;
        Ytrain = Y;
        Xtrain(ix,:) = [];
        Ytrain(ix) = [];
        
        model = TreeBagger(m.NumTrees, Xtrain, Ytrain, ...
            'Cost', m.Cost, 'MinLeafSize', m.MinLeafSize);
        [Yhat, p] = model.predict(Xtest);
        Yhat = str2double(Yhat);
        TPrate = sum(Yhat & Ytest) ./ sum(Ytest == 1);
        TNrate = sum(~(Yhat | Ytest)) ./ sum(Ytest == 0);
        
        precision = sum(Yhat & Ytest) ./ sum(Yhat == 1);
        if isnan(precision)
            precisions(k) = 0;
        else
            precisions(k) = precision;
        end
        
        recall = sum(Yhat & Ytest) ./ sum(Ytest == 1);
        if isnan(recall)
            recalls(k) = 0;
        else
            recalls(k) = recall;
        end
        
        f1 = 2 * precision * recall / (recall + precision);
        if isnan(f1)
            f1s(k) = 0;
        else
            f1s(k) = f1;
        end
        
        bces(k) = -mean(sum(([1-Ytest Ytest] .* log2(p)), 2));
    end
    fprintf('\n');
        
    f1 = mean(f1s);
    precision = mean(precisions);
    recall = mean(recalls);
    bce = mean(bces);
    fprintf('    F1 %d\n    Precision: %.3f\n    Recall: %.3f\n    BCE: %.3f\n', ...
        f1, precision, recall, bce);
end