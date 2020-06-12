clear
% Get seizures
load('../other/all_annots_32.mat')

patients = all_annots(startsWith({all_annots.patient}, "RID00", 'IgnoreCase', false));

sz_times = [];
for i = 1:length(patients)
    patient = patients(i);
    sz_times = [sz_times; patient.sz_start' patient.sz_stop'];
end

sz_lengths = diff(sz_times, 1, 2);
sprintf('mean: %f', mean(sz_lengths))
sprintf('median: %f', median(sz_lengths))
sprintf('min: %f', min(sz_lengths))
sprintf('max: %f', max(sz_lengths))
sprintf('stdev: %f', std(sz_lengths))
histogram(sz_lengths, 30, 'facecolor', '#7E2F8E')
xlabel('Seizure length (seconds)')
