% [r, udata, sdata] = getMultiplicity(data) returns the occurrences/Multiplicity of the elements of 'data'
%
% Inputs:
%         data : n-dimensional input array
%
% Outputs: 
%          rep : # of occurrences for each element of 'data'
%        udata : sorted 1-D array of unique values in 'data'
%        sdata : sorted 1-D array of values in 'data'
%
% Note: NaN/Inf elements in input data are ignored

% Francois Aguet, 03/02/2012 (modified on 10/29/2012)
% Mark Kittisopikul, calculate udata only when requested, 09/11/2014

function [rep, udata, sdata] = getMultiplicity(data)

if(~isinteger(data))
    data = data(isfinite(data));
end
% sort
sdata = sort(data(:));
% store as row vector
sdata = sdata(:)';

% find where the numbers change in the sorted array
isDiff = [diff(sdata)~=0 1];
idx = find(isDiff);

if(nargout > 1)
    udata = sdata(idx);
end

% count occurrences
rep = diff([0 idx]);

