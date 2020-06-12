%% Run all experiments

% ICU EEG project
% created by John Bernabei
% adapted for RAMSES by Ola Owoputi

%% Set up workspace
clear % Clear all data structures
oldpath = addpath('Utils', 'Data');

% Whether to run each portion
run_features = false; % Set to 1 to calculate & save features
train_ML = false; % Set to 1 to train classifiers
test_ML = false; % Set to 1 to test classifiers
run_adaptive = false; % Set to 1 to run adaptive learning
analyze_results = true; % Set to 1 to analyze results
make_figures = true; % Set to 1 to make figures
visualize = true; % Create data visualization figure
save_results = false; % Set to 1 to save results

iEEGid = 'owo'; % Change this for different user
iEEGpw = 'pwdfile.bin'; % Change this for different user

% Set up patients
all_pt_info = readtable('patient_table.csv');

% Extract patient list
pt_list = all_pt_info{:,2}; % The number of the annotation file

% Extract patient types
pt_type_list = all_pt_info{:,3}; % 1 = discrete sz, 2 = sz free, 3 = IIC

%% Set up important variables 

% Set window length
win_len = 10; % seconds

% Set up artifact rejection thresholds
% mean, variance, delta, theta, alpha, beta, LL, enveope, kurtosis, entropy
reject_params.thresholds = [0.25 2000 400 200 200 1000 2e4 40 10 50*10^6];
reject_params.reject_thresh = 0.5;
reject_params.num_reject_ch = 3;

% Machine learning classifier
classifier_type = 'random_forest';

% Number of folds
num_folds = 5;

% Whether to run interictal - ictal continuum patients
run_IIC = 0;

% set up channels
channels = [3 4 5 9 10 11 12 13 14 16 20 21 23 24 31 32 33 34];

% Set machine learning penalty
penalty_val = 500;

%% Calculate features
if run_features
    for i = 1:77
        % Get patient number
        pt_num = pt_list(i);
        
        if pt_num < 33 || pt_num == 92 || pt_num == 93 || pt_num == 94
            channels = [3 4 5 9 10 11 12 13 14 16 20 21 23 24 31 32 33 34];
        else
            channels = [3 4 5 8 9 10 11 12 13 14 16 17 18 19 24 25 26 27];
        end

        % Get patient type
        pt_type = pt_type_list(i); 

        % Use pull_data function to get data (size), times (size), and labels (size)
        [raw_data, raw_times, raw_labels, sample_rate] = pull_data(pt_num, pt_type, channels, iEEGid, iEEGpw);
        
        incorrect_artifact = [];
        a = 0;
        while isempty(incorrect_artifact)
            fprintf('starting feature calculation loop \n')
            % Use moving_Window function to calculate all features
            [features, num_removed, labels, time_windows, incorrect_artifact, bad_rejection_criteria, individual_features] = sliding_window(raw_data, sample_rate, win_len, raw_labels, raw_times(1), reject_params);
            sprintf('rejected %d windows of artifact\n',num_removed)
                            
            if ~isempty(incorrect_artifact) && (a<10)
                reject_params.thresholds = reject_params.thresholds.*1.5
                fprintf('Increasing rejection threshold criteria\n')
                size(bad_rejection_criteria)
                incorrect_artifact = [];
                a = a+1;
            else
                incorrect_artifact = 1;
            end
        end
        fprintf('Finish calculating features\n')
        
        % Save all features
        save(sprintf('Features/feats_3_sec_%d.mat',pt_num),'features', 'num_removed', 'labels', 'time_windows')
    end
end
%% Train machine learning
% Create train / test split
sz_list = pt_list(pt_type_list==1); % extract all patients with seizures
nsz_list = pt_list(pt_type_list==2); % extract all patients without seizures
iic_list = pt_list(pt_type_list==3); % extract interictal ictal continuum patients

% Partition patients into each different type
partition_sz = make_xval_partition(length(sz_list), num_folds);
partition_nsz = make_xval_partition(length(nsz_list), num_folds);
partition_iic = make_xval_partition(length(iic_list), num_folds);

