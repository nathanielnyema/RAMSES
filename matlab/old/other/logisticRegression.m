function [F1, Precision, Recall, accuracy] = logisticRegression(MyHugeFeats, MyHugeLabels, Num_patients)

X = [];
Y = [];
Xtest = [];
Ytest = [];
for i = 1:Num_patients
    X = [X MyHugeFeats{i}];
    Y = [Y MyHugeLabels{i}];
end

indices = randsample(size(X,2),floor(size(X,2)*0.30),false);

Xtest = X(:,indices);
Ytest = Y(indices);
X(:,indices) = [];
Y(indices) = [];

Y = Y+1;

Mdl = mnrfit(X',Y');

Yguess_cell = Mdl.predict(Xtest');

Yhat = str2num(cell2mat(Yguess_cell));

accuracy = sum((Yhat'==Ytest))/size(Ytest,2);

TPrate = sum((Yhat' + Ytest)==2)./sum(Ytest);

TNrate = sum((Yhat' + Ytest)==0)./sum(Ytest == 0);

Precision = sum((Yhat' + Ytest)==2)./sum(Yhat');

Recall = sum((Yhat' + Ytest)==2)./(sum((Yhat' + Ytest)==2) + sum(((Yhat' == 0)+ (Ytest==1))==2));

F1 = 2*Precision*Recall/(Recall + Precision);

