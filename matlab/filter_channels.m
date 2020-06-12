function filtered_data = filter_channels(data, fs, f_low, f_high)
    % adapted from the old get_Features function (ola)
    order = 4;
    [b,a] = besself(order, [f_low f_high], 'bandpass');
    [bz, az] = impinvar(b, a, fs);
    filtered_data = filter(bz, az, data);
end