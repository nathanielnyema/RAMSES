function y_hat = line_length_classify(clip, fs)
    THRESH1 = 10/256;
    THRESH2 = 25/256;

    avg_ll = median(abs(diff(clip, 1, 2)) / fs); % average at each time point
    y_hat_all = (avg_ll >= THRESH1) + (avg_ll >= THRESH2);
    y_hat = mode(y_hat_all);
end
