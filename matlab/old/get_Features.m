function [feats] = get_Features(values,sampleRate)

%   get_Features.m
%   
%   Inputs:
%    
%       values:     Values for which features will be calculated.MxN where
%                   each of M rows is a channel of N samples of 
%                   electrophysiologic data.
%    
%   Output:
%    
%       feats:      Returns vector of features for chunk of data
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
%    Last Revised:  March 2019
% 
%% Do initial data processing
% Get number of channels
channelNo = size(values,2);

% Do filtering
order = 4; % Changed this from 5 to 4
low_freq = 0.5; % Hz
high_freq = 50; % Hz

[b,a] = besself(order,[low_freq high_freq],'bandpass');
[bz, az] = impinvar(b,a,sampleRate);
values=filter(bz,az,values); % This is generating almost 50% Nans

%% Theta band power
fcutlow1=4;   %low cut frequency in Hz
fcuthigh1=8;   %high cut frequency in Hz
p1 = mean(bandpower(values,sampleRate,[fcutlow1 fcuthigh1]));

%% Alpha band power
fcutlow2=8;   %low cut frequency in Hz    
fcuthigh2=12; %high cut frequcency in Hz
p2 = mean(bandpower(values,sampleRate,[fcutlow2 fcuthigh2]));

%% Filter for beta band
fcutlow3=12;   %low cut frequency in kHz
fcuthigh3=25;   %high cut frequency in kHz
p3 = mean(bandpower(values,sampleRate,[fcutlow3 fcuthigh3]));

%% Filter for 25-40 Hz band
fcutlow4=25;   %low cut frequency in kHz
fcuthigh4=40;   %high cut frequency in kHz
%p4 = mean(bandpower(values,sampleRate,[fcutlow4 fcuthigh4]));

%% Calculate features based on channel correlations
%matrix = correlation_Matrix(values);
%cVector = reshape(matrix, 1, []);
%varCM = var(cVector);
%avgCM = mean(cVector);
%upperCM = cVector(cVector>=(avgCM+sqrt(varCM)));
%lowerCM = cVector(cVector<=(avgCM-sqrt(varCM)));

%% Calculate features based on multitaper power spectral density
%[PSD z] = pmtm(values,4,256,256);
%meanmaxPSD = mean(max(PSD));
%PSDVector = reshape(PSD, 1, []);
%varPSD = var(PSDVector);
%avgPSD = mean(PSDVector);
%upperPSD = PSDVector(PSDVector>=(avgPSD+sqrt(varPSD)));
%lowerPSD = PSDVector(PSDVector<=(avgPSD-sqrt(varPSD)));

%% Calculate features based on linelength
%llfn = mean(line_Length(values));
%meanmaxLL = max(llfn);
%avgLL = mean(llfn);
%upperLL = llfn(PSDVector>=(avgLL+sqrt(varLL)));
%lowerLL = llfn(PSDVector<=(avgLL-sqrt(varLL)));
LLFn = sum(abs(diff(values)));
Energy = sum(values.^2);

%% Calculate wavelet entropy
Entropy = wentropy(values,'shannon');

%% Return vector of features
feats = [p1 p2 p3 Entropy LLFn Energy];
end