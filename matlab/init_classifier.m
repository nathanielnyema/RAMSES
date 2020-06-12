function init_classifier()
%   Initialize the classifier into memory.
%   modeltype: choose 'rf' for the random forest classifier.
    clear
    global model;
    
    modeltype = 'rf'; % TODO: ability to choose between classifiers
    
    if strcmp(modeltype, 'rf')
        model = load('model_final.mat', 'rf').rf;
    else
        fprintf(2, 'Error: invalid model selection: %s\n', modeltype);
    end
end