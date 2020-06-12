function build_features_file(input_hdf5_name)
    %% Convert hdf5 data file to 1xn cell array

    sample_rate = 256;
    FEATURES = cell(1, 16);
    LABELS = cell(1, 16);
    for i = 1:16
        patient_id = ['RID00' num2str(59+i)];
        % load ictal group
        ictals = h5read(input_hdf5_name, ['/ictal/' patient_id]);
        n_clips = size(ictals, 3);
        % extract features (n_features X n_clips)
        ictal_feats = zeros(n_clips, 40);
        for j = 1:n_clips
            ictal_feats(j,:) = ...
                get_Features(ictals(:,:,j)', sample_rate);
        end
        
        FEATURES{i} = ictal_feats;
        LABELS{i} = ones(n_clips, 1);

        % do the same thing for interictals
        interictals = h5read(input_hdf5_name, ['/interictal/' patient_id]);
        n_clips = size(interictals, 3);
        interictal_feats = zeros(n_clips, 40);
        for j = 1:n_clips
            interictal_feats(j,:) = ...
                get_Features(interictals(:,:,j)', sample_rate);
        end
        
        FEATURES{i} = [FEATURES{i}; interictal_feats];
        LABELS{i} = [LABELS{i}; zeros(n_clips, 1)];
    end

    % save .mat file
    save('FEATURES.mat', 'FEATURES');
    save('LABELS.mat', 'LABELS');
