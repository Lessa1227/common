function [out,M]=Gauss2D(x,sigma,symmetric)
% Gauss2D	apply a 2 dimensional gauss filter
%
%    out = Gauss2D(x,sigma);
%
%    INPUT: x      image
%           sigma  of gauss filter
%           symmetric 1 to use imfilter with the option 'symmetric', 0
%           otherwise. Optional. Default: 0.
%
%    OUTPUT: out   filtered image
%            M     gaussian mask
%

% bug fix: AP - 10.07.02

if nargin < 3 || isempty(symmetric)
    symmetric = 0;
end

R = ceil(3*sigma);   % cutoff radius of the gaussian kernel
[I J] = meshgrid(-R:R);
M = exp(-.5 * (I.^2+J.^2) / sigma^2); % SB: remove the loop
M = M/sum(M(:));   % normalize the gaussian mask so that the sum is
                   % equal to 1
                   
% more correct version - and probably a bit faster
% M = GaussMask2D(sigma,2*R+1,[],1);

% Convolute matrices
if symmetric
    out = imfilter(x,M,'symmetric');
else
    out = filter2(M,x);
end