if train_ML
    % Train machine learning classifier
    model_struct = machine_learning_train(sz_list, partition_sz, nsz_list, partition_nsz, penalty_val);
    
    % Save results
    save('Models/model_struct_3_sec.mat','model_struct','partition_sz','partition_nsz','partition_iic')
else
    load('Models/model_struct_3_sec.mat','model_struct','partition_sz','partition_nsz','partition_iic')
end

%% Test machine learning
if test_ML
    
    % Run machine learning testing pipeline
    [results_struct] = machine_learning_test(model_struct, sz_list, partition_sz, nsz_list, partition_nsz, iic_list, partition_iic);

    % Save machine learning test results
    save('Results/results_struct_3_4_1.mat','results_struct')
    
end

%% Run adaptive learning
% if run_adaptive
%     
%     [adaptive_struct] = adaptive_learning(sz_list, results_struct);
% 
%     % Save machine learning test results
%     save('Results/adaptive_struct_knn_3.mat','adaptive_struct')
%     
%     [semi_adaptive_struct] = semi_adaptive_learning(sz_list, partition_sz, nsz_list, partition_nsz, results_struct);
%     
%     save('Results/semi_adaptive_struct_rf_3.mat','semi_adaptive_struct')
% end

%% Run null model


%% Analyze machine learning
if analyze_results
        
    % Load desired results
%     load('Results/results_struct_5_1.mat')
%     load('Results/semi_adaptive_struct_rf.mat')
%     load('Results/adaptive_struct_knn-x_fold.mat')
    load('Results/results_struct_3_4_1.mat')
    
    % Analyze all raw results for patients with seizures
    [TN, AdvRecall, num_sz_true, num_sz_detect,all_Recall, segs_per_hour, segs_num] = compute_metrics(sz_list, 1, results_struct);

    % Analyze all raw results for patients without seizures
    [TN_free, ~, ~, ~, ~, segs_per_hour_f, segs_num_f] = compute_metrics(nsz_list, 2, results_struct);
    
    %% Analyze all adaptive learning results for patients with seizures
%     [a_TN, a_AdvRecall, a_num_sz_true, a_num_sz_detect, a_all_Recall] = compute_metrics(sz_list, 1, adaptive_struct);
%     
%     % Semi adaptive learning
%     [semi_sz_TN, semi_sz_AdvRecall, semi_sz_num_sz_true, semi_sz_num_sz_detect, s_all_Recall] = compute_metrics(sz_list, 1, semi_adaptive_struct);
%     [semi_nsz_TN, ~, ~, ~, ~] = compute_metrics(nsz_list, 2, semi_adaptive_struct);
%     
%     % Replace data reduction <75% with adaptive
%     poor_performance = find(TN(:,10)<0.8);
%     poor_performance_nsz = find(TN_free(:,10)<0.8);
%     
%     semi_free_TN = TN_free(:,10);
%     semi_free_TN(poor_performance_nsz) = semi_nsz_TN(poor_performance_nsz,10)
%     
%     semi_final_AdvRecall = AdvRecall(:,10);
%     semi_final_AdvRecall(poor_performance) = semi_sz_AdvRecall(poor_performance,10)
%     
%     semi_final_TN = TN(:,10);
%     semi_final_TN(poor_performance) = semi_sz_TN(poor_performance,10)
%     
%     final_AdvRecall = AdvRecall(:,10);
%     final_AdvRecall(poor_performance) = a_AdvRecall(poor_performance,10)
%     
%     final_TN = TN(:,10);
%     final_TN(poor_performance) = a_TN(poor_performance,10)
%     
end

%% Create plots
if make_figures
    % Set up color pallette
    color_pallette = [78 172 91;
                246 193 67;
                78 171 214;
                103 55 155]/255;
