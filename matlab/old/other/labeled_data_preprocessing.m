
%% Set up workspace
clear all; % Clear all data structures
load all_annots_131.mat; % Annotations from all patients marked on portal
iEEGid = 'jbernabei'; % Change this for different user
iEEGpw = 'jbe_ieeglogin.bin'; % Change this for different user

% Later patients have different extraneous channel labels on ieeg.org so 
% they require a different vector to select channels, however the same 
% location and number of true channels used in analysis is the same
channels_original_patients = [3 4 5 9 10 11 12 13 14 16 20 21 23 24 27 31 32 33 34];
channels_new_patients = [1 2 3 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
num_patients = size(all_annots,2); % Get number of patients

window_Length = 10;
window_Disp = 5;
first_patient = 1;
last_patient = 131;

%% Get intervals for all patients 
for i = first_patient:last_patient
    i
    % Select channel indices based on which patient we are using
    if i<33
        channels = channels_original_patients; %all patients with 'RID' ID on portal
    else
        channels = channels_new_patients; %all patients with 'CNT' ID on portal
    end
    
    % Connect to the IEEG session, and find the number of seizures on the
    % associated dataset.
    session = IEEGSession(all_annots(i).patient, iEEGid, iEEGpw); % Initiate IEEG session
    sampleRate = session.data.sampleRate; % Sampling rate
    sz_num = length(all_annots(i).sz_start); % Get number of seizures
    
    if i<33
        % Get seizure interval times
        a = 0;
        augmentedlabelSeizureVector(i).data = [];
        for j = 1:sz_num
            a = a+1;
            int_length = length([all_annots(i).sz_start(j):all_annots(i).sz_stop(j)]);
            intervals_SZ(i).data(a:(a+int_length-1)) = [all_annots(i).sz_start(j):all_annots(i).sz_stop(j)];
            a = a+int_length-1;
        end

        % Get interictal interval times, including pre-seizure beginning data
        b = 1;
        int_length = length([1:all_annots(i).sz_start(1)]);
        intervals_II(i).data(b:(b+int_length-1)) = [1:all_annots(i).sz_start(1)];
        for j = 1:(sz_num-1)
            b = b+1;
            int_length = length([all_annots(i).sz_stop(j):all_annots(i).sz_start(j+1)]);
            intervals_II(i).data(b:(b+int_length-1)) = [all_annots(i).sz_stop(j):all_annots(i).sz_start(j+1)];
            b = b+int_length-1;
        end
    else
        intervals_II(i).data = (1:(session.data.rawChannels(1).get_tsdetails.getDuration*1e-06));
    end
    
    % In this section, we find the duration of the dataset in terms of
    % number of samples, then we establish that we'd like to pull 4 hours
    % of data from the portal per call. We then make repeated calls to the
    % portal until there is less than one call of 4 hour's worth of data
    % left. This leaves a bit of data left on the table, and could be
    % changed, but there is some overhead in making calls to the portal.
    durationInSamples = floor(session.data.rawChannels(1).get_tsdetails.getDuration*1e-06*sampleRate);
    howMuchData = - 4*60*60*sampleRate - 1;
    hourCount = 0;
    data_with_NaN(i).data = [];
    draw = 0;
    
    while (howMuchData < (durationInSamples - 4*60*60*sampleRate))
        draw = draw +1
        data_with_NaN(i).data = [data_with_NaN(i).data; session.data.getvalues((hourCount*4*60*60*sampleRate+1):((hourCount+1)*4*60*60*sampleRate),channels)];
        hourCount = hourCount+1;
        howMuchData = max(howMuchData,0) + 4*60*60*sampleRate;
    end
        
    % Here we remove data from consideration until there is 15 minutes
    % worth of continuous non-NaN data for all channels in the patient. This is a form
    % of obvious artifact rejection, as some ICU sessions take a few
    % minutes for electrodes to correctly connected to the patient's scalp.
    sample_counter = 0;
    start_ind{i} = 1;
    ind = 1;
    found_full_15 = 0;
    bad_count = 0;
    while (found_full_15 == 0)
        sample_counter = sample_counter + 1;
        if (sum(isnan(data_with_NaN(i).data(ind,:)))>0)
            bad_count = bad_count + sum(isnan(data_with_NaN(i).data(ind,:)));
            if (bad_count>32)
                sample_counter = 0;
                start_ind{i} = ind + 1;
            end
        end
        if (sample_counter == 15*60*sampleRate)
            found_full_15 = 1;
        end
        ind = ind + 1;
    end
    
    chan_Feat = [];
    data_clip(i).data = data_with_NaN(i).data((start_ind{i} + 0.5*sampleRate*60):end - 10*window_Length,:);
    data_clip(i).data = rmmissing(data_clip(i).data);
    data_clip(i).data(find(isnan(data_clip(i).data))) = 0;
    for chan = 1:18
        chan
        chan_Feat(chan,:,:) =  MovingWinFeats(data_clip(i).data(:,chan), sampleRate, window_Length, window_Disp, @get_Features);
    end
    feats{i} = [squeeze(median(chan_Feat)); squeeze(var(chan_Feat)); squeeze(mean(chan_Feat))];
    
    labelSeizureVector{i} = zeros([1,size(feats{i},2)]);
    windPlacer = 1;
    for k = 1:size(labelSeizureVector{i},2)
        if(sum(intervals_SZ(i).data == (floor(start_ind{i}./sampleRate) + window_Disp*windPlacer+floor(window_Length/2))) > 0)
            labelSeizureVector{i}(k) = 1;
        end

        windPlacer = windPlacer + 1;
    end
end

feats
labelSeizureVector






