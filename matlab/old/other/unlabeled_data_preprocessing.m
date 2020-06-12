
%% Set up workspace
clear all; % Clear all data structures
load unlabeled_data; % Annotations from all patients marked on portal
iEEGid = 'cpainter'; % Change this for different user
iEEGpw = 'cpa_ieeglogin.bin'; % Change this for different user
channels = [3 4 5 9 10 11 12 13 14 20 21 23 24 27 31 32 33 34];
num_patients = size(all_annots,2); % Get number of patients

window_Length = 10;
window_Disp = 5;
first_patient = 0;
last_patient = 0;

%% Get intervals for all patients 
for i = first_patient:last_patient
    i
    session = IEEGSession(all_annots(i).patient, iEEGid, iEEGpw); % Initiate IEEG session
    sampleRate = session.data.sampleRate; % Sampling rate
    sz_num = length(all_annots(i).sz_start); % Get number of seizures
    
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
    
end

feats







