function llfn = line_Length(values)
%   line_Length.m
%   
%   Inputs:
%    
%       values:     Values for which features will be calculated.MxN where
%                   each of M rows is a channel of N samples of 
%                   electrophysiologic data.
%    
%   Output:
%    
%       llfn:       Returns line length of data with dimensions Mx(N-1)
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
%% Calculate linelength
llfn = abs(diff(values,1,2));

end