function matrix = correlation_Matrix(values)

%   correlation_Matrix.m
%   
%   Inputs:
%    
%       values:     Values for which features will be calculated.MxN where
%                   each of M rows is a channel of N samples of 
%                   electrophysiologic data.
%    
%   Output:
%    
%       matrix:     Correlation matrix in time for channels MxM
%    
%    License:       MIT License
%
%    Author:        John Bernabei
%    Affiliation:   Center for Neuroengineering & Therapeutics
%                   University of Pennsylvania
%                    
%    Website:       www.littlab.seas.upenn.edu
%    Repository:    http://github.com/jbernabei
%    Email:         johnbe@seas.upenn.edu
%
%    Version:       1.0
%    Last Revised:  October 2018
% 
%% Calculate correlation matrix
channelNo = size(values,2);
matrix = zeros(channelNo);

for i = 1:channelNo
    for j = 1:channelNo
        % Loop through channels and calculate cross correlation in time
        matrix(i,j) = max(abs(xcorr(values(:,i),values(:,j))));
    end
end
end