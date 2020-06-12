function [Ysmooth] = VoteFiltering(Yhat,filtSize)

Ysmooth = Yhat;
for i = 1:(length(Yhat) - (filtSize-1))
    if(Yhat(i) && Yhat(i + (filtSize-1)))
        Ysmooth(i:(i + (filtSize-1))) = 1;
    end
end
end

