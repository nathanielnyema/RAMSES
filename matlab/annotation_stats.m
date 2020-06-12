pt_info = struct('ii_total', cell(77,1), 'sz_total', cell(77,1), ...
    'sz_num', cell(77,1));
for i = 1:77
    % patient info
    pt_num = pt_list(i);
    pt_type = pt_type_list(i); 

    % load annots file
    annot_file = load(sprintf('annot_%d.mat', pt_num));
    pt_name = eval(['annot_file.annot_' num2str(pt_num) '.patient']);
    
    % total length of ictal / iictal data
    if pt_type == 1
        ii_start = eval(['annot_file.annot_' num2str(pt_num) '.ii_start']);
        ii_stop = eval(['annot_file.annot_' num2str(pt_num) '.ii_stop']);
        ii_total = sum(ii_stop - ii_start);
        
        sz_start = eval(['annot_file.annot_' num2str(pt_num) '.sz_start']);
        sz_stop = eval(['annot_file.annot_' num2str(pt_num) '.sz_stop']);
        sz_num = length(sz_start); % Get number of seizures
        sz_total = sum(sz_stop - sz_start);
        
        pt_info(i).sz_num = sz_num;
        
        % Find when to start and stop dataset acquisition
        dataset_start = min([ii_start, ii_stop, sz_start, sz_stop]);
        dataset_stop = max([ii_start, ii_stop, sz_start, sz_stop]);
        
    % Check if patient type = 2, meaning patient is seizure free
    elseif pt_type == 2
        
        % Get interictal start and stop times
        ii_start = eval(['annot_file.annot_' num2str(pt_num) '.ii_start']);
        ii_stop = eval(['annot_file.annot_' num2str(pt_num) '.ii_stop']); 
        ii_total = sum(ii_stop - ii_start);
        
        sz_total = 0;
        
        % Find when to start and stop dataset acquisition
        dataset_start = ii_start;
        dataset_stop = ii_stop;
        
    % Check if patient type = 3, meaning patient is IIC
    elseif pt_type == 3
        
        % Get interictal ictal continuum start and stop times
        iic_start = eval(['annot_file.annot_' num2str(pt_num) '.iic_start']);
        iic_stop = eval(['annot_file.annot_' num2str(pt_num) '.iic_stop']);
        
        ii_total = 0;
        sz_total = 0;
        
        % Find when to start and stop dataset acquisition
        dataset_start = iic_start;
        dataset_stop = iic_stop;
    end
    
    pt_info(i).ii_total = ii_total;
    pt_info(i).sz_total = sz_total;
end

%% plots
ii_ratio = cell2mat({pt_info.ii_total}) ./ (cell2mat({pt_info.sz_total}) + cell2mat({pt_info.ii_total}));
ii_ratio = ii_ratio(ii_ratio < 1);

figure
scatter(ones(size(ii_ratio)), ii_ratio,'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
yline(mean(ii_ratio), '--')
xticks(1)
xticklabels('Seizure patients')
ylim([0 1])
ylabel('Nonseizure fraction')