%     figure(1);clf;
%     histogram(AdvRecall(:,10),10)
%     
%             
% %     % FIGURE 1:
%     figure(1);clf;hold on
%     
%     TPR1 = null_TN(1:27,:);
%     FPR1 = null_Recall(1:27,:);
%     
%     TPR2 = TN(1:27,:);
%     FPR2 = all_Recall(1:27,:);
% 
%     mean_TPR1 = mean(TPR1); mean_FPR1 = mean(FPR1);
% 
%     sem_TPR1 = std(TPR1,1)./sqrt(size(TPR1,1)); sem_FPR1 = std(FPR1,1)./sqrt(size(FPR1,1));
%     
%     mean_TPR2 = mean(TPR2); mean_FPR2 = mean(FPR2);
% 
%     sem_TPR2 = std(TPR2,1)./sqrt(size(TPR2,1)); sem_FPR2 = std(FPR2,1)./sqrt(size(FPR2,1));
%     
%     shadedErrorBar(mean_FPR1,mean_TPR1,sem_TPR1,'lineprops',{'markerfacecolor','red'})
%     shadedErrorBar(mean_FPR2,mean_TPR2,sem_TPR2,'lineprops',{'markerfacecolor','blue'})
% 
%     % Label x and y axes
%     xlabel('Mean data reduction')
%     ylabel('Mean seizure sensitivity')
%     hold off

    % FIGURE 2: 
    % Plot of mean/median patient level seizure sensitivity versus data reduction
    figure(2);clf; hold on

    TPR = [TN;TN_free];
    FPR = AdvRecall(1:27,:);

    mean_TPR = mean(TPR);
    mean_FPR = mean(FPR);

    sem_TPR = std(TPR,1)./sqrt(size(TPR,1));
    sem_FPR = std(FPR,1)./sqrt(size(FPR,1));

    % Make a shaded error bar plot (FPR=sz sensitivity, TPR=data reduction)
    shadedErrorBar(mean_FPR, mean_TPR, sem_TPR, ...
        'lineprops',{'markerfacecolor','red'})

    % Label x and y axes
    xlim([0 1])
    ylim([0 1])
    xlabel('True negative rate')
    ylabel('Mean seizure sensitivity')
    hold off

    % Scatter plot of data reduction in patients with seizures vs without seizures
    figure(3);clf; hold on
    scatter_plot_axis = [ones(1,length(sz_list)),2*ones(1,length(nsz_list))];
    scatter(ones(1,length(sz_list)),TN(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
    scatter(2*ones(1,length(nsz_list)),TN_free(:,10),'jitter','on','MarkerEdgeColor',color_pallette(4,:),'MarkerFaceColor',color_pallette(4,:))
    
    plot([(1-0.15); (1 + 0.15)], [median(TN(:,10)),median(TN(:,10))], 'k-','Linewidth',2)
    plot([(2-0.15); (2 + 0.15)], [median(TN_free(:,10)),median(TN_free(:,10))], 'k-','Linewidth',2)
    
    axis([0.5 2.5 0 1.1])
    legend({'Seizure patients', 'Seizure-free patients'}, 'Location', 'southeast')
    xticks([])
    ylabel('Data reduction')
    hold off
    
    % Scatter plot of different advanced recalls
    figure(4);clf
    hold on
    scatter(ones(1,length(sz_list)), all_Recall(:,10), 'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
%     scatter(2*ones(1,length(sz_list)), semi_AdvRecall, 'jitter','on','MarkerEdgeColor',color_pallette(2,:),'MarkerFaceColor',color_pallette(2,:))
%     scatter(3*ones(1,length(sz_list)), final_AdvRecall(:,10), 'jitter','on','MarkerEdgeColor',color_pallette(4,:),'MarkerFaceColor',color_pallette(4,:))
    scatter(3*ones(1,length(sz_list)), AdvRecall(:,10), 'jitter','on','MarkerEdgeColor',color_pallette(4,:),'MarkerFaceColor',color_pallette(4,:))
    axis([0.5 3.5 0 1.1])
    
    plot([(1-0.15); (1 + 0.15)], [median(all_Recall(:,10)), median(all_Recall(:,10))], 'k-', 'Linewidth',2)
%     plot([(2-0.15); (2 + 0.15)], [median(semi_final_AdvRecall),median(semi_final_AdvRecall)], 'k-', 'Linewidth',2)
%     plot([(3-0.15); (3 + 0.15)], [median(final_AdvRecall),median(final_AdvRecall)], 'k-', 'Linewidth',2)
    plot([(3-0.15); (3 + 0.15)], [median(AdvRecall(:,10)), median(AdvRecall(:,10))], 'k-', 'Linewidth',2)
    
    xticks([1 3])
    xticklabels({'Fraction of seizures detected', 'Fraction of seizure segments detected'})
    yline(1, '--')
    ylabel('Recall')
    hold off
    
    % Plot data reduction for base vs semi-adaptive (seizure patients)
%     figure(5);clf
%     hold on
%     scatter(ones(1,length(sz_list)),TN(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
%     scatter(2*ones(1,length(sz_list)),semi_final_TN,'jitter','on','MarkerEdgeColor',color_pallette(2,:),'MarkerFaceColor',color_pallette(2,:))
%     axis([0.5 2.5 0 1.1])
%     
%     [p3,h3] = signrank(TN(:,10),semi_final_TN)
%     
%     plot([(1-0.15); (1 + 0.15)], [mean(TN(:,10)),mean(TN(:,10))], 'k-','Linewidth',2)
%     plot([(2-0.15); (2 + 0.15)], [mean(semi_final_TN),mean(semi_final_TN)], 'k-','Linewidth',2)
%     
%     title('Base vs semi adaptive data reduction')
%     hold off

    % Plot data reduction for base vs semi-adaptive (seizure-free patients)
%     figure(6);clf
%     hold on
%     scatter(ones(1,length(nsz_list)),TN_free(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
%     scatter(2*ones(1,length(nsz_list)),semi_free_TN,'jitter','on','MarkerEdgeColor',color_pallette(2,:),'MarkerFaceColor',color_pallette(2,:))
%     axis([0.5 2.5 0 1.1])
%     
%     [p4,h4] = signrank(TN_free(:,10),semi_free_TN)
%     
%     plot([(1-0.15); (1 + 0.15)], [mean(TN_free(:,10)),mean(TN_free(:,10))], 'k-','Linewidth',2)
%     plot([(2-0.15); (2 + 0.15)], [mean(semi_free_TN),mean(semi_free_TN)], 'k-','Linewidth',2)
%     
%     title('Base vs semi adaptive data reduction sz free')
%     hold off
end

%% Create data visualization figure
if visualize
    % Determine which patients to show.
    % Load feature matrix
    load('Features/feats_3_sec_5.mat'); %RID0064 ->
    Ytest = results_struct(5).Ytest;
    Yhat = results_struct(5).Yhat;
    figure(1);clf;
    hold on
    plot(time_windows,Ytest,'rs','MarkerSize',20,'markeredgecolor',color_pallette(3,:),'markerfacecolor',color_pallette(3,:))
    plot(time_windows,Yhat,'rs','MarkerSize',8,'markeredgecolor',color_pallette(4,:),'markerfacecolor',color_pallette(4,:))
    hold off

    %%
    load('Features/feats_3_sec_23.mat'); %RID00249 -> >99% data reduction, 72% sensitivity for 18 seizures
    Ytest = results_struct(23).Ytest;
    Yhat = results_struct(23).Yhat;
    figure(2);clf;
    hold on
    plot(time_windows,Ytest,'rs','MarkerSize',20,'markeredgecolor',color_pallette(3,:),'markerfacecolor',color_pallette(3,:))
    plot(time_windows,Yhat,'rs','MarkerSize',8,'markeredgecolor',color_pallette(4,:),'markerfacecolor',color_pallette(4,:))
    hold off
    %%
    load('Features/feats_3_sec_2.mat'); % RID0061 -> 92% data reduction, 100% sensitivity for 39 seizures
    Ytest = results_struct(2).Ytest;
    Yhat = results_struct(2).Yhat;
    figure(2);clf;
    hold on
    plot(time_windows,Ytest,'rs','MarkerSize',20,'markeredgecolor',color_pallette(3,:),'markerfacecolor',color_pallette(3,:))
    plot(time_windows,Yhat,'rs','MarkerSize',8,'markeredgecolor',color_pallette(4,:),'markerfacecolor',color_pallette(4,:))
    hold off

    % Make plots of their seizures & data reduction segments
end

%% Create data tables
sz_pts_bad_redux = find(TN(:,10) < 0.8)
nsz_pts_bad_redux = find(TN_free(:,10) < 0.8)
sz_pts_bad_recall = find(AdvRecall(:,10) < 0.8)
%% Save results

%% Cleanup
% path(oldpath);
