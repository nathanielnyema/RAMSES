function data = getclip(dataset, annots, window, ictal)
    if ictal
        % pick a seizure clip
        sz_time = annots(:, randsample(1:length(sz_times), 1)) * 1e6;
    else
        % pick an interictal clip
    end
    data = dataset.getvalues(start, window, 1:length(ds.channelLabels))';
end