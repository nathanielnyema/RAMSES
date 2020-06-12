function init_classifier()
%   init_classifier builds the Litt Lab classifier by clustering the
%   training data and training a separate model for each cluster (saved as
%   modelArray). Each patient in the training data is mapped to its cluster
%   via clusterMap.

    clear
    %clear Data2Cluster

    global model

    % Load features (38 features x 16 patients)
    load('FEATURES', 'FEATURES')

    % train the random forest model
    %n_clusters = 4;
    model = build_classifier();

    % Patient IDs (RID0060 to RID0075)
    patient_ids = cell(length(FEATURES), 1);
    for i = 1:length(patient_ids)
        patient_ids{i} = ['RID00' num2str(59+i)];
    end
end