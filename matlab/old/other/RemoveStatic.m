function [outputArg1,outputArg2] = RemoveStatic(Yhat)
Ysmooth = Yhat;
for i = 2:(length(Yhat)-1)
    if(~Yhat(i-1) && Yhat(i) && ~Yhat(i+1))
        Ysmooth(i) = 0;
    end
end
end

