function partition = make_xval_partition(n_clips, n_folds)
%     Author: ola
%     Inputs:
%         n_clips: number of clips to partition
%         n_folds: desired number of partitions
%     Output:
%         partition: list of integers representing the fold for each clip

    assert(n_clips >= n_folds);

    % split data
    partition = zeros(n_clips, 1);
    fold_indices = round(linspace(1, n_clips+1, n_folds+1));
    for k = 1:n_folds
        partition(fold_indices(k) : fold_indices(k+1) - 1) = k;
    end
    
    % shuffle
    rand_ix = randperm(n_clips);
    partition = partition(rand_ix);
end