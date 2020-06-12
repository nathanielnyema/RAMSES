% Train random forest without clustering.
function [Model, Precision, Recall, F1] = ...
    train_rf(patientFeats, patientLabels)

    cut = 0.2;
    [F1, Precision, Recall, IsolateInstances, Model] = ...
        random_Forest(patientFeats, patientLabels, length(patientFeats), cut);

end