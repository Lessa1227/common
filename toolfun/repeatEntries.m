function out = repeatEntries(val,kTimes)
%REPEATENTRIES fills a matrix with k repeats the rows of the input matrix
%
% SYNOPSIS out = repeatEntries(val,kTimes)
%
% INPUT    val    : matrix (or vectors) containing the rows to repeat (works for strings, too)
%          kTimes : number of repeats of each row (scalar or vector of size(vlaues,1))
%
% OUTPUT   out    : matrix of size [sum(kTimes) size(values,2)] containing
%                   repeated entries specified with k
%
% EXAMPLES     repeatEntries([1;2;3;4],[2;3;1;1]) returns [1;1;2;2;2;3;4]
%              
%              repeatEntries([1;2;3;4],2) returns [1;1;2;2;3;3;4;4]
%
% c: jonas, 2/04
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%===========
% test input
%===========

% nargin
if nargin ~= 2 | isempty(val) | isempty(kTimes)
    error('two non-empty input arguments are needed!')
end

% size
valSize = size(val);
if length(valSize)>2
    error('only 2D arrays supported for val')
end

% do not care about size of k: we want to make a col vector out of it
kTimes = kTimes(:);

% decide whether we have scalar k
numK = length(kTimes);
if numK == 1
    scalarK = 1;
elseif numK ~= valSize(1)
    error('vector k must have the same length as the number of rows in val or be a scalar')
else 
    % check again whether we could use scalar k
    if all(kTimes(1) == kTimes)
        scalarK = 1;
    else
        scalarK = 0;
    end
end

%============
% fill in out
%============

% first the elegant case: scalar k
if scalarK
    
    % init out
    out = zeros( kTimes(1)*valSize(1), valSize(2) );
    
    % build repeat index matrix idxMat
    idxMat = meshgrid( 1:valSize(1), 1:kTimes(1) );
    idxMat = idxMat(:); % returns [1;1...2;2;... etc]
    
    out = val(idxMat,:);

% second: the loop    
else
    
    % init out, init counter
    out = zeros( sum(kTimes), valSize(2) );
    endct = 0;
    
    if valSize(2) == 1 
        
        % vector: fill directly
        
        % loop and fill
        for i = 1:valSize(1)
            startct = endct + 1;
            endct   = endct + kTimes(i);
            out(startct:endct,:) = val(i);
        end % for i=1:valSize(1)
        
    else
        
        % matrix: fill via index list
        
        idxMat = zeros(sum(kTimes),1);
        
        for i = 1:valSize(1)
            startct = endct + 1;
            endct   = endct + kTimes(i);
            idxMat(startct:endct) = i;
        end % for i=1:valSize(1)
        out = val(idxMat,:);
        
    end
    
    % check for strings and transform if necessary
    if isstr(val)
        out = char(out);
    end
    
end % if doScalar
   

